proc `&`*[T; al, bl: static[int]](a: array[al, T], b: array[bl, T]): array[al + bl, T] =
  for i, e in a: result[i] = e
  for i, e in b: result[i + al] = e