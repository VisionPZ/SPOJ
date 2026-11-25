import algorithm

const flushBlockBytes = 1 shl 17
const treeInfinity: int64 = 1000000000000000000

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

proc magnitude(value: int64): int64 =
  if value < 0:
    return -value
  return value

proc distanceToRange(value: int64, low: int64, high: int64): int64 =
  if value < low:
    return low - value
  if value > high:
    return value - high
  return 0

type MinTree = object
  size: int
  nodes: seq[int64]

proc newMinTree(count: int): MinTree =
  var size = 1
  while size < count:
    size = size * 2
  var nodes = newSeq[int64](2 * size)
  for nodeIndex in 0 .. nodes.len - 1:
    nodes[nodeIndex] = treeInfinity
  return MinTree(size: size, nodes: nodes)

proc setLeaf(tree: var MinTree, index: int, value: int64) =
  var position = index + tree.size
  tree.nodes[position] = value
  position = position div 2
  while position >= 1:
    tree.nodes[position] = min(tree.nodes[position * 2], tree.nodes[position * 2 + 1])
    position = position div 2

proc queryRange(tree: MinTree, left: int, right: int): int64 =
  if left > right:
    return treeInfinity
  var lowCursor = left + tree.size
  var highCursor = right + tree.size
  var best = treeInfinity
  while lowCursor <= highCursor:
    if (lowCursor mod 2) == 1:
      best = min(best, tree.nodes[lowCursor])
      lowCursor += 1
    if (highCursor mod 2) == 0:
      best = min(best, tree.nodes[highCursor])
      highCursor -= 1
    lowCursor = lowCursor div 2
    highCursor = highCursor div 2
  return best

type MoveEvent = object
  coordinate: int64
  treeIndex: int
  targetState: int

proc byCoordinate(left: MoveEvent, right: MoveEvent): int =
  if left.coordinate < right.coordinate:
    return -1
  if left.coordinate > right.coordinate:
    return 1
  return 0

proc ascendingHeight(heights: seq[int64], left: int, right: int): int =
  if heights[left] < heights[right]:
    return -1
  if heights[left] > heights[right]:
    return 1
  return 0

proc lowerBound(values: seq[int64], target: int64): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

proc upperBound(values: seq[int64], target: int64): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] <= target:
      low = middle + 1
    else:
      high = middle
  return low

let treeCount = nextInt(inputData, scanPos)
var heights = newSeq[int64](treeCount + 1)
for position in 1 .. treeCount:
  heights[position] = int64(nextInt(inputData, scanPos))
var baseDisorder: int64 = 0
for position in 1 .. treeCount - 1:
  baseDisorder = baseDisorder + magnitude(heights[position] - heights[position + 1])
var answers = newSeq[int64](treeCount + 1)
for position in 1 .. treeCount:
  answers[position] = baseDisorder

var lowNeighbor = newSeq[int64](treeCount + 1)
var highNeighbor = newSeq[int64](treeCount + 1)
var distanceValue = newSeq[int64](treeCount + 1)
for position in 2 .. treeCount - 1:
  lowNeighbor[position] = min(heights[position - 1], heights[position + 1])
  highNeighbor[position] = max(heights[position - 1], heights[position + 1])
  distanceValue[position] = distanceToRange(heights[position], lowNeighbor[position], highNeighbor[position])

proc localCost(position: int, replacement: int64): int64 =
  if position == 1:
    return magnitude(replacement - heights[2])
  if position == treeCount:
    return magnitude(heights[treeCount - 1] - replacement)
  return magnitude(heights[position - 1] - heights[position + 1]) +
         2 * distanceToRange(replacement, lowNeighbor[position], highNeighbor[position])

proc swapDelta(leftIndex: int, rightIndex: int): int64 =
  if rightIndex == leftIndex + 1:
    var change: int64 = 0
    if leftIndex > 1:
      change = change + magnitude(heights[leftIndex - 1] - heights[rightIndex]) -
                       magnitude(heights[leftIndex - 1] - heights[leftIndex])
    if rightIndex < treeCount:
      change = change + magnitude(heights[leftIndex] - heights[rightIndex + 1]) -
                        magnitude(heights[rightIndex] - heights[rightIndex + 1])
    return change
  return localCost(leftIndex, heights[rightIndex]) - localCost(leftIndex, heights[leftIndex]) +
         localCost(rightIndex, heights[leftIndex]) - localCost(rightIndex, heights[rightIndex])

for position in [1, treeCount]:
  for other in 1 .. treeCount:
    if other != position:
      let change = if position < other: swapDelta(position, other) else: swapDelta(other, position)
      answers[position] = min(answers[position], baseDisorder + change)

var interiorPositions = newSeq[int](treeCount - 2)
for position in 2 .. treeCount - 1:
  interiorPositions[position - 2] = position
interiorPositions.sort(proc(left: int, right: int): int = ascendingHeight(heights, left, right))
var heightAtRank = newSeq[int64](treeCount - 2)
var rankOfPosition = newSeq[int](treeCount + 1)
for rank in 0 .. interiorPositions.len - 1:
  let position = interiorPositions[rank]
  heightAtRank[rank] = heights[position]
  rankOfPosition[position] = rank

