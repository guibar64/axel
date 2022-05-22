# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

from std/math import nextPowerOfTwo

when defined(onDevice):
  import runtime
  import io

const 
  headerContentSize = 2*sizeof(int)+1
  headerSize = nextPowerOfTwo(headerContentSize)
  arrayHeaderPadding = headerSize - headerContentSize
type
  ArrayKind* {.pure.} = enum
    Dual  ## one on cpu, another on device. Requires explicit synchronisations
    Unified ## synchronisation is transparent
  ArrayHeader = object
    len: int
    rc: int # 
    kind: ArrayKind
    # padding to the next power of 2
    padding: array[arrayHeaderPadding, byte]
  ArrayPtr[T] = ptr object 
    header: ArrayHeader
    data: UncheckedArray[T]

# dual: on host dev memory is on the first half so that the device can pick that up
when defined(onDevice):
  type
    Array*[T] = object
      p*: ArrayPtr[T]
      dev*: uint
else:
  type
    Array*[T] = object
      dev*: uint
      p*: ArrayPtr[T]
type
  ArrayImm*[T] = distinct Array[T] ## immutable version

func len*[T](a: Array[T]): int = 
  if a.p == nil: 0 else: a.p.header.len

func len*[T](a: ArrayImm[T]): int = 
  if a.p == nil: 0 else: a.p.header.len

when not defined(onDevice):
  import device_ptrs
  import devthreadpool # for flowvar

  proc deallocArray[T](a: Array[T]) =
    case a.p.header.kind
    of ArrayKind.Dual:
      var dp: DeviceArrayPtr[byte]
      dp.handle = a.dev
      dealloc cast[DeviceArrayPtr[T]](dp)
      deallocShared a.p
    of ArrayKind.Unified:
      deallocUniAddressArrayPtr cast[ptr UncheckedArray[byte]](a.p)

  proc `=destroy`[T](a: var Array[T]) =
    if a.p != nil:
      deallocArray(a)

  proc `=destroy`[T](a: var ArrayImm[T]) =
    discard

  # shallow semantics for now
  proc `=copy`[T](a: var Array[T], b: Array[T]) =
    a.p = b.p
    a.dev = b.dev

  proc `=copy`[T](a: var ArrayImm[T], b: ArrayImm[T]) =
    a.p = b.p
    a.dev = b.dev

  proc initArray*[T](len: int, kind = ArrayKind.Dual): Array[T] =
    case kind
    of ArrayKind.Dual:
      let hp = cast[ptr UncheckedArray[byte]](allocShared(sizeof(ArrayHeader) + sizeof(T)*len))
      let dp = createDeviceArrayPtr[byte](sizeof(ArrayHeader) + sizeof(T)*len)
      result.p = cast[ArrayPtr[T]](hp)
      result.dev = dp.handle
      result.p.header.kind = kind
      result.p.header.len = len
      sync copy(dp, hp, sizeof(ArrayHeader))
    of ArrayKind.Unified:
      result.p = cast[ArrayPtr[T]](createUniAddressArrayPtr[byte](sizeof(ArrayHeader) + sizeof(T)*len))
      result.dev = cast[uint](result.p)
      result.p.header.kind = kind
      result.p.header.len = len

  proc toDevice*[T](a: Array[T]): FlowVar =
    ## copy host data to device data. No-op for Unified kind.
    result = case a.p.header.kind
    of ArrayKind.Dual:
      var dp: DeviceArrayPtr[byte]
      dp.handle = a.dev
      let hp = cast[ptr UncheckedArray[byte]](a.p)
      let size = a.len*sizeof(T) + sizeof(ArrayHeader) 
      copy(dp, hp, size)
    of ArrayKind.Unified:
      newFlowvar()

  proc toHost*[T](a: Array[T]): FlowVar =
    ## copy device data to host data. No-op for Unified kind.
    result = case a.p.header.kind
    of ArrayKind.Dual:
      var dp: DeviceArrayPtr[byte]
      dp.handle = a.dev
      let hp = cast[ptr UncheckedArray[byte]](a.p)
      let size = a.len*sizeof(T) + sizeof(ArrayHeader)
      copy(hp, dp, size)
    of ArrayKind.Unified:
      newFlowvar()

  template `->`*[T](a: Array[T]): FlowVar = toDevice(a)
  template `<-`*[T](a: Array[T]): FlowVar = toHost(a)

func toImm*[T](a: Array) {.inline.} = ArrayImm[T](a)

func checkBounds*[T](a: Array[T], idx: int) =
  if a.p == nil:
    # no exceptions on device (--exceptions:goto ?)
    when defined(onDevice):
      echoString("Error: IndexDefect: devarrays.Array: is nil\n")
      abort()
    else:
      raise newException(IndexDefect, "devarrays.Array: is nil\n")
  elif idx < 0 or idx >= a.p.header.len:
    when defined(onDevice):
      echoString("Error: IndexDefect: devarrays.Array: out of bonds!\n")
      abort()
    else:
      raise newException(IndexDefect, "devarrays.Array: out of bonds!\n")

template `[]`*[T](a: Array[T], idx: int): T =
  when compileOption("boundchecks"): checkBounds(a, idx)
  a.p.data[idx]

template `[]`*[T](a: ArrayImm[T], idx: int): T =
  when compileOption("boundchecks"): checkBounds(a, idx)
  a.p.data[idx]

template `[]=`*[T](a: Array[T], idx: int, val: T) =
  when compileOption("boundchecks"): checkBounds(a, idx)
  a.p.data[idx] = val

template toOpenArray*[T](a: Array[T], start, `end`: int): openArray[T] = 
  toOpenArray(cast[ptr UncheckedArray[T]](unsafeAddr a.p.data[0]), start, `end`)
