import strutils
import math

const flushBlockBytes = 1 shl 17
const searchSteps = 70

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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let entCount = nextInt(inputData, scanPos)
  var entX = newSeq[float](entCount)
  var entY = newSeq[float](entCount)
  var entSpeed = newSeq[float](entCount)
  var minX = 1000000000.0
  var maxX = -1000000000.0
  var minY = 1000000000.0
  var maxY = -1000000000.0
  for entIndex in 0 .. entCount - 1:
    let coordX = nextInt(inputData, scanPos)
    let coordY = nextInt(inputData, scanPos)
    let speed = nextInt(inputData, scanPos)
    entX[entIndex] = float(coordX)
    entY[entIndex] = float(coordY)
    entSpeed[entIndex] = float(speed)
    if entX[entIndex] < minX:
      minX = entX[entIndex]
    if entX[entIndex] > maxX:
      maxX = entX[entIndex]
    if entY[entIndex] < minY:
      minY = entY[entIndex]
    if entY[entIndex] > maxY:
      maxY = entY[entIndex]

  proc latestArrival(pointX: float, pointY: float): float =
    var worstTime: float = 0.0
    for entIndex in 0 .. entCount - 1:
      let deltaX = pointX - entX[entIndex]
      let deltaY = pointY - entY[entIndex]
      let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
      let travelTime = distance / entSpeed[entIndex]
      if travelTime > worstTime:
        worstTime = travelTime
    return worstTime

  proc bestAtX(pointX: float): float =
    var lowY = minY
    var highY = maxY
    for stepIndex in 0 .. searchSteps - 1:
      let firstY = lowY + (highY - lowY) / 3.0
      let secondY = highY - (highY - lowY) / 3.0
      if latestArrival(pointX, firstY) < latestArrival(pointX, secondY):
        highY = secondY
      else:
        lowY = firstY
    return latestArrival(pointX, (lowY + highY) / 2.0)

  var lowX = minX
  var highX = maxX
  for stepIndex in 0 .. searchSteps - 1:
    let firstX = lowX + (highX - lowX) / 3.0
    let secondX = highX - (highX - lowX) / 3.0
    if bestAtX(firstX) < bestAtX(secondX):
      highX = secondX
    else:
      lowX = firstX
  let answer = bestAtX((lowX + highX) / 2.0)
  appendOutput(formatFloat(answer, ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
