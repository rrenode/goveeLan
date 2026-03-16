## TODO:
## [-] Rework lib
## [-] Tools for getting local ip
## [-] Wrap for Python

import std/[os, strutils, json, random, times, nativesockets]
import goveeControl/[models, socker, deviceControl]

const LOCAL_IP: string = "192.168.1.100"
const MCAST_IP: string = "239.255.255.250"
const MCAST_PORT: int = 4001
const LISTEN_PORT: int = 4002

let hostname = getHostname()
let ip = getHostByName(hostname).addrList[0]
echo $ip

when isMainModule:

  const DEVICES_SAVE_PATH: string = "local/devices.json"

  # Initialize our controller
  var ctrl: Controller = initController(
    localIp=LOCAL_IP, mcastIp=MCAST_IP, 
    mcastPort=MCAST_PORT, listenPort=LISTEN_PORT
  )

  var devices: seq[FoundDevice]

  # Can load devices from file to bypass scanning
  if fileExists(DEVICES_SAVE_PATH):
    devices = loadDevices(DEVICES_SAVE_PATH)
  else:
    devices = ctrl.discover
    saveDevices(devices, DEVICES_SAVE_PATH)

  echo "A total of " & $devices.len & " devices were found"

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
    GColor(r:r,g:g,b:b)

  let interval = 5.seconds
  let deadline = now() + interval

  while now() < deadline:
    light1.setColor(randClr())
    sleep(rand(200..800))
    light2.setColor(randClr())
    sleep(rand(200..800))