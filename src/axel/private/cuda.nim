const dlib =
  when defined(windows): "cuda.dll"
  elif defined(macosx): "libcuda.dynlib"
  else: "libcuda.so(|.1)"

const CUDA_VERSION* = 11060

const 
  CU_LAUNCH_PARAM_BUFFER_POINTER* = cast[pointer](0x01)
  CU_LAUNCH_PARAM_BUFFER_SIZE* = cast[pointer](0x02)
  CU_LAUNCH_PARAM_END* = cast[pointer](0x00)

const
  CU_MEMHOSTALLOC_DEVICEMAP* = 0x02
  CU_MEMHOSTALLOC_PORTABLE* = 0x01
  CU_MEMHOSTALLOC_WRITECOMBINED* = 0x04
  CU_MEMHOSTREGISTER_DEVICEMAP* = 0x02
  CU_MEMHOSTREGISTER_PORTABLE* = 0x01


type CUresult* {.size: sizeof(cint).} = enum
  CUDA_SUCCESS   ## The API call returned with no errors. In the case of query calls, this can also mean that the operation being queried is complete (see cuEventQuery() and cuStreamQuery()).
  CUDA_ERROR_INVALID_VALUE   ##   This indicates that one or more of the parameters passed to the API call is not within an acceptable range of values.
  CUDA_ERROR_OUT_OF_MEMORY   ##   The API call failed because it was unable to allocate enough memory to perform the requested operation.
  CUDA_ERROR_NOT_INITIALIZED   ##   This indicates that the CUDA driver has not been initialized with cuInit() or that initialization has failed.
  CUDA_ERROR_DEINITIALIZED   ##   This indicates that the CUDA driver is in the process of shutting down.
  CUDA_ERROR_PROFILER_DISABLED   ##   This indicates profiling APIs are called while application is running in visual profiler mode.
  CUDA_ERROR_PROFILER_NOT_INITIALIZED   ##   This indicates profiling has not been initialized for this context. Call cuProfilerInitialize() to resolve this.
  CUDA_ERROR_PROFILER_ALREADY_STARTED   ##   This indicates profiler has already been started and probably cuProfilerStart() is incorrectly called.
  CUDA_ERROR_PROFILER_ALREADY_STOPPED   ##   This indicates profiler has already been stopped and probably cuProfilerStop() is incorrectly called.
  CUDA_ERROR_NO_DEVICE   ##   This indicates that no CUDA-capable devices were detected by the installed CUDA driver.
  CUDA_ERROR_INVALID_DEVICE   ##   This indicates that the device ordinal supplied by the user does not correspond to a valid CUDA device.
  CUDA_ERROR_INVALID_IMAGE   ##   This indicates that the device kernel image is invalid. This can also indicate an invalid CUDA module.
  CUDA_ERROR_INVALID_CONTEXT   ##   This most frequently indicates that there is no context bound to the current thread. This can also be returned if the context passed to an API call is not a valid handle (such as a context that has had cuCtxDestroy() invoked on it). This can also be returned if a user mixes different API versions (i.e. 3010 context with 3020 API calls). See cuCtxGetApiVersion() for more details.
  CUDA_ERROR_CONTEXT_ALREADY_CURRENT   ##   This indicated that the context being supplied as a parameter to the API call was already the active context.

  CUDA_ERROR_MAP_FAILED   ## This indicates that a map or register operation has failed.
  CUDA_ERROR_UNMAP_FAILED   ## This indicates that an unmap or unregister operation has failed.
  CUDA_ERROR_ARRAY_IS_MAPPED   ## This indicates that the specified array is currently mapped and thus cannot be destroyed.
  CUDA_ERROR_ALREADY_MAPPED   ## This indicates that the resource is already mapped.
  CUDA_ERROR_NO_BINARY_FOR_GPU   ## This indicates that there is no kernel image available that is suitable for the device. This can occur when a user specifies code generation options for a particular CUDA source file that do not include the corresponding device configuration.
  CUDA_ERROR_ALREADY_ACQUIRED   ## This indicates that a resource has already been acquired.
  CUDA_ERROR_NOT_MAPPED   ##   This indicates that a resource is not mapped.
  CUDA_ERROR_NOT_MAPPED_AS_ARRAY   ##   This indicates that a mapped resource is not available for access as an array.
  CUDA_ERROR_NOT_MAPPED_AS_POINTER   ##   This indicates that a mapped resource is not available for access as a pointer.
  CUDA_ERROR_ECC_UNCORRECTABLE   ##   This indicates that an uncorrectable ECC error was detected during execution.
  CUDA_ERROR_UNSUPPORTED_LIMIT   ##   This indicates that the CUlimit passed to the API call is not supported by the active device.
  CUDA_ERROR_CONTEXT_ALREADY_IN_USE   ##   This indicates that the CUcontext passed to the API call can only be bound to a single CPU thread at a time but is already bound to a CPU thread.
  CUDA_ERROR_INVALID_SOURCE   ##   This indicates that the device kernel source is invalid.
  CUDA_ERROR_FILE_NOT_FOUND   ##   This indicates that the file specified was not found.
  CUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND   ##   This indicates that a link to a shared object failed to resolve.
  CUDA_ERROR_SHARED_OBJECT_INIT_FAILED   ##   This indicates that initialization of a shared object failed.
  CUDA_ERROR_OPERATING_SYSTEM   ##   This indicates that an OS call failed.
  CUDA_ERROR_INVALID_HANDLE   ##   This indicates that a resource handle passed to the API call was not valid. Resource handles are opaque types like CUstream and CUevent.
  CUDA_ERROR_NOT_FOUND   ##   This indicates that a named symbol was not found. Examples of symbols are global/constant variable names, texture names, and surface names.
  CUDA_ERROR_NOT_READY   ##   This indicates that asynchronous operations issued previously have not completed yet. This result is not actually an error, but must be indicated differently than CUDA_SUCCESS (which indicates completion). Calls that may return this value include cuEventQuery() and cuStreamQuery().
  CUDA_ERROR_LAUNCH_FAILED   ##   An exception occurred on the device while executing a kernel. Common causes include dereferencing an invalid device pointer and accessing out of bounds shared memory. The context cannot be used, so it must be destroyed (and a new one should be created). All existing device memory allocations from this context are invalid and must be reconstructed if the program is to continue using CUDA.
  CUDA_ERROR_LAUNCH_OUT_OF_RESOURCES   ##   This indicates that a launch did not occur because it did not have appropriate resources. This error usually indicates that the user has attempted to pass too many arguments to the device kernel, or the kernel launch specifies too many threads for the kernel's register count. Passing arguments of the wrong size (i.e. a 64-bit pointer when a 32-bit int is expected) is equivalent to passing too many arguments and can also result in this error.
  CUDA_ERROR_LAUNCH_TIMEOUT   ##   This indicates that the device kernel took too long to execute. This can only occur if timeouts are enabled - see the device attribute CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT for more information. The context cannot be used (and must be destroyed similar to CUDA_ERROR_LAUNCH_FAILED). All existing device memory allocations from this context are invalid and must be reconstructed if the program is to continue using CUDA.
  CUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING   ##   This error indicates a kernel launch that uses an incompatible texturing mode.
  CUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED   ##   This error indicates that a call to cuCtxEnablePeerAccess() is trying to re-enable peer access to a context which has already had peer access to it enabled.
  CUDA_ERROR_PEER_ACCESS_NOT_ENABLED   ##   This error indicates that cuCtxDisablePeerAccess() is trying to disable peer access which has not been enabled yet via cuCtxEnablePeerAccess().
  CUDA_ERROR_PRIMARY_CONTEXT_ACTIVE   ##   This error indicates that the primary context for the specified device has already been initialized.
  CUDA_ERROR_CONTEXT_IS_DESTROYED   ##   This error indicates that the context current to the calling thread has been destroyed using cuCtxDestroy, or is a primary context which has not yet been initialized.
  CUDA_ERROR_UNKNOWN   ##   This indicates that an unknown internal error has occurred. 

