const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'i64

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

var largestSize = 0
while scanPos < inputData.len:
  let sizeValue = nextInt(inputData, scanPos)
  if sizeValue > largestSize:
    largestSize = sizeValue
  if scanPos >= inputData.len:
    break

var treeCounts = newSeq[int64](largestSize + 2)
treeCounts[1] = 1
var treeSize = 2
while treeSize <= largestSize:
  var divisorSum: int64 = 0
  var divisorValue = 1
  let remainderValue = treeSize - 1
  while divisorValue * divisorValue <= remainderValue:
    if remainderValue mod divisorValue == 0:
      divisorSum = (divisorSum + treeCounts[divisorValue]) mod modulusValue
      let pairedDivisor = remainderValue div divisorValue
      if pairedDivisor != divisorValue:
        divisorSum = (divisorSum + treeCounts[pairedDivisor]) mod modulusValue
    divisorValue += 1
  treeCounts[treeSize] = divisorSum
  treeSize += 1

scanPos = 0
var caseIndex = 0
while scanPos < inputData.len:
  let sizeValue = nextInt(inputData, scanPos)
  if sizeValue == 0 and scanPos >= inputData.len:
    break
  if sizeValue < 1:
    continue
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & $treeCounts[sizeValue])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
