import algorithm

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

let dayCount = nextInt(inputData, scanPos)
for dayIndex in 0 .. dayCount - 1:
  let channelCount = nextInt(inputData, scanPos)
  let jumpLimit = nextInt(inputData, scanPos)
  let waitSeconds = nextInt(inputData, scanPos)
  var girlinessValues = newSeq[int](channelCount)
  for channelIndex in 0 .. channelCount - 1:
    girlinessValues[channelIndex] = nextInt(inputData, scanPos)
  let startGirliness = girlinessValues[0]
  girlinessValues.sort(proc (leftValue, rightValue: int): int = system.cmp(leftValue, rightValue))
  var currentGirliness = startGirliness
  var jumpCount = 0
  while true:
    let reachLimit = int64(currentGirliness) + int64(jumpLimit)
    var lowIndex = 0
    var highIndex = channelCount - 1
    var bestIndex = -1
    while lowIndex <= highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if int64(girlinessValues[middleIndex]) <= reachLimit:
        bestIndex = middleIndex
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex - 1
    if bestIndex < 0 or girlinessValues[bestIndex] <= currentGirliness:
      break
    currentGirliness = girlinessValues[bestIndex]
    jumpCount += 1
  appendOutput($currentGirliness)
  appendOutput(" ")
  appendOutput($(int64(jumpCount) * int64(waitSeconds)))
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
