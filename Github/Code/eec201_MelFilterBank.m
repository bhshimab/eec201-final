function [filtBank, melCenters] = eec201_MelFilterBank(freqs, n_filters, f_low, f_high, show_work)
% Compute a set of logarithmically spaced triangular frequency space filter functions

 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        freqs       (1, :)      double      {mustBeNonempty}
        n_filters   (1, 1)      double      {mustBePositive, mustBeInteger}     = 20;
        f_low       (1, 1)      double      {mustBePositive}                    = 100;
        f_high      (1, 1)      double      {mustBePositive}                    = 8000;
        show_work   (1, 1)      logical                                         = false;
    end %args

 %% Script Settings -------------------------------------------------------------------------------------------
    SHOW_WORK  = show_work;

    if SHOW_WORK; close all; end

 %% Calculations ----------------------------------------------------------------------------------------------
  % Get the indicies of the nearest frequency in freqs to the desired high and low bank centers
    [~, fLoInd] = min(abs(freqs - f_low ));
    [~, fHiInd] = min(abs(freqs - f_high));
 
  % Calculate the evenly spaced mel frequencies
    % This code modifies the given Mel Freq calcualtion by adjusting the filter centers of the
    % triangles to the given start and end frequency, which is intended for later utility of
    % this script for log-spaced frequency analysis functions
    melFreqCenters            = zeros(1, n_filters + 2);
    melFreqCenters(2:end-1)   = 1125 .* linspace(log(1+freqs(fLoInd)/700), ...
                                                 log(1+freqs(fHiInd)/700), ...
                                                 n_filters);
    melFreqDiff               = melFreqCenters(3)     - melFreqCenters(2);
    melFreqCenters(1)         = melFreqCenters(2)     - melFreqDiff;
    melFreqCenters(end)       = melFreqCenters(end-1) + melFreqDiff;

  % Convert back from log spaced mel values to frequency
    melFreqFreqs   = 700 * (exp(melFreqCenters/1125) - 1);
    melCenters     = melFreqFreqs(2:end-1);

  % Preallocate the filter bank vectors
  %                   filter #    freq bin #
    filtBank = zeros(n_filters, length(freqs));

  % Calculate the triangular window for each freq center
    for ind = 1:n_filters
      % Find the FFT freq bin values that are closest to the target Mel points
        [~, fLoInd] = min(abs(freqs - melFreqFreqs(ind)));
        [~, fMiInd] = min(abs(freqs - melFreqFreqs(ind+1)));
        [~, fHiInd] = min(abs(freqs - melFreqFreqs(ind+2)));

      % Build the triangular filters using two mirrored linspace calcs
        filtBank(ind, fLoInd:fMiInd) = linspace(0, 1, (fMiInd - fLoInd) + 1);
        filtBank(ind, fMiInd:fHiInd) = linspace(1, 0, (fHiInd - fMiInd) + 1);
    end %for ind

  % Plot the resulting filter bank
    if SHOW_WORK
        figure('Position', [1500, 300, 1000, 700]); hold on;
        hold on; grid on

        for ind = 1:n_filters
            plot(freqs, filtBank(ind, :));
            xline(melFreqFreqs(ind+1));
            plot([melFreqFreqs(ind), melFreqFreqs(ind+2)], ind/n_filters .* [1,1]);
        end %for ind

        xlabel('Frequency, Hz'); ylabel('Amplitude')
    end %if
end %fcn