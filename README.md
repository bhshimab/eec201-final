
"Github/Result_Plots" folder contains outputs for tasks 1-6.

Run "batchtest.m" to demonstrate tests 7-10 (uncomment out the task function as described at the top of the file). All necessary functions are contained in this file.

# Speaker Recognition Report
### Table of Contents  
- [1. Introduction](#1-introduction)
- [3. Feature analysis](#3-feature-analysis)
  * [3.1 Clustering and Training](#31-clustering-and-training)




## 1. Introduction
This project builds a speaker recognition architecture using Mel frequency cepstrum coefficient (MFCC) feature extraction and a vector quantization (VQ) approach for feature matching. Initial tests yield promising results.
### 1.1 Training and test data
There are three sets of test data provided.
* Baseline test data of "zero"; 11 training, 8 testing
* 2024 student recordings of "zero" and "twelve"; 18 training, 18 testing
* 2025 student recordings of "five" and "eleven"; 23 training, 23 testing

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
                <li>Compute change in distortion:
                  <br> \\( \textit{min\_distortion} - \textit{new\_distortion} \\)
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
2. Use the raw MFCC vectors and compute the mean distortion between the uncompressed data and the training codebooks.

We initially used method 1 but quickly saw poor results. In addition, the order of complexity for one calculation of the codebook is *O*(*fM*log(*M)*), where *M* is the size of the codebook and *f* is the number of MFCC frames. The complexity of the distance calculation for the distortion calculation function `vq_dist(test, cb)` is *O*(*nM*), where *n* is the size of the test codebook and *M* is the size of the training codebook. This results in a total complexity of *O*(*fM*log(*M)*\+*nMc*), where c is the number of codebooks.

Method 2 avoids the clustering step and decreases total complexity. Complexity is now O(*fMc*) 

## 4. Results
### 4.1 Initial results

| Task | Description | Result |
| :---- | :---- | :---- |
| 7 |  | 7/8 (87.5%) |
| 8 |  | 7/8 |
| 9 |  | 16/18 (89%) |
| 10a.1 |  | 14/18 twelve 16/18 zero |
| 10a.2 |  | Speaker 30/36 Word 36/36 |
| 10b |  | 21/23 ‘Five’ 22/23 ‘Eleven’ Word classification 46/46 100% |

