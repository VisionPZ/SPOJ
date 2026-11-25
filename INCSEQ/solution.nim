const flushBlockBytes = 1 shl 17
const valueLimit = 100000
const modulusValue = 5000000

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

proc prefixQuery(tree: seq[int], upperIndex: int): int =
  var total = 0
  var cursor = upperIndex
  while cursor > 0:
    total = (total + tree[cursor]) mod modulusValue
    cursor -= cursor and (-cursor)
  return total

proc addToTree(tree: var seq[int], startIndex: int, deltaValue: int) =
  var cursor = startIndex
  while cursor <= valueLimit:
    tree[cursor] = (tree[cursor] + deltaValue) mod modulusValue
    cursor += cursor and (-cursor)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
let subsequenceLength = nextInt(inputData, scanPos)
var fenwickTrees = newSeq[seq[int]](subsequenceLength + 1)
for lengthIndex in 0 .. subsequenceLength:
  fenwickTrees[lengthIndex] = newSeq[int](valueLimit + 1)
for position in 0 .. elementCount - 1:
  let currentValue = nextInt(inputData, scanPos)
  let treeIndex = currentValue + 1
  for lengthIndex in countdown(subsequenceLength, 2):
    let smallerTotal = prefixQuery(fenwickTrees[lengthIndex - 1], currentValue)
    addToTree(fenwickTrees[lengthIndex], treeIndex, smallerTotal)
  addToTree(fenwickTrees[1], treeIndex, 1)
let answerValue = prefixQuery(fenwickTrees[subsequenceLength], valueLimit)
appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
