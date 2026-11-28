const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxElementValue = 1000000

proc readInputBytes(): string =
  const chunkSize = 1 shl 15
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

var outBuffer = newStringOfCap(flushBlockBytes + 64)

proc appendIntLine(val: int) =
  outBuffer.add $val
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc bitAdd(bitTree: var seq[int], treeSize: int, idxStart: int, delta: int) {.inline.} =
  var idx = idxStart
  while idx <= treeSize:
    bitTree[idx] += delta
    idx += idx and (-idx)

proc bitSum(bitTree: seq[int], idxStart: int): int {.inline.} =
  var idx = idxStart
  var acc = 0
  while idx > 0:
    acc += bitTree[idx]
    idx -= idx and (-idx)
  acc

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let arrayLen = nextInt(inputData, scanPos)
  var values = newSeq[int](arrayLen + 1)
  for idx in 1 .. arrayLen:
    values[idx] = nextInt(inputData, scanPos)

  let queryCount = nextInt(inputData, scanPos)
  var bucketHead = newSeq[int](arrayLen + 1)
  for idx in 0 .. arrayLen:
    bucketHead[idx] = -1
  var queryLeft = newSeq[int](queryCount)
  var queryNext = newSeq[int](queryCount)
  var queryAnswers = newSeq[int](queryCount)

  for qIdx in 0 ..< queryCount:
    let leftPos = nextInt(inputData, scanPos)
    let rightPos = nextInt(inputData, scanPos)
    queryLeft[qIdx] = leftPos
    queryNext[qIdx] = bucketHead[rightPos]
    bucketHead[rightPos] = qIdx

  var lastSeenPos = newSeq[int](maxElementValue + 1)
  var bitTree = newSeq[int](arrayLen + 1)

  for rightPos in 1 .. arrayLen:
    let elem = values[rightPos]
    let prevPos = lastSeenPos[elem]
    if prevPos > 0:
      bitAdd(bitTree, arrayLen, prevPos, -1)
    lastSeenPos[elem] = rightPos
    bitAdd(bitTree, arrayLen, rightPos, 1)

    let rightTotal = bitSum(bitTree, rightPos)
    var qIdx = bucketHead[rightPos]
    while qIdx != -1:
      queryAnswers[qIdx] = rightTotal - bitSum(bitTree, queryLeft[qIdx] - 1)
      qIdx = queryNext[qIdx]

  for qIdx in 0 ..< queryCount:
    appendIntLine(queryAnswers[qIdx])
  if outBuffer.len > 0:
    stdout.write outBuffer

main()
