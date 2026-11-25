const flushBlockBytes = 1 shl 17
const metersPerGap = 3

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

let treeCount = nextInt(inputData, scanPos)
let reachMeters = nextInt(inputData, scanPos)
let reachTrees = reachMeters div metersPerGap
var fruitCounts = newSeq[int](treeCount)
for treeIndex in 0 .. treeCount - 1:
  fruitCounts[treeIndex] = nextInt(inputData, scanPos)
var bestHarvest: int64 = 0
for centerTree in 0 .. treeCount - 1:
  var leftTree = centerTree - reachTrees
  if leftTree < 0:
    leftTree = 0
  var rightTree = centerTree + reachTrees
  if rightTree >= treeCount:
    rightTree = treeCount - 1
  var windowTotal: int64 = 0
  var currentTree = leftTree
  while currentTree <= rightTree:
    windowTotal = windowTotal + int64(fruitCounts[currentTree])
    currentTree += 1
  if windowTotal > bestHarvest:
    bestHarvest = windowTotal
appendOutput($bestHarvest)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
