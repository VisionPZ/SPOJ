import algorithm

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

proc compareHeights(leftValue, rightValue: int): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let treeCount = nextInt(inputData, scanPos)
var heights = newSeq[int](treeCount)
for treeIndex in 0 .. treeCount - 1:
  heights[treeIndex] = nextInt(inputData, scanPos)
heights.sort(compareHeights)

var prefixTotals = newSeq[int64](treeCount + 1)
for treeIndex in 0 .. treeCount - 1:
  prefixTotals[treeIndex + 1] = prefixTotals[treeIndex] + int64(heights[treeIndex])

var bestCost = prefixTotals[treeCount]
var groupStart = 0
while groupStart < treeCount:
  let targetHeight = heights[groupStart]
  var groupEnd = groupStart + 1
  while groupEnd < treeCount and heights[groupEnd] == targetHeight:
    groupEnd += 1
  let shorterTotal = prefixTotals[groupStart]
  let tallerTotal = prefixTotals[treeCount] - prefixTotals[groupEnd]
  let tallerCount = treeCount - groupEnd
  let groupCost = shorterTotal + tallerTotal - int64(tallerCount) * int64(targetHeight)
  if groupCost < bestCost:
    bestCost = groupCost
  groupStart = groupEnd

appendOutput($bestCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
