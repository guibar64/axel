# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import std/macros

when defined(onDevice):
  {.error: "This module is not available on device side".}

import ./kernel
import ./private/[cuda, cuda_utils]

type
  DevThreadpool* = object
    ctx: CUcontext
    module: CUmodule
    teams: tuple[x,y,z: cuint]
    threads: tuple[x,y,z: cuint]
    sharedMemSize: cuint
  FlowVar* = object
    stream*: CUstream

proc shutdown*(tp: var DevThreadpool) =
  if tp.ctx != nil:
    check cuCtxSetCurrent(tp.ctx)
    check cuCtxSynchronize()
    check cuModuleUnload(tp.module)
    check cuCtxDestroy(tp.ctx)
    tp.ctx = nil

proc `=destroy`(fv: var DevThreadpool) =
  shutdown(fv)

proc getAddressOrNil(s: string): ptr char =
  if s.len == 0: nil else: unsafeAddr(s[0])

proc newDevThreadpool*(code: string, deviceNum = 0): DevThreadpool =
  # Create a context and device code for a threadpool and for a given device
  var device: CUdevice
  try:
    check cuDeviceGet(addr device, cint deviceNum)
    check cuCtxCreate(addr result.ctx, 0, device)
    check cuModuleLoadDataEx(addr result.module, getAddressOrNil(code), 0, nil, nil)
    result.teams = (1.cuint,1.cuint,1.cuint)
    result.threads = (1.cuint,1.cuint,1.cuint)
    result.sharedMemSize = 0
  except CudaError as e:
    # reset tp.ctx otherwise destructor will try to destroy an unhappy state
    result.ctx = nil
    raise e

template newDevThreadpool*(deviceNum = 0): DevThreadpool =
  # Create a context and get code from what has been compiled in the project
  newDevThreadpool(theGeneratedDeviceCode, deviceNum)

proc newFlowvar*(): FlowVar =
  check cuStreamCreate(addr result.stream, 0)

proc `=destroy`(fv: var Flowvar) =
  if fv.stream != nil:
    try:
      check cuStreamQuery(fv.stream)
      check cuStreamSynchronize(fv.stream)
      check cuStreamDestroy(fv.stream)
    except CudaError:
      discard # Ressource could have been freed at shutdown so we ignore errors
    fv.stream = nil

proc `=copy`(dst: var FlowVar, src: FlowVar) {.error: "A FlowVar cannot be copied".}

proc isSpawned*(fv: FlowVar): bool = 
  # This is probably wrong
  fv.stream != nil and (let q = cuStreamQuery(fv.stream); q == CUDA_SUCCESS or q == CUDA_ERROR_NOT_READY)

proc isReady*(fv: FlowVar): bool =
  fv.stream == nil or cuStreamQuery(fv.stream) == CUDA_SUCCESS

proc sync*(fv: sink FlowVar) = 
  if fv.stream != nil:
    check cuStreamSynchronize(fv.stream)

proc sync*(fv: varargs[FlowVar]) =
  ## wait for all ``fc`` to finish
  var done = false
  while not done:
    # a bit busy, maybe there is something smarter to do…
    for i in 0..<fv.len:
      done = fv[i].isReady

proc syncAll*(tp: DevThreadpool) =
  check cuCtxSetCurrent(tp.ctx)
  check cuCtxSynchronize()

proc launch*(tp: DevThreadpool, fn: string, args: openArray[pointer]): FlowVar =
  check cuCtxSetCurrent(tp.ctx) # ?
  var hfunc: CUfunction
  check cuModuleGetFunction(addr hfunc, tp.module, fn.cstring)
  result = newFlowvar()
  check cuLaunchKernel(hfunc, tp.teams.x, tp.teams.y, tp.teams.z, tp.threads.x, tp.threads.y, 
    tp.threads.z, tp.sharedMemSize, result.stream, if args.len == 0: nil else: unsafeAddr(args[0]), nil)

template tempAndTakeAddr(o): pointer =
  let o2 = o
  pointer(unsafeAddr o2)

template takeAddr(o): pointer =
  pointer(unsafeAddr o)

template takeOpenArrayAddr(o): pointer =
  var p = unsafeAddr o[0]
  pointer(addr p)

template takeOpenArrayLenAddr(o): pointer =
  var p = o.len
  pointer(addr p)

template takeOpenArrayLenAddrStartEnd(start, `end`): pointer =
  var p = `end` - start + 1
  pointer(addr p)

macro spawn*(tp: DevThreadpool, fnCall: typed): untyped =
  fnCall.expectKind {nnkCall, nnkCommand}
  let fn = fnCall[0].getImpl()
  var fname = fnCall[0].strVal()
  var hasKernelTag = false
  if fn != nil:
    for p in fn[4]:
      if p.kind in {nnkCall,nnkExprColonExpr} and p.len >= 2 and p[0].kind == nnkIdent and p[0].eqIdent("exportc"):
        fname = p[1].strVal()
      elif p.kind == nnkCall and p[0].kind == nnkSym and p[0].eqIdent("kerneltag"):
        hasKernelTag = true
  if not hasKernelTag:
    error("Error: '" & fnCall[0].strVal() & "' needs to be a kernel")
  var args = nnkBracket.newTree()
  for i in 1..<fnCall.len:
    let arg = fnCall[i]
    let typ = arg.getType()
    if arg.kind == nnkCall and arg[0].eqIdent("toOpenArray") and arg.len == 4:
      # matched toOpenArray(a, start, end)
      # break up openArray as done in backend
      args.add getAst(takeOpenArrayAddr(arg[1]))
      args.add getAst(takeOpenArrayLenAddrStartEnd(arg[2], arg[3]))
    else:
      # If is is an expression not reducible to a varialbe one needs to make a temporary
      args.add if arg.kind == nnkSym: getAst(takeAddr(arg)) else: getAst(tempAndTakeAddr(arg))
  result = newCall(ident"launch", tp, newLit(fname), args)

proc setGrid*(tp: var DevThreadpool, numTeams, numThreads: int, sharedMemSize = 0) =
  # Sets a 1D grid of threads for the next spawn, as well as the amount of shared memory
  tp.teams = (numTeams.cuint, 1.cuint, 1.cuint)
  tp.threads = (numThreads.cuint, 1.cuint, 1.cuint)
  tp.sharedMemSize = sharedMemSize.cuint

proc setGrid*(tp: var DevThreadpool, numTeams, numThreads: (int, int, int), sharedMemSize = 0) =
  ## Sets a 3D grid of threads for the next spawn, as well as the amount of shared memory
  tp.teams = (numTeams[0].cuint, numTeams[1].cuint, numTeams[2].cuint)
  tp.threads = (numThreads[0].cuint, numThreads[1].cuint, numThreads[2].cuint)
  tp.sharedMemSize = sharedMemSize.cuint


proc grid*(tp: var DevThreadpool, numTeams, numThreads: int, sharedMemSize = 0): var DevThreadpool =
  ## Same as setGrid, but returns ``tp`` for e.g. chaining
  tp.setGrid(numTeams, numThreads, sharedMemSize)
  tp

proc grid*(tp: var DevThreadpool, numTeams, numThreads: (int, int, int), sharedMemSize = 0): var DevThreadpool =
  ## Same as setGrid, but returns ``tp`` for e.g. chaining
  tp.setGrid(numTeams, numThreads, sharedMemSize)
  tp

