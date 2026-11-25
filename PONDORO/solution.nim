const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextWorldString(data: string, pos: var int): string =
  while pos < data.len and data[pos] != 'R' and data[pos] != '.':
    pos += 1
  var world = ""
  while pos < data.len and (data[pos] == 'R' or data[pos] == '.'):
    world.add data[pos]
    pos += 1
  return world

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let worldLength = nextInt(inputData, scanPos)
let mouthCount = nextInt(inputData, scanPos)
let world = nextWorldString(inputData, scanPos)
var mouthLengths = newSeq[int](mouthCount)
var longestMouth = 0
for mouthIndex in 0 .. mouthCount - 1:
  mouthLengths[mouthIndex] = nextInt(inputData, scanPos)
  if mouthLengths[mouthIndex] > longestMouth:
    longestMouth = mouthLengths[mouthIndex]
var rainingCount = 0
for index in 0 .. longestMouth - 1:
  if world[index] == 'R':
    rainingCount += 1
var bestCount = rainingCount
var startIndex = 1
while startIndex + longestMouth <= worldLength:
  if world[startIndex - 1] == 'R':
    rainingCount -= 1
  if world[startIndex + longestMouth - 1] == 'R':
    rainingCount += 1
  if rainingCount > bestCount:
    bestCount = rainingCount
  startIndex += 1
var rainPositions = newSeq[int]()
for index in 0 .. worldLength - 1:
  if world[index] == 'R':
    rainPositions.add index
var minimalRequired = 0
if bestCount > 0:
  minimalRequired = worldLength + 1
  var firstRain = 0
  while firstRain + bestCount <= rainPositions.len:
    let span = rainPositions[firstRain + bestCount - 1] - rainPositions[firstRain] + 1
    if span < minimalRequired:
      minimalRequired = span
    firstRain += 1
var bestMouth = longestMouth
for mouthIndex in 0 .. mouthCount - 1:
  if mouthLengths[mouthIndex] >= minimalRequired and mouthLengths[mouthIndex] < bestMouth:
    bestMouth = mouthLengths[mouthIndex]
appendOutput($bestMouth)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
