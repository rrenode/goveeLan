import std/[os, strutils, json]
import socker, deviceControl

const LOCAL_IP: string = "192.168.1.100"
const MCAST_IP: string = "239.255.255.250"
const MCAST_PORT: int = 4001
const LISTEN_PORT: int = 4002

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

light1.turn(true)

light1.setColor(GColor(r:30,g:150,b:255))