type
  CUarray* = ptr object

type
  CUcontext* = ptr object
  CUctx_flags* {.size: sizeof(cint).}= enum
    CU_CTX_SCHED_AUTO  ## Automatic scheduling
    CU_CTX_SCHED_SPIN  ## Set spin as default scheduling
    CU_CTX_SCHED_YIELD  ## Set yield as default scheduling
    CU_CTX_SCHED_BLOCKING_SYNC  ## Set blocking synchronization as default scheduling
    CU_CTX_BLOCKING_SYNC  ## Set blocking synchronization as default scheduling
    CU_CTX_MAP_HOST  ## Support mapped pinned allocations
    CU_CTX_LMEM_RESIZE_TO_MAX  ## Keep local memory allocation after launch  

type
  CUDevice* = distinct cint 
  CUdeviceptr* = distinct uint
  CUdevice_attribute* {.size: sizeof(cint).} = enum
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK  ## Maximum number of threads per block
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_X  ## Maximum block dimension X
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Y  ## Maximum block dimension Y
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Z  ## Maximum block dimension Z
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_X  ## Maximum grid dimension X
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Y  ## Maximum grid dimension Y
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Z  ## Maximum grid dimension Z
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK  ## Maximum shared memory available per block in bytes
    CU_DEVICE_ATTRIBUTE_SHARED_MEMORY_PER_BLOCK  ## Deprecated, use CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK
    CU_DEVICE_ATTRIBUTE_TOTAL_CONSTANT_MEMORY  ## Memory available on device for __constant__ variables in a CUDA C kernel in bytes
    CU_DEVICE_ATTRIBUTE_WARP_SIZE  ## Warp size in threads
    CU_DEVICE_ATTRIBUTE_MAX_PITCH  ## Maximum pitch in bytes allowed by memory copies
    CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_BLOCK  ## Maximum number of 32-bit registers available per block
    CU_DEVICE_ATTRIBUTE_REGISTERS_PER_BLOCK  ## Deprecated, use CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_BLOCK
    CU_DEVICE_ATTRIBUTE_CLOCK_RATE  ## Peak clock frequency in kilohertz
    CU_DEVICE_ATTRIBUTE_TEXTURE_ALIGNMENT  ## Alignment requirement for textures
    CU_DEVICE_ATTRIBUTE_GPU_OVERLAP  ## Device can possibly copy memory and execute a kernel concurrently. Deprecated. Use instead CU_DEVICE_ATTRIBUTE_ASYNC_ENGINE_COUNT.
    CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT  ## Number of multiprocessors on device
    CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT  ## Specifies whether there is a run time limit on kernels
    CU_DEVICE_ATTRIBUTE_INTEGRATED  ## Device is integrated with host memory
    CU_DEVICE_ATTRIBUTE_CAN_MAP_HOST_MEMORY  ## Device can map host memory into CUDA address space
    CU_DEVICE_ATTRIBUTE_COMPUTE_MODE  ## Compute mode (See CUcomputemode for details)
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_WIDTH  ## Maximum 1D texture width
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_WIDTH  ## Maximum 2D texture width
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_HEIGHT  ## Maximum 2D texture height
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_WIDTH  ## Maximum 3D texture width
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_HEIGHT  ## Maximum 3D texture height
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_DEPTH  ## Maximum 3D texture depth
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_WIDTH  ## Maximum 2D layered texture width
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_HEIGHT  ## Maximum 2D layered texture height
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_LAYERS  ## Maximum layers in a 2D layered texture
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_WIDTH  ## Deprecated, use CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_WIDTH
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_HEIGHT  ## Deprecated, use CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_HEIGHT
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_NUMSLICES  ## Deprecated, use CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_LAYERS
    CU_DEVICE_ATTRIBUTE_SURFACE_ALIGNMENT  ## Alignment requirement for surfaces
    CU_DEVICE_ATTRIBUTE_CONCURRENT_KERNELS  ## Device can possibly execute multiple kernels concurrently
    CU_DEVICE_ATTRIBUTE_ECC_ENABLED  ## Device has ECC support enabled
    CU_DEVICE_ATTRIBUTE_PCI_BUS_ID  ## PCI bus ID of the device
    CU_DEVICE_ATTRIBUTE_PCI_DEVICE_ID  ## PCI device ID of the device
    CU_DEVICE_ATTRIBUTE_TCC_DRIVER  ## Device is using TCC driver model
    CU_DEVICE_ATTRIBUTE_MEMORY_CLOCK_RATE  ## Peak memory clock frequency in kilohertz
    CU_DEVICE_ATTRIBUTE_GLOBAL_MEMORY_BUS_WIDTH  ## Global memory bus width in bits
    CU_DEVICE_ATTRIBUTE_L2_CACHE_SIZE  ## Size of L2 cache in bytes
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_MULTIPROCESSOR  ## Maximum resident threads per multiprocessor
    CU_DEVICE_ATTRIBUTE_ASYNC_ENGINE_COUNT  ## Number of asynchronous engines
    CU_DEVICE_ATTRIBUTE_UNIFIED_ADDRESSING  ## Device shares a unified address space with the host
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LAYERED_WIDTH  ## Maximum 1D layered texture width
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LAYERED_LAYERS  ## Maximum layers in a 1D layered texture
    CU_DEVICE_ATTRIBUTE_PCI_DOMAIN_ID  ## PCI domain ID of the device

