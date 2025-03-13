"Github/Result_Plots" folder contains outputs for tasks 1-6.

Run "batchtest.m" to demonstrate tests 7-10 (uncomment out the task function as described at the top of the file). All necessary functions are contained in this file.


![til](./VQTraining.gif)


| Task | Description | Result |
| :---- | :---- | :---- |
| 7 |  | 7/8 (87.5%) |
| 8 |  | 7/8 |
| 9 |  | 16/18 (89%) |
| 10a.1 |  | 14/18 twelve 16/18 zero |
| 10a.2 |  | Speaker 30/36 Word 36/36 |
| 10b |  | 21/23 ‘Five’ 22/23 ‘Eleven’ Word classification 46/46 100% |


### 2.1 Clustering and Training

For feature matching, we adopt the Vector Quantization (VQ) method. Clustering is performed using the LBG algorithm with slight modifications for numerical stability. The algorithm is implemented as follows:

| Inputs: MFCC matrix (*n* frames x *m* coefficients) *M* (size of codebook) *ε* Output: Codebook (*m* x *M*) |
| ----- |
| Algorithm: Initialize codebook (find mean of input MFCC vectors) While codebook size \< *M*: Set *min\_distortion* \= ∞ Split codebook via  *yn\+*\=*yn*(1+*ε)yn\-*\=*yn*(1-*ε)* While **true** until **break** condition: Create empty vectors *cells* and *dists* For *n* frames in MFCC matrix, compute the distance to each centroid. select min distance, and store centroid number in *cells* and corresponding distance (distortion) in *dists*. For *y* centroids in codebook, find *cells* \== *y* and use that to index the corresponding MFCC vectors. Compute the new mean of these vectors and update *y*. Compute *new\_distortion* by averaging *dists*. Compute change in distortion by computing *min\_distortion* \- *new\_distortion*. If change in distortion between current and previous cycle is smaller than threshold, **break**. Else, update *min\_distortion* with *new\_distortion*. |

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
