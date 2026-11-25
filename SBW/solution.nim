const flushBlockBytes = 1 shl 17
const highestValueBit = 46

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

var opKind = newSeq[int]()
var opFirst = newSeq[int64]()
var opSecond = newSeq[int64]()
var caseStarts = newSeq[int]()
var insertKeys = newSeq[int64]()

while true:
  let operationCount = nextInt(inputData, scanPos)
  if operationCount == 0:
    break
  caseStarts.add opKind.len
  for operationIndex in 0 .. operationCount - 1:
    let kind = nextInt(inputData, scanPos)
    let firstValue = int64(nextInt(inputData, scanPos))
    let secondValue = int64(nextInt(inputData, scanPos))
    opKind.add kind
    opFirst.add firstValue
    opSecond.add secondValue
    if kind == 2:
      insertKeys.add firstValue

var keyCount = insertKeys.len
if keyCount > 1:
  for outerIndex in 1 .. keyCount - 1:
    let carried = insertKeys[outerIndex]
    var innerIndex = outerIndex - 1
    while innerIndex >= 0 and insertKeys[innerIndex] > carried:
      insertKeys[innerIndex + 1] = insertKeys[innerIndex]
      innerIndex -= 1
    insertKeys[innerIndex + 1] = carried
var uniqueCount = 0
for keyIndex in 0 .. keyCount - 1:
  if keyIndex == 0 or insertKeys[keyIndex] != insertKeys[keyIndex - 1]:
    insertKeys[uniqueCount] = insertKeys[keyIndex]
    uniqueCount += 1
keyCount = uniqueCount

proc findExact(key: int64): int =
  var low = 0
  var high = keyCount - 1
  while low <= high:
    let middle = (low + high) div 2
    if insertKeys[middle] == key:
      return middle
    if insertKeys[middle] < key:
      low = middle + 1
    else:
      high = middle - 1
  return -1

proc lowerBound(key: int64): int =
  var low = 0
  var high = keyCount
  while low < high:
    let middle = (low + high) div 2
    if insertKeys[middle] < key:
      low = middle + 1
    else:
      high = middle
  return low

proc upperBound(key: int64): int =
  var low = 0
  var high = keyCount
  while low < high:
    let middle = (low + high) div 2
    if insertKeys[middle] <= key:
      low = middle + 1
    else:
      high = middle
  return low

var trieZero = newSeq[int](1)
var trieOne = newSeq[int](1)

proc newNode(): int =
  trieZero.add 0
  trieOne.add 0
  return trieZero.len - 1

proc trieInsert(rootIndex: var int, value: int64) =
  if rootIndex == 0:
    rootIndex = newNode()
  var node = rootIndex
  for bit in countdown(highestValueBit, 0):
    let oneBit = int((value shr bit) and 1'i64)
    if oneBit == 0:
      if trieZero[node] == 0:
        let freshNode = newNode()
        trieZero[node] = freshNode
      node = trieZero[node]
    else:
      if trieOne[node] == 0:
        let freshNode = newNode()
        trieOne[node] = freshNode
      node = trieOne[node]

proc trieMaxXor(rootIndex: int, value: int64): int64 =
  if rootIndex == 0:
    return 0
  var node = rootIndex
  var best: int64 = 0
  for bit in countdown(highestValueBit, 0):
    if node == 0:
      break
    let oneBit = int((value shr bit) and 1'i64)
    let wanted = 1 - oneBit
    if wanted == 0 and trieZero[node] != 0:
      best = best or (1'i64 shl bit)
      node = trieZero[node]
    elif wanted == 1 and trieOne[node] != 0:
      best = best or (1'i64 shl bit)
      node = trieOne[node]
    elif oneBit == 0:
      node = trieZero[node]
    else:
      node = trieOne[node]
  return best

var segmentMax = newSeq[int64](1)
var segmentSize = 1

proc segmentInit(count: int) =
  segmentSize = 1
  while segmentSize < count:
    segmentSize = segmentSize * 2
  segmentMax = newSeq[int64](segmentSize * 2)

proc segmentSet(index: int, value: int64) =
  var position = segmentSize + index
  segmentMax[position] = value
  position = position div 2
  while position >= 1:
    var largest = segmentMax[position * 2]
    if segmentMax[position * 2 + 1] > largest:
      largest = segmentMax[position * 2 + 1]
    segmentMax[position] = largest
    position = position div 2

proc segmentQuery(leftIndex, rightIndex: int): int64 =
  var left = segmentSize + leftIndex
  var right = segmentSize + rightIndex
  var best: int64 = 0
  while left < right:
    if (left and 1) != 0:
      if segmentMax[left] > best:
        best = segmentMax[left]
      left += 1
    if (right and 1) != 0:
      right -= 1
      if segmentMax[right] > best:
        best = segmentMax[right]
    left = left div 2
    right = right div 2
  return best

var listActive = newSeq[bool](keyCount)
var listRoot = newSeq[int](keyCount)
var listPrefix = newSeq[int64](keyCount)
var listBest = newSeq[int64](keyCount)

for caseIndex in 0 .. caseStarts.len - 1:
  let caseBegin = caseStarts[caseIndex]
  var caseFinish = opKind.len
  if caseIndex + 1 < caseStarts.len:
    caseFinish = caseStarts[caseIndex + 1]
  for listIndex in 0 .. keyCount - 1:
    listActive[listIndex] = false
    listRoot[listIndex] = 0
    listPrefix[listIndex] = 0
    listBest[listIndex] = 0
  trieZero.setLen(1)
  trieOne.setLen(1)
  segmentInit(keyCount)
  for operationIndex in caseBegin .. caseFinish - 1:
    let kind = opKind[operationIndex]
    let firstValue = opFirst[operationIndex]
    let secondValue = opSecond[operationIndex]
    if kind == 2:
      let listIndex = findExact(firstValue)
      if not listActive[listIndex]:
        listActive[listIndex] = true
        listRoot[listIndex] = 0
        listPrefix[listIndex] = 0
        listBest[listIndex] = 0
        trieInsert(listRoot[listIndex], 0)
      let newPrefix = listPrefix[listIndex] xor secondValue
      let candidate = trieMaxXor(listRoot[listIndex], newPrefix)
      if candidate > listBest[listIndex]:
        listBest[listIndex] = candidate
      trieInsert(listRoot[listIndex], newPrefix)
      listPrefix[listIndex] = newPrefix
      segmentSet(listIndex, listBest[listIndex])
    elif kind == 1:
      let leftIndex = lowerBound(firstValue)
      let rightIndex = upperBound(secondValue)
      for listIndex in leftIndex .. rightIndex - 1:
        if listActive[listIndex]:
          listActive[listIndex] = false
          listRoot[listIndex] = 0
          listPrefix[listIndex] = 0
          listBest[listIndex] = 0
          segmentSet(listIndex, 0)
    else:
      let leftIndex = lowerBound(firstValue)
      let rightIndex = upperBound(secondValue)
      let answer = segmentQuery(leftIndex, rightIndex)
      appendOutput($answer)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