type
  CUEvent* = ptr object
const
  CU_EVENT_DEFAULT*: cint = 0x0 ## Default event flag
  CU_EVENT_BLOCKING_SYNC*: cint = 0x1  ## Event uses blocking synchronization
  CU_EVENT_DISABLE_TIMING*: cint = 0x2 ## Event will not record timing 
  CU_EVENT_INTERPROCESS*: cint   = 0x4  ## Event is suitable for interprocess use. CU_EVENT_DISABLE_TIMING must be set */
  CU_EVENT_RECORD_DEFAULT*: cint  = 0x0 ## Default event record flag */
  CU_EVENT_RECORD_EXTERNAL*: cint = 0x1  ## When using stream capture, create an event record node
  CU_EVENT_WAIT_DEFAULT*: cint  = 0x0 ## Default event wait flag */
  CU_EVENT_WAIT_EXTERNAL*: cint = 0x1  ## When using stream capture, create an event wait node


type
  CUfunction* = ptr object
  CUfunction_attribute* {.size: sizeof(cint).} = enum
    CU_FUNC_ATTRIBUTE_MAX_THREADS_PER_BLOCK  ## The maximum number of threads per block, beyond which a launch of the function would fail. This number depends on both the function and the device on which the function is currently loaded.
    CU_FUNC_ATTRIBUTE_SHARED_SIZE_BYTES  ## The size in bytes of statically-allocated shared memory required by this function. This does not include dynamically-allocated shared memory requested by the user at runtime.
    CU_FUNC_ATTRIBUTE_CONST_SIZE_BYTES  ## The size in bytes of user-allocated constant memory required by this function.
    CU_FUNC_ATTRIBUTE_LOCAL_SIZE_BYTES  ##The size in bytes of local memory used by each thread of this function.
    CU_FUNC_ATTRIBUTE_NUM_REGS  ## The number of registers used by each thread of this function.
    CU_FUNC_ATTRIBUTE_PTX_VERSION ## The PTX virtual architecture version for which the function was compiled. This value is the major PTX version * 10 + the minor PTX version, so a PTX version 1.3 function would return the value 13. Note that this may return the undefined value of 0 for cubins compiled prior to CUDA 3.0.
    CU_FUNC_ATTRIBUTE_BINARY_VERSION  ##The binary architecture version for which the function was compiled. This value is the major binary version * 10 + the minor binary version, so a binary version 1.3 function would return the value 13. Note that this will return a value of 10 for legacy cubins that do not have a properly-encoded binary architecture version. 
    CU_FUNC_ATTRIBUTE_MAX
  CUfunc_cache* = ptr object

