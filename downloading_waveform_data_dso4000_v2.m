function w = downloading_waveform_data_dso4000_v2(w, os)
wave_format = query(os, 'WAVEFORM:FORMAT?');
if strcmp(wave_format, 'WORD')
    format_byte = 'int16';
    i_dat = 10;
elseif strcmp(wave_format, 'ASCii') || strcmp(wave_format, 'BYTE')
    format_byte = 'int8';
    i_dat = 19;
else
    disp('Error in getting Waveform Format while downloading waveform.')
    return
end
while(w.send_len_data + w.cur_len_data < w.tot_len_data)
    fprintf(os, 'WAVEFORM:DATA:ALL?');
    pause(1)
    [data, len] = binblockread(os, format_byte);
    fprintf(os, '*WAI');
    w.send_len_data=w.send_len_data + len;
    w.cur_len_data=len;
    for i=i_dat:1:length(data)
     w.data(w.data_len,1)=(data(i));
     w.data_len=w.data_len+1;
    end    
end
% One more pulling...
fprintf(os, 'WAVEFORM:DATA:ALL?');
[data, len] = binblockread(os, format_byte);
fprintf(os, '*WAI');
pause(1)
w.send_len_data=w.send_len_data + len;
w.cur_len_data=len;
for i=i_dat:1:length(data)
 w.data(w.data_len,1)=(data(i));
 w.data_len=w.data_len+1;
end