function [spect, freqs, times] = eec201_segmentedFFT(signal, fs, segment_len, overlap, window, show_work)
% Caluclate a segmented FFT periodogram using a window and segment overlaps

 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        signal      (1, :)      double      {mustBeNonempty}
        fs          (1, 1)      double      {mustBePositive, mustBeInteger}     = 44100;
        segment_len (1, 1)      double      {mustBePositive, mustBeInteger}     = 128;
        overlap     (1, 1)      double      {mustBePositive, mustBeInteger}     = 0;
        window      (1, :)      double                                          = ones(1, segment_len);
        show_work   (1, 1)      logical                                         = false;

    end %args

 %% Script Settings -------------------------------------------------------------------------------------------
    SHOW_WORK  = show_work;
    PAD_FACTOR = 4;


    if SHOW_WORK; close all; end

 %% Preloop Calculations --------------------------------------------------------------------------------------
  % Calculate non-loop variables
    freqs   = (fs/(segment_len*PAD_FACTOR)) * (0:(segment_len/2)*PAD_FACTOR - 1);

  % Pad the signal for full segement length slices
    % if mod(segment_len - overlap + 1, overlap)
    %     overpad = mod(length(signal), segment_len - overlap + 1) + overlap;
    %     signal  = [signal, zeros(1, overpad)];
    % end %if

    seglen  = (segment_len - overlap + 1);
    tsiglen = ceil(length(signal) ./ seglen) .* seglen;
    signal  = [signal, zeros(1, tsiglen - length(signal))];

  % Window Indicies and Times
    winInd  = 1:(segment_len-overlap)-1:length(signal)-(overlap+2);
    times   = (1/fs).*(winInd(1:end-1) - 1);

  % Window Amplitude Correction
    windowCorr = 1/(sum(window)/length(window));

    if SHOW_WORK
        figure('Position', [1500, 300, 1000, 700]); hold on; grid on;
        plot(signal)

        for ind = 1:length(winInd)
            xline(winInd(ind)); xline(winInd(ind) + overlap)
            plot(winInd(ind):winInd(ind)+length(window)-1, window)
        end %for ind

        xlabel('Sample Number'), ylabel('Amplitude')
    end %if
    
 %% Main spectrogram calculation loop -------------------------------------------------------------------------
  % Preallocate the spectrum matrix variable
  %                   FFT coeffs             Segment #
    spect = zeros(segment_len*PAD_FACTOR, length(winInd));

  % Perform the FFTs on the windowed signal slices
    for ind = 1:length(winInd)-1
      % Cut out and window the segment from the signal
        segment = signal(winInd(ind):winInd(ind)+segment_len-1) .* window .* windowCorr;

      % Perform the FFT and store in the output variable
        spect(:, ind) = fft(segment, segment_len*PAD_FACTOR);
    end %for ind

    if SHOW_WORK
        figure('Position', [1500, 300, 1000, 700]); hold on;
        surf(times, freqs, 20*log10(abs(spect(1:length(freqs), :))), 'EdgeColor', 'none');
        view(0, 90)

        xlabel('Segement Time, S'); ylabel('Frequency, Hz')
    end %if
end %fcn