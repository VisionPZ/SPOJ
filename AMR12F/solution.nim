const flushBlockBytes = 1 shl 17
const answerMod = 1000000007
const maxArmySize = 100000

var powerOfTwo: array[maxArmySize + 1, int64]
powerOfTwo[0] = 1
for exponent in 1 .. maxArmySize:
  powerOfTwo[exponent] = (powerOfTwo[exponent - 1] * 2) mod answerMod

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

var segmentLength = 0
var prefixWeight: seq[int64]
var sumMin: seq[int64]
var sumMax: seq[int64]
var lazyMin: seq[int]
var lazyMax: seq[int]

proc applyMin(node: int, left: int, right: int, value: int) =
  if value == 1:
    sumMin[node] = prefixWeight[right] - prefixWeight[left - 1]
    if sumMin[node] < 0:
      sumMin[node] += answerMod
  else:
    sumMin[node] = 0
  lazyMin[node] = value

proc applyMax(node: int, left: int, right: int, value: int) =
  if value == 1:
    sumMax[node] = prefixWeight[right] - prefixWeight[left - 1]
    if sumMax[node] < 0:
      sumMax[node] += answerMod
  else:
    sumMax[node] = 0
  lazyMax[node] = value

proc pushDown(node: int, left: int, right: int) =
  let middle = (left + right) div 2
  if lazyMin[node] != -1:
    applyMin(node * 2, left, middle, lazyMin[node])
    applyMin(node * 2 + 1, middle + 1, right, lazyMin[node])
    lazyMin[node] = -1
  if lazyMax[node] != -1:
    applyMax(node * 2, left, middle, lazyMax[node])
    applyMax(node * 2 + 1, middle + 1, right, lazyMax[node])
    lazyMax[node] = -1

proc assignMin(node: int, left: int, right: int, queryLeft: int, queryRight: int, value: int) =
  if queryLeft > right or queryRight < left:
    return
  if queryLeft <= left and right <= queryRight:
    applyMin(node, left, right, value)
    return
  pushDown(node, left, right)
  let middle = (left + right) div 2
  assignMin(node * 2, left, middle, queryLeft, queryRight, value)
  assignMin(node * 2 + 1, middle + 1, right, queryLeft, queryRight, value)
  sumMin[node] = (sumMin[node * 2] + sumMin[node * 2 + 1]) mod answerMod

proc assignMax(node: int, left: int, right: int, queryLeft: int, queryRight: int, value: int) =
  if queryLeft > right or queryRight < left:
    return
  if queryLeft <= left and right <= queryRight:
    applyMax(node, left, right, value)
    return
  pushDown(node, left, right)
  let middle = (left + right) div 2
  assignMax(node * 2, left, middle, queryLeft, queryRight, value)
  assignMax(node * 2 + 1, middle + 1, right, queryLeft, queryRight, value)
  sumMax[node] = (sumMax[node * 2] + sumMax[node * 2 + 1]) mod answerMod

proc setMinRange(leftBound: int, rightBound: int, value: int) =
  var leftPos = leftBound
  var rightPos = rightBound
  if leftPos < 1:
    leftPos = 1
  if rightPos > segmentLength:
    rightPos = segmentLength
  if leftPos <= rightPos:
    assignMin(1, 1, segmentLength, leftPos, rightPos, value)

proc setMaxRange(leftBound: int, rightBound: int, value: int) =
  var leftPos = leftBound
  var rightPos = rightBound
  if leftPos < 1:
    leftPos = 1
  if rightPos > segmentLength:
    rightPos = segmentLength
  if leftPos <= rightPos:
    assignMax(1, 1, segmentLength, leftPos, rightPos, value)

var bitTree: seq[int]

proc bitAdd(position: int) =
  var pos = position
  while pos <= segmentLength:
    bitTree[pos] += 1
    pos += pos and -pos

proc bitPrefix(position: int): int =
  var pos = position
  var total = 0
  while pos > 0:
    total += bitTree[pos]
    pos -= pos and -pos
  return total

