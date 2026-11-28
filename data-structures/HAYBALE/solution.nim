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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let stackCount = nextInt(inputData, scanPos)
let instructionCount = nextInt(inputData, scanPos)
var heightChanges = newSeq[int](stackCount + 2)
for instructionIndex in 0 .. instructionCount - 1:
  let firstStack = nextInt(inputData, scanPos)
  let lastStack = nextInt(inputData, scanPos)
  heightChanges[firstStack] += 1
  heightChanges[lastStack + 1] -= 1
var heightFrequency = newSeq[int](instructionCount + 1)
var currentHeight = 0
for stackIndex in 1 .. stackCount:
  currentHeight += heightChanges[stackIndex]
  heightFrequency[currentHeight] += 1
let middleRank = stackCount div 2 + 1
var seenStacks = 0
var medianHeight = 0
for heightValue in 0 .. instructionCount:
  seenStacks += heightFrequency[heightValue]
  if seenStacks >= middleRank:
    medianHeight = heightValue
    break
appendOutput($medianHeight)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
