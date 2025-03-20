function [codebook, centroid_pops, cpop_codewords] = eec201_LBGVQTrainer(training_vectors, codebook_size, delta, show_work)
% Linde-Buzo-Gray Algorithm for training a vector quantization codebook
%
%   codebook(Centroid#, X_i)
%
 %% Argument checks -------------------------------------------------------------------------------------------
    arguments
        training_vectors    (:, :)      double      {mustBeNonempty}
        codebook_size       (1, 1)      double      {mustBePositive, mustBeInteger}
        delta               (1, 1)      double      {mustBePositive, mustBeNumeric}
        show_work           (1, 1)      logical                                         = false;
    end %args

 %% Script Settings -------------------------------------------------------------------------------------------
    SHOW_WORK  = show_work;
    GIF_NAME   = 'VQTraining.gif';
    SC_DIM3D   = false;

    if SHOW_WORK; close all; end


 %% Vector Quantization Notes
  % training_coeffs(Segment#, Filter#) - MFCCoeffs of the training data for a single voice


  % The vector space to be quantized is n_filter dimenstional. This is probably why the DCT is
  % used for the cepstrum so that the dimensionality at this step can be reduced.

  % If the input vector set is S(n, K), where n is the number of total vectors in the bouquet,
  % and Ki is the length of the vector in each ith dimension

  % The codebook training algorithm effectively looks at each n_filter-dimension vector in the 
  % set of n_segments and clusters them to a set of codebook_size groups


 %% Algorithm Initilization -----------------------------------------------------------------------------------
  % The initial codebook, C, is a set of means of the cepstrums for each filter band
  % length(C(k)) << length(S(n))

  % This is the 'center of mass' along each dimension of all of the vectors
    codebook = mean(training_vectors, 1);


  % n_vectors is the number of ceptstrum frames in time
    [nVectors, nDims] = size(training_vectors);
    
  % Setup fancy figure for gif plotting
    if SHOW_WORK
        F = figure('Position', [1000, 300, 1100, 600], 'Color', [1,1,1]);
        T = tiledlayout(F, 3, 1);
        G = nexttile(T, [2, 1]); G.NextPlot = 'add';
        H = nexttile(T);
        gifframeind = 1;
    end %if

    while length(codebook(:, 1)) < codebook_size
      % The codebook is 'split' by taking the existing centroid point(s) and shifting them
      % forward and backwards a small amount in each dimension
        codebook = [codebook.*(1+delta);  ...
                    codebook.*(1-delta)];

        minDistError = 1e10;
        BreakFlag    = true;

        if SHOW_WORK
            cla(G); grid(G, 'on');
            cla(H); grid(H, 'on');
            title(G, ['K = 1,2, 3 Scatter Plot, Codebook Size: ', num2str(length(codebook(:, 1)))]); 
            title(H, 'Relative Distance Error')
            
            if SC_DIM3D
                scatter3(G, training_vectors(:, 1), training_vectors(:, 2), training_vectors(:, 3), 100, '.');
                scatter3(G, codebook(end-1, 1), codebook(end-1, 2), codebook(end-1, 3), 100, 'red', '*');
                scatter3(G, codebook(end,   1), codebook(end,   2), codebook(end,   3), 100, 'red', '*');
                view(G, 45, 45); %zlim(G, [-15, 15])

            else
                scatter(G, training_vectors(:, 1), training_vectors(:, 2), 100, '.');
                scatter(G, codebook(end-1, 1), codebook(end-1, 2), 100, 'red', '*');
                scatter(G, codebook(end,   1), codebook(end,   2), 100, 'red', '*');            
            end %if

            xlim(G, [-10, 10]); ylim(G, [-10, 10]);

            A  = animatedline(H);
            animIter = 1;
        end %if

        while BreakFlag
          % Each group centroid is a codeword
            nCodewords = length(codebook(:, 1));

            cells = zeros(1, nVectors);
            dists = zeros(1, nVectors);

          % Determine which centroid each vector point is closest to
          % For each vector
            for ind = 1:nVectors
                vecDists = zeros(1, nCodewords);

              % For each codebook centroid
                for jnd = 1:nCodewords
                  % The K-dimension distances between each vector and the codebook centroid
                    vecDists(jnd) = sqrt(sum((training_vectors(ind, :) - codebook(jnd, :)).^2));
                end %for jnd

              % Find the closer centroid to the vector, log the cell and distance
                [dists(ind), cells(ind)] = min(vecDists);
            end %for ind

          % Guess new codewords as the center of mass of only the near vectors
            for ind = 1:nCodewords
                if any(cells==ind)
                    codebook(ind, :) = mean(training_vectors(cells==ind, :), 1);
                else
                    codebook(ind, :) = codebook(ind, :) .* (3*delta*(rand(1, nDims)-0.5));
                end %if
            end %for ind

          % Calculate the mean of the distances
            distError = mean(dists);

          % If the step error percentage is smaller than the given accuracy, break the loop
            if (minDistError - distError)/distError < delta
                BreakFlag = false;
            elseif distError <= 0.0001
                BreakFlag = false;
            else
                minDistError = distError;
            end %if

          % Fancy GIF animation of the training/centroid process
            if SHOW_WORK
                addpoints(A, animIter, minDistError);
                xlim(H, [1, 7]); ylim([0, 5])
                xlabel(H, 'Iteration Number'); ylabel(H, 'Distance Error')
                animIter = animIter + 1;

                ac = allchild(G);
                delete(ac(1:end-1));

                for ind = 1:nCodewords
                    if SC_DIM3D
                        scatter3(G, codebook(ind, 1), codebook(ind, 2), codebook(ind, 3), 100, 'red', '*');
                    else
                        scatter(G, codebook(ind, 1), codebook(ind, 2), 100, 'red', '*');
                    end %if
                end %for ind

                if nCodewords > 2
                    axes(G); K = voronoi(codebook(:, 1), codebook(:, 2));
                    set(K, 'color', "#D95319");
                    xlim(G, [-10, 10]); ylim(G, [-10, 10]);
                end %if
                
                drawnow;

                if BreakFlag; delay = 0.1; else delay = 0.5; end

                frame = getframe(F);
                im = frame2im(frame);
                [imind, cm] = rgb2ind(im, 256);

                if gifframeind == 1
                    imwrite(imind, cm, GIF_NAME, 'gif', 'Loopcount', inf, 'DelayTime', delay);
                else
                    imwrite(imind, cm, GIF_NAME, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
                end %if

                gifframeind = gifframeind + 1;
            end %if
        end %while true
    end %while codebook_size

    [centroid_pops, cpop_codewords] = histcounts(cells, 1:nCodewords);

    if SHOW_WORK; close(F); end

end %fcn