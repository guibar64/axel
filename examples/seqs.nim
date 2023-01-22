# Copyright (c) 2023 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import std/algorithm
import axel/device

proc noyau(result: ptr UncheckedArray[int], n: int) {.kernel.} =
  let idx = thisTeam()*numTeams() + thisThread()
  let n = 2 + idx
  var x = newSeq[int](n)
  for i in 0..<n:
    x[i] = 1 + n*(n - i)
  var y = sorted(x)

  result[idx] = y[0]+y[1]


when not defined(onDevice):
  # host side
  import axel/[devthreadpool, device_ptrs]
  import axel/build_device_code

  let n = 32
  var tp = newDevThreadpool()
  var r = createUniAddressArrayPtr[int](n)

  sync tp.grid(1, n).spawn noyau(r, 10)

  echo $(toOpenArray(r, 0, n-1))

  deallocUniAddressArrayPtr(r)

