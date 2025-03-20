function [distance, confidence] = eec201_VQSpeakerLikeness(speaker_mfcc, codebook_page, cb_size, cb_delta)


 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        speaker_mfcc            (:, :)      double      {mustBeNonempty}
        codebook_page           (:, :)      double      {mustBeNonempty}
        cb_size                 (1, 1)      double      {mustBeNonempty, mustBePositive, mustBeInteger}
        cb_delta                (1, 1)      double      {mustBeNonempty, mustBePositive}
    end %args

 %% Script Setup ----------------------------------------------------------------------------------------------
  % Save the minimum distances of each frame to each codeword
    distances     = zeros(1, cb_size);
    codewordIndex = zeros(1, cb_size);

 %% Use the LBG VQ Trainer on the test data to produce another codebook ---------------------------------------
    [codebook, ...
     centpops, ...
     centcods] = eec201_LBGVQTrainer(speaker_mfcc, ...
                                     cb_size,      ...
                                     cb_delta);

 %% Compare the two codebook distances and populations to see if theyre a strong match ------------------------
  % For each test mfcc centroid:
    for ind = 1:length(codebook)
      % Save the inter centroid distances for the permutations of each book 
        codewordDists = zeros(1, size(codebook_page, 1));

      % For each comparison centroid:
        for jnd = 1:size(codebook_page, 1)
            codewordDists(jnd) = sqrt(sum((codebook(ind, :) - codebook_page(jnd, :)).^2));
            %codewordDists(jnd) = mean(abs(speaker_mfcc(ind, 1:N_FILTERS) - codebook_page(jnd, :)));

            if any(isnan(codewordDists))
                disp('hey')
            end %if
        end %for jnd

      % The final frame difference is the minimum codeword distance
        [distances(ind), codewordIndex(ind)] = min(codewordDists);

    end %for ind

    distance   = sum(distances);
    confidence = sum(diff(codewordIndex) == 1) ./ length(codebook);

end %fcn