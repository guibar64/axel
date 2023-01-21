import axel/device

proc vecAdd(a, b, c: ptr UncheckedArray[float32], n: int) {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  echo thisTeam()
  if i < n:
    c[i] = a[i] + b[i]

when not defined(onDevice):
  import std/random
  import axel/[devthreadpool, device_ptrs]
  # Importing this module will trigger a recompilation by nlvm to generate
  # device code. Otherwise one could load independant device modules
  import axel/build_device_code

  # Initialize a context, loads device code
  var tp = newDevThreadpool()

  # allocates 3 arrays on a common address betwen host and device.
  let n = 10_000
  var a, b, c = createUniAddressArrayPtr[float32](n)
  randomize(2727383)
  for i in 0..<n:
    a[i] = rand(1.0'f32)
    b[i] = rand(1.0'f32)


  let nth = 128
  let ntm = (n + nth - 1) div nth
  # launches a grid of ntm×nth kernels
  # Returns a 'FlowVar'.
  # 'sync' waits for the tasks to finish.
  sync tp.grid(ntm, nth).spawn vecAdd(a, b, c, n)

  # Sanity check
  for i in 0..<n:
    doAssert abs(c[i] - (a[i] + b[i])) < 1.0e-6

  deallocUniAddressArrayPtr(a)
  deallocUniAddressArrayPtr(b)
  deallocUniAddressArrayPtr(c)
