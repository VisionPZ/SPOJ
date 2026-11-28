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

proc bfsFarthest(
    startNode: int,
    nodeCount: int,
    head: seq[int],
    edgeTo: seq[int],
    edgeNext: seq[int],
    dist: var seq[int],
    queue: var seq[int]
): tuple[node: int, distance: int] =
  for idx in 1 .. nodeCount:
    dist[idx] = -1
  var qHead = 0
  var qTail = 0
  dist[startNode] = 0
  queue[qTail] = startNode
  qTail += 1
  var bestNode = startNode
  var bestDist = 0
  while qHead < qTail:
    let cur = queue[qHead]
    qHead += 1
    let curDist = dist[cur]
    if curDist > bestDist:
      bestDist = curDist
      bestNode = cur
    var edgeIdx = head[cur]
    while edgeIdx != -1:
      let nxt = edgeTo[edgeIdx]
      if dist[nxt] == -1:
        dist[nxt] = curDist + 1
        queue[qTail] = nxt
        qTail += 1
      edgeIdx = edgeNext[edgeIdx]
  result = (bestNode, bestDist)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let nodeCount = nextInt(inputData, scanPos)
  if nodeCount <= 1:
    outBuffer.add "0\n"
    stdout.write outBuffer
    return
  let totalHalfEdges = (nodeCount - 1) * 2
  var head = newSeq[int](nodeCount + 1)
  for idx in 1 .. nodeCount:
    head[idx] = -1
  var edgeTo = newSeq[int](totalHalfEdges)
  var edgeNext = newSeq[int](totalHalfEdges)
  var halfIdx = 0
  for edgeIdx in 0 ..< nodeCount - 1:
    let nodeU = nextInt(inputData, scanPos)
    let nodeV = nextInt(inputData, scanPos)
    edgeTo[halfIdx] = nodeV
    edgeNext[halfIdx] = head[nodeU]
    head[nodeU] = halfIdx
    halfIdx += 1
    edgeTo[halfIdx] = nodeU
    edgeNext[halfIdx] = head[nodeV]
    head[nodeV] = halfIdx
    halfIdx += 1

  var dist = newSeq[int](nodeCount + 1)
  var queue = newSeq[int](nodeCount + 1)
  let firstPass = bfsFarthest(1, nodeCount, head, edgeTo, edgeNext, dist, queue)
  let secondPass = bfsFarthest(firstPass.node, nodeCount, head, edgeTo, edgeNext, dist, queue)
  outBuffer.add $secondPass.distance
  outBuffer.add '\n'
  stdout.write outBuffer

main()
