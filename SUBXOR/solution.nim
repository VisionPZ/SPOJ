const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const highestBit = 20
const missingChild = -1

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

var zeroChild = newSeq[int]()
var oneChild = newSeq[int]()
var nodeCountAt = newSeq[int]()

proc resetTrie() =
  zeroChild = newSeq[int](1)
  oneChild = newSeq[int](1)
  nodeCountAt = newSeq[int](1)
  zeroChild[0] = missingChild
  oneChild[0] = missingChild
  nodeCountAt[0] = 0

proc insertPrefix(prefixValue: int) =
  var nodeIndex = 0
  nodeCountAt[nodeIndex] += 1
  for bitIndex in countdown(highestBit, 0):
    let bitValue = (prefixValue shr bitIndex) and 1
    if bitValue == 0:
      if zeroChild[nodeIndex] == missingChild:
        zeroChild[nodeIndex] = zeroChild.len
        zeroChild.add missingChild
        oneChild.add missingChild
        nodeCountAt.add 0
      nodeIndex = zeroChild[nodeIndex]
    else:
      if oneChild[nodeIndex] == missingChild:
        oneChild[nodeIndex] = oneChild.len
        zeroChild.add missingChild
        oneChild.add missingChild
        nodeCountAt.add 0
      nodeIndex = oneChild[nodeIndex]
    nodeCountAt[nodeIndex] += 1

proc countBelowLimit(prefixValue, limitValue: int): int =
  var nodeIndex = 0
  var totalCount = 0
  for bitIndex in countdown(highestBit, 0):
    if nodeIndex == missingChild:
      break
    let prefixBit = (prefixValue shr bitIndex) and 1
    let limitBit = (limitValue shr bitIndex) and 1
    if limitBit == 1:
      var equalBranch: int
      var greaterBranch: int
      if prefixBit == 0:
        equalBranch = zeroChild[nodeIndex]
        greaterBranch = oneChild[nodeIndex]
      else:
        equalBranch = oneChild[nodeIndex]
        greaterBranch = zeroChild[nodeIndex]
      if equalBranch != missingChild:
        totalCount += nodeCountAt[equalBranch]
      nodeIndex = greaterBranch
    else:
      if prefixBit == 0:
        nodeIndex = zeroChild[nodeIndex]
      else:
        nodeIndex = oneChild[nodeIndex]
  return totalCount

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let limitValue = nextInt(inputData, scanPos)
  resetTrie()
  insertPrefix(0)
  var prefixXor = 0
  var subarrayCount: int64 = 0
  for elementIndex in 0 .. elementCount - 1:
    prefixXor = prefixXor xor nextInt(inputData, scanPos)
    subarrayCount += int64(countBelowLimit(prefixXor, limitValue))
    insertPrefix(prefixXor)
  appendOutput($subarrayCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
