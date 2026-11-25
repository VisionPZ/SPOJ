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

let stationCount = nextInt(inputData, scanPos)
let peopleLimit = nextInt(inputData, scanPos)
var trainA = newSeq[int](stationCount)
for stationIndex in 0 .. stationCount - 1:
  trainA[stationIndex] = nextInt(inputData, scanPos)
var trainB = newSeq[int](stationCount)
for stationIndex in 0 .. stationCount - 1:
  trainB[stationIndex] = nextInt(inputData, scanPos)

var previousOnA = trainA[0]
var previousOnB = trainB[0]
var bestStationCount = 0
var bestPeopleSeen = 0
for stationIndex in 0 .. stationCount - 1:
  var currentOnA = 0
  var currentOnB = 0
  if stationIndex == 0:
    currentOnA = trainA[0]
    currentOnB = trainB[0]
  else:
    let switchCost = trainA[stationIndex] + trainB[stationIndex]
    currentOnA = min(previousOnA + trainA[stationIndex], previousOnB + switchCost)
    currentOnB = min(previousOnB + trainB[stationIndex], previousOnA + switchCost)
  let stationBest = min(currentOnA, currentOnB)
  if stationBest <= peopleLimit:
    bestStationCount = stationIndex + 1
    bestPeopleSeen = stationBest
  previousOnA = currentOnA
  previousOnB = currentOnB

appendOutput($bestStationCount & " " & $bestPeopleSeen)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
