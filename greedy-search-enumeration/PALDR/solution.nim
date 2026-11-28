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

let caseCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
if scanPos < inputData.len:
  scanPos += 1

var palindromeStack = ""
for caseIndex in 0 .. caseCount - 1:
  if scanPos >= inputData.len:
    appendOutput("YES \n")
  else:
    var lineEnd = scanPos
    while lineEnd < inputData.len and inputData[lineEnd] != '\n':
      lineEnd += 1
    var charPos = scanPos
    while charPos < lineEnd:
      let currentChar = inputData[charPos]
      if currentChar != '\r':
        if palindromeStack.len > 0 and palindromeStack[palindromeStack.len - 1] == currentChar:
          palindromeStack.setLen(palindromeStack.len - 1)
        else:
          palindromeStack.add currentChar
      charPos += 1
    scanPos = lineEnd + 1
    if palindromeStack.len == 0:
      appendOutput("YES \n")
    else:
      appendOutput("NO\n")
    palindromeStack.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
