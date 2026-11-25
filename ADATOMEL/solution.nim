const flushBlockBytes = 1 shl 17
const flavorWords = 16

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

proc countBits(value: uint64): int =
  var packedBits = value
  packedBits = packedBits - ((packedBits shr 1) and 0x5555555555555555'u64)
  packedBits = (packedBits and 0x3333333333333333'u64) + ((packedBits shr 2) and 0x3333333333333333'u64)
  packedBits = (packedBits + (packedBits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((packedBits * 0x0101010101010101'u64) shr 56)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let nodeCount = nextInt(inputData, scanPos)
let flavorCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

var parentNodes = newSeq[int](nodeCount)
var depths = newSeq[int](nodeCount)
parentNodes[0] = 0
for nodeIndex in 1 .. nodeCount - 1:
  let parentNode = nextInt(inputData, scanPos)
  parentNodes[nodeIndex] = parentNode
  depths[nodeIndex] = depths[parentNode] + 1
var flavors = newSeq[int](nodeCount)
for node in 0 .. nodeCount - 1:
  flavors[node] = nextInt(inputData, scanPos) - 1

var liftLevels = 1
while (1 shl liftLevels) <= nodeCount:
  liftLevels += 1
var ancestors = newSeq[int](nodeCount * liftLevels)
var jumpBits = newSeq[uint64](nodeCount * liftLevels * flavorWords)
for node in 0 .. nodeCount - 1:
  let baseSlot = node * liftLevels
  ancestors[baseSlot] = parentNodes[node]
  let flavorIndex = flavors[node]
  jumpBits[baseSlot * flavorWords + flavorIndex div 64] =
    jumpBits[baseSlot * flavorWords + flavorIndex div 64] or (1'u64 shl (flavorIndex mod 64))
for level in 1 .. liftLevels - 1:
  for node in 0 .. nodeCount - 1:
    let earlierAncestor = ancestors[node * liftLevels + level - 1]
    ancestors[node * liftLevels + level] = ancestors[earlierAncestor * liftLevels + level - 1]
    let currentSlot = (node * liftLevels + level) * flavorWords
    let previousSlot = (node * liftLevels + level - 1) * flavorWords
    let ancestorSlot = (earlierAncestor * liftLevels + level - 1) * flavorWords
    jumpBits[currentSlot] = jumpBits[previousSlot] or jumpBits[ancestorSlot]
    jumpBits[currentSlot + 1] = jumpBits[previousSlot + 1] or jumpBits[ancestorSlot + 1]
    jumpBits[currentSlot + 2] = jumpBits[previousSlot + 2] or jumpBits[ancestorSlot + 2]
    jumpBits[currentSlot + 3] = jumpBits[previousSlot + 3] or jumpBits[ancestorSlot + 3]
    jumpBits[currentSlot + 4] = jumpBits[previousSlot + 4] or jumpBits[ancestorSlot + 4]
    jumpBits[currentSlot + 5] = jumpBits[previousSlot + 5] or jumpBits[ancestorSlot + 5]
    jumpBits[currentSlot + 6] = jumpBits[previousSlot + 6] or jumpBits[ancestorSlot + 6]
    jumpBits[currentSlot + 7] = jumpBits[previousSlot + 7] or jumpBits[ancestorSlot + 7]
    jumpBits[currentSlot + 8] = jumpBits[previousSlot + 8] or jumpBits[ancestorSlot + 8]
    jumpBits[currentSlot + 9] = jumpBits[previousSlot + 9] or jumpBits[ancestorSlot + 9]
    jumpBits[currentSlot + 10] = jumpBits[previousSlot + 10] or jumpBits[ancestorSlot + 10]
    jumpBits[currentSlot + 11] = jumpBits[previousSlot + 11] or jumpBits[ancestorSlot + 11]
    jumpBits[currentSlot + 12] = jumpBits[previousSlot + 12] or jumpBits[ancestorSlot + 12]
    jumpBits[currentSlot + 13] = jumpBits[previousSlot + 13] or jumpBits[ancestorSlot + 13]
    jumpBits[currentSlot + 14] = jumpBits[previousSlot + 14] or jumpBits[ancestorSlot + 14]
    jumpBits[currentSlot + 15] = jumpBits[previousSlot + 15] or jumpBits[ancestorSlot + 15]

var queryWords = newSeq[uint64](flavorWords)

proc mergeJump(jumpSlot: int) =
  let baseSlot = jumpSlot * flavorWords
  queryWords[0] = queryWords[0] or jumpBits[baseSlot]
  queryWords[1] = queryWords[1] or jumpBits[baseSlot + 1]
  queryWords[2] = queryWords[2] or jumpBits[baseSlot + 2]
  queryWords[3] = queryWords[3] or jumpBits[baseSlot + 3]
  queryWords[4] = queryWords[4] or jumpBits[baseSlot + 4]
  queryWords[5] = queryWords[5] or jumpBits[baseSlot + 5]
  queryWords[6] = queryWords[6] or jumpBits[baseSlot + 6]
  queryWords[7] = queryWords[7] or jumpBits[baseSlot + 7]
  queryWords[8] = queryWords[8] or jumpBits[baseSlot + 8]
  queryWords[9] = queryWords[9] or jumpBits[baseSlot + 9]
  queryWords[10] = queryWords[10] or jumpBits[baseSlot + 10]
  queryWords[11] = queryWords[11] or jumpBits[baseSlot + 11]
  queryWords[12] = queryWords[12] or jumpBits[baseSlot + 12]
  queryWords[13] = queryWords[13] or jumpBits[baseSlot + 13]
  queryWords[14] = queryWords[14] or jumpBits[baseSlot + 14]
  queryWords[15] = queryWords[15] or jumpBits[baseSlot + 15]

proc findCommonAncestor(firstNode, secondNode: int): int =
  var nodeLeft = firstNode
  var nodeRight = secondNode
  if depths[nodeLeft] < depths[nodeRight]:
    swap nodeLeft, nodeRight
  var depthGap = depths[nodeLeft] - depths[nodeRight]
  var level = 0
  while depthGap > 0:
    if (depthGap and 1) == 1:
      nodeLeft = ancestors[nodeLeft * liftLevels + level]
    depthGap = depthGap shr 1
    level += 1
  if nodeLeft == nodeRight:
    return nodeLeft
  for levelIndex in countdown(liftLevels - 1, 0):
    let leftParent = ancestors[nodeLeft * liftLevels + levelIndex]
    let rightParent = ancestors[nodeRight * liftLevels + levelIndex]
    if leftParent != rightParent:
      nodeLeft = leftParent
      nodeRight = rightParent
  return parentNodes[nodeLeft]

proc addUpwardPath(startNode, stopNode: int) =
  var currentNode = startNode
  var depthGap = depths[currentNode] - depths[stopNode]
  var level = 0
  while depthGap > 0:
    if (depthGap and 1) == 1:
      mergeJump(currentNode * liftLevels + level)
      currentNode = ancestors[currentNode * liftLevels + level]
    depthGap = depthGap shr 1
    level += 1

proc addWholePath(firstNode, secondNode: int) =
  let meetingNode = findCommonAncestor(firstNode, secondNode)
  addUpwardPath(firstNode, meetingNode)
  addUpwardPath(secondNode, meetingNode)
  let meetingFlavor = flavors[meetingNode]
  let wordOffset = meetingFlavor div 64
  queryWords[wordOffset] = queryWords[wordOffset] or (1'u64 shl (meetingFlavor mod 64))

for queryIndex in 0 .. queryCount - 1:
  let firstBegin = nextInt(inputData, scanPos)
  let firstEnd = nextInt(inputData, scanPos)
  let secondBegin = nextInt(inputData, scanPos)
  let secondEnd = nextInt(inputData, scanPos)
  let thirdBegin = nextInt(inputData, scanPos)
  let thirdEnd = nextInt(inputData, scanPos)
  queryWords[0] = 0'u64
  queryWords[1] = 0'u64
  queryWords[2] = 0'u64
  queryWords[3] = 0'u64
  queryWords[4] = 0'u64
  queryWords[5] = 0'u64
  queryWords[6] = 0'u64
  queryWords[7] = 0'u64
  queryWords[8] = 0'u64
  queryWords[9] = 0'u64
  queryWords[10] = 0'u64
  queryWords[11] = 0'u64
  queryWords[12] = 0'u64
  queryWords[13] = 0'u64
  queryWords[14] = 0'u64
  queryWords[15] = 0'u64
  addWholePath(firstBegin, firstEnd)
  addWholePath(secondBegin, secondEnd)
  addWholePath(thirdBegin, thirdEnd)
  var distinctFlavors = 0
  for wordIndex in 0 .. flavorWords - 1:
    distinctFlavors += countBits(queryWords[wordIndex])
  appendOutput($distinctFlavors)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
