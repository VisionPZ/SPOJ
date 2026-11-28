const flushBlockBytes = 1 shl 17
const searchPattern = "segsi"
const patternLength = 5

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

var sourceEnd = 0
while sourceEnd < inputData.len and inputData[sourceEnd] != '\n':
  sourceEnd += 1
let sourceString = inputData[0 .. sourceEnd - 1]
scanPos = sourceEnd + 1
let repeatCount = nextInt(inputData, scanPos)

var extendedString = ""
let copiesNeeded = patternLength div sourceString.len + 2
for copyIndex in 0 .. copiesNeeded - 1:
  extendedString.add sourceString

var interiorMatches: int64 = 0
var wrapMatches: int64 = 0
let lastInteriorStart = sourceString.len - patternLength
for startIndex in 0 .. sourceString.len - 1:
  var foundMatch = true
  for patternOffset in 0 .. patternLength - 1:
    if extendedString[startIndex + patternOffset] != searchPattern[patternOffset]:
      foundMatch = false
      break
  if foundMatch:
    if startIndex <= lastInteriorStart:
      interiorMatches += 1
    else:
      wrapMatches += 1

let totalMatches = interiorMatches * int64(repeatCount) + wrapMatches * int64(repeatCount - 1)
appendOutput($totalMatches)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
