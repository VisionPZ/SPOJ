import math

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
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var wallCount = 0
var lowerX: seq[int] = @[]
var upperX: seq[int] = @[]
var lowerY: seq[int] = @[]
var upperY: seq[int] = @[]

proc squaredGap(firstIndex: int, secondIndex: int): int64 =
  var gapX = 0'i64
  var gapY = 0'i64
  if lowerX[firstIndex] > upperX[secondIndex]:
    gapX = int64(lowerX[firstIndex] - upperX[secondIndex])
  elif lowerX[secondIndex] > upperX[firstIndex]:
    gapX = int64(lowerX[secondIndex] - upperX[firstIndex])
  if lowerY[firstIndex] > upperY[secondIndex]:
    gapY = int64(lowerY[firstIndex] - upperY[secondIndex])
  elif lowerY[secondIndex] > upperY[firstIndex]:
    gapY = int64(lowerY[secondIndex] - upperY[firstIndex])
  return gapX * gapX + gapY * gapY

proc minimumBoardSquared(): int64 =
  var bestDistance = newSeq[int64](wallCount)
  var settled = newSeq[bool](wallCount)
  for wallIndex in 0 .. wallCount - 1:
    bestDistance[wallIndex] = high(int64) div 4
  bestDistance[0] = 0'i64
  for stepIndex in 0 .. wallCount - 1:
    var chosen = -1
    for wallIndex in 0 .. wallCount - 1:
      if not settled[wallIndex] and (chosen == -1 or
          bestDistance[wallIndex] < bestDistance[chosen]):
        chosen = wallIndex
    if chosen == -1:
      break
    settled[chosen] = true
    for otherIndex in 0 .. wallCount - 1:
      if not settled[otherIndex]:
        let candidate = max(bestDistance[chosen], squaredGap(chosen, otherIndex))
        if candidate < bestDistance[otherIndex]:
          bestDistance[otherIndex] = candidate
  return bestDistance[1]

proc appendDistance(squared: int64) =
  let scaled = int64(round(sqrt(float(squared)) * 100.0))
  var text = $int(scaled div 100) & "."
  let fraction = scaled mod 100
  if fraction < 10:
    text.add '0'
  text.add $int(fraction)
  appendOutput(text)
  outputBuffer.add '\n'

while scanPos < inputData.len:
  wallCount = nextInt(inputData, scanPos)
  if wallCount == 0:
    break
  lowerX = newSeq[int](wallCount)
  upperX = newSeq[int](wallCount)
  lowerY = newSeq[int](wallCount)
  upperY = newSeq[int](wallCount)
  for wallIndex in 0 .. wallCount - 1:
    let originX = nextInt(inputData, scanPos)
    let originY = nextInt(inputData, scanPos)
    let span = nextInt(inputData, scanPos)
    lowerX[wallIndex] = originX
    upperX[wallIndex] = originX
    lowerY[wallIndex] = originY
    upperY[wallIndex] = originY
    if span > 0:
      upperX[wallIndex] = originX + span
    elif span < 0:
      upperY[wallIndex] = originY - span
  appendDistance(minimumBoardSquared())
stdout.write outputBuffer
outputBuffer.setLen 0
