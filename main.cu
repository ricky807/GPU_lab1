#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "timing.h"

typedef unsigned long long bignum;
//is prime function that both cpu and gpu use
__device__ __host__ int isPrime(bignum x){
    #ifndef __CUDA_ARCH__
        bignum i;
        bignum lim = (bignum)sqrt((float)x) + 1;

        if (x % 2 == 0)
        {
            return 0;
        }

        for (i = 3; i < lim; i += 2)
        {
            if (x % i == 0)
                return 0;
        }

        return 1;
    #else
        bignum i;
        bignum lim = (bignum) sqrt((double)x) + 1;
        if (x % 2 == 0){
            return 0;
        }
        for(i=2; i<lim; i++){
            if ( x % i == 0)
                return 0;
        }
        return 1;
    #endif
}
//GPU find prime function. This is probably where the problem is occuring
__global__ void findPrimes(int *results, int arr_size)
{
    // Get our global thread ID
    bignum index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < arr_size)
    {
        bignum number = 2 * index + 1;
        results[index] = isPrime(number);
    }
}

//CPU function. This is working perfectly
void computePrimes(double results[], bignum s, bignum n){
   
   bignum i;

   if(s % 2 == 0) s ++;  //make sure s is an odd number

   for(i=s; i< s+n; i = i + 2){
      results[i]=isPrime(i);
   }
}
//sums up primes. This also is working fine
int arrSum( double a[], bignum len )
{
    int i, s = 0;
    for( i = 0; i < len; i ++ )
        s += a[i];

    return s;
}

int main( int argc, char* argv[] )
{
    if (argc < 3)
    {
        printf("Usage: prime upbound\n");
        exit(-1);
    }
    // Get N and blockSize 
    bignum N = (bignum) atoi(argv[1]);
    bignum n = (bignum) atoi(argv[1]);
    bignum blockSize = atoi(argv[2]);
    int i;

    int *h_results;

    // Device input vectors
    int *d_results;
 
    // Size, in bytes, of each vector
    size_t bytes = (N+1)*sizeof(double);
    
    double now, then, scost, pcost;

    //this section takes care of the CPU computing. This sections works perfectly fine
    double *CPUArray;
    then = currentTime();
    CPUArray = (double*)malloc(bytes);
    for( i = 0; i < N + 1; i++ ) {
        CPUArray[i] = 0;
    }
    computePrimes(CPUArray, 0, N);
    now = currentTime();
    printf("Total number of primes in that range is: %d.\n", arrSum(CPUArray, N + 1));
    scost = now - then;
    printf("%%%%%% Serial code executiontime in second is %lf\n\n", scost);
    free(CPUArray);

    //this section is for GPU
    // Allocate memory for host
    size_t arr_size = (int)ceil((float) ((n - 1.0) / 2.0));
    size_t results_num_bytes = arr_size * sizeof(int);
    h_results = (int *)malloc(results_num_bytes);
    // Initialize vectors on host
    cudaMalloc(&d_results, results_num_bytes);

    bignum a;
    // Initialize vectors on host
    for (a = 0; a < arr_size; a++)
    {
        h_results[a] = 0;
    }
    then = currentTime();
    cudaMemcpy(d_results, h_results, results_num_bytes, cudaMemcpyHostToDevice);
    
 
    int gridSize;
 
    // Number of thread blocks in grid
    gridSize = (int)ceil((float) ((n + 1.0) / 2.0 / blockSize));

    // Execute the Gpu function
    findPrimes<<<gridSize, blockSize>>>(d_results, arr_size);
 
    // Copy array back to host
    cudaMemcpy(h_results, d_results, results_num_bytes, cudaMemcpyDeviceToHost);
    bignum sum = 0;
    for (i = 0; i < n/2; i++){
        sum += h_results[i];
    }
    printf("Total number of primes in that range is: %lld.\n", sum);
    now = currentTime();
    pcost = now - then;
    printf("GPU execution time is : %lf\n\n", pcost);
    // Release device memory
    cudaFree(d_results);
 
    // Release host memory
    free(h_results);
    printf("Speedup : %lf\n", scost - pcost);
    return 0;
}
