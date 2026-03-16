type
  GPowerState* = enum
    pOn, pOff

  Percent* = range[0..100]

  GBrightness* = Percent
  GTemp* = range[2000..9000]
  GColor* = object
    r*: int
    g*: int
    b*: int

proc `bool`*(ps: GPowerState): bool =
  case ps:
  of pOn: true
  of pOff: false