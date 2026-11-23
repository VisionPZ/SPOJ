const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  treeArraySize = 1 shl 16
  emptyPrefixValue = 1 shl 25

var
  inputData = ""
  inputPosition = 0
  outputBuffer = ""
  segmentSum = newSeq[int](treeArraySize)
  segmentMinPrefix = newSeq[int](treeArraySize)
  treeSize = 1

proc loadInput() =
  var lineContents = ""
  while readLine(stdin, lineContents):
    inputData.add lineContents
    inputData.add '\n'

proc skipWhitespace() =
  while inputPosition < inputData.len and ord(inputData[inputPosition]) <= spaceCode:
    inc inputPosition

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while inputPosition < inputData.len and inputData[inputPosition] >= '0' and inputData[inputPosition] <= '9':
    result = result * 10 + (ord(inputData[inputPosition]) - firstDigitCode)
    inc inputPosition

proc loadBracketWord(wordLength: int) =
  skipWhitespace()
  var leafIndex = treeSize
  while leafIndex < treeSize + wordLength:
    if inputData[inputPosition] == '(':
      segmentSum[leafIndex] = 1
      segmentMinPrefix[leafIndex] = 1
    else:
      segmentSum[leafIndex] = -1
      segmentMinPrefix[leafIndex] = -1
    inc leafIndex
    inc inputPosition
  while leafIndex < treeSize + treeSize:
    segmentSum[leafIndex] = 0
    segmentMinPrefix[leafIndex] = emptyPrefixValue
    inc leafIndex

proc rebuildParents() =
  var nodeIndex = treeSize - 1
  while nodeIndex >= 1:
    let leftChild = nodeIndex shl 1
    let rightChild = leftChild or 1
    segmentSum[nodeIndex] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[nodeIndex] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    dec nodeIndex

proc flipBracket(bracketPosition: int) =
  var nodeIndex = treeSize + bracketPosition - 1
  if segmentSum[nodeIndex] == 1:
    segmentSum[nodeIndex] = -1
    segmentMinPrefix[nodeIndex] = -1
  else:
    segmentSum[nodeIndex] = 1
    segmentMinPrefix[nodeIndex] = 1
  nodeIndex = nodeIndex shr 1
  while nodeIndex >= 1:
    let leftChild = nodeIndex shl 1
    let rightChild = leftChild or 1
    segmentSum[nodeIndex] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[nodeIndex] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    nodeIndex = nodeIndex shr 1

proc isBalanced(): bool =
  segmentSum[1] == 0 and segmentMinPrefix[1] >= 0

proc flushOutput(forceAll: bool) =
  if forceAll or outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

loadInput()
var testNumber = 1
while true:
  skipWhitespace()
  if inputPosition >= inputData.len: break
  let wordLength = readInteger()
  treeSize = 1
  while treeSize < wordLength:
    treeSize = treeSize shl 1
  loadBracketWord(wordLength)
  rebuildParents()
  let operationCount = readInteger()
  outputBuffer.add "Test "
  outputBuffer.add $testNumber
  outputBuffer.add ":\n"
  for operationIndex in 0 ..< operationCount:
    let operation = readInteger()
    if operation == 0:
      if isBalanced():
        outputBuffer.add "YES\n"
      else:
        outputBuffer.add "NO\n"
      flushOutput(false)
    else:
      flipBracket(operation)
  inc testNumber
flushOutput(true)
