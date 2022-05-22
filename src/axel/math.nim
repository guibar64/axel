# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

when defined(cuda):
  import std/math  as std_math except log10, sqrt, cbrt, exp, sin, cos, tan, arcsin, arccos, arctan, arctan2, 
    arcsinh, arccosh, arctanh, hypot, pow, gamma, lgamma, erf, erfc, floor, ceil, trunc, round,
    `mod`   
  func sqrt*(x: float32): float32 {.importc: "__nv_sqrtf".}
  func sqrt*(x: float64): float64 {.importc: "__nv_sqrt".}
  func cbrt*(x: float32): float32 {.importc: "__nv_cbrtf".}
  func cbrt*(x: float64): float64 {.importc: "__nv_cbrt".}
  func ln*(x: float32): float32 {.importc: "__nv_logf".}
  func ln*(x: float64): float64 {.importc: "__nv_log".}
  func log10*(x: float32): float32 {.importc: "__nv_log10f".}
  func log10*(x: float64): float64 {.importc: "__nv_log10".}
  func exp*(x: float32): float32 {.importc: "__nv_expf".}
  func exp*(x: float64): float64 {.importc: "__nv_exp".}
  func sin*(x: float32): float32 {.importc: "__nv_sinf".}
  func sin*(x: float64): float64 {.importc: "__nv_sin".}
  func cos*(x: float32): float32 {.importc: "__nv_cosf".}
  func cos*(x: float64): float64 {.importc: "__nv_cos".}
  func tan*(x: float32): float32 {.importc: "__nv_tanf".}
  func tan*(x: float64): float64 {.importc: "__nv_tan".}
  func sinh*(x: float32): float32 {.importc: "__nv_sinhf".}
  func sinh*(x: float64): float64 {.importc: "__nv_sinh".}
  func cosh*(x: float32): float32 {.importc: "__nv_coshf".}
  func cosh*(x: float64): float64 {.importc: "__nv_cosh".}
  func tanh*(x: float32): float32 {.importc: "__nv_tanhf".}
  func tanh*(x: float64): float64 {.importc: "__nv_tanh".}
  func arcsin*(x: float32): float32 {.importc: "__nv_asinf".}
  func arcsin*(x: float64): float64 {.importc: "__nv_asin".}
  func arccos*(x: float32): float32 {.importc: "__nv_acosf".}
  func arccos*(x: float64): float64 {.importc: "__nv_acos".}
  func arctan*(x: float32): float32 {.importc: "__nv_atanf".}
  func arctan*(x: float64): float64 {.importc: "__nv_atan".}
  func arctan2*(y, x: float32): float32 {.importc: "__nv_atan2f".}
  func arctan2*(y, x: float64): float64 {.importc: "__nv_atan2".}
  func arcsinh*(x: float32): float32 {.importc: "__nv_asinhf".}
  func arcsinh*(x: float64): float64 {.importc: "__nv_asinh".}
  func arccosh*(x: float32): float32 {.importc: "__nv_acoshf".}
  func arccosh*(x: float64): float64 {.importc: "__nv_acosh".}
  func arctanh*(x: float32): float32 {.importc: "__nv_atanhf".}
  func arctanh*(x: float64): float64 {.importc: "__nv_atanh".}
  func hypot*(x, y: float32): float32 {.importc: "__nv_hypotf".}
  func hypot*(x, y: float64): float64 {.importc: "__nv_hypot".}
  func pow*(x, y: float32): float32 {.importc: "__nv_powf".}
  func pow*(x, y: float64): float64 {.importc: "__nv_pow".}
  func erf*(x: float32): float32 {.importc: "__nv_erff".}
  func erf*(x: float64): float64 {.importc: "__nv_erf".}
  func erfc*(x: float32): float32 {.importc: "__nv_erfcf".}
  func erfc*(x: float64): float64 {.importc: "__nv_erfc".}
  func gamma*(x: float32): float32 {.importc: "__nv_tgammaf".}
  func gamma*(x: float64): float64 {.importc: "__nv_tgamma".}
  func lgamma*(x: float32): float32 {.importc: "__nv_lgammaf".}
  func lgamma*(x: float64): float64 {.importc: "__nv_lgamma".}
  func floor*(x: float32): float32 {.importc: "__nv_floorf".}
  func floor*(x: float64): float64 {.importc: "__nv_floor".}
  func ceil*(x: float32): float32 {.importc: "__nv_ceilf".}
  func ceil*(x: float64): float64 {.importc: "__nv_ceil".}
  func round*(x: float32): float32 {.importc: "__nv_roundf".}
  func round*(x: float64): float64 {.importc: "__nv_round".}
  func trunc*(x: float32): float32 {.importc: "__nv_truncf".}
  func trunc*(x: float64): float64 {.importc: "__nv_trunc".}
  func `mod`*(x, y: float32): float32 {.importc: "__nv_fmodf".}
  func `mod`*(x, y: float64): float64 {.importc: "__nv_fmod".} 

  export std_math except log10, sqrt, cbrt, exp, sin, cos, tan, arcsin, arccos, arctan, arctan2, 
    arcsinh, arccosh, arctanh, hypot, pow, gamma, lgamma, erf, erfc, floor, ceil, trunc, round,
    `mod`   
else:
  import std/math as std_math
  export std_math