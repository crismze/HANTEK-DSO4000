%% SCI commands script for Hantek osccilloscope
%
% Find a VISA-USB object.
%
clear; close all;
os = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x049F::0x505C::CN2043001005579::0::INSTR', 'Tag', '');
os = visa('agilent', 'USB0::0x049F::0x505C::CN2043001005579::0::INSTR');
%
% Buffers' length and Timeout
%
set(os, 'Timeout', 60.0) % Long time out for slow transfer and reading
set(os, 'InputBufferSize', 1e7);
% set(os, 'OutputBufferSize', 1e4);
%% Open Instrument
fopen(os);
%% Init the instrument to a known state
%
idn = query(os, '*IDN?');
idn = strsplit(idn, ',');
fprintf('\nConnected to Oscilloscope: "%s %s"\n',idn{1}, idn{2})
fprintf(os, '*CLS');        % Clear status (all register lines)
fprintf(os, '*RST');        % Default setup
fprintf(os, 'RUN OFF');     
isOPC = query(os, '*OPC?');
if ~isOPC
    disp('Reset and Clear Register Error');
    return;
end
%% My settings
%
os_settings.disp.num_channel = 1;
os_settings.channels.probe = [1 10 1 1];
os_settings.channels.range = {'10V' '1V' '1V' '1V'};
os_settings.timebase.mode = 'MAIN';
os_settings.timebase.Xsource = 'CHANNEL1';
os_settings.timebase.Ysource = 'CHANNEL2';
os_settings.timebase.range = 0.008;
os_settings.timebase.scale = 0.0005;
os_settings.acq.type = 'NORMAL';
os_settings.acq.count = 4;
os_settings.acq.points = 64000;
os_settings.acq.sRate = str2double(query(os, 'ACQUIRE:SRATE?'));
os_settings.trig.force_flag = 1;
os_settings.trig.sweep = 'NORMAL';
os_settings.trig.mode = 'EDGE';
os_settings.trig.slope = 'RISING';
os_settings.trig.source = 'EXT'; % Also the waveform source
os_settings.trig.level = 0.0;
os_settings.waveform.format = 'ASCII'; %Default Byte
os_settings.waveform.byteOrder = 'LITTLEENDIAN';
os_settings.waveform.source = 'CHANNEL1';
os_settings.waveform.mode = 'RAW';
os_settings.waveform.wPoints = 16000;
%% Timebase
%
fprintf(os, 'AUTO');
fprintf(os, '*WAI');
fprintf(os, ['TIMEBASE:MODE ' os_settings.timebase.mode]);
fprintf(os, ['TIMEBASE:SCALE ' num2str(os_settings.timebase.scale)]);
if strcmp(os_settings.timebase.mode, 'XY') 
    fprintf(os, ['TIMEBASE:XY:XSOURCE ' os_settings.timebase.Xsource]);
    fprintf(os, ['TIMEBASE:XY:YSOURCE ' os_settings.timebase.Ysource]);
end
%% Acquire config
%
fprintf(os, ['ACQUIRE:TYPE ' os_settings.acq.type]);
fprintf(os, '*WAI');
fprintf(os, ['ACQUIRE:COUNT ' num2str(os_settings.acq.count)]);
fprintf(os, '*WAI');
fprintf(os, ['ACQUIRE:POINTS ' num2str(os_settings.acq.points)]);
fprintf(os, '*WAI');
%% Channels off and Range
%
for it = 1:4
   fprintf(os, sprintf('CHANNEL%d:RANGE %s',it,os_settings.channels.range{it}));
   fprintf(os, '*WAI');
   fprintf(os, sprintf('CHANnel%d:DISPLAY OFF',it));
   fprintf(os, '*WAI');
   fprintf(os, sprintf('CHANnel%d:COUPling AC',it));
   fprintf(os, '*WAI');
   fprintf(os, sprintf('CHANNEL%d:PROBE %d',it, os_settings.channels.probe(it)));
   fprintf(os, '*WAI');
   
