const flushBlockBytes = 1 shl 17
const coordinateOffset: int64 = 2147483648
const hashMultiplier: uint64 = 1099511628211'u64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc gcdAbs(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  if leftValue < 0:
    leftValue = -leftValue
  if rightValue < 0:
    rightValue = -rightValue
  while rightValue != 0:
    var remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

var pointX = newSeq[int64](0)
var pointY = newSeq[int64](0)
var pointQuality = newSeq[int64](0)
var hashStamp = newSeq[int](0)
var hashKey = newSeq[uint64](0)
var hashSum = newSeq[int64](0)
var touchedSlots = newSeq[int](0)
var tableMask = 0
var currentStamp = 0

proc packSlope(deltaX: int64, deltaY: int64): uint64 =
  return (uint64(deltaX + coordinateOffset) shl 32) or uint64(deltaY + coordinateOffset)

proc addSlope(packedKey: uint64, quality: int64) =
  var slot = int((packedKey * hashMultiplier) and uint64(tableMask))
  while hashStamp[slot] == currentStamp and hashKey[slot] != packedKey:
    slot = (slot + 1) and tableMask
  if hashStamp[slot] != currentStamp:
    hashStamp[slot] = currentStamp
    hashKey[slot] = packedKey
    hashSum[slot] = quality
    touchedSlots.add slot
  else:
    hashSum[slot] = hashSum[slot] + quality

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pointCount = nextInt(inputData, scanPos)
  pointX.setLen pointCount
  pointY.setLen pointCount
  pointQuality.setLen pointCount
  for pointIndex in 0 .. pointCount - 1:
    pointX[pointIndex] = int64(nextInt(inputData, scanPos))
    pointY[pointIndex] = int64(nextInt(inputData, scanPos))
    pointQuality[pointIndex] = int64(nextInt(inputData, scanPos))
  var tableSize = 8
  while tableSize < pointCount * 8:
    tableSize = tableSize * 2
  tableMask = tableSize - 1
  hashStamp = newSeq[int](tableSize)
  hashKey = newSeq[uint64](tableSize)
  hashSum = newSeq[int64](tableSize)
  var bestSum: int64 = 0
  for anchorIndex in 0 .. pointCount - 1:
    currentStamp += 1
    touchedSlots.setLen 0
    if pointQuality[anchorIndex] > bestSum:
      bestSum = pointQuality[anchorIndex]
    for otherIndex in 0 .. pointCount - 1:
      if otherIndex != anchorIndex:
        var deltaX = pointX[otherIndex] - pointX[anchorIndex]
        var deltaY = pointY[otherIndex] - pointY[anchorIndex]
        let divisor = gcdAbs(deltaX, deltaY)
        deltaX = deltaX div divisor
        deltaY = deltaY div divisor
        if deltaX < 0 or (deltaX == 0 and deltaY < 0):
          deltaX = -deltaX
          deltaY = -deltaY
        addSlope(packSlope(deltaX, deltaY), pointQuality[otherIndex])
    for slot in touchedSlots:
      let candidate = pointQuality[anchorIndex] + hashSum[slot]
      if candidate > bestSum:
        bestSum = candidate
  appendOutput($bestSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
