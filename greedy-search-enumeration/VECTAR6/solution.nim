const flushBlockBytes = 1 shl 17
const modValue = 1000000007

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

let caseCount = nextInt(inputData, scanPos)
var heightQueries = newSeq[int](caseCount)
var maxHeight = 0
for caseIndex in 0 .. caseCount - 1:
  heightQueries[caseIndex] = nextInt(inputData, scanPos)
  if heightQueries[caseIndex] > maxHeight:
    maxHeight = heightQueries[caseIndex]

var treeCounts = newSeq[int](maxHeight + 1)
if maxHeight >= 1:
  treeCounts[1] = 1
  var prefixTotal = 2
  for height in 2 .. maxHeight:
    treeCounts[height] =
      int(int64(treeCounts[height - 1]) * int64(prefixTotal) mod modValue)
    prefixTotal = (prefixTotal + treeCounts[height]) mod modValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  appendOutput($treeCounts[heightQueries[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
