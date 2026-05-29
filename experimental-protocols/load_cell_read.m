%% Test Parameters
root = 'C:\Users\jense\Documents\MATLAB\master\data-processing\data\load-cell-calibration';

dir = [root '\100g' '\10g'];

%% USER SETTINGS

% --- NI DAQ setup ---
daqDeviceID  = "Dev1";      % NI device name from NI MAX
daqChannel   = "ai1";       % Analog input channel
sampleRate   = 1000;        % Hz
chunkSize    = 100;         % Samples per DataAvailable event (buffer size)

% --- Arduino setup ---
arduinoPort  = "COM3";      % Change to your port
arduinoBaud  = 115200;      % Must match Arduino sketch

cmdGo        = "go";      % Command to start fin actuation
doneKeyword  = "done";      % What Arduino sends back when finished

maxWaitTime  = 200;          % seconds before we give up waiting for DONE


%% INITIALIZE DAQ

dq = daq("ni");
addinput(dq, daqDeviceID, daqChannel, "Voltage");   % adjust type if needed
dq.Rate = sampleRate;


% How often the callback fires (in scans)
dq.ScansAvailableFcnCount = chunkSize;

%% Experiment loop
h = figure;
hold on;

dq.UserData.Time = [];
dq.UserData.Data = [];


% DEFINE CALLBACK (no addlistener, just a property)

dq.ScansAvailableFcn = @(src,evt) onScansAvailable(src);

disp('Starting continuous DAQ acquisition (listener active)...');
start(dq, "continuous");

pause(10.0)

stop(dq);
disp('Stopping DAQ acquisition...');
dq.ScansAvailableFcn = [];    % optional: remove callback

% SAVE DATA

t = dq.UserData.Time;
data = dq.UserData.Data;

% Plot
figure(h);
plot(t, data);
xlabel('Time [s]');
ylabel('Sensor voltage [V]');
grid on;
box on;

% Optional: save to MAT file
save([dir '.mat'], 't', 'data');

hold off;

%% store data
function onScansAvailable(src)
    n = src.ScansAvailableFcnCount;

    % Read whatever is available (guard so we don't error)
    if src.NumScansAvailable < 1
        return;
    end
    n = min(n, src.NumScansAvailable);

    [d, t] = read(src, n, "OutputFormat","Matrix");

    src.UserData.Data = [src.UserData.Data; d];
    src.UserData.Time = [src.UserData.Time; t];
end