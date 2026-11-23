const flushBlockBytes = 1 shl 18

var inputData = ""
var line = ""
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'

var inputLength = inputData.len
var cursor = 0
var caseCount = 0
while cursor < inputLength and (inputData[cursor] < '0' or inputData[cursor] > '9'):
  cursor = cursor + 1
while cursor < inputLength and inputData[cursor] >= '0' and inputData[cursor] <= '9':
  caseCount = caseCount * 10 + (ord(inputData[cursor]) - 48)
  cursor = cursor + 1

var outputBuffer = ""
for caseNumber in 1 .. caseCount:
  while cursor < inputLength and (inputData[cursor] < '0' or inputData[cursor] > '9'):
    cursor = cursor + 1
  var numberStart = cursor
  while cursor < inputLength and inputData[cursor] >= '0' and inputData[cursor] <= '9':
    cursor = cursor + 1
  var numberEnd = cursor
  if numberStart == numberEnd:
    break
  while numberStart < numberEnd - 1 and inputData[numberStart] == '0':
    numberStart = numberStart + 1
  var numberLength = numberEnd - numberStart
  var leftOffset = numberLength div 2 - 1
  var rightOffset = numberLength - numberLength div 2
  while leftOffset >= 0 and inputData[numberStart + leftOffset] == inputData[numberStart + rightOffset]:
    leftOffset = leftOffset - 1
    rightOffset = rightOffset + 1
  var carried = false
  if leftOffset < 0 or inputData[numberStart + leftOffset] < inputData[numberStart + rightOffset]:
    var carryPos = numberStart + (numberLength - 1 - numberLength div 2)
    while carryPos >= numberStart:
      if inputData[carryPos] < '9':
        inputData[carryPos] = chr(ord(inputData[carryPos]) + 1)
        break
      inputData[carryPos] = '0'
      carryPos = carryPos - 1
    if carryPos < numberStart:
      outputBuffer.add '1'
      for zeroCount in 1 .. numberLength - 1:
        outputBuffer.add '0'
      outputBuffer.add "1\n"
      carried = true
  if not carried:
    var mirrorStep = 0
    while mirrorStep < numberLength div 2:
      inputData[numberEnd - 1 - mirrorStep] = inputData[numberStart + mirrorStep]
      mirrorStep = mirrorStep + 1
    outputBuffer.add inputData.substr(numberStart, numberEnd - 1)
    outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
