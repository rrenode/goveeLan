# begin Nimble config (version 2)
--noNimblePath
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

task bdocs, "Builds docs":
  exec "nim doc --project --index:on --outdir:docs src/goveeLan.nim"