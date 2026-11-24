import std/algorithm

const
  maxCoordinate = 50000
  treeSize = maxCoordinate + 1
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18

type
  Interval = object
    left: int
    right: int
    demand: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var chosenBit = newSeq[int](treeSize + 1)
var freeBit = newSeq[int](treeSize + 1)
for index in 1..treeSize:
  freeBit[index] += 1
  let parent = index + (index and (-index))
  if parent <= treeSize:
    freeBit[parent] += freeBit[index]

var startStep = 1
while startStep shl 1 <= treeSize:
  startStep = startStep shl 1

proc bitAdd(bit: var seq[int], index: int, delta: int) =
  var position = index
  while position <= treeSize:
    bit[position] += delta
    position += position and (-position)

proc bitPrefix(bit: seq[int], index: int): int =
  var position = index
  var total = 0
  while position > 0:
    total += bit[position]
    position -= position and (-position)
  return total

proc findKthFree(rank: int): int =
  var index = 0
  var step = startStep
  var remaining = rank
  while step != 0:
    let nextIndex = index + step
    if nextIndex <= treeSize and freeBit[nextIndex] < remaining:
      index = nextIndex
      remaining -= freeBit[nextIndex]
    step = step shr 1
  return index + 1

proc compareIntervals(x, y: Interval): int =
  if x.right != y.right:
    return x.right - y.right
  return y.left - x.left

proc solveCase(intervals: var seq[Interval], touched: var seq[int]): int =
  intervals.sort(compareIntervals)
  var totalChosen = 0
  for interval in intervals:
    let leftIndex = interval.left + 1
    let rightIndex = interval.right + 1
    let already = bitPrefix(chosenBit, rightIndex) - bitPrefix(chosenBit, leftIndex - 1)
    var missing = interval.demand - already
    var freeRank = rightIndex - bitPrefix(chosenBit, rightIndex)
    while missing > 0:
      let freeIndex = findKthFree(freeRank)
      bitAdd(chosenBit, freeIndex, 1)
      bitAdd(freeBit, freeIndex, -1)
      touched.add freeIndex
      freeRank -= 1
      totalChosen += 1
      missing -= 1
  return totalChosen

var touched = newSeq[int]()

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let intervalCount = nextInt(inputData, scanPos)
  var intervals = newSeq[Interval](intervalCount)
  for intervalIndex in 0..<intervalCount:
    intervals[intervalIndex].left = nextInt(inputData, scanPos)
    intervals[intervalIndex].right = nextInt(inputData, scanPos)
    intervals[intervalIndex].demand = nextInt(inputData, scanPos)
  let answer = solveCase(intervals, touched)
  appendOutput($answer)
  outputBuffer.add '\n'
  for position in touched:
    bitAdd(chosenBit, position, -1)
    bitAdd(freeBit, position, 1)
  touched.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