type
  CUstream* = ptr object

type
  CUlimit* {.size: sizeof(cint).} = enum
    CU_LIMIT_STACK_SIZE  ## GPU thread stack size
    CU_LIMIT_PRINTF_FIFO_SIZE  ## GPU printf FIFO size
    CU_LIMIT_MALLOC_HEAP_SIZE  ## GPU malloc heap size

type
  CUjit_option* {.size: sizeof(cint).} = enum
    CU_JIT_MAX_REGISTERS  ## Max number of registers that a thread may use.
                          ## Option type: unsigned int
    CU_JIT_THREADS_PER_BLOCK  ## IN: Specifies minimum number of threads per block to target compilation for
                              ## OUT: Returns the number of threads the compiler actually targeted. This restricts the resource utilization fo the compiler (e.g. max registers) such that a block with the given number of threads should be able to launch based on register limitations. Note, this option does not currently take into account any other resource limitations, such as shared memory utilization.
                              ## Option type: unsigned int
    CU_JIT_WALL_TIME  ## Returns a float value in the option of the wall clock time, in milliseconds, spent creating the cubin
                      ## Option type: float
    CU_JIT_INFO_LOG_BUFFER  ## Pointer to a buffer in which to print any log messsages from PTXAS that are informational in nature (the buffer size is specified via option CU_JIT_INFO_LOG_BUFFER_SIZE_BYTES)
                            ## Option type: char*
    CU_JIT_INFO_LOG_BUFFER_SIZE_BYTES ## IN: Log buffer size in bytes. Log messages will be capped at this size (including null terminator)
                                      ## OUT: Amount of log buffer filled with messages
                                      ## Option type: unsigned int
    CU_JIT_ERROR_LOG_BUFFER ## Pointer to a buffer in which to print any log messages from PTXAS that reflect errors (the buffer size is specified via option CU_JIT_ERROR_LOG_BUFFER_SIZE_BYTES)
                            ## Option type: char*
    CU_JIT_ERROR_LOG_BUFFER_SIZE_BYTES  ## IN: Log buffer size in bytes. Log messages will be capped at this size (including null terminator)
                                        ## OUT: Amount of log buffer filled with messages
                                        ## Option type: unsigned int
    CU_JIT_OPTIMIZATION_LEVEL ## Level of optimizations to apply to generated code (0 - 4), with 4 being the default and highest level of optimizations.
                              ## Option type: unsigned int
    CU_JIT_TARGET_FROM_CUCONTEXT  ## No option value required. Determines the target based on the current attached context (default)
                                  ## Option type: No option value needed
    CU_JIT_TARGET ## Target is chosen based on supplied CUjit_target_enum.
                  ## Option type: unsigned int for enumerated type CUjit_target_enum
    CU_JIT_FALLBACK_STRATEGY  ## Specifies choice of fallback strategy if matching cubin is not found. Choice is based on supplied CUjit_fallback_enum.
                              ## Option type: unsigned int for enumerated type CUjit_fallback_enum
