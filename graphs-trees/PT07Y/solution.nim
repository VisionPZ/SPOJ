const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc readInputBytes(): string =
  const chunkSize = 1 shl 14
  var res = ""
  var buf = newString(chunkSize)
  while true:
    let got = readBuffer(stdin, addr buf[0], chunkSize)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr buf[0], got)
  res

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var val = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10 + (int(data[pos]) - firstDigitValue)
    pos += 1
  val

var outBuffer = newStringOfCap(flushBlockBytes + 32)

proc findRoot(parent: var seq[int], node: int): int =
  var cur = node
  while parent[cur] >= 0:
    cur = parent[cur]
  var root = cur
  cur = node
  while cur != root:
    let nxt = parent[cur]
    parent[cur] = root
    cur = nxt
  root

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  if edgeCount != nodeCount - 1:
    outBuffer.add "NO\n"
    stdout.write outBuffer
    return
  var parent = newSeq[int](nodeCount + 1)
  for idx in 1 .. nodeCount:
    parent[idx] = -1
  var components = nodeCount
  for edgeIdx in 0 ..< edgeCount:
    let nodeU = nextInt(inputData, scanPos)
    let nodeV = nextInt(inputData, scanPos)
    let rootU = findRoot(parent, nodeU)
    let rootV = findRoot(parent, nodeV)
    if rootU != rootV:
      if parent[rootU] > parent[rootV]:
        parent[rootV] += parent[rootU]
        parent[rootU] = rootV
      else:
        parent[rootU] += parent[rootV]
        parent[rootV] = rootU
      components -= 1
  if components == 1:
    outBuffer.add "YES\n"
  else:
    outBuffer.add "NO\n"
  stdout.write outBuffer

main()
