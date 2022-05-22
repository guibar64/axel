
## Axel

Threadpool-like for managing device compute kernels

**Note**: This is experimental, currently based of a fork of [nlvm](https://github.com/arnetheduck/nlvm), for now only nvdia GPU (via CUDA driver API) are supported.
```

### Motivating example: vecAdd

```nim
import axel/device
import axel/device_arrays

proc vecAdd(a,b: Array[float32], c: Array[float32])  {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  if i < a.len:
    c[i] = a[i] + b[i]


when not defined(onDevice):
  # host code
  import std/random
  import axel/[devthreadpool, device_ptrs] 
  # Importing this module will trigger a recompilation by nlvm to generate
  # device code. Otherwise one could load independant device modules
  import axel/build_device_code

  # Initialize a context, loads device code
  var tp = newDevThreadpool()

  let n = 10_000
  # Allocates input/output arrays. With 'Unified' host and device buffers shares an address.
  var a,b,c = initArray[float32](n, kind = ArrayKind.Unified) 

  randomize(2727383)
  for i in 0..<n:
    a[i] = rand(1.0'f32)
    b[i] = rand(1.0'f32)

  let nth = 128
  let ntm = (n + nth - 1) div nth
  # launches a grid of ntm×nth kernels
  # Returns a 'FlowVar'.
  # 'sync' waits for the tasks to finish.
  sync tp.grid(ntm, nth).spawn vecAdd(a, b, c)

  #  check
  for i in 0..<n:
    doAssert abs(c[i] - (a[i] + b[i])) < 1.0e-6
```

The threadpool API is based [guidelines](https://github.com/nim-lang/RFCs/issues/347#task-parallelism-api),
and tries to follow the [nim-taskpools](https://github.com/status-im/nim-taskpools) implementation. The main difference being
that a ``spawn`` launches a grid of tasks instead of a single one.

In this example, the host and device shares the same virtual addresses, so that the memory transfer are 
automagically performed, see the [Unified Memory Programming](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#um-unified-memory-programming-hd) section of the CUDA documentation for more.

An API exists to do an explicit handling of device and host memory buffers

```nim
var c = newSeq[float32](1000)
let dc = createDeviceArrayPtr[float32](c.len)
# Host to Device
let fv1 = dc <- c
# …
# Host to Device
let fv2 = c <- dc
# ! operator to pass device handles to kernel
let fv3 = tp.grid(10, 256).spawn myKernel(!c)
```


### Prerequisites

- an NVIDIA GPU with the CUDA driver library installed
- ``libdevice`` LLVM library for math functions (``axel/math`` module), usually found in a full CUDA installations. Option ``--nlvm.cuda.path=…`` added to nim.cfg/config.nims can help.
Use ``--nlvm.cuda.nolibdevice`` to ignore it.
- nlvm: nlvm is only available on x86_64-Linux (incl. WSL), with some tweaking of the Makefile it may work on other platforms (full support of other targets is not required, regular ``nim`` is enough for host code)

## Getting started

The library can be installed with

```
nimble install https://github.com/guibar64/axel@#head
```

As for nlvm, we need an hacked version to generate PTX
```
git clone https://github.com/guibar64/nlvm
cd nlvm
git checkout nvidiagpu
```

Building can be done by
```
make STATIC_LLVM=1
```

**Warning**: The simple command ``make`` will try to build LLVM, which can take 1h or so, and can take more than 1GB/core.

The resulting binary is located in the ``nlvm/`` subfolder, adding this folder to the ``PATH`` is advisable.

Now the Nim compiler can be used on the examples or tests, ``nlvm`` with be invoked under the hood.

To compile the host code with nlvm you have to pass options to the linker, like this:
```
nlvm c --dynlibOverride:cuda --passl:"-L/opt/cuda/lib64 -lcuda" tests/test1.nim
```

**Warning**: the patched nlvm overrides the target cpu ``ia64`` on the Nim side to get it going

### Garbage collection and exceptions

At this moment, none of Nim's memory management schemes work but for ``--gc:none``, calls like ``newSeq`` crash.
One can use manual MM (``alloc``/``dealloc``), besides the use of preallocated global/shared memory which is more customary on GPUs. Shared memory allocated at launch is accessible via the call ``getSharedMemBuffer()``.

Exceptions are a non-starter

Possible directions: ``--gc:arc --exceptions:goto``, but it need nlvm support first.
