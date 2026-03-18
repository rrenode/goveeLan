## # Design Notes
## 
##      Communication with the MCAST group versus the devices is technically 
##          seperate concerns; though related. The Govee device discovery is 
##          send-reply. All of the device commands, excluding the status 
##          command, do not send back return data.
## 
##      Interestingly, despite the docs written by people before me, it appears
##        that responses from devices is unicast. And since multicast does not 
##        require membership to a group to send, GMulticast Socket is sort of 
##        pointless. I leave it on the off chance that Govee changes 
##        communication with devices and adds something where the devices actually
##        broadcast to the multicast group.
## 
##      GMulticast Socket
##        \|- Domain: AF_INET (IPv4)
##        \|- SockType: SOCK_DGRAM (datagram-oriented communication)
##        \|- Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
##        \|- Is address/port bound
##        \|- Joins MCast Group (IP_ADD_MEMBERSHIP)
##        \|- Can send and recieve
##      
##      GUnicast Socket
##        \|- Domain: AF_INET (IPv4)
##        \|- SockType: SOCK_DGRAM (datagram-oriented communication)
##        \|- Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
##        \|- Is address/port bound
##        \|- Doesn't care to join the MCast group
##        \|- Can send and recieve
## 

import std/[net, nativesockets, json, times, os]

when defined(windows):
  import ../core/net/winnet

type
  GMulticastClient* = ref object
    ## An IPv4 UDP multicast socket wrapper for communicating with Govee devices 
    ##    and the Govee multicast group.
    ## 
    ## Domain: AF_INET (IPv4)
    ## SockType: SOCK_DGRAM (datagram-oriented communication)
    ## Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
    ## 
    ## Binds to port (and address if specified)
    ## 
    ## Joins specified MCast Group
    ## 
    socket: Socket
    listenPort: Port
    groupIp: IpAddress

  GUnicastClient* = ref object
    ## An IPv4 UDP "unicast" socket wrapper for communicating with Govee devices.
    ## 
    ## Domain: AF_INET (IPv4)
    ## SockType: SOCK_DGRAM (datagram-oriented communication)
    ## Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
    ## 
    ## Binds to listen port, can be changed...
    ## 
    socket: Socket
    listenPort: Port
  
proc newGMulticastClient*(groupAddress: string, listenPort: Port, localAddress: string = ""): GMulticastClient =
  new(result)
  try:
    result.socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  except OSError as e:
    raise newException(OsError, "GMulticastClient failed to create a new native socket.", e)
  
  result.socket.bindAddr(Port(listenPort), localAddress)
  
  when defined(windows):
    var mreq: IpMreq
    mreq.imr_multiaddr.s_addr = inet_addr(groupAddress.cstring)
    mreq.imr_interface.s_addr = inet_addr(localAddress.cstring)

    let rc: cint = winnet.setSockOpt(
      s=result.socket.getFd(), 
      level=IPPROTO_IP.int,
      optname=IP_ADD_MEMBERSHIP, 
      optval=cast[pointer](addr mreq)
    )
  else:
    raise newException(NotImplementedError, "Not implemented")

proc newGUnicastClient(listenPort: Port, localAddress: string = ""): GUnicastClient =
  ## GUnicastClient Constructor.
  ## 
  ## Domain: AF_INET (IPv4)
  ## SockType: SOCK_DGRAM (datagram-oriented communication)
  ## Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
  ## 
  new(result)
  try:
    result.socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  except OSError as e:
    raise newException(OsError, "GUnicastClient failed to create a new native socket.", e)
  result.socket.bindAddr(listenPort, localAddress)