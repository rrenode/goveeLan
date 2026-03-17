import std/[json]

type
  GPowerState* = enum
    pOff = 0,
    pOn = 1

  Percent* = range[0..100]

  GBrightness* = Percent

  GColorMode* = enum
    cmRgb, cmWhite

  GTemperature* = range[2000..9000]
  GColor* = object
    r*: range[0..255]
    g*: range[0..255]
    b*: range[0..255]
  
  GColorWc* = object
    case mode*: GColorMode
    of cmRgb:
      color*: GColor
    of cmWhite:
      temperature*: GTemperature

  GDeviceStatus* = object
    onOff*: GPowerState
    brightness*: GBrightness
    clrWc*: GColorWc

proc `%`*(clr: GColor): JsonNode =
  %*{
    "color":{
      "r":clr.r,
      "g":clr.g,
      "b":clr.b
    }
  }

proc `bool`*(ps: GPowerState): bool =
  case ps:
  of pOff: false
  of pOn: true

proc to*(j: JsonNode, _: typedesc[GColor]): GColor =
  let data =
    if j.hasKey("color"): j["color"]
    else: j

  result = GColor(
    r: data["r"].getInt,
    g: data["g"].getInt,
    b: data["b"].getInt
  )

proc to*(j: JsonNode, _: typedesc[GDeviceStatus]): GDeviceStatus =
  let data = j["msg"]["data"]
  let temp = data["colorTemInKelvin"].getInt
  let clr = data["color"].to(GColor)
  var clrwc: GColorWc = GColorWc(mode:cmRgb, color:clr)
  if temp != 0:
    clrwc = GColorWc(mode:cmWhite, temperature:GTemperature(temp))

  result = GDeviceStatus(
    onOff: GPowerState(data["onOff"].getInt),
    brightness: GBrightness(data["brightness"].getInt),
    clrWc: clrwc
  )