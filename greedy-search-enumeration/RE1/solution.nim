const flushBlockBytes = 1 shl 17
const modulus = 1000000007
const maxNumberCount = 100
const maxSwapCount = 10000
const tableStride = maxSwapCount + 1

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

var swapTable = newSeq[int]((maxNumberCount + 1) * tableStride)
swapTable[0] = 1
for numberCount in 1 .. maxNumberCount:
  var windowTotal = 0
  let previousRow = (numberCount - 1) * tableStride
  let currentRow = numberCount * tableStride
  for inversionCount in 0 .. maxSwapCount:
    windowTotal += swapTable[previousRow + inversionCount]
    if windowTotal >= modulus:
      windowTotal -= modulus
    if inversionCount >= numberCount:
      windowTotal -= swapTable[previousRow + inversionCount - numberCount]
      if windowTotal < 0:
        windowTotal += modulus
    swapTable[currentRow + inversionCount] = windowTotal

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let numberCount = nextInt(inputData, scanPos)
  let swapLimit = nextInt(inputData, scanPos)
  var arrangementCount = 0
  if numberCount >= 1 and numberCount <= maxNumberCount and swapLimit <= maxSwapCount:
    arrangementCount = swapTable[numberCount * tableStride + swapLimit]
  appendOutput("Case " & $caseIndex & ": " & $arrangementCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
