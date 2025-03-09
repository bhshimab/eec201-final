function eec201_SpeakerEstimatorBaseline(speaker_folder_path, codebook, trainorder, show_work)
% Estimate source speaker by calculating cepstrum vector similarity to the VQ codebook entries


 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        speaker_folder_path     (1, :)      char        {mustBeFolder}
        codebook                (1, :)      cell        {mustBeNonempty}
        trainorder              (1, :)      string
        show_work               (1, 1)      logical                         = false;
    end %args

    % MFCC isn't actually indexing per mf filter band, but that's how i'm tracking it
    % speaker_mfcc(frame_time#, filter#)
    % codebook{speaker#} => codebook(codeword#, mffilter#)

 %% Script Settings -------------------------------------------------------------------------------------------
    SHOW_WORK  = show_work;

  % Make sure these match the training script parameters
    FRAME_TIME = 0.040;     % Rougly 40ms time window for each processing frame

    MEL_LOW_F  = 100;       % Assume most voice information lies between these two frequencies
    MEL_HIGH_F = 4000;
    N_MELFILTS = 20;        % Use this many filterbanks and 
    N_MFCOEFFS = 12;

 %% Initial script setup --------------------------------------------------------------------------------------
  % Initial folder to go back to
    init_dir    = cd;

  % Go to the folder to process and get the contents
    start_dir   = cd(speaker_folder_path);   
    filelist    = dir();

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

          % Use H(z) = 1 - az^-1, a = 15/16, as a premphasis filter
            pesignal    = [signal(1), signal(2:end) - (15/16*signal(1:end-1))];
            
          % The blocksize is chosen as the nearest order of 2 to the desired frame time
            blocksize   = 2.^ceil(log2(FRAME_TIME ./ (1/fs)));
            overlap     = blocksize/2;

            %blocksize = 2048;
            %overlap   = 1024;

          % Calc the window used for the spectrogram processor
            window      = hann(blocksize);

          % Calculate the mel freq cepstrum coefficients
          % This wraps the segmented FFT, mel filter bank, and mel cepstrum functions used
          % previously
            [mfcc, mfccTimes] = MelFreqCalc(pesignal,                                                       ...
                                            fs,                                                             ...
                                            blocksize,                                                      ...
                                            overlap,                                                        ...
                                            window,                                                         ...
                                            MEL_HIGH_F,                                                     ...
                                            MEL_LOW_F,                                                      ...
                                            N_MELFILTS);

            distances = zeros(length(codebook), size(mfcc, 1));

          % For each trained VQ codebook:
            for jnd = 1:length(codebook)
              % Calculate the minimum frame-to-codeword distances per codebook
                distances(jnd, :) = eec201_CalcSpeakerLikeness(mfcc(:, 2:N_MFCOEFFS+1), codebook{jnd});
            end %for ind

            [~, guess] = min(mean(distances, 2));
            disp([filelist(ind).name, ' guess is ', char(trainorder(guess))])
        end %if
    end %for ind

    delete(wb)
    cd(init_dir)

end %fcn