type
  CUmodule* = ptr object

const cudaDriverVersion {.intdefine.} = 2

when cudaDriverVersion == 2:
  {.pragma: importcv2 importc("$1_v2").}
else:
  {.pragma: importcv2 importc("$1").}

{.push dynlib(dlib), cdecl.}

proc cuInit*(flags: cuint): CUresult {.importc.}
proc cuDriverGetVersion*(driverVersion: ptr cint): CUresult {.importc.}

proc cuDeviceComputeCapability*(major: ptr cint, minor: ptr cint, dev: CUdevice) : CUresult {.importc.}
  ## Returns the compute capability of the device.
proc cuDeviceGet*(device: ptr CUdevice, ordinal: cint) : CUresult {.importc.}
  ## Returns a handle to a compute device.
proc cuDeviceGetAttribute*(pi: cint, attrib: CUdevice_attribute, dev: CUdevice) : CUresult {.importc.}
  ## Returns information about the device.
proc cuDeviceGetCount*(count: ptr cint) : CUresult {.importc.}
  ## Returns the number of compute-capable devices.
proc cuDeviceGetName*(cname: cstring, len: cint, dev: CUdevice) : CUresult {.importc.}
  ## Returns an identifer string for the device.
proc cuDeviceTotalMem*(bytes: ptr csize_t, dev: CUdevice) : CUresult {.importcv2.}

