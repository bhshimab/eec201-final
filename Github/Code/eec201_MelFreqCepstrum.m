function [mfCept] = eec201_MelFreqCepstrum(spectrum, filterBank, mel_cent_freqs, times, show_work)



 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        spectrum        (:, :)      double      {mustBeNonempty}
        filterBank      (:, :)      double      {mustBeNonempty}
        mel_cent_freqs  (1, :)      double
        times           (1, :)      double
        show_work       (1, 1)      logical                         = false;
    end %args


 %% Script Settings -------------------------------------------------------------------------------------------
    SHOW_WORK  = show_work;


    if SHOW_WORK; close all; end

 %% Mel Filter Bank Application -------------------------------------------------------------------------------
  % Preallocate the melfreq filtered spectrogram
  %                      Spectrogram Segment #       Mel Freq Filter #
    melFiltSpect = zeros(length(spectrum(1, :)), length(filterBank(:, 1)));

  % Each value of the filtered spectrum is the sum of each spectrum segment multiplied by the
  % mel freq bank filter function, such that the resulting matrix is an estimate of the energy
  % contained in the original spectrum slice for each mel frequency band
    for ind = 1:length(spectrum(1, :))
      % Get the magnitude of the complex half-spectrum
        specthalf = abs(spectrum(1:length(spectrum(:,1))/2, ind));

      % For each filter:
        for jnd = 1:length(filterBank(:, 1))
          % Compute the total sum of the amount of the spectrum under the filter
            melFiltSpect(ind, jnd) = sum(specthalf' .* filterBank(jnd, :));
        end %for jnd;
    end %for ind;

  % Show the new spectrogram after the filtering
    if SHOW_WORK
        figure('Position', [1500, 300, 1000, 700]); hold on;
        surf(times, mel_cent_freqs, 20*log10(melFiltSpect'), 'EdgeColor', 'none');
        xlabel('Time, S'); ylabel('Frequency, Hz')
    end %if

 %% Cepstrum Calculation --------------------------------------------------------------------------------------
  % Calculate the DCT of the log values of the Mel Freq filtered spectrogram
    mfCept = zeros(size(melFiltSpect));

  % For each spectrogram slice, calculate the DCT of the log of the mel-freq filtered segment
    for ind = 1:length(melFiltSpect(:, 1))
        if ~any(melFiltSpect(ind, :) == 0)
            mfCept(ind, :) = dct(log(melFiltSpect(ind, :)));
        end %if
    end %for ind

  % Does this thing make any intuitive sense at this point?
    if SHOW_WORK
        figure('Position', [1500, 300, 1000, 700]); hold on;
        surf(times, 1:length(mel_cent_freqs), mfCept', 'EdgeColor', 'none');
        xlabel('Time, S'); ylabel('DCT Bin Number')
    end %if


end %fcn

