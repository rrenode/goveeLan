import socket
import json
import time
from dataclasses import dataclass

LOCAL_IP = "192.168.1.100"
MCAST_IP = "239.255.255.250"
MCAST_PORT = 4001
LISTEN_PORT = 4002

scan_packet = {
    "msg": {
        "cmd": "scan",
        "data": {
            "account_topic": "reserve"
        }
    }
}

def bound(val, upperBound: int | float, lowerBound: int | float):
    return max(lowerBound, min(val, upperBound))

@dataclass
class FoundDevice:
    """Simple dataclass for found devices."""
    macAddr: str
    ipAddr: str
    sku: str
    # TODO: bleVersion and wifiVerison

class DeviceControl:
    """Wrapper for controlling devices"""
    def __init__(self, device: FoundDevice, controller):
        self.device = device
        self.controller = controller

    def turn(self, on: bool):
        payload = {
            "msg": {
                "cmd": "turn",
                "data": {"value": 1 if on else 0}
            }
        }
        self.controller.send(self.device.ipAddr, payload)

    def brightness(self, percent: int):
        """Set brightness.
        
        ARGS:
            percent (int) - Bound from 0 to 100. 
        """
        value = bound(percent, 0, 100)
        payload = {
            "msg": {
                "cmd": "brightness",
                "data": {"value": value}
            }
        }
        self.controller.send(self.device.ipAddr, payload)
    
    def status(self):
        """Queries the status of the device.
        """
        payload = {
            "msg": {
                "cmd": "devStatus",
                "data": {
                    
                }
            }
        }
        self.controller.send(self.device.ipAddr, payload)
    
    def setTemp(self, temp: int):
        """
        """
        temp = bound(temp, 2000, 9000)
        payload = {
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
        self.controller.send(self.device.ipAddr, payload)
    
    def setColor(self, r, g, b):
        """
        """
        payload = {
            "msg":{
                "cmd":"colorwc",
                "data":{
                "color":{
                    "r":r,
                    "g":g,
                    "b":b
                },
                "colorTemInKelvin":0
                }
            }
        }
        self.controller.send(self.device.ipAddr, payload)

class Controller:
    """Wrapper that handles socket connect, requests/responses.
    Uses DeviceControl instances to know payload and commands.
    """
    MCAST_IP = "239.255.255.250"
    MCAST_PORT = 4001
    LISTEN_PORT = 4002
    DEVICE_PORT = 4003

    def __init__(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(("", self.LISTEN_PORT))
        self.sock.settimeout(3)

    def discover(self, skuModel: str = None, timeout: int = 5) -> list[FoundDevice]:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind((LOCAL_IP, LISTEN_PORT))
        sock.settimeout(5)

        sock.setsockopt(
            socket.IPPROTO_IP,
            socket.IP_MULTICAST_IF,
            socket.inet_aton(LOCAL_IP)
        )

        print(f"Listening on {LOCAL_IP}:{LISTEN_PORT}")
        print("Sending scan...")

        sock.sendto(json.dumps(scan_packet).encode("utf-8"), (MCAST_IP, MCAST_PORT))

        foundDevices: list[FoundDevice] = []
        
        start = time.time()
        while time.time() - start < timeout:
            try:
                data, addr = sock.recvfrom(4096)
                #print(f"From {addr[0]}:{addr[1]} -> {data.decode('utf-8', errors='ignore')}")
                jdata: dict = json.loads(data.decode('utf-8', errors='ignore'))
                sku = jdata["msg"]["data"]["sku"]
                ip = jdata["msg"]["data"]["ip"]
                mac = jdata["msg"]["data"]["device"]
                if skuModel:
                    if sku != skuModel:
                        continue
                foundDevices.append(
                    FoundDevice(
                        macAddr=mac,
                        ipAddr=ip,
                        sku=sku
                    )
                )
            except socket.timeout:
                break
        return foundDevices

    def send(self, ip, payload):
        self.sock.sendto(json.dumps(payload).encode(), (ip, self.DEVICE_PORT))
        
ctrl = Controller()
devices = ctrl.discover(skuModel="H6004")
print(f"Found {len(devices)} devices...")

light1 = DeviceControl(devices[0], ctrl)

light1.turn(True)
#light1.brightness(50)
x = 0
light1.setColor(186, 235, 52)
from sys import exit
exit()
while x < 15:
    light1.setColor(0, 255, 0)
    time.sleep(0.75)
    light1.setColor(0, 0, 255)
    time.sleep(0.75)
    light1.setColor(255, 0, 0)
    time.sleep(0.75)
    x+=1