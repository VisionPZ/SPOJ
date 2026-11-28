const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt64(inputData, scanPos))
for caseNumber in 1 .. caseCount:
  let monsterCount = int(nextInt64(inputData, scanPos))
  var prevTwoBest: int64 = 0
  var prevOneBest: int64 = 0
  for idx in 0 .. monsterCount - 1:
    let coins = nextInt64(inputData, scanPos)
    let takeCurrent = prevTwoBest + coins
    let currentBest = if takeCurrent > prevOneBest: takeCurrent else: prevOneBest
    prevTwoBest = prevOneBest
    prevOneBest = currentBest
  appendOutput("Case ")
  appendOutput($caseNumber)
  appendOutput(": ")
  appendOutput($prevOneBest)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
