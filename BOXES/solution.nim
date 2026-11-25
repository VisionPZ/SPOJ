const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc minimumMoves(ballCounts: seq[int], ballTotal: int): int =
  let boxCount = ballCounts.len
  var bestCost = high(int)
  for cutIndex in 0 .. (boxCount - 1):
    var boxIndex = cutIndex + 1
    if boxIndex >= boxCount: boxIndex = 0
    var ballsSeen = 0
    var filledSlots = 0
    var cutCost = 0
    for linePosition in 1 .. (boxCount - 1):
      ballsSeen += ballCounts[boxIndex]
      var upperBound = ballsSeen
      if filledSlots + 1 < upperBound: upperBound = filledSlots + 1
      let lowerBound = ballTotal - (boxCount - linePosition)
      if lowerBound > upperBound:
        filledSlots = lowerBound
      else:
        filledSlots = upperBound
      if ballsSeen > filledSlots:
        cutCost += ballsSeen - filledSlots
      else:
        cutCost += filledSlots - ballsSeen
      boxIndex += 1
      if boxIndex >= boxCount: boxIndex = 0
    if cutCost < bestCost: bestCost = cutCost
  return bestCost

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 1 .. caseCount:
  let boxCount = nextInt(inputData, scanPos)
  var ballCounts = newSeq[int](boxCount)
  var ballTotal = 0
  for boxIndex in 0 .. (boxCount - 1):
    ballCounts[boxIndex] = nextInt(inputData, scanPos)
    ballTotal += ballCounts[boxIndex]
  outputBuffer.add $minimumMoves(ballCounts, ballTotal)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
