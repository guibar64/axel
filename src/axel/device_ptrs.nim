# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

when defined(onDevice):
  {.error: "This module is not available on device side".}

import ./private/[cuda, cuda_utils]
import devthreadpool

type
  DeviceArrayPtr*[T] = object 
    h: CUdeviceptr ## Handle to Device Memory

func handle*[T](d: DeviceArrayPtr[T]): uint {.inline.} = uint(d.h)

func `handle=`*[T](d: var DeviceArrayPtr[T], h: uint){.inline.} = 
  d.h = CUdeviceptr(h)

proc dealloc*[T](d: DeviceArrayPtr[T]) =
  ## Deallocates a buffer on the device
  if d.h.uint != 0: check cuMemFree(d.h)

proc toKernelParam*[T](d: DeviceArrayPtr[T]): ptr UncheckedArray[T] {.inline.} = 
  ## For interfacing device memory with a kernel call expecting an array
  result = cast[typeof(result)](d.h)

template `!`*[T](d: DeviceArrayPtr[T]): ptr UncheckedArray[T] = toKernelParam[T](d)
  ## alias to ``toKernelParam``

proc realloc*[T](d: var DeviceArrayPtr[T], size: int) =
  ## Reallocates a buffer on the device from an array on host
  if d.h.uint != 0: dealloc(d)
  check cuMemAlloc(addr d.h, csize_t size*sizeof(T))

proc createDeviceArrayPtr*[T](size: int): DeviceArrayPtr[T] =
  ## Creates a buffer on the device from an array on host
  realloc(result, size)

proc `<-`*[T](dest: DeviceArrayPtr[T], src: openArray[T]): FlowVar =
  ## transfer Device -> Host
  result = newFlowVar()
  check cuMemcpyHtoDAsync(dest.h, unsafeAddr src[0], csize_t  sizeof(T)*src.len, result.stream)

proc `<-`*[T](dest: var openArray[T], src: DeviceArrayPtr[T]): FlowVar =
  ## transfer Host -> Device
  result = newFlowVar()
  check cuMemcpyDtoHAsync(addr dest[0], src.h, csize_t sizeof(T)*dest.len, result.stream)

proc copy*[T](dest: ptr UncheckedArray[T], src: DeviceArrayPtr[T], len: int): FlowVar =
  ## transfer Device -> Host
  result = newFlowVar()
  check cuMemcpyDtoHAsync(addr dest[0], src.h, csize_t sizeof(T)*len, result.stream)

proc copy*[T](dest: DeviceArrayPtr[T], src: ptr UncheckedArray[T], len: int): FlowVar =
  ## transfer Host -> Device
  result = newFlowVar()
  check cuMemcpyHtoDAsync(dest.h, addr src[0], csize_t sizeof(T)*len, result.stream)

proc copyBlocking*[T](dest: DeviceArrayPtr[T], src: openArray[T]) =
  ## transfer Host -> Device, sans asynchronism.
  check cuMemcpyHtoD(dest.h, unsafeAddr src[0], csize_t  sizeof(T)*src.len)

proc copyBlocking*[T](dest: var openArray[T], src: DeviceArrayPtr[T]) =
  ## transfer Device -> Host , sans asynchronism
  check cuMemcpyDtoHAsync(addr dest[0], src.h, csize_t sizeof(T)*dest.len)

proc createDeviceArrayPtr*[T](src: openArray[T]): DeviceArrayPtr[T] =
  ## Creates a buffer on the device from an array on host
  realloc(result, src.len)
  copyBlocking(result, src)

proc createUniAddressArrayPtr*[T](size: int): ptr UncheckedArray[T] = 
  ## Creates a buffer that uses Universal Addressing, ie uses same virtual address to both CPU and GPU.
  var p: pointer
  check cuMemAllocHost(addr p, csize_t(sizeof(T)*size))
  result = cast[ptr UncheckedArray[T]](p)

proc deallocUniAddressArrayPtr*[T](p: ptr UncheckedArray[T]) = 
  ## Deallocates a buffer that uses Universal Addressing
  check cuMemFreeHost(p)

proc reallocUniAddressArrayPtr*[T](d: var DeviceArrayPtr[T], size: int) =
  ## Reallocates a buffer on the device from an array on host
  if d != nil: deallocUniAddressArrayPtr(d)
  d = createUniAddressArrayPtr
