#include <cuda.h>
#include <cuda_runtime.h>
#include "common.h"
#include "efficient.h"
#include <iostream>
namespace StreamCompaction {
    namespace Efficient {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }


		__global__ void kernelScanReduce(int n, int d, int* odata, int* idata)
		{
			int thID = threadIdx.x + blockDim.x * blockIdx.x;
			if (thID >= n) return;
			int temp = 1 << d;
			int temp2 = 1 << (d - 1);
			
			if ((thID % temp) == 0)
			{
				odata[thID + temp - 1] = idata[thID + temp2 - 1] + idata[thID + temp - 1];
			}
			else
			{
				odata[thID] = idata[thID];
			}
		}

		__global__ void kernelScanDownSweep(int n, int d, int* odata, int* idata)
		{
			int thID = threadIdx.x + blockDim.x * blockIdx.x;
			if (thID >= n) return;
			int tempdp1 = 1 << (d + 1);
			int tempd = 1 << d;
			if ((thID % tempdp1) == 0)
			{
				int t = idata[thID + tempd - 1];
				odata[thID + tempd - 1] = idata[thID + tempdp1 - 1];
				odata[thID + tempdp1 - 1] = t + idata[thID + tempdp1 - 1];

			}
			else
			{
				odata[thID] = idata[thID];
			}
		}
        /**
         * Performs prefix-sum (aka scan) on idata, storing the result into odata.
         */
        void scan(int n, int *odata, const int *idata) {
            timer().startGpuTimer();
            // TODO
			int temp = 1 << ilog2ceil(n);
			std::cout << "my temp number is " << temp << std::endl;
			std::cout << "my ilog2ceil(n) is " << ilog2ceil(n) << std::endl;
			std::cout << "my n is " << n << std::endl;
			int myIdentity = 0;

			dim3 fullBlocksPerGrid((temp + blockSize - 1) / blockSize);
			int* dev_In = NULL;
			int* dev_Out = NULL;

			cudaMalloc((void**)&dev_In, temp * sizeof(int));
			checkCUDAError("Malloc dev_In failed!");
			cudaMalloc((void**)&dev_Out, temp * sizeof(int));
			checkCUDAError("Malloc dev_Out failed!");
			cudaMemcpy(dev_In, idata, temp * sizeof(int), cudaMemcpyHostToDevice);
			checkCUDAError("Memcpy from idata to dev_In failed!");

			std::cout << "still works before kernel scan reduce" << std::endl;
			for (int d = 1; d <= ilog2ceil(n); ++d)
			{
				std::cout << "d is " << d << std::endl;
				kernelScanReduce << <fullBlocksPerGrid, blockSize >> > (temp, d, dev_Out, dev_In);
				std::swap(dev_Out, dev_In);

			}
			std::swap(dev_Out, dev_In);
			dev_Out[n - 1] = myIdentity;
			//
			//for (int d = ilog2ceil(n) - 1; d >= 0; --d)
			//{
			//	kernelScanDownSweep << <fullBlocksPerGrid, blockSize >> > (temp, d, dev_Out, dev_In);
			//	std::swap(dev_Out, dev_In);
			//}
			//
			//std::swap(dev_Out, dev_In);
			cudaMemcpy(odata, dev_Out, temp * sizeof(int), cudaMemcpyDeviceToHost);
			checkCUDAError("Memcoy from dev_Out to odata failed!");

			for (int i = 0; i < temp; ++i)
			{
				std::cout << odata[i] << " ";
			}
            timer().endGpuTimer();

			cudaFree(dev_In);
			cudaFree(dev_Out);
        }

        /**
         * Performs stream compaction on idata, storing the result into odata.
         * All zeroes are discarded.
         *
         * @param n      The number of elements in idata.
         * @param odata  The array into which to store elements.
         * @param idata  The array of elements to compact.
         * @returns      The number of elements remaining after compaction.
         */
        int compact(int n, int *odata, const int *idata) {
            timer().startGpuTimer();
            // TODO
            timer().endGpuTimer();
            return -1;
        }
    }
}
