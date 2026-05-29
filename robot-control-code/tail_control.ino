#include "isr_servo.h"

ISRServo finServo;

// ---- USER SETTINGS ----

// Servo pin
const int SERVO_PIN = 9;

// PWM frame frequency
const float PWM_FREQUENCY_HZ = 50.0f;

// Pulse width limits
const int PULSE_MIN_US = 1000;
const int PULSE_MAX_US = 2000;

// Safe mechanical limits
float MIN_ANGLE = 0;
float MAX_ANGLE = 100;

// Motion defaults
float centerAngle   = 50.0;   // servo mid-angle
float amplitudeDeg  = 24.0;   // swing around center
float frequencyHz   = 0.6;    // tail beat frequency (full cycles per second)

// How many command updates per cycle
const int UPDATES_PER_CYCLE = 30;
unsigned long UPDATE_INTERVAL_US;

// ---- Experiment State ----
float angle = centerAngle;   // used by PWM generator

bool experimentRunning       = false;

unsigned long experimentStartMs = 0;
unsigned long experimentStopMs  = 0;   // when to stop (in millis)

// Timing
unsigned long lastUpdateUs   = 0;

int numTailBeats = 5;  // default number of beats for next experiment

// Forward declarations
void startExperiment(int beats);
void stopExperiment();
void printCurrentSettings();
void updateUpdateInterval();

void setup() {
  finServo.begin(SERVO_PIN,PWM_FREQUENCY_HZ,PULSE_MIN_US,PULSE_MAX_US);
  finServo.writeAngle(angle);

  updateUpdateInterval();

  Serial.begin(115200);
  while (!Serial) { }            // wait for Serial on some boards

  Serial.println("=== Tail Beat Controller ===");
  Serial.println("Commands:");
  Serial.println("  f <value>  -> set frequency in Hz (e.g. f 1.5)");
  Serial.println("  a <value>  -> set amplitude in degrees (e.g. a 25)");
  Serial.println("  c <value>  -> set center angle (e.g. c 90)");
  Serial.println("  b <value>  -> set number of tail beats (e.g. b 10)");
  Serial.println("  go         -> start experiment with current beats");
  Serial.println("  <number>   -> start with that many beats (e.g. 8)");
  Serial.println();
  printCurrentSettings();
}

void loop() {
  // If no experiment is running, listen for commands
  if (!experimentRunning) {
    checkSerialCommand();
    return;
  }

  unsigned long nowUs = micros();
  unsigned long nowMs = millis();

  // Stop condition: reached total duration
  if (nowMs >= experimentStopMs) {
    stopExperiment();
    return;
  }

  // Time to update servo position?
  if (nowUs - lastUpdateUs >= UPDATE_INTERVAL_US) {
    lastUpdateUs = nowUs;

    // Time in seconds since experiment start
    float t = (nowMs - experimentStartMs) / 1000.0;

    // Sinusoidal angle: center + A * sin(2π f t)
    angle = centerAngle + amplitudeDeg * sin(2.0 * PI * frequencyHz * t);
    angle = constrain(angle, MIN_ANGLE, MAX_ANGLE);

    finServo.writeAngle(angle);
  }
}

// ---------------- Serial Command Handling ----------------

void checkSerialCommand() {
  if (Serial.available() == 0) return;

  String line = Serial.readStringUntil('\n');
  line.trim();
  if (line.length() == 0) return;

  char cmd = line.charAt(0);
  String argStr;
  float value;

  // If line starts with a letter, treat as command + value
  if ((cmd == 'f') || (cmd == 'F')) {
    argStr = line.substring(1);
    argStr.trim();
    value = argStr.toFloat();
    if (value > 0.0) {
      frequencyHz = value;
      updateUpdateInterval();
      Serial.print("Set frequencyHz = ");
      Serial.println(frequencyHz, 3);
      printCurrentSettings();
    } else {
      Serial.println("Invalid frequency.");
    }
    return;
  }

  if ((cmd == 'a') || (cmd == 'A')) {
    argStr = line.substring(1);
    argStr.trim();
    value = argStr.toFloat();
    if (value > 0.0) {
      // Ensure amplitude fits inside mechanical limits
      float maxAllowedAmp = (MAX_ANGLE - MIN_ANGLE) / 2.0;
      if (value > maxAllowedAmp) {
        Serial.print("Amplitude too large; limiting to ");
        Serial.println(maxAllowedAmp);
        amplitudeDeg = maxAllowedAmp;
      } else {
        amplitudeDeg = value;
      }
      Serial.print("Set amplitudeDeg = ");
      Serial.println(amplitudeDeg, 2);
      printCurrentSettings();
    } else {
      Serial.println("Invalid amplitude.");
    }
    return;
  }

  if ((cmd == 'c') || (cmd == 'C')) {
    argStr = line.substring(1);
    argStr.trim();
    value = argStr.toFloat();
    if (value >= 0.0 && value <= 180.0) {
      centerAngle = value;
      angle = centerAngle;
      Serial.print("Set centerAngle = ");
      Serial.println(centerAngle, 2);
      finServo.writeAngle(centerAngle);  // update immediately
      printCurrentSettings();
    } else {
      Serial.println("Invalid center angle (must be 0–180).");
    }
    return;
  }

  if ((cmd == 'b') || (cmd == 'B')) {
    argStr = line.substring(1);
    argStr.trim();
    int beats = argStr.toInt();
    if (beats > 0) {
      numTailBeats = beats;
      Serial.print("Set numTailBeats = ");
      Serial.println(numTailBeats);
      printCurrentSettings();
    } else {
      Serial.println("Invalid tail beat count.");
    }
    return;
  }

  // 'go' command (start with current numTailBeats)
  if (line.equalsIgnoreCase("go")) {
    startExperiment(numTailBeats);
    return;
  }

  // If it wasn't a lettered command, try to interpret as a bare number of beats
  int beats = line.toInt();
  if (beats > 0) {
    startExperiment(beats);
  } else {
    Serial.println("Unknown command. Use: f/a/c/b/go or a number for beats.");
  }
}

// ---------------- Experiment Control ----------------

void startExperiment(int beats) {
  if (beats <= 0 || frequencyHz <= 0.0) {
    Serial.println("Invalid beats or frequency; experiment not started.");
    return;
  }

  numTailBeats = beats;

  // Total experiment duration (s) = beats / frequency
  float durationSec = (float)numTailBeats / frequencyHz;

  experimentStartMs = millis();
  experimentStopMs  = experimentStartMs + (unsigned long)(durationSec * 1000.0);
  lastUpdateUs      = micros();

  experimentRunning = true;
}

void stopExperiment() {
  experimentRunning = false;
  angle = centerAngle;   // return to center
  finServo.writeAngle(angle);
  Serial.println("done");
}

// ---------------- Utility ----------------

void printCurrentSettings() {
  Serial.print("Current settings -> ");
  Serial.print("f = ");
  Serial.print(frequencyHz, 3);
  Serial.print(" Hz, A = ");
  Serial.print(amplitudeDeg, 1);
  Serial.print(" deg, center = ");
  Serial.print(centerAngle, 1);
  Serial.print(" deg, beats = ");
  Serial.println(numTailBeats);
}

void updateUpdateInterval() {
  float intervalSec = 1.0 / (frequencyHz * UPDATES_PER_CYCLE);
  UPDATE_INTERVAL_US = (unsigned long)(intervalSec * 1e6);

  // Clamp for safety
  UPDATE_INTERVAL_US = constrain(UPDATE_INTERVAL_US, 278, 20000);
}
