import macros

proc `&`*[T; al, bl: static[int]](a: array[al, T], b: array[bl, T]): array[al + bl, T] {.compileTime.} =
  for i, e in a: result[i] = e
  for i, e in b: result[i + al] = e


macro strEnum*(name: untyped, vals: static openArray[string]): untyped =
  let enumTy = newNimNode(nnkEnumTy)
  enumTy.add newEmptyNode()

  for v in vals:
    enumTy.add ident(v)

  result = newNimNode(nnkTypeSection)
  result.add newTree(
    nnkTypeDef,
    newTree(nnkPostfix, ident"*", name),
    newEmptyNode(),
    enumTy
  )