proc cuCtxCreate*(pctx: ptr CUcontext, flags: cuint, dev: CUdevice): CUresult {.importcv2.}
  ## Create a CUDA context.
proc cuCtxDestroy*(ctx: CUcontext): CUresult {.importcv2.}
  ## Destroy a CUDA context.
proc cuCtxGetApiVersion*(ctx: CUcontext, version: ptr cuint): CUresult {.importc.}
  ## Gets the context's API version.
proc cuCtxGetCacheConfig*(pconfig: CUfunc_cache): CUresult {.importc.}
  ## Returns the preferred cache configuration for the current context.
proc cuCtxGetCurrent*(pctx: ptr CUcontext): CUresult {.importc.}
  ## Returns the CUDA context bound to the calling CPU thread.
proc cuCtxGetDevice*(device: ptr CUdevice): CUresult {.importc.}
  ## Returns the device ID for the current context.
proc cuCtxGetLimit*(pvalue: ptr csize_t, limit: CUlimit): CUresult {.importc.}
  ## Returns resource limits.
proc cuCtxPopCurrent*(pctx: ptr CUcontext): CUresult {.importc.}
  ## Pops the current CUDA context from the current CPU thread.
proc cuCtxPushCurrent*(ctx: CUcontext): CUresult {.importc.}
  ## Pushes a context on the current CPU thread.
proc cuCtxSetCacheConfig*(config: CUfunc_cache): CUresult {.importc.}
  ## Sets the preferred cache configuration for the current context.
proc cuCtxSetCurrent*(ctx: CUcontext): CUresult {.importc.}
  ## Binds the specified CUDA context to the calling CPU thread.
proc cuCtxSetLimit*(limit: CUlimit, value: csize_t): CUresult {.importc.}
  ## Set resource limits.
proc cuCtxSynchronize*(): CUresult {.importc.}
  ## Block for a context's tasks to complete.

proc cuModuleGetFunction*(hfunc: ptr CUfunction, hmod: CUmodule, name: cstring): CUresult {.importc.}
  ## Returns a function handle.
proc cuModuleGetGlobal*(dptr: ptr CUdeviceptr, bytes: ptr csize_t, hmod: CUmodule , name: cstring): CUresult {.importc.}
  ## Returns a global pointer from a module.
#proc cuModuleGetSurfRef*(pSurfRef: ptr CUsurfref, hmod: CUmodule, name: cstring): CUresult {.importc.}
#  ## Returns a handle to a surface reference.
#proc cuModuleGetTexRef*(pTexRef: ptr CUtexref, hmod: CUmodule, name: cstring): CUresult {.importc.}
#  ## Returns a handle to a texture reference.
proc cuModuleLoad*(module: ptr CUmodule, fname: cstring): CUresult {.importc.}
  ## Loads a compute module.
proc cuModuleLoadData*(module: ptr CUmodule, image: pointer): CUresult {.importc.}
  ## Load a module's data.
proc cuModuleLoadDataEx*(module: ptr CUmodule, image: pointer, numOptions: cuint, option: ptr CUjit_option, optionValues: ptr pointer): CUresult {.importc.}
  ## Load a module's data with options.