proc bitFindKth(rank: int): int =
  var remaining = rank
  var pos = 0
  var step = 1
  while step shl 1 <= segmentLength:
    step = step shl 1
  while step > 0:
    let nextPos = pos + step
    if nextPos <= segmentLength and bitTree[nextPos] < remaining:
      pos = nextPos
      remaining -= bitTree[nextPos]
    step = step div 2
  return pos + 1

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let armySize = nextInt(inputData, scanPos)
  segmentLength = armySize div 2
  prefixWeight = newSeq[int64](segmentLength + 2)
  for position in 1 .. segmentLength:
    let exponent = armySize - position - 1
    prefixWeight[position] = (prefixWeight[position - 1] + powerOfTwo[exponent]) mod answerMod
  prefixWeight[segmentLength + 1] = prefixWeight[segmentLength]
  sumMin = newSeq[int64](4 * segmentLength + 5)
  sumMax = newSeq[int64](4 * segmentLength + 5)
  lazyMin = newSeq[int](4 * segmentLength + 5)
  lazyMax = newSeq[int](4 * segmentLength + 5)
  for cellIndex in 0 .. 4 * segmentLength + 4:
    lazyMin[cellIndex] = -1
    lazyMax[cellIndex] = -1
  bitTree = newSeq[int](segmentLength + 1)
  var requiredBacks = newSeq[int](segmentLength + 1)
  var isBackChoice = newSeq[bool](segmentLength + 1)
  var inconsistent = false
  for pairIndex in 0 .. segmentLength - 1:
    let position = nextInt(inputData, scanPos)
    let value = nextInt(inputData, scanPos)
    if inconsistent:
      appendOutput("-1\n")
      continue
    var choiceBack = false
    var backsBefore = 0
    if value <= position:
      backsBefore = position - value
    elif value >= armySize - position + 1:
      choiceBack = true
      backsBefore = armySize - value
    else:
      inconsistent = true
      appendOutput("-1\n")
      continue
    if bitPrefix(position) - bitPrefix(position - 1) != 0:
      inconsistent = true
      appendOutput("-1\n")
      continue
    let countBefore = bitPrefix(position - 1)
    var predecessor = 0
    if countBefore > 0:
      predecessor = bitFindKth(countBefore)
    var successor = segmentLength + 1
    if bitPrefix(segmentLength) > countBefore:
      successor = bitFindKth(countBefore + 1)
    let backsAfterPredecessor = if predecessor == 0: 0 else:
      requiredBacks[predecessor] + (if isBackChoice[predecessor]: 1 else: 0)
    let firstIncrease = backsBefore - backsAfterPredecessor
    if firstIncrease < 0 or firstIncrease > position - 1 - predecessor:
      inconsistent = true
      appendOutput("-1\n")
      continue
    var secondIncrease = 0
    if successor <= segmentLength:
      secondIncrease = requiredBacks[successor] - (backsBefore + (if choiceBack: 1 else: 0))
      if secondIncrease < 0 or secondIncrease > successor - 1 - position:
        inconsistent = true
        appendOutput("-1\n")
        continue
    bitAdd(position)
    requiredBacks[position] = backsBefore
    isBackChoice[position] = choiceBack
    setMinRange(predecessor + 1, position - firstIncrease - 1, 0)
    setMinRange(position - firstIncrease, position - 1, 1)
    setMaxRange(predecessor + 1, predecessor + firstIncrease, 1)
    setMaxRange(predecessor + firstIncrease + 1, position - 1, 0)
    setMinRange(position, position, if choiceBack: 1 else: 0)
    setMaxRange(position, position, if choiceBack: 1 else: 0)
    if successor == segmentLength + 1:
      setMinRange(position + 1, segmentLength, 0)
      setMaxRange(position + 1, segmentLength, 1)
    else:
      setMinRange(position + 1, successor - secondIncrease - 1, 0)
      setMinRange(successor - secondIncrease, successor - 1, 1)
      setMaxRange(position + 1, position + secondIncrease, 1)
      setMaxRange(position + secondIncrease + 1, successor - 1, 0)
    let minValue = sumMin[1]
    let tailSize = powerOfTwo[armySize - segmentLength - 1]
    let maxValue = (sumMax[1] + tailSize - 1) mod answerMod
    appendOutput($minValue & " " & $maxValue)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