var stateTrees: array[0 .. 2, array[0 .. 2, MinTree]]
for state in 0 .. 2:
  for offset in 0 .. 2:
    stateTrees[state][offset] = newMinTree(interiorPositions.len)

for position in 2 .. treeCount - 1:
  let rank = rankOfPosition[position]
  let firstValue = lowNeighbor[position] - distanceValue[position]
  stateTrees[0][0].setLeaf(rank, firstValue - heights[position])
  stateTrees[0][1].setLeaf(rank, firstValue)
  stateTrees[0][2].setLeaf(rank, firstValue + heights[position])

var moveEvents = newSeq[MoveEvent](2 * interiorPositions.len)
var eventCount = 0
for position in 2 .. treeCount - 1:
  moveEvents[eventCount] = MoveEvent(coordinate: lowNeighbor[position],
                                     treeIndex: rankOfPosition[position], targetState: 1)
  eventCount += 1
  moveEvents[eventCount] = MoveEvent(coordinate: highNeighbor[position] + 1,
                                     treeIndex: rankOfPosition[position], targetState: 2)
  eventCount += 1
moveEvents.setLen eventCount
moveEvents.sort(byCoordinate)

var eventCursor = 0
for queryIndex in 0 .. interiorPositions.len - 1:
  let position = interiorPositions[queryIndex]
  let currentHeight = heights[position]
  while eventCursor < moveEvents.len and moveEvents[eventCursor].coordinate <= currentHeight:
    let moveEvent = moveEvents[eventCursor]
    let movedPosition = interiorPositions[moveEvent.treeIndex]
    let target = moveEvent.targetState
    var baseValue: int64 = 0
    if target == 1:
      baseValue = -distanceValue[movedPosition]
    else:
      baseValue = -highNeighbor[movedPosition] - distanceValue[movedPosition]
    var offsetValues = [-heights[movedPosition], 0, heights[movedPosition]]
    for offset in 0 .. 2:
      stateTrees[target][offset].setLeaf(moveEvent.treeIndex, baseValue + offsetValues[offset])
      stateTrees[target - 1][offset].setLeaf(moveEvent.treeIndex, treeInfinity)
    eventCursor += 1

  var excludedCount = 0
  var excludedStates = newSeq[int](3)
  var excludedRanks = newSeq[int](3)
  var excludedPositions = newSeq[int](3)
  var candidatePosition = position - 1
  while candidatePosition <= position + 1:
    if candidatePosition >= 2 and candidatePosition <= treeCount - 1:
      var currentState = 0
      if currentHeight >= lowNeighbor[candidatePosition] and currentHeight <= highNeighbor[candidatePosition]:
        currentState = 1
      elif currentHeight > highNeighbor[candidatePosition]:
        currentState = 2
      let rank = rankOfPosition[candidatePosition]
      excludedStates[excludedCount] = currentState
      excludedRanks[excludedCount] = rank
      excludedPositions[excludedCount] = candidatePosition
      excludedCount += 1
      for offset in 0 .. 2:
        stateTrees[currentState][offset].setLeaf(rank, treeInfinity)
    candidatePosition += 1

  let lowEnd = lowerBound(heightAtRank, lowNeighbor[position]) - 1
  let middleStart = lowEnd + 1
  let middleEnd = upperBound(heightAtRank, highNeighbor[position]) - 1
  let highStart = middleEnd + 1
  var bestCross = treeInfinity
  for state in 0 .. 2:
    var common: int64 = 0
    if state == 0:
      common = -currentHeight
    elif state == 2:
      common = currentHeight
    let lowValue = stateTrees[state][0].queryRange(0, lowEnd) + common +
                   lowNeighbor[position] - distanceValue[position]
    let middleValue = stateTrees[state][1].queryRange(middleStart, middleEnd) + common -
                      distanceValue[position]
    let highValue = stateTrees[state][2].queryRange(highStart, heightAtRank.len - 1) + common -
                    highNeighbor[position] - distanceValue[position]
    bestCross = min(bestCross, min(lowValue, min(middleValue, highValue)))
  if bestCross < treeInfinity div 2:
    answers[position] = min(answers[position], baseDisorder + 2 * bestCross)

  if position > 1:
    answers[position] = min(answers[position], baseDisorder + swapDelta(position - 1, position))
  if position < treeCount:
    answers[position] = min(answers[position], baseDisorder + swapDelta(position, position + 1))
  answers[position] = min(answers[position], baseDisorder + swapDelta(1, position))
  answers[position] = min(answers[position], baseDisorder + swapDelta(position, treeCount))

  for excludedIndex in 0 .. excludedCount - 1:
    let excludedPosition = excludedPositions[excludedIndex]
    let excludedState = excludedStates[excludedIndex]
    let rank = excludedRanks[excludedIndex]
    var baseValue: int64 = 0
    if excludedState == 0:
      baseValue = lowNeighbor[excludedPosition] - distanceValue[excludedPosition]
    elif excludedState == 1:
      baseValue = -distanceValue[excludedPosition]
    else:
      baseValue = -highNeighbor[excludedPosition] - distanceValue[excludedPosition]
    var offsetValues = [-heights[excludedPosition], 0, heights[excludedPosition]]
    for offset in 0 .. 2:
      stateTrees[excludedState][offset].setLeaf(rank, baseValue + offsetValues[offset])

for position in 1 .. treeCount:
  appendOutput($answers[position])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
