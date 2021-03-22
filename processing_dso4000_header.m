function [w, msg] = processing_dso4000_header(data)
%% Function for reading preamble of the querying waveform data
%
% The processing length of the waveform parameter data header is 128
% bytes, but by querying the instrument, it only retunrs a length of
% 117~128 bits
%
    if length(data)>128
        w = NaN;
        msg = 1;
        fprintf('\nError in processing header. Probably, this is a waveform data\n')
        return
    elseif length(data)<=128 && length(data)>=117
        msg = 2;
        fprintf('\n...A preamble has been read. -OK-\n')
    else 
        msg = 3;
        fprintf('\nAnother Error has ocurred during preamble reading\n')
        return
    end
    %
    % OBS: The Programming manual is wrong. 
    % -For the CHs Voltages, it corresponds to 8 bits data
    % -Setting a CH Range of 1Volt returns 4.9e-318 in the querying.
    % -CH Scale correspond to Voltage_Range/10.
    %
    w.tmc_head =strcat(data(1:2));      % data[0]-data[1] (2 bits): Data header #9
    w.cur_len = strcat(data(3:11));     % data[2]-data[10] (9 bits): Indicates the byte length of the current data packet
    w.tot_len = strcat(data(12:20));    % data[11]-data[19] (9 bits): The total length of bytes indicating the amount of data
    w.send_len = strcat(data(21:29));   % data[20]-data[28] (9 bits): Indicates the byte length of the uploaded data
    w.run_state = strcat(data(30));     % data[29] (1 digit): Indicates the current running status 0 is paused 1 is running
    w.trig_state = strcat(data(31));    % data[30] (1 digit): Indicates the state of the trigger 0 is no valid trigger 1 is valid trigger
    w.ch1_offset = strcat(data(32:35)); % data[31]-data[34] (4 bits): Indicates the offset of channel 1
    w.ch2_offset = strcat(data(36:39)); % data[35]-data[38] (4 bits): Indicates the offset of channel 2
    w.ch3_offset = strcat(data(40:43)); % data[39]-data[42] (4 bits): Indicates the offset of channel 3
    w.ch4_offset = strcat(data(44:47)); % data[43]-data[46] (4 bits): Indicates the offset of channel 4
    w.CH1_voltage = strcat(data(48:55));% data[47]-data[54] (8 bits): Indicates the voltage of channel 1  1 V Range == 4.9e-318
    w.CH2_voltage = strcat(data(56:63));% data[55]-data[62] (8 bits): Indicates the voltage of channel 2  1 V Range == 4.9e-318
    w.CH3_voltage = strcat(data(64:71));% data[63]-data[70] (8 bits): Indicates the voltage of channel 3  1 V Range == 4.9e-318
    w.CH4_voltage = strcat(data(72:79));% data[71]-data[78] (8 bits): Indicates the voltage of channel 4  1 V Range == 4.9e-318
    w.ch_enabled = strcat(data(80:83)'); % data[79]-data[82] (4 bits): Indicates the status of the channel. 
    % See instructions for details
    w.sampling_rate = strcat(data(84:92)); % data[83]-data[91] (9 bits): Indicates the sampling rate
    w.extract_len = strcat(data(93:98));   % data[92]-data[97] (6 bits): indicates the sampling multiple
    w.trig_time = strcat(data(99:107));    % data[98]-data[106] (9 bits): Display trigger time of current frame
    w.start_time = strcat(data(108:116));  % data[107]-data[115] (9 bits): The start time point of the acquisition start point of the current frame display data
    w.Reserve_data = strcat(data(117:end));% data[116]-data[127] (12 bits?): reserved
    % The data read later is valid waveform data
    % Preparing waveform data reading...
    w.send_len_data=str2double(w.send_len); % String converted to number
    w.cur_len_data=str2double(w.cur_len);   % String converted to number
    w.tot_len_data=str2double(w.tot_len);   % String converted to number
    w.data_len=1;
end