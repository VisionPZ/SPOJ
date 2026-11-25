import math
import strutils

const flushBlockBytes = 1 shl 17
const maxBoxCount = 500

type BoxRect = object
  xLow: int
  xHigh: int
  yLow: int
  yHigh: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

proc nextCommand(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  if pos >= data.len:
    return '\0'
  result = data[pos]
  pos += 1
  return result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc rectangleDistance(firstBox: BoxRect, secondBox: BoxRect): float =
  var gapX = 0
  var gapY = 0
  if firstBox.xLow > secondBox.xHigh:
    gapX = firstBox.xLow - secondBox.xHigh
  elif secondBox.xLow > firstBox.xHigh:
    gapX = secondBox.xLow - firstBox.xHigh
  if firstBox.yLow > secondBox.yHigh:
    gapY = firstBox.yLow - secondBox.yHigh
  elif secondBox.yLow > firstBox.yHigh:
    gapY = secondBox.yLow - firstBox.yHigh
  return sqrt(float(gapX * gapX + gapY * gapY))

var boxes: array[maxBoxCount, BoxRect]
var distances = newSeq[float](maxBoxCount * maxBoxCount)

proc addBox(boxIndex: int, newBox: BoxRect) =
  boxes[boxIndex] = newBox
  for previousBox in 0 .. boxIndex - 1:
    let gap = rectangleDistance(boxes[previousBox], newBox)
    distances[boxIndex * maxBoxCount + previousBox] = gap
    distances[previousBox * maxBoxCount + boxIndex] = gap
  for middleBox in 0 .. boxIndex - 1:
    for targetBox in 0 .. boxIndex - 1:
      let throughOld = distances[boxIndex * maxBoxCount + middleBox] +
                       distances[middleBox * maxBoxCount + targetBox]
      if throughOld < distances[boxIndex * maxBoxCount + targetBox]:
        distances[boxIndex * maxBoxCount + targetBox] = throughOld
        distances[targetBox * maxBoxCount + boxIndex] = throughOld
  for leftBox in 0 .. boxIndex - 1:
    for rightBox in 0 .. boxIndex - 1:
      let throughNew = distances[leftBox * maxBoxCount + boxIndex] +
                       distances[boxIndex * maxBoxCount + rightBox]
      if throughNew < distances[leftBox * maxBoxCount + rightBox]:
        distances[leftBox * maxBoxCount + rightBox] = throughNew

var boxCount = 0
while true:
  let command = nextCommand(inputData, scanPos)
  if command == '\0':
    break
  if command == 'B':
    let firstX = nextInt(inputData, scanPos)
    let firstY = nextInt(inputData, scanPos)
    let secondX = nextInt(inputData, scanPos)
    let secondY = nextInt(inputData, scanPos)
    var newBox: BoxRect
    if firstX <= secondX:
      newBox.xLow = firstX
      newBox.xHigh = secondX
    else:
      newBox.xLow = secondX
      newBox.xHigh = firstX
    if firstY <= secondY:
      newBox.yLow = firstY
      newBox.yHigh = secondY
    else:
      newBox.yLow = secondY
      newBox.yHigh = firstY
    addBox(boxCount, newBox)
    boxCount += 1
  else:
    let fromBox = nextInt(inputData, scanPos) - 1
    let toBox = nextInt(inputData, scanPos) - 1
    let flightDistance = distances[fromBox * maxBoxCount + toBox]
    appendOutput(formatFloat(flightDistance, ffDecimal, 2) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
