const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sequenceLength = nextInt(inputData, scanPos)
let neighborRadius = nextInt(inputData, scanPos)
var leftSequence = newSeq[int](sequenceLength)
var rightSequence = newSeq[int](sequenceLength)
var positionIndex = 0
while positionIndex < sequenceLength:
  leftSequence[positionIndex] = nextInt(inputData, scanPos)
  positionIndex += 1
positionIndex = 0
while positionIndex < sequenceLength:
  rightSequence[positionIndex] = nextInt(inputData, scanPos)
  positionIndex += 1

var emittedAny = false
positionIndex = 0
while positionIndex < sequenceLength:
  let wantedValue = leftSequence[positionIndex]
  var windowStart = positionIndex - neighborRadius
  if windowStart < 0:
    windowStart = 0
  var windowEnd = positionIndex + neighborRadius
  if windowEnd >= sequenceLength:
    windowEnd = sequenceLength - 1
  var candidateIndex = windowStart
  while candidateIndex <= windowEnd:
    if rightSequence[candidateIndex] == wantedValue:
      if emittedAny:
        appendOutput(" ")
      appendOutput($(positionIndex + 1))
      emittedAny = true
      break
    candidateIndex += 1
  positionIndex += 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
