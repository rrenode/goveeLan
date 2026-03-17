type
  GPowerState* = enum
    pOff = 0,
    pOn = 1

  Percent* = range[0..100]

  GBrightness* = Percent
  GTemperature* = range[2000..9000]
  GColor* = object
    r*: int
    g*: int
    b*: int

proc `bool`*(ps: GPowerState): bool =
  case ps:
  of pOff: false
  of pOn: true