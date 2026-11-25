const flushBlockBytes = 1 shl 17
const answerModulus = 100000007

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

proc absoluteValue(value: int64): int64 =
  if value < 0:
    return -value
  return value

proc greatestCommonDivisor(first: int64, second: int64): int64 =
  var larger = absoluteValue(first)
  var smaller = absoluteValue(second)
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc squaredDistance(firstX: int64, firstY: int64, secondX: int64, secondY: int64): int64 =
  let deltaX = secondX - firstX
  let deltaY = secondY - firstY
  return deltaX * deltaX + deltaY * deltaY

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  var cornerX = newSeq[int64](4)
  var cornerY = newSeq[int64](4)
  for cornerIndex in 0 .. 3:
    cornerX[cornerIndex] = int64(nextInt(inputData, scanPos))
    cornerY[cornerIndex] = int64(nextInt(inputData, scanPos))
  var sideSquared = high(int64)
  for firstCorner in 0 .. 3:
    for secondCorner in firstCorner + 1 .. 3:
      let distanceSquared = squaredDistance(cornerX[firstCorner], cornerY[firstCorner], cornerX[secondCorner], cornerY[secondCorner])
      if distanceSquared < sideSquared:
        sideSquared = distanceSquared
  var sideX = 0.int64
  var sideY = 0.int64
  var otherSideX = 0.int64
  var otherSideY = 0.int64
  var neighboursFound = 0
  for neighbourCorner in 1 .. 3:
    if squaredDistance(cornerX[0], cornerY[0], cornerX[neighbourCorner], cornerY[neighbourCorner]) == sideSquared:
      if neighboursFound == 0:
        sideX = cornerX[neighbourCorner] - cornerX[0]
        sideY = cornerY[neighbourCorner] - cornerY[0]
      else:
        otherSideX = cornerX[neighbourCorner] - cornerX[0]
        otherSideY = cornerY[neighbourCorner] - cornerY[0]
      neighboursFound += 1
  let sideSteps = greatestCommonDivisor(sideX, sideY)
  let otherSideSteps = greatestCommonDivisor(otherSideX, otherSideY)
  let interiorPoints = sideSquared - sideSteps - otherSideSteps + 1
  let answerValue = (interiorPoints mod answerModulus) * ((2 * (sideSquared mod answerModulus)) mod answerModulus) mod answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
