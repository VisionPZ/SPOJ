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

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseTotal:
  var lowerIndex = nextInt(inputData, scanPos)
  var upperIndex = nextInt(inputData, scanPos)
  if lowerIndex > upperIndex:
    let swapValue = lowerIndex
    lowerIndex = upperIndex
    upperIndex = swapValue
  var firstEvenIndex = lowerIndex
  while firstEvenIndex mod 3 != 1:
    firstEvenIndex += 1
  var evenCount: int64 = 0
  if firstEvenIndex <= upperIndex:
    evenCount = int64((upperIndex - firstEvenIndex) div 3 + 1)
  let spanLength = upperIndex - lowerIndex + 1
  let oddCount = int64(spanLength) - evenCount
  appendOutput("Case " & $caseIndex & ":\n")
  appendOutput("Odd = " & $oddCount & "\n")
  appendOutput("Even = " & $evenCount & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
