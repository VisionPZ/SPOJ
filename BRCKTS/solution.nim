const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  treeArraySize = 1 shl 16
  emptyPrefixValue = 1 shl 25

var
  inputData = ""
  i = 0
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
  while i < inputData.len and ord(inputData[i]) <= spaceCode:
    inc i

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitCode)
    inc i

proc loadBracketWord(wordLength: int) =
  skipWhitespace()
  var j = treeSize
  while j < treeSize + wordLength:
    if inputData[i] == '(':
      segmentSum[j] = 1
      segmentMinPrefix[j] = 1
    else:
      segmentSum[j] = -1
      segmentMinPrefix[j] = -1
    inc j
    inc i
  while j < treeSize + treeSize:
    segmentSum[j] = 0
    segmentMinPrefix[j] = emptyPrefixValue
    inc j

proc rebuildParents() =
  var i = treeSize - 1
  while i >= 1:
    let leftChild = i shl 1
    let rightChild = leftChild or 1
    segmentSum[i] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[i] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    dec i

proc flipBracket(j: int) =
  var i = treeSize + j - 1
  if segmentSum[i] == 1:
    segmentSum[i] = -1
    segmentMinPrefix[i] = -1
  else:
    segmentSum[i] = 1
    segmentMinPrefix[i] = 1
  i = i shr 1
  while i >= 1:
    let leftChild = i shl 1
    let rightChild = leftChild or 1
    segmentSum[i] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[i] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    i = i shr 1

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
  if i >= inputData.len: break
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
  for j in 0 ..< operationCount:
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
