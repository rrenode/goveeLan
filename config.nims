# begin Nimble config (version 2)
--noNimblePath
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

when withDir(thisDir(), system.fileExists("local.nims")):
  include "local.nims"

task bdocs, "Builds docs":
  exec "nim doc --project --index:on --outdir:docs --git.url:https://github.com/rrenode/goveeLan --git.commit:main src/goveeLan.nim"
