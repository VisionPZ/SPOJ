import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fillBuckets(matrixValues: seq[int64], rowOffset: int, groupSize: int,
                 columnCount: int, rowIndex: int, usedMask: int,
                 runningSum: int64, buckets: var seq[seq[int64]]) =
  if rowIndex == groupSize:
    buckets[usedMask].add runningSum
    return
  let matrixRow = rowOffset + rowIndex
  var columnIndex = 0
  while columnIndex < columnCount:
    if (usedMask and (1 shl columnIndex)) == 0:
      let cellValue = matrixValues[matrixRow * columnCount + columnIndex]
      let nextMask = usedMask or (1 shl columnIndex)
      fillBuckets(matrixValues, rowOffset, groupSize, columnCount, rowIndex + 1,
                  nextMask, runningSum + cellValue, buckets)
      fillBuckets(matrixValues, rowOffset, groupSize, columnCount, rowIndex + 1,
                  nextMask, runningSum - cellValue, buckets)
    columnIndex += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matrixSize = nextInt(inputData, scanPos)
  var matrixValues = newSeq[int64](matrixSize * matrixSize)
  for cellIndex in 0 .. matrixSize * matrixSize - 1:
    matrixValues[cellIndex] = int64(nextInt(inputData, scanPos))

  let firstRows = matrixSize div 2
  let secondRows = matrixSize - firstRows
  let maskCount = 1 shl matrixSize
  var firstBuckets = newSeq[seq[int64]](maskCount)
  var secondBuckets = newSeq[seq[int64]](maskCount)
  fillBuckets(matrixValues, 0, firstRows, matrixSize, 0, 0, 0, firstBuckets)
  fillBuckets(matrixValues, firstRows, secondRows, matrixSize, 0, 0, 0, secondBuckets)
  for bucketIndex in 0 .. maskCount - 1:
    firstBuckets[bucketIndex].sort(proc(leftValue, rightValue: int64): int =
      if leftValue < rightValue: return -1
      if leftValue > rightValue: return 1
      return 0)
    secondBuckets[bucketIndex].sort(proc(leftValue, rightValue: int64): int =
      if leftValue < rightValue: return -1
      if leftValue > rightValue: return 1
      return 0)

  let fullMask = maskCount - 1
  var bestAbs: int64 = 1 shl 60
  for columnMask in 0 .. fullMask:
    let firstSums = firstBuckets[columnMask]
    let secondSums = secondBuckets[fullMask xor columnMask]
    if firstSums.len == 0 or secondSums.len == 0:
      continue
    var leftCursor = 0
    var rightCursor = secondSums.len - 1
    while leftCursor < firstSums.len and rightCursor >= 0:
      let combined = firstSums[leftCursor] + secondSums[rightCursor]
      let magnitude = if combined >= 0: combined else: -combined
      if magnitude < bestAbs:
        bestAbs = magnitude
      if combined > 0:
        rightCursor -= 1
      elif combined < 0:
        leftCursor += 1
      else:
        break
    if bestAbs == 0:
      break

  appendOutput($bestAbs)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
