const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const tileCount = 12
const jumpSizes = [1, 3, 6, 12]
const unreachableDistance = 1000

var neighborCounts: array[tileCount, int]
var neighbors: array[tileCount, array[4, int]]
var positionDistance: array[tileCount, array[tileCount, int]]
var tileState: array[tileCount, int]
var solvedDepth = -1
var currentBound = 0

proc buildPositionDistances() =
  for firstPosition in 0 .. tileCount - 1:
    for secondPosition in 0 .. tileCount - 1:
      positionDistance[firstPosition][secondPosition] = unreachableDistance
    positionDistance[firstPosition][firstPosition] = 0
  for firstPosition in 0 .. tileCount - 1:
    for secondPosition in firstPosition + 1 .. tileCount - 1:
      for stepIndex in 0 .. 2:
        if abs(firstPosition - secondPosition) != jumpSizes[stepIndex]: continue
        if firstPosition div jumpSizes[stepIndex + 1] != secondPosition div jumpSizes[stepIndex + 1]: continue
        neighbors[firstPosition][neighborCounts[firstPosition]] = secondPosition
        neighbors[secondPosition][neighborCounts[secondPosition]] = firstPosition
        inc neighborCounts[firstPosition]
        inc neighborCounts[secondPosition]
        positionDistance[firstPosition][secondPosition] = 1
        positionDistance[secondPosition][firstPosition] = 1
        break
  for viaPosition in 0 .. tileCount - 1:
    for firstPosition in 0 .. tileCount - 1:
      for secondPosition in 0 .. tileCount - 1:
        let throughDistance = positionDistance[firstPosition][viaPosition] + positionDistance[viaPosition][secondPosition]
        if throughDistance < positionDistance[firstPosition][secondPosition]:
          positionDistance[firstPosition][secondPosition] = throughDistance

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc startingHeuristic(blankPosition: int): int =
  var total = 0
  for positionIndex in 0 .. tileCount - 1:
    if positionIndex != blankPosition:
      total += positionDistance[positionIndex][tileState[positionIndex]]
  return total

proc searchSolution(blankPosition, previousPosition, heuristicValue, depth: int): int =
  if heuristicValue == 0:
    solvedDepth = depth
    return depth
  if depth + heuristicValue > currentBound:
    return depth + heuristicValue
  var orderedTargets: array[4, int]
  var orderedHeuristics: array[4, int]
  var orderedCount = 0
  let neighborTotal = neighborCounts[blankPosition]
  for neighborIndex in 0 .. neighborTotal - 1:
    let targetPosition = neighbors[blankPosition][neighborIndex]
    if targetPosition == previousPosition: continue
    let movedTile = tileState[targetPosition]
    let nextHeuristic = heuristicValue - positionDistance[targetPosition][movedTile] + positionDistance[blankPosition][movedTile]
    var insertAt = orderedCount
    while insertAt > 0 and nextHeuristic < orderedHeuristics[insertAt - 1]:
      orderedHeuristics[insertAt] = orderedHeuristics[insertAt - 1]
      orderedTargets[insertAt] = orderedTargets[insertAt - 1]
      insertAt -= 1
    orderedHeuristics[insertAt] = nextHeuristic
    orderedTargets[insertAt] = targetPosition
    orderedCount += 1
  var bestCandidate = high(int)
  for moveIndex in 0 .. orderedCount - 1:
    let targetPosition = orderedTargets[moveIndex]
    swap tileState[blankPosition], tileState[targetPosition]
    let candidate = searchSolution(targetPosition, blankPosition, orderedHeuristics[moveIndex], depth + 1)
    swap tileState[blankPosition], tileState[targetPosition]
    if solvedDepth >= 0: return solvedDepth
    if candidate < bestCandidate: bestCandidate = candidate
  return bestCandidate

proc solveCase(blankPosition: int): int =
  let initialHeuristic = startingHeuristic(blankPosition)
  if initialHeuristic == 0: return 0
  solvedDepth = -1
  currentBound = initialHeuristic
  var previousBound = currentBound - 1
  while solvedDepth < 0:
    if currentBound <= previousBound: currentBound = previousBound + 1
    previousBound = currentBound
    currentBound = searchSolution(blankPosition, -1, initialHeuristic, 0)
  return solvedDepth

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
buildPositionDistances()
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  for positionIndex in 0 .. tileCount - 1:
    tileState[positionIndex] = nextInt(inputData, scanPos)
  var blankPosition = 0
  for positionIndex in 0 .. tileCount - 1:
    if tileState[positionIndex] == 0: blankPosition = positionIndex
  appendOutput($(solveCase(blankPosition)))

stdout.write outputBuffer
