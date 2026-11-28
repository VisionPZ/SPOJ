const flushBlockBytes = 1 shl 17
const blockWidth = 512

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var sequenceLength = 0
var blockCount = 0
var baseValues = newSeq[int64](0)
var blockOffsets = newSeq[int](0)
var blockLazy = newSeq[int64](0)
var blockTotals = newSeq[int64](0)
var blockBestPrefix = newSeq[int64](0)
var blockPrefixes = newSeq[int64](0)
var blockReady = newSeq[bool](0)

proc ensureBlock(blockIndex: int) =
  if blockReady[blockIndex]:
    return
  let startIndex = blockOffsets[blockIndex]
  let stopIndex = blockOffsets[blockIndex + 1]
  var runningTotal: int64 = 0
  var bestTotal: int64 = -(1 shl 60)
  for position in startIndex ..< stopIndex:
    runningTotal = runningTotal + baseValues[position] + blockLazy[blockIndex]
    blockPrefixes[position] = runningTotal
    if runningTotal > bestTotal:
      bestTotal = runningTotal
  blockTotals[blockIndex] = runningTotal
  blockBestPrefix[blockIndex] = bestTotal
  blockReady[blockIndex] = true

proc updateRange(leftIndex, rightIndex: int; increment: int64) =
  let firstBlock = leftIndex div blockWidth
  let lastBlock = rightIndex div blockWidth
  for blockIndex in firstBlock .. lastBlock:
    let startIndex = blockOffsets[blockIndex]
    let stopIndex = blockOffsets[blockIndex + 1]
    var segmentLeft = leftIndex
    if segmentLeft < startIndex:
      segmentLeft = startIndex
    var segmentRight = rightIndex
    if segmentRight >= stopIndex:
      segmentRight = stopIndex - 1
    if segmentLeft == startIndex and segmentRight == stopIndex - 1:
      blockLazy[blockIndex] = blockLazy[blockIndex] + increment
      blockTotals[blockIndex] = blockTotals[blockIndex] + increment * int64(stopIndex - startIndex)
      blockReady[blockIndex] = false
    else:
      for position in segmentLeft .. segmentRight:
        baseValues[position] = baseValues[position] + increment
      blockTotals[blockIndex] = blockTotals[blockIndex] + increment * int64(segmentRight - segmentLeft + 1)
      blockReady[blockIndex] = false

proc queryRange(leftIndex, rightIndex: int): int64 =
  let firstBlock = leftIndex div blockWidth
  let lastBlock = rightIndex div blockWidth
  var passedTotal: int64 = 0
  for blockIndex in 0 ..< firstBlock:
    passedTotal = passedTotal + blockTotals[blockIndex]

  var bestTotal: int64 = -(1 shl 60)
  for blockIndex in firstBlock .. lastBlock:
    ensureBlock(blockIndex)
    let startIndex = blockOffsets[blockIndex]
    let stopIndex = blockOffsets[blockIndex + 1]
    var segmentLeft = leftIndex
    if segmentLeft < startIndex:
      segmentLeft = startIndex
    var segmentRight = rightIndex
    if segmentRight >= stopIndex:
      segmentRight = stopIndex - 1
    if segmentLeft == startIndex and segmentRight == stopIndex - 1:
      let candidate = passedTotal + blockBestPrefix[blockIndex]
      if candidate > bestTotal:
        bestTotal = candidate
      passedTotal = passedTotal + blockTotals[blockIndex]
    else:
      for position in segmentLeft .. segmentRight:
        let candidate = passedTotal + blockPrefixes[position]
        if candidate > bestTotal:
          bestTotal = candidate
      passedTotal = passedTotal + blockTotals[blockIndex]
  return bestTotal

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

sequenceLength = nextInt(inputData, scanPos)
baseValues = newSeq[int64](sequenceLength)
for position in 0 .. sequenceLength - 1:
  baseValues[position] = int64(nextInt(inputData, scanPos))
blockCount = (sequenceLength + blockWidth - 1) div blockWidth
blockOffsets = newSeq[int](blockCount + 1)
blockLazy = newSeq[int64](blockCount)
blockTotals = newSeq[int64](blockCount)
blockBestPrefix = newSeq[int64](blockCount)
blockPrefixes = newSeq[int64](sequenceLength)
blockReady = newSeq[bool](blockCount)
for blockIndex in 0 .. blockCount - 1:
  blockOffsets[blockIndex] = blockIndex * blockWidth
blockOffsets[blockCount] = sequenceLength
for blockIndex in 0 .. blockCount - 1:
  ensureBlock(blockIndex)

let operationCount = nextInt(inputData, scanPos)
for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  if operationType == 0:
    let updateLeft = nextInt(inputData, scanPos) - 1
    let updateRight = nextInt(inputData, scanPos) - 1
    let increment = int64(nextInt(inputData, scanPos))
    updateRange(updateLeft, updateRight, increment)
  else:
    let queryLeft = nextInt(inputData, scanPos) - 1
    let queryRight = nextInt(inputData, scanPos) - 1
    appendOutput($queryRange(queryLeft, queryRight))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
