## TODO:
## [-] Rework lib
## [-] Tools for getting local ip
## [-] Wrap for Python

import std/[os, strutils, json, random, times]
import goveeControl/[models, socker, deviceControl]

const LOCAL_IP: string = "192.168.1.100"
const MCAST_IP: string = "239.255.255.250"
const MCAST_PORT: int = 4001
const LISTEN_PORT: int = 4002


when isMainModule:

  const DEVICE_PATH: string = "local/devices.json"

  var ctrl: Controller = initController(
    localIp=LOCAL_IP, mcastIp=MCAST_IP, 
    mcastPort=MCAST_PORT, listenPort=LISTEN_PORT
  )

  var devices: seq[FoundDevice]

  if fileExists(DEVICE_PATH):
    devices = loadDevices(DEVICE_PATH)
  else:
    devices = ctrl.discover
    saveDevices(devices, DEVICE_PATH)

  echo "A total of " & $devices.len & " devices were found"
  #echo devices

  let light1 = DeviceControl(device:devices[0],controller:ctrl)
  let light2 = DeviceControl(device:devices[1],controller:ctrl)
  let light3 = DeviceControl(device:devices[2],controller:ctrl)

  light1.turn(true)
  light2.turn(true)

  proc randClr(): GColor =
    randomize()
    let r = rand(0..255)
    let g = rand(0..255)
    let b = rand(0..255)
    return GColor(r:r,g:g,b:b)

  let interval = 5.seconds
  let deadline = now() + interval

  while now() < deadline:
    light1.setColor(randClr())
    sleep(rand(200..800))
    light2.setColor(randClr())
    sleep(rand(200..800))