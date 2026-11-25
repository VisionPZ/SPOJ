import math

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

proc hasMore(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc largerValue(first: int64, second: int64): int64 =
  if first > second:
    return first
  return second

proc integerSquareRoot(value: int64): int64 =
  if value <= 1:
    return value
  var guess = int64(sqrt(float64(value)))
  while (guess + 1) * (guess + 1) <= value:
    guess += 1
  while guess * guess > value:
    guess -= 1
  return guess

var treeSum = newSeq[int64](1)
var treeMax = newSeq[int64](1)

proc buildTree(node: int, left: int, right: int, values: seq[int64]) =
  if left == right:
    treeSum[node] = values[left]
    treeMax[node] = values[left]
    return
  let middle = (left + right) div 2
  buildTree(node * 2, left, middle, values)
  buildTree(node * 2 + 1, middle + 1, right, values)
  treeSum[node] = treeSum[node * 2] + treeSum[node * 2 + 1]
  treeMax[node] = largerValue(treeMax[node * 2], treeMax[node * 2 + 1])

proc updateRange(node: int, left: int, right: int, queryLeft: int, queryRight: int) =
  if treeMax[node] <= 1:
    return
  if queryLeft <= left and right <= queryRight:
    if left == right:
      let rooted = integerSquareRoot(treeSum[node])
      treeSum[node] = rooted
      treeMax[node] = rooted
      return
  let middle = (left + right) div 2
  if queryLeft <= middle:
    updateRange(node * 2, left, middle, queryLeft, queryRight)
  if queryRight > middle:
    updateRange(node * 2 + 1, middle + 1, right, queryLeft, queryRight)
  treeSum[node] = treeSum[node * 2] + treeSum[node * 2 + 1]
  treeMax[node] = largerValue(treeMax[node * 2], treeMax[node * 2 + 1])

proc queryRange(node: int, left: int, right: int, queryLeft: int, queryRight: int): int64 =
  if queryLeft <= left and right <= queryRight:
    return treeSum[node]
  let middle = (left + right) div 2
  var total: int64 = 0
  if queryLeft <= middle:
    total = total + queryRange(node * 2, left, middle, queryLeft, queryRight)
  if queryRight > middle:
    total = total + queryRange(node * 2 + 1, middle + 1, right, queryLeft, queryRight)
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseNumber = 0
while hasMore(inputData, scanPos):
  let valueCount = nextInt(inputData, scanPos)
  var values = newSeq[int64](valueCount)
  for valueIndex in 0 .. valueCount - 1:
    values[valueIndex] = int64(nextInt(inputData, scanPos))
  treeSum = newSeq[int64](valueCount * 4 + 5)
  treeMax = newSeq[int64](valueCount * 4 + 5)
  if valueCount > 0:
    buildTree(1, 0, valueCount - 1, values)
  let operationCount = nextInt(inputData, scanPos)
  caseNumber += 1
  appendOutput("Case #" & $caseNumber & ":\n")
  for operationIndex in 0 .. operationCount - 1:
    let operationKind = nextInt(inputData, scanPos)
    let leftIndex = nextInt(inputData, scanPos) - 1
    let rightIndex = nextInt(inputData, scanPos) - 1
    if operationKind == 0:
      if valueCount > 0:
        updateRange(1, 0, valueCount - 1, leftIndex, rightIndex)
    else:
      let rangeSum = queryRange(1, 0, valueCount - 1, leftIndex, rightIndex)
      appendOutput($rangeSum)
      outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
