import std/[json, net, strutils]
import socker
type
  Percent = range[0..100]

  GBrightness* = Percent
  GTemp* = range[2000..9000]
  GColor* = object
    r*: int
    g*: int
    b*: int

  DeviceControl* = object
    device*: FoundDevice
    controller*: Controller
  
  DeviceStatus* = object
    on*: bool
    brightness*: GBrightness
    color*: GColor
    temp*: GTemp

proc send*(d: DeviceControl, payload: JsonNode) =
  d.controller.send(d.device.ipAddr, payload)

proc turn*(d: DeviceControl, on: bool) =
  let val = if on: 1 else: 0
  let payload = %*{
    "msg": {
      "cmd": "turn",
      "data": {
        "value": val
      }
    }
  }
  d.send(payload)

proc status*(d: DeviceControl): JsonNode =
  let payload = %*{
    "msg": {
      "cmd": "devStatus",
      "data": {}
    }
  }

  d.send(payload)

  var
    data = ""
    address = ""
    port: Port

  let n = d.controller.sock.recvFrom(data, 4096, address, port)
  if n <= 0:
    raise newException(IOError, "No response received")

  result = parseJson(data)

proc toggleOn*(d: DeviceControl) =
  let status = d.status
  let onOff = status["msg"]["data"]["onOff"].getInt
  if onOff == 1:
    d.turn(on=false)
  else:
    d.turn(on=true)

proc setBrightness(d: DeviceControl, b: GBrightness) =
  let payload = %*{
    "msg": {
      "cmd": "brightness",
      "data": {"value": b}
    }
  }
  d.send(payload)

proc setTemp*(d: DeviceControl, temp: GTemp) =
  let payload = %*{
    "msg":{
      "cmd":"colorwc",
        "data":{
          "color":{
            "r":0,
            "g":12,
            "b":8
          },
          "colorTemInKelvin":temp
      }
    }
  }
  d.send(payload)

proc setColor*(d: DeviceControl, clr: GColor) =
  let payload = %*{
      "msg":{
          "cmd":"colorwc",
          "data":{
          "color":{
              "r":clr.r,
              "g":clr.g,
              "b":clr.b
          },
          "colorTemInKelvin":0
          }
      }
  }
  d.send(payload)