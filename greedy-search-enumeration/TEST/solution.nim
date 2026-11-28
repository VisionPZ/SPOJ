const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

var lineStart = 0
let totalLen = inputData.len
while lineStart < totalLen:
  var lineEnd = lineStart
  while lineEnd < totalLen and inputData[lineEnd] != '\n':
    lineEnd += 1
  var trimStart = lineStart
  while trimStart < lineEnd and inputData[trimStart] <= ' ':
    trimStart += 1
  var trimEnd = lineEnd
  while trimEnd > trimStart and inputData[trimEnd - 1] <= ' ':
    trimEnd -= 1
  if trimEnd - trimStart == 2 and inputData[trimStart] == '4' and inputData[trimStart + 1] == '2':
    break
  for charIdx in trimStart..<trimEnd:
    outputBuffer.add inputData[charIdx]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  lineStart = lineEnd + 1

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
