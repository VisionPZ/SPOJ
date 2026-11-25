const flushBlockBytes = 1 shl 17
const patternWord = "PANDA"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var letterData = ""
for charIndex in 0 .. inputData.len - 1:
  let currentChar = inputData[charIndex]
  if currentChar == 'P' or currentChar == 'A' or currentChar == 'N' or currentChar == 'D':
    letterData.add currentChar

let stringLength = letterData.len

proc canBuild(level: int): bool =
  if level == 0:
    return true
  var matchPos = 0
  for phaseIndex in 0 .. 4:
    let wantedChar = patternWord[phaseIndex]
    var matchedCount = 0
    while matchPos < stringLength and matchedCount < level:
      if letterData[matchPos] == wantedChar:
        matchedCount += 1
      matchPos += 1
    if matchedCount < level:
      return false
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var lowLevel = 0
var highLevel = stringLength div 5 + 1
while highLevel - lowLevel > 1:
  let midLevel = (lowLevel + highLevel) div 2
  if canBuild(midLevel):
    lowLevel = midLevel
  else:
    highLevel = midLevel
appendOutput($lowLevel)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
