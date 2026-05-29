clear;
clc;

%% ==========================================================
% SETTINGS
% ===========================================================

root = 'C:\Users\jense\Documents\MATLAB\master\data-processing\data\swimming\forward-locomotion\anguilliform\power\2Hz';

Rshunt = 0.15;

%% ==========================================================
% DAQ SETTINGS
% ===========================================================

daqDeviceID = "Dev1";

daqChanVservo = "ai1";
daqChanVshunt = "ai0";

sampleRate = 1000;
chunkSize = 100;

%% ==========================================================
% PYTHON SOCKET CONNECTION
% ===========================================================

t = tcpclient("127.0.0.1", 5000);

%% ==========================================================
% INITIALIZE DAQ
% ===========================================================

dq = daq("ni");

addinput(dq, daqDeviceID, daqChanVservo, "Voltage");
addinput(dq, daqDeviceID, daqChanVshunt, "Voltage");

dq.Rate = sampleRate;

dq.ScansAvailableFcnCount = chunkSize;

%% ==========================================================
% PARAMETERS
% ===========================================================

frequency = 2;
amplitude = 10;
center = 87;

write(t, sprintf("freq %.3f\n", frequency));
pause(0.1);

write(t, sprintf("amp %.3f\n", amplitude));
pause(0.1);

write(t, sprintf("center %.3f\n", center));
pause(0.1);

%% ==========================================================
% EXPERIMENT LOOP
% ===========================================================

for k = 6





    fprintf('\n');
    fprintf('====================================\n');
    fprintf('Experiment %d\n', k);
    fprintf('====================================\n');

    % ------------------------------------------------------
    % Reset buffers
    % ------------------------------------------------------

    dq.UserData.Time = [];
    dq.UserData.Raw = [];

    dq.ScansAvailableFcn = @(src,evt) onScansAvailable(src);

    % ------------------------------------------------------
    % Start DAQ
    % ------------------------------------------------------

    disp('Starting DAQ');

    start(dq, "continuous");

    pause(0.5);

    % ------------------------------------------------------
    % Start swimming
    % ------------------------------------------------------

    disp('Starting swimming');

    write(t, "go");

    tSwim = tic;

    % ------------------------------------------------------
    % USER CONTROLLED STOP
    % ------------------------------------------------------

    input('Press ENTER when robot reaches target distance');

    write(t, "stop");

    disp('Waiting for graceful stop...');

    % ------------------------------------------------------
    % Wait for DONE
    % ------------------------------------------------------

    gotDone = false;

    while ~gotDone

        if t.NumBytesAvailable > 0

            msg = readline(t);

            disp(msg);

            if contains(msg, "done")
                gotDone = true;
            end
        end

        pause(0.01);

    end

    swimTime = toc(tSwim);

    % ------------------------------------------------------
    % Stop DAQ
    % ------------------------------------------------------

    stop(dq);

    dq.ScansAvailableFcn = [];

    % ------------------------------------------------------
    % Extract data
    % ------------------------------------------------------

    tDAQ = dq.UserData.Time;

    raw = dq.UserData.Raw;

    Vservo = raw(:,1)*2;

    Vshunt = raw(:,2);

    I = Vshunt ./ Rshunt;

    P = Vservo .* I;

    % ------------------------------------------------------
    % Plot
    % ------------------------------------------------------

    figure;

    plot(tDAQ, P);

    xlabel('Time [s]');
    ylabel('Power [W]');

    title(['Experiment ' int2str(k)]);

    grid on;

    % ------------------------------------------------------
    % Save
    % ------------------------------------------------------

    save(fullfile(root, sprintf('%d.mat', k)), ...
        'tDAQ', ...
        'Vservo', ...
        'Vshunt', ...
        'I', ...
        'P');

    fprintf('Experiment %d saved\n', k);

end

%% ==========================================================
% SHUTDOWN
% ===========================================================

write(t, uint8("exit\n"));

clear t;

disp('Finished');

%% ==========================================================
% CALLBACK
% ===========================================================

function onScansAvailable(src)

    if src.NumScansAvailable < 1
        return;
    end

    n = min(src.ScansAvailableFcnCount, src.NumScansAvailable);

    [d, t] = read(src, n, "OutputFormat", "Matrix");

    src.UserData.Raw = [src.UserData.Raw; d];

    src.UserData.Time = [src.UserData.Time; t];

end