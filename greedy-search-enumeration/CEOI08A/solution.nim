const flushBlockBytes = 1 shl 17
const postCost = 20
const treeLoss = 111
const impossibleValue = -1000000000

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

proc crossAt(originX: int, originY: int, firstX: int, firstY: int, secondX: int, secondY: int): int =
  (firstX - originX) * (secondY - originY) - (firstY - originY) * (secondX - originX)

proc insideTriangle(firstX: int, firstY: int, secondX: int, secondY: int,
                    thirdX: int, thirdY: int, pointX: int, pointY: int): bool =
  let firstCheck = crossAt(firstX, firstY, secondX, secondY, pointX, pointY) >= 0
  let secondCheck = crossAt(secondX, secondY, thirdX, thirdY, pointX, pointY) >= 0
  let thirdCheck = crossAt(thirdX, thirdY, firstX, firstY, pointX, pointY) >= 0
  return firstCheck and secondCheck and thirdCheck

let holeCount = nextInt(inputData, scanPos)
let treeCount = nextInt(inputData, scanPos)
var holeX = newSeq[int](holeCount + 1)
var holeY = newSeq[int](holeCount + 1)
var treeX = newSeq[int](treeCount + 1)
var treeY = newSeq[int](treeCount + 1)
for holeIndex in 1 .. holeCount:
  holeX[holeIndex] = nextInt(inputData, scanPos)
  holeY[holeIndex] = nextInt(inputData, scanPos)
for treeIndex in 1 .. treeCount:
  treeX[treeIndex] = nextInt(inputData, scanPos)
  treeY[treeIndex] = nextInt(inputData, scanPos)

var bestScore = 0
for anchorHole in 1 .. holeCount:
  var candidateHoles = newSeq[int](holeCount)
  var candidateCount = 0
  for holeIndex in 1 .. holeCount:
    if holeY[holeIndex] > holeY[anchorHole] or
       (holeY[holeIndex] == holeY[anchorHole] and holeX[holeIndex] > holeX[anchorHole]):
      candidateHoles[candidateCount] = holeIndex
      candidateCount += 1
  if candidateCount < 2:
    continue

  for sortIndex in 1 .. candidateCount - 1:
    let heldHole = candidateHoles[sortIndex]
    var shiftIndex = sortIndex - 1
    while shiftIndex >= 0:
      let earlierHole = candidateHoles[shiftIndex]
      let orientation = crossAt(holeX[anchorHole], holeY[anchorHole],
                                holeX[earlierHole], holeY[earlierHole],
                                holeX[heldHole], holeY[heldHole])
      if orientation > 0:
        break
      candidateHoles[shiftIndex + 1] = earlierHole
      shiftIndex -= 1
    candidateHoles[shiftIndex + 1] = heldHole

  var triangleTrees = newSeq[seq[int]](candidateCount)
  for rowIndex in 0 .. candidateCount - 1:
    triangleTrees[rowIndex] = newSeq[int](candidateCount)
  for firstIndex in 0 .. candidateCount - 2:
    for secondIndex in firstIndex + 1 .. candidateCount - 1:
      let firstHole = candidateHoles[firstIndex]
      let secondHole = candidateHoles[secondIndex]
      var enclosedTrees = 0
      for treeIndex in 1 .. treeCount:
        if insideTriangle(holeX[anchorHole], holeY[anchorHole],
                          holeX[firstHole], holeY[firstHole],
                          holeX[secondHole], holeY[secondHole],
                          treeX[treeIndex], treeY[treeIndex]):
          enclosedTrees += 1
      triangleTrees[firstIndex][secondIndex] = enclosedTrees

  var chainScores = newSeq[seq[int]](candidateCount)
  for rowIndex in 0 .. candidateCount - 1:
    chainScores[rowIndex] = newSeq[int](candidateCount)
    for columnIndex in 0 .. candidateCount - 1:
      chainScores[rowIndex][columnIndex] = impossibleValue
  for firstIndex in 0 .. candidateCount - 2:
    for secondIndex in firstIndex + 1 .. candidateCount - 1:
      let addedScore = treeLoss * triangleTrees[firstIndex][secondIndex] - 3 * postCost
      var bestHere = addedScore
      let middleHole = candidateHoles[firstIndex]
      let lastHole = candidateHoles[secondIndex]
      for previousIndex in 0 .. firstIndex - 1:
        let previousHole = candidateHoles[previousIndex]
        let turn = crossAt(holeX[previousHole], holeY[previousHole],
                           holeX[middleHole], holeY[middleHole],
                           holeX[lastHole], holeY[lastHole])
        if turn > 0 and chainScores[previousIndex][firstIndex] > impossibleValue:
          let extendedScore = chainScores[previousIndex][firstIndex] +
                              treeLoss * triangleTrees[firstIndex][secondIndex] - postCost
          if extendedScore > bestHere:
            bestHere = extendedScore
      chainScores[firstIndex][secondIndex] = bestHere
      if bestHere > bestScore:
        bestScore = bestHere

appendOutput($(treeLoss * treeCount - bestScore))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
