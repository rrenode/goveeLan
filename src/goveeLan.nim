## .. importdoc:: goveeLan/highlevel
## 
## # goveeLan - A lib written in Nim for controlling Govee devices with their LAN API.
## 
## .. note:: This is for Govee Devices LAN API. To my knowledge, all devices supported by the cloud 
##      API are supported by the LAN API. You can see [supported devices](goveeLan/gsupport.html). 
## 
## ## Structure of the project
## 
## There are essentially three levels of abstraction that are boringly, though aptly named:
##    - [goveeLan/highlevel](goveeLan/highlevel.html)
##    - [goveeLan/midlevel](goveeLan/midlevel.html)
##    - [goveeLan/lowlevel](goveeLan/lowlevel.html)
## 
## With highlevel depending on midlevel and midlevel on lowlevel. I wanted a higher level API for interacting 
## with Govee devices, but as I worked on the lib I realized I wanted some more abstractions layers to 
## facilitate the end goal of the high level design.
## 
## You are free, of course, to use the other levels but the highlevel module is where my focus will be for 
## writing docs for the time being. Despite that, feel free to open a discussion on GitHub if you have any questions. 
## 
## Speaking of which...
## 
## ## Contributing
## #TODO: add GitHub link
## Please see
## 
## ## Inspiration
## 
## My pops went a bit crazy and replaced every single light in the house with Govee. I'm not a big fan 
## of smart home stuff; a weird deep distrust of them. Anyway, Govee's app absolutely sucks (to me at least): 
## the UI is clunky; features I want are missing; the features they do have use weird conceptual semantics 
## to connect together. Point is, I realized that it lacks the control I am after. And luckily for me, Govee 
## has an API for interacting with their devices; huzzah!
## 
## # Ussage Stuffs
## 
## .. important:: You must use the Govee app and enable **LAN CONTROL** for your device(s).
##      
##    Without this, the devices are not discoverable through MCAST and are not controllable per the API.
##    Instructions can be found on [Govee's docs](https://app-h5.govee.com/user-manual/wlan-guide).
## 
## ## Highlevel Ussage
## 
##
##```nim 
## import goveeLan # <-- Import(s)
## 
## # Create client
## let myClient = newGClient()
## 
## # Discover and attach devices
## discard c.discoverAttachDevices()
## 
## # Get a client's attached devices
## let devices = myClient.listDevices()
## 
## # Get one device (assuming some are on the network)
## let device1 = devices[0]
## 
## # Change its color (I like red)
## device1.setColor(GColor(r:255,g:0,b:0))
##```
## See [GClient] for more with the client.
## 
## See [GDevice] for more with devices.
## 

when isMainModule:
  # Really just used for development...
  import goveeLan/[highlevel]

  proc cTest() =
    let c = newGClient()
    let ds = c.discoverAttachDevices()

  cTest()

else:
  import goveeLan/[highlevel, models]

  export highlevel, models