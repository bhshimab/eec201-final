function [codebook, centpops, centcods, fileorder] = eec201_CodeBookTrainerBaseline(training_folder_path, show_work)
%
%

 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        training_folder_path    (1, :)      char        {mustBeFolder}
        show_work               (1, 1)      logical                         = false;
    end %args

 %% Script Settings -------------------------------------------------------------------------------------------
    SHOW_WORK  = show_work;

    FRAME_TIME = 0.040;     % Rougly 40ms time window for each processing frame

    MEL_LOW_F  = 100;       % Assume most voice information lies between these two frequencies
    MEL_HIGH_F = 4000;
    N_MELFILTS = 20;        % Use this many filterbanks and 
    N_MFCOEFFS = 12;

    CB_SIZE    = 15;        % The number of centroid vectors to use per voice (becomes the next power of 2)
    CB_DELTA   = 0.01;      % The LBG epislon value for training

    if SHOW_WORK; close all; end


 %% Initial script setup --------------------------------------------------------------------------------------
  % Initial folder to go back to
    init_dir    = cd;

  % Go to the folder to process and get the contents
    start_dir   = cd(training_folder_path);   
    filelist    = dir();

  % Use a dynamic cell array to hold the trained speaker codebooks
    codebook    = {};

  % Waitbar so we know what's going on
    wb          = waitbar(0);
  
 %% Main audio read and processing loop -----------------------------------------------------------------------
    cbInd = 1;
    fileorder = [];

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

          % Demean the signal
            signal = signal - mean(signal);

          % Use H(z) = 1 - az^-1, a = 15/16, as a premphasis filter
            pesignal    = [signal(1), signal(2:end) - (15/16*signal(1:end-1))];
            
          % The blocksize is chosen as the nearest order of 2 to the desired frame time
            blocksize   = 2.^ceil(log2(FRAME_TIME ./ (1/fs)));
            overlap     = blocksize/2;

          % Calc the window used for the spectrogram processor
            window      = hann(blocksize);

          % Run the spectrogram analysis on the audio file
            [spectro,       ...
             freqs,         ...
             frametimes]    = eec201_segmentedFFT(      pesignal,                                           ...
                                                        fs,                                                 ...
                                                        blocksize,                                          ...
                                                        overlap,                                            ...
                                                        window);

          % Calculate the mel-freq filter bank vector set
            [filtbank,      ...
             melfreqs]      = eec201_MelFilterBank(     freqs,                                              ...
                                                        N_MELFILTS,                                         ...
                                                        MEL_LOW_F,                                          ...
                                                        MEL_HIGH_F); %whitespace? never heard of it

          % Calculate the mel-freq cepstrum from the spectrogram
            melFreqCept     = eec201_MelFreqCepstrum(   spectro,                                            ...
                                                        filtbank,                                           ...
                                                        melfreqs,                                           ...
                                                        frametimes); %yes i do it like this in real life too

          % melFreqCept(Spectrogram Segment #, Mel Freq Filter #)

          % Do the VQ training to produce the vector codebook to compare unknowns to
            [codebook{cbInd}, ...
             centpops{cbInd}, ...
             centcods{cbInd}] = eec201_LBGVQTrainer(    melFreqCept(:, 2:N_MFCOEFFS+1),                     ...
                                                        CB_SIZE,                                            ...
                                                        CB_DELTA);

            cbInd = cbInd + 1;

            fileorder = [fileorder, string(filelist(ind).name)];
        end %if
    end %for ind

    delete(wb)
    cd(init_dir)
end %fcn