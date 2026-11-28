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

let classSize = nextInt(inputData, scanPos)
var remainingValue = classSize
var inviteCount = classSize
var primeCandidate = 2
while primeCandidate * primeCandidate <= remainingValue:
  if remainingValue mod primeCandidate == 0:
    while remainingValue mod primeCandidate == 0:
      remainingValue = remainingValue div primeCandidate
    inviteCount = inviteCount div primeCandidate * (primeCandidate - 1)
  primeCandidate += 1
if remainingValue > 1:
  inviteCount = inviteCount div remainingValue * (remainingValue - 1)
appendOutput($inviteCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
