import std/[net, nativesockets, json, times, os]

when defined(windows):
  import ../core/net/winnet

type
  GMulticastSocket* = ref object
    ## An IPv4 UDP multicast socket wrapper for communicating with Govee devices.
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

  GUnicastSocket* = ref object
    ## An IPv4 UDP "unicast" socket wrapper for communicating with Govee devices.
    ## 
    ## Domain: AF_INET (IPv4)
    ## SockType: SOCK_DGRAM (datagram-oriented communication)
    ## Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
    ## 
    ## Doesn't bind; using the OS assigned ephemeral ports
    ## 
    socket: Socket
    listenPort: Port
  
proc newGMulticastSocket*(groupAddress: string, listenPort: Port, localAddress: string = ""): GMulticastSocket =
  new(result)
  try:
    result.socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  except OSError as e:
    raise newException(OsError, "GMulticastSocket failed to create a new native socket.", e)
  
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