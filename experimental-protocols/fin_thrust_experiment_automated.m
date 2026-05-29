%% Test Parameters
root = 'C:\Users\jense\Documents\MATLAB\master\data-processing\data\fin-oscillation';
finType = {'eel'; 'trout'; 'mackeral'; 'tuna'; 'boxfish'; 'average'};
material = {'petg+petg'; 'petg+tpu'; 'tpu+tpu'};
thickness = {'-const'; '-conic'};
frequency = {'0.6Hz'; '1Hz'; '1.5Hz'; '2Hz'; '2.5Hz'; '3Hz'; '3.5Hz'; '4Hz'; '4.5Hz'; '5Hz'; '5.5Hz'; '6Hz'; '6.5Hz'; '7Hz'};
amplitude = {'A0.15';'A0.18';'A0.21'};
frequency_num = [0.6 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7];
amplitude_num = [21.68 26.32 31.15
                 18.92 22.90 27.00
                 18.60 22.51 26.53
                 19.25 23.30 27.49
                 13.44 16.19 18.99
                 21.68 26.32 31.15];
beats = "b 7";
center = "c 49";
repitions = 6;
finType_num = 6;
material_num = 1;
thickness_num = 2;
dir = [root '\' finType{finType_num} '\' material{material_num} thickness{thickness_num}];

%% USER SETTINGS

% --- NI DAQ setup ---
daqDeviceID  = "Dev1";      % NI device name from NI MAX
daqChannel   = "ai0";       % Analog input channel
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


%% INITIALIZE ARDUINO SERIAL

arduino = serialport(arduinoPort, arduinoBaud);
pause(2.0);   % allow Arduino to reset after opening port

% Flush any startup text from Arduino
while arduino.NumBytesAvailable > 0
    line = strtrim(readline(arduino));
    fprintf("Arduino says: %s\n", line);
end


%% Experiment loop
for i = 1:length(frequency)
    for j = 1:length(amplitude)
        % SET TEST PARAMETERS
        writeline(arduino, center);
        writeline(arduino, beats);
        freq_line = "f " + string(frequency_num(i));
        writeline(arduino, freq_line);
        amp_line = "a " + string(amplitude_num(finType_num,j));
        writeline(arduino, amp_line);
        
        pause(5.0);
        
        % Flush any startup text from Arduino
        while arduino.NumBytesAvailable > 0
            line = strtrim(readline(arduino));
            fprintf("Arduino says: %s\n", line);
        end
        
        h = figure;
        hold on;
        for k = 1:repitions
            % BUFFERS FOR DATA (accessible from nested callback)
            
            dq.UserData.Time = [];
            dq.UserData.Data = [];
            
            
            % DEFINE CALLBACK (no addlistener, just a property)
            
            dq.ScansAvailableFcn = @(src,evt) onScansAvailable(src);
            
            disp('Starting continuous DAQ acquisition (listener active)...');
            write(arduino, cmdGo, "string");
            start(dq, "continuous");
            
            tStart = tic;
            gotDone = false;
            
            while ~gotDone
                if arduino.NumBytesAvailable > 0
                    line = strtrim(readline(arduino));
                    if contains(line, doneKeyword)
                        gotDone = true;
                    end
                end
            
                if toc(tStart) > maxWaitTime
                    warning('Timed out waiting for DONE from Arduino.');
                    break;
                end
            
                pause(0.01);  % small pause to avoid hammering CPU
            end
            
            pause(5.0)
            
            stop(dq);
            fprintf("Arduino says: %s\n", line);
            disp('Stopping DAQ acquisition...');
            dq.ScansAvailableFcn = [];    % optional: remove callback
            
            % SAVE DATA
            
            t = dq.UserData.Time;
            data = dq.UserData.Data;
            
            % Plot
            figure(h);
            subplot(2,3,k)
            plot(t, data);
            xlabel('Time [s]');
            ylabel('Sensor voltage [V]');
            title(['Experiment ' int2str(k)]);
            grid on;
            box on;
            
            % Optional: save to MAT file
            save([dir '\' frequency{i} '\' amplitude{j} '\' int2str(k) '.mat'], 't', 'data');
            
            disp(['Experiment ' int2str(k) ' complete.']);
        end
        sgtitle(['Experiments for ' finType{finType_num} ' fin with ' frequency{i} ' frequency and ' amplitude{j} ' amplitude - Sensor signal (baseline + actuation)']);
        hold off;
    end
end

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