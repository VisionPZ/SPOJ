const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var onesLength = 0
var onesEightsLength = 0
var onesEightsZerosLength = 0
var fullLength = 0

for charIndex in 0 .. inputData.len - 1:
  let currentChar = inputData[charIndex]
  if currentChar == '1':
    onesLength = onesLength + 1
  elif currentChar == '8' and onesLength > 0:
    if onesEightsLength < onesLength:
      onesEightsLength = onesLength
    onesEightsLength = onesEightsLength + 1
  elif currentChar == '0' and onesEightsLength > 0:
    if onesEightsZerosLength < onesEightsLength:
      onesEightsZerosLength = onesEightsLength
    onesEightsZerosLength = onesEightsZerosLength + 1
  elif currentChar == '7' and onesEightsZerosLength > 0:
    if fullLength < onesEightsZerosLength:
      fullLength = onesEightsZerosLength
    fullLength = fullLength + 1

var answer = fullLength
if onesLength == 0 or onesEightsLength == 0 or onesEightsZerosLength == 0:
  answer = 0
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
