const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cardCount = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)

var leftChild = newSeq[int](cardCount + 1)
var rightChild = newSeq[int](cardCount + 1)
var parentNode = newSeq[int](cardCount + 1)
var subtreeSize = newSeq[int](cardCount + 1)
var nodePriority = newSeq[int](cardCount + 1)
var reverseFlag = newSeq[bool](cardCount + 1)

var randomState: uint32 = 2463534242'u32
proc nextPriority(): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState xor (randomState shr 17)
  randomState = randomState xor (randomState shl 5)
  return int(randomState)

proc pullNode(nodeIndex: int) =
  subtreeSize[nodeIndex] = subtreeSize[leftChild[nodeIndex]] + subtreeSize[rightChild[nodeIndex]] + 1
  if leftChild[nodeIndex] != 0:
    parentNode[leftChild[nodeIndex]] = nodeIndex
  if rightChild[nodeIndex] != 0:
    parentNode[rightChild[nodeIndex]] = nodeIndex

proc pushNode(nodeIndex: int) =
  if reverseFlag[nodeIndex]:
    let firstChild = leftChild[nodeIndex]
    let secondChild = rightChild[nodeIndex]
    if firstChild != 0:
      let firstLeft = leftChild[firstChild]
      leftChild[firstChild] = rightChild[firstChild]
      rightChild[firstChild] = firstLeft
      reverseFlag[firstChild] = not reverseFlag[firstChild]
    if secondChild != 0:
      let secondLeft = leftChild[secondChild]
      leftChild[secondChild] = rightChild[secondChild]
      rightChild[secondChild] = secondLeft
      reverseFlag[secondChild] = not reverseFlag[secondChild]
    reverseFlag[nodeIndex] = false

proc mergeTrees(firstRoot: int, secondRoot: int): int =
  if firstRoot == 0:
    if secondRoot != 0:
      parentNode[secondRoot] = 0
    return secondRoot
  if secondRoot == 0:
    parentNode[firstRoot] = 0
    return firstRoot
  if nodePriority[firstRoot] > nodePriority[secondRoot]:
    pushNode(firstRoot)
    let mergedRight = mergeTrees(rightChild[firstRoot], secondRoot)
    rightChild[firstRoot] = mergedRight
    pullNode(firstRoot)
    parentNode[firstRoot] = 0
    return firstRoot
  pushNode(secondRoot)
  let mergedLeft = mergeTrees(firstRoot, leftChild[secondRoot])
  leftChild[secondRoot] = mergedLeft
  pullNode(secondRoot)
  parentNode[secondRoot] = 0
  return secondRoot

proc splitTree(rootIndex: int, prefixSize: int, leftRoot: var int, rightRoot: var int) =
  if rootIndex == 0:
    leftRoot = 0
    rightRoot = 0
    return
  pushNode(rootIndex)
  if subtreeSize[leftChild[rootIndex]] >= prefixSize:
    var newLeft = 0
    splitTree(leftChild[rootIndex], prefixSize, leftRoot, newLeft)
    leftChild[rootIndex] = newLeft
    pullNode(rootIndex)
    parentNode[rootIndex] = 0
    rightRoot = rootIndex
  else:
    var newRight = 0
    splitTree(rightChild[rootIndex], prefixSize - subtreeSize[leftChild[rootIndex]] - 1, newRight, rightRoot)
    rightChild[rootIndex] = newRight
    pullNode(rootIndex)
    parentNode[rootIndex] = 0
    leftRoot = rootIndex

proc nodeAtPosition(rootIndex: int, position: int): int =
  var current = rootIndex
  var remaining = position
  while true:
    pushNode(current)
    let leftSize = subtreeSize[leftChild[current]]
    if remaining <= leftSize:
      current = leftChild[current]
    elif remaining == leftSize + 1:
      return current
    else:
      remaining = remaining - leftSize - 1
      current = rightChild[current]

proc rankOfNode(nodeIndex: int): int =
  var current = nodeIndex
  var answer = subtreeSize[leftChild[current]] + 1
  while parentNode[current] != 0:
    let ancestor = parentNode[current]
    let leftSize = subtreeSize[leftChild[ancestor]]
    let rightSize = subtreeSize[rightChild[ancestor]]
    if reverseFlag[ancestor]:
      if current == leftChild[ancestor]:
        answer = leftSize + 1 - answer
      else:
        answer = leftSize + rightSize + 2 - answer
    elif current == rightChild[ancestor]:
      answer = answer + leftSize + 1
    current = ancestor
  return answer

var treapRoot = 0
for cardNumber in 1 .. cardCount:
  subtreeSize[cardNumber] = 1
  nodePriority[cardNumber] = nextPriority()
  treapRoot = mergeTrees(treapRoot, cardNumber)

for operationIndex in 0 .. operationCount - 1:
  let nephewNumber = nextInt(inputData, scanPos)
  if nephewNumber == 1:
    let leftPosition = nextInt(inputData, scanPos)
    let rightPosition = nextInt(inputData, scanPos)
    var middleTree = 0
    var tailTree = 0
    splitTree(treapRoot, rightPosition, middleTree, tailTree)
    var headTree = 0
    splitTree(middleTree, leftPosition - 1, headTree, middleTree)
    if middleTree != 0:
      let firstChild = leftChild[middleTree]
      leftChild[middleTree] = rightChild[middleTree]
      rightChild[middleTree] = firstChild
      reverseFlag[middleTree] = not reverseFlag[middleTree]
      parentNode[middleTree] = 0
    treapRoot = mergeTrees(mergeTrees(headTree, middleTree), tailTree)
  elif nephewNumber == 2:
    let askedPosition = nextInt(inputData, scanPos)
    appendOutput($(nodeAtPosition(treapRoot, askedPosition)))
    outputBuffer.add '\n'
  else:
    let askedCard = nextInt(inputData, scanPos)
    appendOutput($(rankOfNode(askedCard)))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