proc cuModuleLoadFatBinary*(module: ptr CUmodule, fatCubin: pointer): CUresult {.importc.}
  ## Load a module's data.
proc cuModuleUnload*(hmod: CUmodule): CUresult {.importc.}
  ## Unloads a module. 

proc cuMemAlloc*(dptr: ptr CUdeviceptr, bytesize: csize_t): CUresult {.importcv2.}
  ## Allocates device memory.
proc cuMemAllocHost*(pp: ptr pointer, bytesize: csize_t): CUresult {.importcv2.}
  ## Allocates page-locked host memory.
proc cuMemcpyDtoHAsync*(dstHost: pointer, srcDevice: CUdeviceptr, ByteCount: csize_t, hSTream: CUstream): CUresult {.importcv2.}
  ## Copies memory from Device to Host.
proc cuMemcpyHtoDAsync*(dstDevice: CUdeviceptr, srcHost: pointer, ByteCount: csize_t, hSTream: CUstream): CUresult {.importcv2.}
  ## Copies memory from Host to Device.
proc cuMemcpyDtoH*(dstHost: pointer, srcDevice: CUdeviceptr, ByteCount: csize_t): CUresult {.importcv2.}
  ## Copies memory from Device to Host.
proc cuMemcpyHtoD*(dstDevice: CUdeviceptr, srcHost: pointer, ByteCount: csize_t): CUresult {.importcv2.}
  ## Copies memory from Host to Device.
proc cuMemFree*(dptr: CUdeviceptr): CUresult {.importcv2.}
  ## ## Frees device memory.
proc cuMemFreeHost*(p: pointer): CUresult {.importc.}
  ## Frees page-locked host memory.
proc cuMemGetInfo*(free: ptr csize_t, total: ptr csize_t): CUresult {.importc.}
  ## Gets free and total memory.
proc cuMemHostAlloc*(pp: ptr pointer, bytesize: csize_t, Flags: cuint): CUresult {.importc.}
  ## Allocates page-locked host memory.
proc cuMemHostGetDevicePointer*(pdptr: ptr CUdeviceptr, p: pointer, Flags: cuint): CUresult {.importcv2.}
  ## Passes back device pointer of mapped pinned memory.
proc cuMemHostGetFlags*(pFlags: ptr cuint, p: pointer): CUresult {.importc.}
## Passes back flags that were used for a pinned allocation.

proc cuStreamCreate*(phStream: ptr CUstream, Flags: cuint): CUresult {.importc.}
  ## Create a stream.
proc cuStreamDestroy*(hStream: CUstream): CUresult {.importcv2.}
  ## Destroys a stream.
proc cuStreamQuery*(hStream: CUstream): CUresult {.importc.}
  ## Determine status of a compute stream.
proc cuStreamSynchronize*(hStream: CUstream): CUresult {.importc.}
  ## Wait until a stream's tasks are completed.
proc cuStreamWaitEvent*(hStream: CUstream, hEvent: CUevent, Flags: cuint): CUresult {.importc.}
  ## Make a compute stream wait on an event. 

proc cuFuncGetAttribute*(pi: ptr cint, attrib: CUfunction_attribute, hfunc: CUfunction): CUresult {.importc.}
  ## Returns information about a function.
proc cuFuncSetCacheConfig*(hfunc: CUfunction, config: CUfunc_cache): CUresult {.importc.}
  ## Sets the preferred cache configuration for a device function.
proc cuLaunchKernel*(f: CUfunction, gridDimX: cuint, gridDimY: cuint, gridDimZ: cuint, blockDimX: cuint, 
    blockDimY: cuint, blockDimZ: cuint, sharedMemBytes: cuint, hStream: CUstream, kernelParams: ptr pointer, 
    extra: ptr pointer): CUresult {.importc.}
  ## Launches a CUDA function. 

proc cuGetErrorString*(error: CUresult, pStr: ptr cstring) {.importc.}
proc cuGetErrorName*(error: CUresult, pStr: ptr cstring) {.importc.}

{.pop.}
