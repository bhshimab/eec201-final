function distances = eec201_CalcSpeakerLikeness(speaker_mfcc, codebook_page)
% Calculate the vector distances from a speaker mel freq cepstrum coefficient set to a given set
% of VQ vectors

 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        speaker_mfcc            (:, :)      double      {mustBeNonempty}
        codebook_page           (:, :)      double      {mustBeNonempty}
    end %args

    % MFCC isn't actually indexing per mf filter band, but that's how i'm tracking it
    % speaker_mfcc(frame_time#, filter#)
    % codebook{speaker#} => codebook_page(codeword#, mffilter#)

 %% Script Settings -------------------------------------------------------------------------------------------
    N_FILTERS = size(codebook_page, 2);

 %% Script Setup ----------------------------------------------------------------------------------------------
  % Save the minimum distances of each frame to each codeword
    distances = zeros(1, size(speaker_mfcc, 1));


 %% Main Loop -------------------------------------------------------------------------------------------------
  % For each frame of the mfcc
    for ind = 1:size(speaker_mfcc, 1)
        
      % Save the distance of the frame vector to each codeword
        codewordDists = zeros(1, size(codebook_page, 1));

      % For each codeword (centroid)
        for jnd = 1:size(codebook_page, 1)
            codewordDists(jnd) = sqrt(sum((speaker_mfcc(ind, 1:N_FILTERS) - codebook_page(jnd, :)).^2));
            %codewordDists(jnd) = mean(abs(speaker_mfcc(ind, 1:N_FILTERS) - codebook_page(jnd, :)));

            if any(isnan(codewordDists))
                disp('hey')
            end %if
        end %for jnd

      % The final frame difference is the minimum codeword distance
        distances(ind) = min(codewordDists);
        %distances(ind) = mean(codewordDists);
    end %for ind
end %fcn