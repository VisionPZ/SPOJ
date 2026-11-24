const flushBlockBytes = 1 shl 18

var inputData = ""
var line = ""
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'

var inputLength = inputData.len
var i = 0
var caseCount = 0
while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
  i = i + 1
while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
  caseCount = caseCount * 10 + (ord(inputData[i]) - 48)
  i = i + 1

var outputBuffer = ""
for j in 1 .. caseCount:
  while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var numberStart = i
  while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
    i = i + 1
  var numberEnd = i
  if numberStart == numberEnd:
    break
  while numberStart < numberEnd - 1 and inputData[numberStart] == '0':
    numberStart = numberStart + 1
  var numberLength = numberEnd - numberStart
  var k = numberLength div 2 - 1
  var l = numberLength - numberLength div 2
  while k >= 0 and inputData[numberStart + k] == inputData[numberStart + l]:
    k = k - 1
    l = l + 1
  var carried = false
  if k < 0 or inputData[numberStart + k] < inputData[numberStart + l]:
    var i = numberStart + (numberLength - 1 - numberLength div 2)
    while i >= numberStart:
      if inputData[i] < '9':
        inputData[i] = chr(ord(inputData[i]) + 1)
        break
      inputData[i] = '0'
      i = i - 1
    if i < numberStart:
      outputBuffer.add '1'
      for i in 1 .. numberLength - 1:
        outputBuffer.add '0'
      outputBuffer.add "1\n"
      carried = true
  if not carried:
    var i = 0
    while i < numberLength div 2:
      inputData[numberEnd - 1 - i] = inputData[numberStart + i]
      i = i + 1
    outputBuffer.add inputData.substr(numberStart, numberEnd - 1)
    outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
