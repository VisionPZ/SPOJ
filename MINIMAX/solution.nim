{.push checks: off.}

const firstDigitValue = 48
const largeSentinel = 1000000000
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  let inputLength = inputData.len
  while scanPos < inputLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var numberValue = 0
  while scanPos < inputLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    numberValue = numberValue * 10 + (int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return numberValue

let inputData = readAll(stdin)
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let inputCount = nextInt(inputData, scanPos)
  let sorterCount = nextInt(inputData, scanPos)
  var baseSize = 1
  while baseSize <= inputCount:
    baseSize = baseSize shl 1
  var tree = newSeq[int](baseSize shl 1)
  for nodeIndex in 0 ..< tree.len:
    tree[nodeIndex] = largeSentinel
  tree[baseSize + 1] = 0
  var walkIndex = baseSize + 1
  walkIndex = walkIndex shr 1
  while walkIndex >= 1:
    tree[walkIndex] = 0
    walkIndex = walkIndex shr 1
  var bestCosts = newSeq[int](inputCount + 1)
  for position in 0 .. inputCount:
    bestCosts[position] = largeSentinel
  bestCosts[1] = 0
  for sorterIndex in 0 ..< sorterCount:
    let leftEdge = nextInt(inputData, scanPos)
    let rightEdge = nextInt(inputData, scanPos)
    var lowNode = leftEdge + baseSize
    var highNode = rightEdge + baseSize
    var bestEarlier = largeSentinel
    while lowNode <= highNode:
      if (lowNode and 1) != 0:
        if tree[lowNode] < bestEarlier:
          bestEarlier = tree[lowNode]
        lowNode += 1
      if (highNode and 1) == 0:
        if tree[highNode] < bestEarlier:
          bestEarlier = tree[highNode]
        highNode -= 1
      lowNode = lowNode shr 1
      highNode = highNode shr 1
    let trialCost = bestEarlier + 1
    if trialCost < bestCosts[rightEdge]:
      bestCosts[rightEdge] = trialCost
      var nodeIndex = rightEdge + baseSize
      tree[nodeIndex] = trialCost
      nodeIndex = nodeIndex shr 1
      while nodeIndex >= 1:
        let leftChild = tree[nodeIndex shl 1]
        let rightChild = tree[(nodeIndex shl 1) + 1]
        var childMinimum = leftChild
        if rightChild < childMinimum:
          childMinimum = rightChild
        if childMinimum == tree[nodeIndex]:
          break
        tree[nodeIndex] = childMinimum
        nodeIndex = nodeIndex shr 1
  outputBuffer.add $bestCosts[inputCount]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

{.pop.}