end
%% Trigger
%
fprintf(os, ['TRIGGER:SWEEP ' os_settings.trig.sweep]);
fprintf(os, ['TRIGger:MODE ' os_settings.trig.mode]);
fprintf(os, '*WAI');
fprintf(os, ['TRIGger:EDGe:SOURce ' os_settings.trig.source]);
fprintf(os, '*WAI');
fprintf(os, ['TRIGger:EDGe:LEVel ' num2str(os_settings.trig.level)]);
fprintf(os, '*WAI');
fprintf(os, ['TRIGGER:EDGE:SLOPE ' os_settings.trig.slope]);
fprintf(os, '*WAI');
pause(1)
%% Waveform config
%
fprintf(os, ['WAV:POINTS:MODE ' os_settings.waveform.mode]);
fprintf(os, '*WAI');
fprintf(os, ['WAV:POINTS ' num2str(os_settings.waveform.wPoints)]); % The instr. accepts the command, but doesn't affect the waveform data
fprintf(os, '*WAI');
fprintf(os, ['WAVEFORM:FORMAT ' os_settings.waveform.format]); % NORMAL, RAW, 
fprintf(os, '*WAI');
fprintf(os, ['WAVEFORM:BYTEORDER ' os_settings.waveform.byteOrder]); %BIGENDIAN, LITTLEENDIAN
pause(1)
%%
fprintf('\nOscilloscope configured with "My Settings"\n')
%% OPC Loop
%
fprintf(os, '*OPC');
ESRvalue = query(os, '*ESR?');
while ~bitand(str2double(ESRvalue),1)
    ESRvalue = query(os, '*ESR?');
end
%% Acquiring the signal
%
% Simulating actuation and image acquisition
%
fprintf(os, [os_settings.waveform.source ':DISPLAY ON']);
if strcmp(os_settings.timebase.mode, 'MAIN') 
    fprintf(os, 'CHANNEL2:DISPLAY ON');
end
pause(1)
fprintf(os, 'CLS');
flushinput(os);
fprintf(os, 'RUN ON');
disp('Trigger ON?')
if os_settings.trig.force_flag == 1
   fprintf(os, 'TRIGGER:FORCE ON');
end
pause(5);
if os_settings.trig.force_flag == 1
   fprintf(os, 'TRIGGER:FORCE OFF');
end
%
fprintf(os, 'RUN OFF');
fprintf('\n-----Waveform record completed----\n')
fprintf(os, '*WAI');
%%
%
% First query correspond to the preamble with all the Oscilloscope
% configuration. The Second query correspond to waveform data.
%
% In the RAW waveform points mode, up to 10k or 20k points of memory 
% data is available only when the oscilloscope is stopped.
%

%
% First query: PREAMBLE
%
preamble = query(os, 'WAVEFORM:DATA:ALL?');
fprintf(os, '*WAI');
pause(1)
[waveform, hedear_err] = processing_dso4000_header(preamble);
%
% Second query: WAVE DATA
%
waveform.data = [];
waveform = downloading_waveform_data_dso4000_v2(waveform,os);
pause(1)
fprintf('\n-----Waveform download complete----\n')
fprintf(os, '*WAI');
%
% Closing session
%
flushinput(os);
fclose(os);
set(os, 'InputBufferSize', 512);
set(os, 'OutputBufferSize', 512);
delete(os)
clear os
%% Post-processing
%
% 1 V correspond to 4.9e-318 (Tested by setting and getting CHANNEL1:RANGE)
%
factor = 4.9e-318;
probes = os_settings.channels.probe;
ch_scale = probes.*[str2num(waveform.CH1_voltage) str2num(waveform.CH2_voltage)...
            str2num(waveform.CH3_voltage) str2num(waveform.CH4_voltage)]/factor;
ch_range = 10*ch_scale;
adc2volt = ch_range/(2^8-1); % Factor to convert 8-bit ADC to Volt
num_points = length(waveform.data);
figure(100)
if strcmp(os_settings.timebase.mode, 'MAIN')
   wv_data1 = adc2volt(1)*waveform.data(1:num_points/2);
   wv_data2 = adc2volt(2)*waveform.data(num_points/2+1:end);
   plot(wv_data1);
   hold on
   plot(wv_data2)
   hold off
   xlim([0 num_points/2])
   legend('CH1','CH2')
else
   plot(waveform.data)
   xlim([0 num_points])
   legend('CH1')
end
xlabel('Number of Points');
ylabel('Volts')