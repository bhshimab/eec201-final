%% Comment out the tests you don't want to run

% Run this for test 7
test7()

% Run this for test 8
% test8()

% Run this for test 9
% test9()

% Run this for test 10a Question 1
% test10aQ1()

% Run this for test 10a Question 2
% test10aQ2()

% Run this for test 10b
% test10b()

%% Batch tests
function test7()
    % Number of training and test files
    num_train = 11;
    num_test = 8;
    M = 64; % Number of codebook centroids
    eps = 0.01; % Convergence threshold
    
    % Initialize storage for training VQ codebooks
    vq_codebooks = cell(1, num_train);
    
    % Counter for correct matches
    correct_matches = 0;
    total_tests = 0;

    % Load training data and compute VQ codebooks
    for i = 1:num_train
        filename = sprintf("GivenSpeech_Data/Training_Data/s%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end
    
    % Load test data and compare against training set
    for j = 1:num_test
        test_filename = sprintf("GivenSpeech_Data/Test_Data/s%d.wav", j);
        test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
        test_codebook = test_mfcc; % Use MFCC directly for comparison
        total_tests = total_tests + 1;

        % Compare test VQ codebook with all training codebooks
        min_dist = inf;
        best_match = -1;
        
        for i = 1:num_train
            dist = vq_dist(test_codebook, vq_codebooks{i}); % Compute VQ distortion
            
            if dist < min_dist
                min_dist = dist;
                best_match = i;
            end
        end
    
        % Check if the match is correct (test number matches training number)
        if best_match == j
            correct_matches = correct_matches + 1;
        end

        % Print best matching speaker for this test file
        fprintf("Test file s%d.wav best matches with Training file s%d.wav\n", j, best_match);
    end

    % Display correct match statistics
    fprintf("\nCorrect matches: %d/%d (%.2f%%)\n", correct_matches, total_tests, (correct_matches / total_tests) * 100);
end

function test8()
    % Number of training and test files
    num_train = 11;
    num_test = 8;
    M = 64 ; % Number of codebook centroids
    eps = 0.01; % Convergence threshold
    
    % Initialize storage for training VQ codebooks
    vq_codebooks = cell(1, num_train);
    
    % Notch filter parameters (adjustable)
    notch_freqs = [250, 400];  % Frequencies to suppress (Hz)
    
    % Load training data and compute VQ codebooks
    for i = 1:num_train
        filename = sprintf("GivenSpeech_Data/Training_Data/s%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end
    
    % Counters for correct matches
    correct_matches = 0;
    total_tests = 0;

    % Load test data, apply notch filtering, save, and compare against training set
    for j = 1:num_test
        test_filename = sprintf("GivenSpeech_Data/Test_Data/s%d.wav", j);
        [y, fs] = audioread(test_filename); % Load audio signal
        
        % Apply notch filters to the test signal
        filtered_signal = y;
        for f = notch_freqs
            d = designfilt('bandstopiir', 'FilterOrder', 2, ...
                           'HalfPowerFrequency1', f-5, 'HalfPowerFrequency2', f+5, ...
                           'SampleRate', fs);
            filtered_signal = filtfilt(d, filtered_signal); % Apply notch filter
        end
        
        % Save the filtered signal to a temporary file
        filtered_filename = sprintf("GivenSpeech_Data/Test_Data/filtered_s%d.wav", j);
        audiowrite(filtered_filename, filtered_signal, fs);

        % Compute MFCC for the filtered file
        test_mfcc = mfccvec(filtered_filename); 
        total_tests = total_tests + 1;

        % Compare test VQ codebook with all training codebooks
        min_dist = inf;
        best_match = -1;
        
        for i = 1:num_train
            dist = vq_dist(test_mfcc, vq_codebooks{i}); % Compute VQ distortion
            
            if dist < min_dist
                min_dist = dist;
                best_match = i;
            end
        end

        % Check if the match is correct (test number matches training number)
        if best_match == j
            correct_matches = correct_matches + 1;
        end

        % Print best matching speaker for this test file
        fprintf("Filtered Test file s%d.wav best matches with Training file s%d.wav\n", j, best_match);
    end

    % Display correct match statistics
    fprintf("\nCorrect matches (Notch Filtered): %d/%d (%.2f%%)\n", correct_matches, total_tests, (correct_matches / total_tests) * 100);
end

function test9() 
    % Number of original training and test files
    num_train_orig = 11;
    num_test_orig = 8;
    
    % Number of new students' recordings (excluding student #5)
    student_ids = [1, 2, 3, 4, 6, 7, 8, 9, 10, 11]; 
    num_students = length(student_ids);
    
    % Total number of training and test files
    num_train = num_train_orig + num_students;
    num_test = num_test_orig + num_students;
    
    M = 98; % Number of codebook centroids
    eps = 0.01; % Convergence threshold
    
    % Initialize storage for training VQ codebooks
    vq_codebooks = cell(1, num_train);
    
    % Load original training data and compute VQ codebooks
    for i = 1:num_train_orig
        filename = sprintf("GivenSpeech_Data/Training_Data/s%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end
    
    % Load new students' training data (excluding student #5)
    for i = 1:num_students
        student_id = student_ids(i);
        filename = sprintf("2024StudentAudioRecording/Zero-Training/Zero_train%d.wav", student_id);
        mfcc_data = mfccvec(filename); % Compute MFCC
        vq_codebooks{num_train_orig + i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end
    
    % Initialize accuracy count
    correct_count = 0;
    
    % Load test data and compare against training set
    for j = 1:num_test
        if j <= num_test_orig
            test_filename = sprintf("GivenSpeech_Data/Test_Data/s%d.wav", j);
            expected_match = j; % Original dataset matches same index
        else
            student_idx = j - num_test_orig;
            student_id = student_ids(student_idx);
            test_filename = sprintf("2024StudentAudioRecording/Zero-Testing/Zero_test%d.wav", student_id);
            expected_match = num_train_orig + student_idx; % Ensure correct mapping
        end
        % disp(test_filename)
        test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
        test_codebook = test_mfcc;
        
        % Compare test VQ codebook with all training codebooks
        min_dist = inf;
        best_match = -1;
        
        for i = 1:num_train
            dist = vq_dist(test_codebook, vq_codebooks{i}); % Compute VQ distortion
            
            if dist < min_dist
                min_dist = dist;
                best_match = i;
            end
        end
        
        % Check if classification is correct
        if best_match == expected_match
            correct_count = correct_count + 1;
        end
        
        % Print matching result
        fprintf("Test file %s best matches with Training file %d\n", test_filename, best_match);
    end
    
    % Print accuracy
    fprintf("\nTotal Correct: %d/%d\n", correct_count, num_test);
end

function test10aQ1()
    % Number of training and test files
    num_train = 19;
    num_test = 19;
    M = 32; % Number of codebook centroids
    eps = 0.01; % Convergence threshold

    % Initialize storage for training VQ codebooks
    vq_codebooks_twelve = cell(1, num_train);
    vq_codebooks_zero = cell(1, num_train);

    % Counters for correct matches
    correct_matches_twelve = 0;
    correct_matches_zero = 0;
    total_tests_twelve = 0;
    total_tests_zero = 0;

    % Load training data and compute VQ codebooks for "Twelve"
    for i = [1:4, 6:19]
        filename = sprintf("2024StudentAudioRecording\\Twelve-Training\\Twelve_train%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks_twelve{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end

    % Load test data and compare against training set for "Twelve"
    for j = [1:4, 6:19]
        test_filename = sprintf("2024StudentAudioRecording\\Twelve-Testing\\Twelve_test%d.wav", j);
        test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
        test_codebook = test_mfcc; % Use MFCC directly for comparison
        total_tests_twelve = total_tests_twelve + 1;

        % Compare test VQ codebook with all training codebooks
        min_dist = inf;
        best_match = -1;

        for i = [1:4, 6:19]
            dist = vq_dist(test_codebook, vq_codebooks_twelve{i}); % Compute VQ distortion

            if dist < min_dist
                min_dist = dist;
                best_match = i;
            end
        end

        % Check if the match is correct (test number matches training number)
        if best_match == j
            correct_matches_twelve = correct_matches_twelve + 1;
        end

        % Print best matching training file for this test file
        fprintf("Test file Twelve_test%d.wav best matches with Training file Twelve_train%d.wav\n", j, best_match);
    end

    % Load training data and compute VQ codebooks for "Zero"
    for i = [1:4, 6:19]
        filename = sprintf("2024StudentAudioRecording\\Zero-Training\\Zero_train%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks_zero{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end

    % Load test data and compare against training set for "Zero"
    for j = [1:4, 6:19]
        test_filename = sprintf("2024StudentAudioRecording\\Zero-Testing\\Zero_test%d.wav", j);
        test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
        test_codebook = test_mfcc; % Use MFCC directly for comparison
        total_tests_zero = total_tests_zero + 1;

        % Compare test VQ codebook with all training codebooks
        min_dist = inf;
        best_match = -1;

        for i = [1:4, 6:19]
            dist = vq_dist(test_codebook, vq_codebooks_zero{i}); % Compute VQ distortion

            if dist < min_dist
                min_dist = dist;
                best_match = i;
            end
        end

        % Check if the match is correct (test number matches training number)
        if best_match == j
            correct_matches_zero = correct_matches_zero + 1;
        end

        % Print best matching training file for this test file
        fprintf("Test file Zero_test%d.wav best matches with Training file Zero_train%d.wav\n", j, best_match);
    end

    % Display correct match statistics
    fprintf("\nCorrect matches for 'Twelve': %d/%d\n", correct_matches_twelve, total_tests_twelve);
    fprintf("Correct matches for 'Zero': %d/%d\n", correct_matches_zero, total_tests_zero);
end

function test10aQ2()
    % Number of training and test files
    num_train = 19;
    num_test = 19;
    M = 32; % Number of codebook centroids
    eps = 0.01; % Convergence threshold

    % List of students (excluding #5)
    student_ids = [1:4, 6:19]; 
    
    % Initialize storage for training VQ codebooks
    vq_codebooks_twelve = cell(1, num_train);
    vq_codebooks_zero = cell(1, num_train);
    
    % Counters for correct matches
    correct_speaker_matches = 0;
    correct_word_matches = 0;
    total_tests = 0;

    % Load training data for "Twelve"
    for i = student_ids
        filename = sprintf("2024StudentAudioRecording\\Twelve-Training\\Twelve_train%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC
        vq_codebooks_twelve{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end

    % Load training data for "Zero"
    for i = student_ids
        filename = sprintf("2024StudentAudioRecording\\Zero-Training\\Zero_train%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC
        vq_codebooks_zero{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end

    % Load and classify test data
    for j = student_ids
        for word_type = ["Twelve", "Zero"]
            test_filename = sprintf("2024StudentAudioRecording\\%s-Testing\\%s_test%d.wav", word_type, word_type, j);
            test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
            test_codebook = test_mfcc;
            total_tests = total_tests + 1;

            % Compare test VQ codebook with both "Twelve" and "Zero" training sets
            min_dist_speaker = inf;
            best_match_speaker = -1;
            min_dist_word = inf;
            best_match_word = "";

            % Check against "Twelve" training data
            for i = student_ids
                dist = vq_dist(test_codebook, vq_codebooks_twelve{i});
                if dist < min_dist_speaker
                    min_dist_speaker = dist;
                    best_match_speaker = i;
                    best_match_word = "Twelve";
                end
            end

            % Check against "Zero" training data
            for i = student_ids
                dist = vq_dist(test_codebook, vq_codebooks_zero{i});
                if dist < min_dist_speaker
                    min_dist_speaker = dist;
                    best_match_speaker = i;
                    best_match_word = "Zero";
                end
            end

            % Check if speaker identification is correct
            if best_match_speaker == j
                correct_speaker_matches = correct_speaker_matches + 1;
            end

            % Check if word classification is correct
            if best_match_word == word_type
                correct_word_matches = correct_word_matches + 1;
            end

            % Print results for each test case
            fprintf("Test file %s best matches with Training file %s_train%d.wav\n", ...
                test_filename, best_match_word, best_match_speaker);
        end
    end

    % Display accuracy results
    fprintf("\nSpeaker Identification Accuracy: %d/%d (%.2f%%)\n", ...
        correct_speaker_matches, total_tests, (correct_speaker_matches / total_tests) * 100);
    fprintf("Word Identification Accuracy: %d/%d (%.2f%%)\n", ...
        correct_word_matches, total_tests, (correct_word_matches / total_tests) * 100);
end

function test10b()
    % Number of training and test files
    num_train = 23;
    num_test = 23;
    M = 36; % Number of codebook centroids
    eps = 0.01; % Convergence threshold

    % List of student IDs (1 to 23)
    student_ids = 1:23; 

    % Initialize storage for training VQ codebooks
    vq_codebooks_five = cell(1, num_train);
    vq_codebooks_eleven = cell(1, num_train);

    % Counters for accuracy tracking
    correct_speaker_matches_five = 0;
    correct_speaker_matches_eleven = 0;
    correct_word_matches = 0;
    total_tests_five = 0;
    total_tests_eleven = 0;

    % Load training data for "Five"
    for i = student_ids
        filename = sprintf("2025StudentAudioRecording\\Five Training\\s%d.wav", i);
        % disp(filename)
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks_five{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end

    % Load training data for "Eleven"
    for i = student_ids
        filename = sprintf("2025StudentAudioRecording\\Eleven Training\\s%d.wav", i);
        mfcc_data = mfccvec(filename); % Compute MFCC for training speech
        vq_codebooks_eleven{i} = vq(mfcc_data, M, eps); % Compute VQ codebook
    end

    % Process test data for "Five"
    for j = student_ids
        test_filename = sprintf("2025StudentAudioRecording\\Five Test\\s%d.wav", j);
        test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
        test_codebook = test_mfcc;
        total_tests_five = total_tests_five + 1;

        % Speaker identification
        min_dist = inf;
        best_match_speaker = -1;

        for i = student_ids
            dist = vq_dist(test_codebook, vq_codebooks_five{i});
            if dist < min_dist
                min_dist = dist;
                best_match_speaker = i;
            end
        end

        % Check speaker match
        if best_match_speaker == j
            correct_speaker_matches_five = correct_speaker_matches_five + 1;
        end

        % Print result
        fprintf("Test file Five_Test\\s%d.wav best matches with Training file Five_Training\\s%d.wav\n", j, best_match_speaker);
    end

    % Process test data for "Eleven"
    for j = student_ids
        test_filename = sprintf("2025StudentAudioRecording\\Eleven Test\\s%d.wav", j);
        test_mfcc = mfccvec(test_filename); % Compute MFCC for test speech
        test_codebook = test_mfcc;
        total_tests_eleven = total_tests_eleven + 1;

        % Speaker identification
        min_dist = inf;
        best_match_speaker = -1;

        for i = student_ids
            dist = vq_dist(test_codebook, vq_codebooks_eleven{i});
            if dist < min_dist
                min_dist = dist;
                best_match_speaker = i;
            end
        end

        % Check speaker match
        if best_match_speaker == j
            correct_speaker_matches_eleven = correct_speaker_matches_eleven + 1;
        end

        % Print result
        fprintf("Test file Eleven_Test\\s%d.wav best matches with Training file Eleven_Training\\s%d.wav\n", j, best_match_speaker);
    end

    % Word Classification: Compare "Five" vs. "Eleven"
    total_tests = total_tests_five + total_tests_eleven;
    for j = student_ids
        for word_type = ["Five", "Eleven"]
            test_filename = sprintf("2025StudentAudioRecording\\%s Test\\s%d.wav", word_type, j);
            test_mfcc = mfccvec(test_filename); % Compute MFCC
            test_codebook = test_mfcc;

            min_dist_word = inf;
            best_match_word = "";

            % Check against "Five"
            for i = student_ids
                dist = vq_dist(test_codebook, vq_codebooks_five{i});
                if dist < min_dist_word
                    min_dist_word = dist;
                    best_match_word = "Five";
                end
            end

            % Check against "Eleven"
            for i = student_ids
                dist = vq_dist(test_codebook, vq_codebooks_eleven{i});
                if dist < min_dist_word
                    min_dist_word = dist;
                    best_match_word = "Eleven";
                end
            end

            % Check if the word classification is correct
            if best_match_word == word_type
                correct_word_matches = correct_word_matches + 1;
            end
        end
    end

    % Print accuracy results
    fprintf("\nSpeaker Identification Accuracy using 'Five': %d/%d (%.2f%%)\n", ...
        correct_speaker_matches_five, total_tests_five, (correct_speaker_matches_five / total_tests_five) * 100);
    fprintf("Speaker Identification Accuracy using 'Eleven': %d/%d (%.2f%%)\n", ...
        correct_speaker_matches_eleven, total_tests_eleven, (correct_speaker_matches_eleven / total_tests_eleven) * 100);
    fprintf("Word Classification Accuracy (Five vs. Eleven): %d/%d (%.2f%%)\n", ...
        correct_word_matches, total_tests, (correct_word_matches / total_tests) * 100);
end




%% Function defs
% This function avoids duplicate matches between test and codebook
% function dist = vq_dist(test, codebook)
%     % Number of test vectors and codewords
%     M = size(test, 2);
%     N = size(codebook, 2);
% 
%     % Ensure we do not assign duplicates
%     assigned_codewords = false(1, N);  
%     dists = zeros(1, M);
%     cells = zeros(1, M);
% 
%     for f = 1:M
%         % Find the closest unassigned codeword
%         available_indices = find(~assigned_codewords);
%         [min_dist, min_idx] = min(vecnorm(test(:, f) - codebook(:, available_indices), 2, 1));
% 
%         % Assign this test vector to the selected codeword
%         assigned_codeword = available_indices(min_idx);
%         dists(f) = min_dist;
%         cells(f) = assigned_codeword;
%         assigned_codewords(assigned_codeword) = true;  % Mark it as assigned
%     end
%     dists(isnan(dists))=0;
%     % Return total VQ distortion
%     dist = sum(dists);
% end


function dist = vq_dist(test, codebook)
    % Number of test vectors
    M = size(test, 2);

    dists = zeros(1, M);

    for f = 1:M
        % Find the closest codeword (allows duplicates)
        dists(f) = min(vecnorm(test(:, f) - codebook, 2, 1));
    end

    plot(dists)

    % Return total VQ distortion
    dist = sum(dists);
end



function out = spect(file)
    [audio, Fs] = audioread(file);

    % Frame blocking parameters
    frame_size = 0.025;
    frame_stride = 0.01;
    frame_length = round(frame_size*Fs);
    frame_step = round(frame_stride*Fs);
    
    % Plot
    tiledlayout(5,1)
    nexttile
    plot(audio)
    
    % Spectrogram
    nexttile
    M = 128;
    N = round(M/3);
    [s,w,t] = spectrogram(audio,hamming(M),N,"yaxis");
    imagesc(t, w ,dB(abs(s).^2));
    colormap jet;
    colorbar;
    axis xy;

    nexttile
    % spectrogram(audio,hamming(M),N,"yaxis")

    % size(s)
    % max(dB(abs(s).^2))
    [row,col] = find(abs(s)==max(abs(s),[],"all"));
    max_freq = pi*row/height(s)
    max_time = length(audio)/Fs*col/width(s)
    fprintf()

end

function out = mfccvec(file)
    [audio, Fs] = audioread(file);
    % size(audio)
    audio = mean(audio,2);

    % tiledlayout(5,1)
    % nexttile
    % plot(audio)
    
    % Pre-emphasis
    a = 0.97;
    audio_emph = [audio(1); audio(2:end) - a * audio(1:end-1)];
    % nexttile
    % plot(audio_emph)
    
    % Frame blocking parameters
    frame_size = 0.025;
    frame_stride = 0.01;
    frame_length = round(frame_size*Fs);
    frame_step = round(frame_stride*Fs);
    
    % Pad the signal to good length to fit with frame blocking
    n_frames = ceil((length(audio_emph) - frame_length) / frame_step);
    pad_signal_len = n_frames*frame_step+frame_length;
    z = zeros(pad_signal_len-length(audio_emph),1);
    pad_signal = [audio_emph; z];
    
    % Make frames
    indices = repmat(0:frame_length-1, n_frames, 1) + repmat((0:frame_step:(n_frames-1)*frame_step)', 1, frame_length);
    frames = pad_signal(indices+1);
    
    % Window
    frames = frames.*hamming(frame_length)';

    NFFT = 512;

    fbank = melfb_own(40,NFFT,Fs); % Generate Mel filterbank
    % nexttile
    % plot(fbank')

    % FFT and power spectrum (TRANPOSE MATRIX AT THIS POINT)
    mag_frames = abs(fft(frames', NFFT));
    mag_frames = mag_frames(1:floor(NFFT/2)+1,:); % Keep positive frequencies
    pow_frames = (1.0/NFFT) * mag_frames.^2;
    
    % Apply Mel filterbank
    % filter_banks = (pow_frames * fbank');
    filter_banks = fbank * pow_frames;
    
    % Convert to log scale
    filter_banks(filter_banks == 0) = eps;
    filter_banks = 20 * log10(filter_banks);
    
    % Obtain MFCCs
    num_ceps = 12;
    mfccout = dct(filter_banks,[],1);
    mfccout = mfccout(2:(num_ceps+1),:); % Keep coefficients 2-13

    % Apply sinusoidal liftering (optional)
    % [nframes, ncoeff] = size(mfcc);
    % n = (0:ncoeff-1);
    % lift = 1 + (cep_lifter / 2) * sin(pi * n / cep_lifter);
    % mfcc = mfcc .* lift; % Element-wise multiplication
    
    % Mean normalization
    filter_banks = filter_banks - mean(filter_banks, 2);
    mfccout = mfccout - mean(mfccout,2);
    
    % Plot spectrogram (fix axes)
    % nexttile
    % imagesc(1:size(filter_banks,2), 1:40, filter_banks);
    
    % axis xy; % Flip Y-axis to have low freq at bottom
    % xlabel('Time Frames');
    % ylabel('Mel Filter Index');
    % title('Mel Spectrogram');
    % colormap jet;
    % colorbar;

    % nexttile
    % imagesc(1:size(mfccout,2), 2:13,mfccout);
    % axis xy; % Flip Y-axis to have low freq at bottom
    % xlabel('Time Frames');
    % ylabel('MFCC Coefficients');
    % colormap jet;
    % colorbar;

    out = mfccout;
    
end

function m = melfb_own(p, n, fs)

% MELFB_own Determine matrix for a mel-spaced filterbank
%
% Inputs: p = number of filters in filterbank
% n = length of fft
% fs = sample rate in Hz
%
% Outputs: x = a (sparse) matrix containing the filterbank amplitudes
% size(x) = [p, 1+floor(n/2)]
%
% Usage: Compute the mel-scale spectrum of a colum-vector s, with length n and sample rate fs:
% f = fft(s);
% m = melfb(p, n, fs);
% n2 = 1 + floor(n/2);
% z = m * abs(f(1:n2)).^2;
%
% z would contain p samples of the desired mel-scale spectrum
% To plot filterbank responses:
% plot(linspace(0, (12500/2), 129), melfb(20, 256, 12500)'),
% title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');
f0 = 700 / fs; % frequency times sampling rate
fn2 = floor(n/2); % half fft size
Lr = log(1 + 0.5/f0) / (p+1); % log spacing factor

% convert to fft bin numbers with 0 for DC term
Bv = n*(f0*(exp([0 1 p p+1]*Lr) - 1)); % map log filter to fft bin numbers
b1 = floor(Bv(1)) + 1; b2 = ceil(Bv(2)); % filter bin indices
b3 = floor(Bv(3)); b4 = min(fn2, ceil(Bv(4))) - 1; % bin limits for filterbanks
pf = log(1 + (b1:b4)/n/f0) / Lr; % map bin indices to the filter bank frequencies
fp = floor(pf);
pm = pf - fp; % find fractional part 
r = [fp(b2:b4) 1+fp(1:b3)]; % row indices
c = [b2:b4 1:b3] + 1; % column indices
v = 2 * [1-pm(b2:b4) pm(1:b3)]; % filter bank with interpolation
m = sparse(r, c, v, p, 1+fn2); % final output
end

function out = dB(in)
    out = 20*log10(in);
end

function codebook = vq(mfcc, M, eps)
    % Initialize codebook with mfcc centroid
    n_frames = size(mfcc,2);
    codebook = mean(mfcc,2);
    
    % While codebook size is less than M
    while size(codebook,2) < M
        min_distortion = inf;
        codebook = [codebook*(1+10*eps) codebook*(1-10*eps)];
        while true
            % Split the codebook
            n_codewords = size(codebook,2);
            
            % Create cell blocks for frame indeces and distances
            cells = zeros(1,n_frames);
            dists = zeros(1,n_frames);
    
            % Run through all frames and assign to nearest centroid
            for f = 1:n_frames
                [m,i] = min(vecnorm(mfcc(:,f)-codebook)); % i = index of closest centroid
                cells(f) = i; % Assign the frame to nearest centroid
                dists(f) = m; % Mark corresponding distance
            end
            
            % Update codebook with new centroids
            for c = 1:n_codewords
                newcent = mean(mfcc(:,cells==c),2);
                % ~isnan(newcent(1));
                % if ~isnan(newcent(1))
                    codebook(:,c) = newcent;
                % end
            end
            codebook(isnan(codebook)) = 0;
            
            distortion = mean(dists);
            if (min_distortion-distortion) < 1e-6%eps*distortion
                break;
            end
            min_distortion = distortion;
            
        end
    end
end
