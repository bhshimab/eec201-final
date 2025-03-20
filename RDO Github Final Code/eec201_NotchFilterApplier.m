function eec201_NotchFilterApplier(folder_path)

    filtFreqs = [200, 450, 1200, 3700];

 %% Initial script setup --------------------------------------------------------------------------------------
  % Initial folder to go back to
    init_dir    = cd;

  % Go to the folder to process and get the contents
    start_dir   = cd(folder_path);   
    filelist    = dir();

  % Use a dynamic cell array to hold the trained speaker codebooks
    codebook    = {};

  % Waitbar so we know what's going on
    wb          = waitbar(0);

 %% Main audio read and processing loop -----------------------------------------------------------------------
  % For each file to process:
    for ind = 1:length(filelist)
      % If the file is valid
        if and(~filelist(ind).isdir, ~strcmp(filelist(ind).name(1), '.'))
            waitbar(ind./length(filelist),  wb, ['Working on file ', filelist(ind).name]);

          % Read the audio file info and data
            info        = audioinfo(filelist(ind).name);
            fs          = info.SampleRate;
            %bitDepth    = info.BitsPerSample;
            
            signal      = audioread(filelist(ind).name, 'double');

          % Confirm the signal is a mono row vector
            if min(size(signal)) > 1
                if size(signal, 1) > size(signal, 2)
                    signal = sum(signal, 2);
                else
                    signal = sum(signal, 1);
                end %if
            end %if

            if iscolumn(signal); signal = signal'; end

            filtsig = signal;

            for jnd = 1:length(filtFreqs)
                bstopfilt = designfilt('bandstopfir',                                                       ...
                                       'filterorder',       256,                                            ...
                                       'cutofffrequency1',  filtFreqs(jnd) - 10,                            ...
                                       'cutofffrequency2',  filtFreqs(jnd) + 10,                            ...
                                       'samplerate',        fs);

                filtsig = filtfilt(bstopfilt, filtsig);
            end %for jnd

            audiowrite([filelist(ind).name(1:end-4), '_filtered.wav'], filtsig, fs);

        end %if
    end %for ind
end %fcn