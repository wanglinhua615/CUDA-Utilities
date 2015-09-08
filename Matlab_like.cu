#include <thrust/device_vector.h>

#include "Utilities.cuh"

/************/
/* LINSPACE */
/************/
template <class T>
T * linspace(const T a, const T b, const unsigned int N) {
	
	T *out_array; gpuErrchk(cudaMalloc((void**)&out_array, N * sizeof(T)));

	T Dx = (b-a)/(T)(N-1);
   
	thrust::device_ptr<T> d = thrust::device_pointer_cast(out_array); 	
	thrust::transform(thrust::make_counting_iterator(a/Dx), thrust::make_counting_iterator((b+1.f)/Dx), thrust::make_constant_iterator(Dx), d, thrust::multiplies<T>());

	return out_array;
}

template float  * linspace<float> (const float  a, const float  b, const unsigned int N);
template double * linspace<double>(const double a, const double b, const unsigned int N);

/*******************/
/* MESHGRID KERNEL */
/*******************/
template <class T>
__global__ void meshgrid_kernel(const T * __restrict__ x, const unsigned int Nx, const T * __restrict__ y, const unsigned int Ny, T * __restrict__ X, T * __restrict__ Y) 
{
	unsigned int tidx = blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int tidy = blockIdx.y * blockDim.y + threadIdx.y;

	if ((tidx < Nx) && (tidy < Ny)) {	
		X[tidy * Nx + tidx] = x[tidx];
		Y[tidy * Nx + tidx] = y[tidy];
	}
}

/************/
/* MESHGRID */
/************/
#define BLOCKSIZE_MESHGRID_X	16
#define BLOCKSIZE_MESHGRID_Y	16

#include <thrust/pair.h>

template <class T>
thrust::pair<T *,T *> meshgrid(const T *x, const unsigned int Nx, const T *y, const unsigned int Ny) {
	
	T *X; gpuErrchk(cudaMalloc((void**)&X, Nx * Ny * sizeof(T)));
	T *Y; gpuErrchk(cudaMalloc((void**)&Y, Nx * Ny * sizeof(T)));

	dim3 BlockSize(BLOCKSIZE_MESHGRID_X, BLOCKSIZE_MESHGRID_Y);
	dim3 GridSize (iDivUp(Nx, BLOCKSIZE_MESHGRID_X), iDivUp(BLOCKSIZE_MESHGRID_Y, BLOCKSIZE_MESHGRID_Y));
	
	meshgrid_kernel<<<GridSize, BlockSize>>>(x, Nx, y, Ny, X, Y);
#ifdef DEBUG
	gpuErrchk(cudaPeekAtLastError());
	gpuErrchk(cudaDeviceSynchronize());
#endif

	return thrust::make_pair(X, Y);
}

template thrust::pair<float  *, float  *>  meshgrid<float>  (const float  *, const unsigned int, const float  *, const unsigned int);
template thrust::pair<double *, double *>  meshgrid<double> (const double *, const unsigned int, const double *, const unsigned int);