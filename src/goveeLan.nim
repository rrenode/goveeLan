import goveeLan/[highlevel, models, midlevel]
import std/[sequtils, strutils]

proc mLvlTest() =
  let c = newGController()

proc cTest() =
  let c = newGClient()
  let ds = c.discoverAttachDevices()
cTest()