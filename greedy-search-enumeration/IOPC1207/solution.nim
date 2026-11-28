const flushBlockBytes = 1 shl 17

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

proc pushDown(tree: var seq[int], lazyFlags: var seq[int], nodeIndex: int,
              leftBound: int, middle: int, rightBound: int) =
  if lazyFlags[nodeIndex] == 1:
    let leftChild = nodeIndex * 2
    let rightChild = leftChild + 1
    tree[leftChild] = (middle - leftBound + 1) - tree[leftChild]
    lazyFlags[leftChild] = lazyFlags[leftChild] xor 1
    tree[rightChild] = (rightBound - middle) - tree[rightChild]
    lazyFlags[rightChild] = lazyFlags[rightChild] xor 1
    lazyFlags[nodeIndex] = 0

proc flipRange(tree: var seq[int], lazyFlags: var seq[int], nodeIndex: int,
               leftBound: int, rightBound: int, flipLeft: int, flipRight: int) =
  if flipRight < leftBound or rightBound < flipLeft:
    return
  if flipLeft <= leftBound and rightBound <= flipRight:
    tree[nodeIndex] = (rightBound - leftBound + 1) - tree[nodeIndex]
    lazyFlags[nodeIndex] = lazyFlags[nodeIndex] xor 1
    return
  let middle = (leftBound + rightBound) div 2
  pushDown(tree, lazyFlags, nodeIndex, leftBound, middle, rightBound)
  let leftChild = nodeIndex * 2
  let rightChild = leftChild + 1
  flipRange(tree, lazyFlags, leftChild, leftBound, middle, flipLeft, flipRight)
  flipRange(tree, lazyFlags, rightChild, middle + 1, rightBound, flipLeft, flipRight)
  tree[nodeIndex] = tree[leftChild] + tree[rightChild]

proc countOnes(tree: var seq[int], lazyFlags: var seq[int], nodeIndex: int,
               leftBound: int, rightBound: int, queryLeft: int, queryRight: int): int =
  if queryRight < leftBound or rightBound < queryLeft:
    return 0
  if queryLeft <= leftBound and rightBound <= queryRight:
    return tree[nodeIndex]
  let middle = (leftBound + rightBound) div 2
  pushDown(tree, lazyFlags, nodeIndex, leftBound, middle, rightBound)
  let leftChild = nodeIndex * 2
  let rightChild = leftChild + 1
  return countOnes(tree, lazyFlags, leftChild, leftBound, middle, queryLeft, queryRight) +
      countOnes(tree, lazyFlags, rightChild, middle + 1, rightBound, queryLeft, queryRight)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let xExtent = nextInt(inputData, scanPos)
  let yExtent = nextInt(inputData, scanPos)
  let zExtent = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var xTree = newSeq[int](4 * xExtent + 5)
  var xLazy = newSeq[int](4 * xExtent + 5)
  var yTree = newSeq[int](4 * yExtent + 5)
  var yLazy = newSeq[int](4 * yExtent + 5)
  var zTree = newSeq[int](4 * zExtent + 5)
  var zLazy = newSeq[int](4 * zExtent + 5)
  for queryIndex in 1 .. queryCount:
    let queryType = nextInt(inputData, scanPos)
    if queryType <= 2:
      let flipLeft = nextInt(inputData, scanPos)
      let flipRight = nextInt(inputData, scanPos)
      if queryType == 0:
        flipRange(xTree, xLazy, 1, 0, xExtent - 1, flipLeft, flipRight)
      elif queryType == 1:
        flipRange(yTree, yLazy, 1, 0, yExtent - 1, flipLeft, flipRight)
      else:
        flipRange(zTree, zLazy, 1, 0, zExtent - 1, flipLeft, flipRight)
    else:
      let xLow = nextInt(inputData, scanPos)
      let yLow = nextInt(inputData, scanPos)
      let zLow = nextInt(inputData, scanPos)
      let xHigh = nextInt(inputData, scanPos)
      let yHigh = nextInt(inputData, scanPos)
      let zHigh = nextInt(inputData, scanPos)
      let xOnes = countOnes(xTree, xLazy, 1, 0, xExtent - 1, xLow, xHigh)
      let yOnes = countOnes(yTree, yLazy, 1, 0, yExtent - 1, yLow, yHigh)
      let zOnes = countOnes(zTree, zLazy, 1, 0, zExtent - 1, zLow, zHigh)
      let spanX = int64(xHigh - xLow + 1)
      let spanY = int64(yHigh - yLow + 1)
      let spanZ = int64(zHigh - zLow + 1)
      let signedSum = (spanX - 2 * int64(xOnes)) * (spanY - 2 * int64(yOnes)) *
          (spanZ - 2 * int64(zOnes))
      let answer = (spanX * spanY * spanZ - signedSum) div 2
      appendOutput($answer)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
