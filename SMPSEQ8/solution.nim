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

let firstLength = nextInt(inputData, scanPos)
var firstSequence = newSeq[int](firstLength)
var firstSum = 0
var positionIndex = 0
while positionIndex < firstLength:
  let currentValue = nextInt(inputData, scanPos)
  firstSequence[positionIndex] = currentValue
  firstSum += currentValue
  positionIndex += 1

let secondLength = nextInt(inputData, scanPos)
var secondSequence = newSeq[int](secondLength)
var secondSum = 0
positionIndex = 0
while positionIndex < secondLength:
  let currentValue = nextInt(inputData, scanPos)
  secondSequence[positionIndex] = currentValue
  secondSum += currentValue
  positionIndex += 1

var outputSequence = firstSequence
if secondSum >= firstSum:
  outputSequence = secondSequence
positionIndex = 0
while positionIndex < outputSequence.len:
  if positionIndex > 0:
    appendOutput(" ")
  appendOutput($(outputSequence[positionIndex]))
  positionIndex += 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
