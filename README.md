# goveeLan - A Nim lang lib for Govee light devices utilizing their LAN api.

Controls Govee light devices using their LAN API (not their cloud API). You can view their docs and ensure your device is supported here: https://app-h5.govee.com/user-manual/wlan-guide



## How to Use

There is three main modules: highlevel, midlevel, and lowlevel. The highlevel module is what is exposed when you `import goveeLan`. The other two are supporting code for the highlevel module but are of course importable such that you can work your own backend. The docs here are mostly focused on the highlevel but you can find more information in midlevel and lowlevel docs pages.

### Controlling with a client
```nim
import goveeLan
import json

# Create our client
let c = newGClient()

# Auto discover and attach devices that are on network
let devices = c.discoverAttachDevices()

# 
# Or you can discoverDevices and attach them yourself
# let foundDevices = c.disocverDevices()
#
# for d in foundDevices:
#   if d.macAddress in ["04:1A:5C:E7:53:9A:2D:68", "3A:2B:5C:E7:53:9A:E1:48"]:
#     c.attach(d)
# 
# let devices = c.devices
#

if devices.len < 1:
  quit()

# Look! A single light!
let light1 = devices[0]
echo light1
light1.setColor(
  GColor(
    r:155,
    g:102,
    b:102
    )
)

# Let's cache the devices!
#   Requires importing json
let jDevicesNode = devicesToJson(devices)
writeFile("devices.json", $jDevicesNode)

# There is more. See docs!
```

### Creating a GDevice
```nim
import goveeLan
import goveeLan/[midlevel]

let netLight1 = GNetDevice(
  macAddr: "3A:2B:5C:E7:53:9A:E1:48",
  ipAddr: "192.168.1.133",
  sku: "H6004"
)
let light1 = newGDevice(netLight1)

# We can't yet control the light because it needs to be connected to a GClient... 
# ...let's do that
let c = newGClient()
c.attchDevice(light1)

# We can detach it as well.
# Let's also pretend that we have other devices already attached
for d in c.devices:
  if d.macAddress == "3A:2B:5C:E7:53:9A:E1:48":
    c.detach(d)
    break

```

### Controlling lights

Commands are not yet queued or rated so it's possible to send commands as quickly as your computer/network can handle and thus is only limited by the light's own time ability to do the work. Wonderful yes but this also means that multiple commands in a row may need some `os.sleep` between them to see their effects.

```nim
# Assuming you already have a client

let light1 = c.devices[0]

light1.turnOn()

# GBrightness is just an int with values from 0 and 100
light1.setBrightness(
    GBrightness(
        90
    )
)

# GColor is 3 ints (r, g, b) with values from 0 to 255.
light1.setColor(
    GColor(
        r: 235,
        g: 102,
        b: 102
    )
)

# You can also set the light's temp but that overwrite the color
# Its value is from 2000 to 9000 (kelvin)
# light1.setTemperature()
light1.turnOff()

```