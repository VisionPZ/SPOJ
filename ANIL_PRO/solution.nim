const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

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

proc treeAdd(tree: var seq[int64], index: int, delta: int64) =
  var position = index
  while position < tree.len:
    tree[position] = (tree[position] + delta) mod modulusValue
    if tree[position] < 0:
      tree[position] += modulusValue
    position += position and (-position)

proc treeSum(tree: seq[int64], index: int): int64 =
  var position = index
  var total: int64 = 0
  while position > 0:
    total = (total + tree[position]) mod modulusValue
    position -= position and (-position)
  return total

proc addRampEvent(index: int, alphaValue: int64, betaValue: int64,
                  fibonacci: seq[int64], alphaTree: var seq[int64],
                  betaTree: var seq[int64], alphaWeightTree: var seq[int64],
                  betaWeightTree: var seq[int64]) =
  let alphaWeight = alphaValue * fibonacci[index] mod modulusValue
  let betaWeight = betaValue * fibonacci[index + 1] mod modulusValue
  treeAdd(alphaTree, index, alphaValue)
  treeAdd(betaTree, index, betaValue)
  treeAdd(alphaWeightTree, index, alphaWeight)
  treeAdd(betaWeightTree, index, betaWeight)

proc prefixTotal(limitIndex: int, fibonacci: seq[int64],
                 alphaTree: seq[int64], betaTree: seq[int64],
                 alphaWeightTree: seq[int64], betaWeightTree: seq[int64]): int64 =
  if limitIndex <= 0:
    return 0
  let leadingAlpha = fibonacci[limitIndex + 1] * treeSum(alphaTree, limitIndex)
  let leadingBeta = fibonacci[limitIndex + 2] * treeSum(betaTree, limitIndex)
  var total = leadingAlpha + leadingBeta -
              treeSum(alphaWeightTree, limitIndex) -
              treeSum(betaWeightTree, limitIndex)
  total = total mod modulusValue
  if total < 0:
    total += modulusValue
  return total

let arraySize = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)
var fibonacci = newSeq[int64](arraySize + 3)
fibonacci[1] = 1
fibonacci[2] = 1
for index in 3 .. arraySize + 2:
  fibonacci[index] = (fibonacci[index - 1] + fibonacci[index - 2]) mod modulusValue
var alphaTree = newSeq[int64](arraySize + 2)
var betaTree = newSeq[int64](arraySize + 2)
var alphaWeightTree = newSeq[int64](arraySize + 2)
var betaWeightTree = newSeq[int64](arraySize + 2)

for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  let leftBound = nextInt(inputData, scanPos)
  let rightBound = nextInt(inputData, scanPos)
  if operationType == 0:
    let stopIndex = rightBound + 1
    if leftBound == 1:
      addRampEvent(leftBound, 0, int64(1), fibonacci, alphaTree, betaTree,
                   alphaWeightTree, betaWeightTree)
      addRampEvent(stopIndex, 0, int64(-1), fibonacci, alphaTree, betaTree,
                   alphaWeightTree, betaWeightTree)
    else:
      let leftSign = if leftBound mod 2 == 0: int64(1) else: int64(-1)
      let alphaValue = leftSign * fibonacci[leftBound - 1] mod modulusValue
      let betaValue = -leftSign * fibonacci[leftBound - 2] mod modulusValue
      addRampEvent(leftBound, alphaValue, betaValue, fibonacci, alphaTree,
                   betaTree, alphaWeightTree, betaWeightTree)
      addRampEvent(stopIndex, -alphaValue, -betaValue, fibonacci, alphaTree,
                   betaTree, alphaWeightTree, betaWeightTree)
  else:
    let answer = (prefixTotal(rightBound, fibonacci, alphaTree, betaTree,
                              alphaWeightTree, betaWeightTree) -
                  prefixTotal(leftBound - 1, fibonacci, alphaTree, betaTree,
                               alphaWeightTree, betaWeightTree) +
                  modulusValue) mod modulusValue
    appendOutput($answer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
