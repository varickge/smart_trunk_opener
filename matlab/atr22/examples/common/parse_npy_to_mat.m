function [file_data]=parse_npy_to_mat(filename)
    % This function is used to parse npy Radar raw data data and returns a
    % struct with the Frame data and the frame count
    
    data = readNPY(filename);

    cnt = 0;
    for i = 1:size(data,1)
       single_frame = squeeze(data(i,:,:,:));     % We will have  antennas, real/imag/, samples 
       Frame(i).Raw_data(:,:,:) = single_frame;
       cnt=cnt+1;
    end
%     frame_count=cnt;
%     output_matfile='recording.mat';
%     save(output_matfile,'Frame','frame_count','-v7.3')
    file_data.Frame = Frame;
    file_data.frame_count = cnt;
end