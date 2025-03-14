
"Github/Result_Plots" folder contains outputs for tasks 1-6.

Run "batchtest.m" to demonstrate tests 7-10 (uncomment out the task function as described at the top of the file). All necessary functions are contained in this file.

# Speaker Recognition Report
### Table of Contents  
- [1. Introduction](#1-project-summary)
- [2. Feature extraction](#2-feature-extraction)
- [3. Feature analysis](#3-feature-analysis)
  * [3.1 Clustering and Training](#31-clustering-and-training)




## 1. Project summary
This project builds a speaker recognition architecture using Mel frequency cepstrum coefficient (MFCC) feature extraction and a vector quantization (VQ) approach for feature matching.
### 1.1 Data sets
We use a single file to train a codebook that contains a "fingerprint" of the speaker+word. After collecting 
* Baseline test data of "zero"; 11 training, 8 testing
* 2024 student recordings of "zero" and "twelve"; 18 training, 18 testing
* 2025 student recordings of "five" and "eleven"; 23 training, 23 testing
### 1.2 Key MATLAB Functions
* `out = mfccvec(file)`: Inputs `file` as a text string, outputs matrix `out` with 12 coefficient rows and variable frames.
* `m = melfb_own(p, n, fs)`: Inputs `p` number of filter banks, `n` number of FFT coefficients, and `fs` sampling frequency and outputs matrix `m` containing Mel filter banks.
* `codebook = vq(mfcc, M, eps)`: Inputs matrix `mfcc` of Mel frequency cepstrum coefficient vectors, `M` number of centroids, and `eps` splitting parameter and outputs M x n `codebook`, where n equals the cepstrum coefficient count.


## 2. Feature extraction


## 3. Feature analysis
### 3.1 Clustering and Training

For feature matching, we adopt the Vector Quantization (VQ) method. Clustering is performed using the LBG algorithm with slight modifications for numerical stability. The algorithm is implemented as follows:

<div style="display: flex; justify-content: center;">
<table align="center"">
  <tr>
    <td><b>Inputs:</b>
      <ul>
        <li><b>MFCC matrix</b> (<i>n</i> frames × <i>m</i> coefficients)</li>
        <li><b>M</b> (size of codebook)</li>
        <li><b>ε</b></li>
      </ul>
      <b>Output:</b>
      <ul>
        <li><b>Codebook</b> (<i>m</i> × <i>M</i>)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td><b>Algorithm:</b>
      <ol>
        <li>Initialize codebook (find mean of input MFCC vectors)</li>
        <li>While codebook size &lt; <i>M</i>:
          <ul>
            <li>Set <i>min_distortion</i> = ∞</li>
            <li>Split codebook
            </li>
            <li>While <b>true</b> until <b>break</b> condition:
              <ol>
                <li>Create empty vectors <i>cells</i> and <i>dists</i></li>
                <li>For <i>n</i> frames in MFCC matrix:
                  <ul>
                    <li>Compute the distance to each centroid</li>
                    <li>Select min distance</li>
                    <li>Store centroid number in <i>cells</i></li>
                    <li>Store corresponding distance (distortion) in <i>dists</i></li>
                  </ul>
                </li>
                <li>For <i>y</i> centroids in <i>codebook</i>:
                  <ul>
                    <li>Find <i>cells == y</i> and index corresponding MFCC vectors</li>
                    <li>Compute the new mean of these vectors and update <i>y</i></li>
                  </ul>
                </li>
                <li>Compute <i>new_distortion</i> by averaging <i>dists</i></li>
                <li>Compute change in distortion: <i>min_distortion</i> - <i>new_distortion</i>
                  <br> If change in distortion is smaller than <i>threshold</i>, <b>break</b>
                  <br> Else, update <i>min_distortion</i> with <i>new_distortion</i>
                </li>
              </ol>
            </li>
          </ul>
        </li>
      </ol>
    </td>
  </tr>
</table>
</div>





Selection of *ε* too small keeps the split centroids too close together, and the minimum distance from all vectors to the nearest centroid may be assigned only to a single centroid. Thus we employ one of two methods:

- Set empty centroid to zero: conceptually not optimal and doesn’t follow the LBG algorithm, since we now reorder the centroid list.  
- Set empty centroid to previous centroid.

We are fortunate that the recursive nature of the algorithm accounts for this and corrects the location of the centroids, even if we now use a greater number of cycles to perform this correction. However, speed isn’t our goal here, and we demonstrate with results that the clustering of the vectors is within reason.

### 3.2 Matching

Once the codebooks have been completed, we tackle the problem of matching test sets against them. We considered a few methods for matching:

1. Generate a new codebook of clusters from the test vectors and compare the similarity between this codebook and the training codebooks.  
2. Use the raw MFCC vectors and compute the total distortion between the uncompressed data and the training codebooks.

We mistakenly initially used method 1 but quickly saw the error in our ways with poor results. In addition, the order of complexity for one calculation of the codebook is *O*(*fM*log(*M)*), where *M* is the size of the codebook and *f* is the number of MFCC frames. The complexity of the distance calculation for the distortion calculation function `vq_dist(test, cb)` is *O*(*nM*), where *n* is the size of the test codebook and *M* is the size of the training codebook. This results in a total complexity of *O*(*fM*log(*M)*\+*nMc*), where c is the number of codebooks.

Method 2 avoids the clustering step and decreases total complexity to O(*fMc*). This change also more closely coincides with the theory behind VQ distortion - by finding the distance from each frame to the nearest codeword, we inherently cluster the test vectors by association. We then take the total sum of the distances to the codewords and compute the total distortion. 

## 4. Results
### 4.1 Initial results
We saw promising initial results with a codebook size of _M_ = 64
| Task | Description | Result |
| :---- | :---- | :---- |
| 7 | Recognition rate of baseline “zero” recordings | 7/8 (87.5%) |
| 8 | Recognition rate after using notch filters | 7/8 |
| 9 | 2024 student “zero” recordings + baseline “zero” recordings | 16/18 (89%) |
| 10a.1 | Accuracy of 2024 student data; “twelve” results vs “zero” results | 14/18 twelve 16/18 zero |
| 10a.2 | Accuracy of 2024 student data; speaker recognition vs word recognition | Speaker 30/36 Word 36/36 |
| 10b | 2025 student data; speaker recognition using ;five’ vs using ‘eleven’.
Word recognition results | 21/23 ‘Five’ 22/23 ‘Eleven’ Word classification 46/46 100% |

