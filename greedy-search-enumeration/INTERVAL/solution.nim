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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var chosenBit = newSeq[int](treeSize + 1)
var freeBit = newSeq[int](treeSize + 1)
for j in 1..treeSize:
  freeBit[j] += 1
  let k = j + (j and (-j))
  if k <= treeSize:
    freeBit[k] += freeBit[j]

var startStep = 1
while startStep shl 1 <= treeSize:
  startStep = startStep shl 1

proc bitAdd(bit: var seq[int], i: int, delta: int) =
  var j = i
  while j <= treeSize:
    bit[j] += delta
    j += j and (-j)

proc bitPrefix(bit: seq[int], i: int): int =
  var j = i
  var total = 0
  while j > 0:
    total += bit[j]
    j -= j and (-j)
  return total

proc findKthFree(rank: int): int =
  var i = 0
  var step = startStep
  var remaining = rank
  while step != 0:
    let j = i + step
    if j <= treeSize and freeBit[j] < remaining:
      i = j
      remaining -= freeBit[j]
    step = step shr 1
  return i + 1

proc compareIntervals(x, y: Interval): int =
  if x.right != y.right:
    return x.right - y.right
  return y.left - x.left

proc solveCase(intervals: var seq[Interval], touched: var seq[int]): int =
  intervals.sort(compareIntervals)
  var totalChosen = 0
  for interval in intervals:
    let i = interval.left + 1
    let j = interval.right + 1
    let already = bitPrefix(chosenBit, j) - bitPrefix(chosenBit, i - 1)
    var missing = interval.demand - already
    var freeRank = j - bitPrefix(chosenBit, j)
    while missing > 0:
      let k = findKthFree(freeRank)
      bitAdd(chosenBit, k, 1)
      bitAdd(freeBit, k, -1)
      touched.add k
      freeRank -= 1
      totalChosen += 1
      missing -= 1
  return totalChosen

var touched = newSeq[int]()

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let intervalCount = nextInt(inputData, i)
  var intervals = newSeq[Interval](intervalCount)
  for k in 0..<intervalCount:
    intervals[k].left = nextInt(inputData, i)
    intervals[k].right = nextInt(inputData, i)
    intervals[k].demand = nextInt(inputData, i)
  let answer = solveCase(intervals, touched)
  appendOutput($answer)
  outputBuffer.add '\n'
  for k in touched:
    bitAdd(chosenBit, k, -1)
    bitAdd(freeBit, k, 1)
  touched.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
