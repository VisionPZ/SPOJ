const flushBlockBytes = 1 shl 17
const maxLength = 10000
const maxGain = 10000
const maxRoot = 101

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

proc integerRoot(value: int): int =
  var low = 1
  var high = maxRoot
  while low < high:
    let middle = (low + high + 1) div 2
    if middle * middle <= value:
      low = middle
    else:
      high = middle - 1
  return low

type Query = object
  lengthValue: int
  moveCount: int
  caseIndex: int

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[Query](caseCount)
var lengthCounts = newSeq[int](maxLength + 2)
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex].lengthValue = nextInt(inputData, scanPos)
  queries[caseIndex].moveCount = nextInt(inputData, scanPos)
  queries[caseIndex].caseIndex = caseIndex
  lengthCounts[queries[caseIndex].lengthValue] += 1

var lengthOffsets = newSeq[int](maxLength + 2)
var runningOffset = 0
for lengthValue in 1 .. maxLength:
  lengthOffsets[lengthValue] = runningOffset
  runningOffset += lengthCounts[lengthValue]
var sortedQueries = newSeq[Query](caseCount)
for caseIndex in 0 .. caseCount - 1:
  let carried = queries[caseIndex]
  let destination = lengthOffsets[carried.lengthValue]
  sortedQueries[destination] = carried
  lengthOffsets[carried.lengthValue] += 1

var chainHeads = newSeq[int](maxLength + 2)
var chainGains = newSeq[int](0)
var gainCount = 0
for value in 1 .. maxLength:
  chainHeads[value] = gainCount
  var current = value
  while current > 1:
    let child = integerRoot(current)
    chainGains.add(current - child)
    gainCount += 1
    current = child
  chainHeads[value + 1] = gainCount

var countTree = newSeq[int](maxGain + 2)
var sumTree = newSeq[int64](maxGain + 2)

proc addGain(gain: int) =
  var index = gain
  while index <= maxGain:
    countTree[index] += 1
    sumTree[index] += int64(gain)
    index += index and -index

proc prefixCount(index: int): int =
  var total = 0
  var cursor = index
  while cursor > 0:
    total += countTree[cursor]
    cursor -= cursor and -cursor
  return total

proc prefixSum(index: int): int64 =
  var total: int64 = 0
  var cursor = index
  while cursor > 0:
    total += sumTree[cursor]
    cursor -= cursor and -cursor
  return total

var answers = newSeq[int64](caseCount)
var totalCount = 0
var totalSum: int64 = 0
var queryIndex = 0
for lengthValue in 1 .. maxLength:
  for gainPosition in chainHeads[lengthValue] .. chainHeads[lengthValue + 1] - 1:
    addGain(chainGains[gainPosition])
    totalCount += 1
    totalSum += int64(chainGains[gainPosition])
  while queryIndex < caseCount and sortedQueries[queryIndex].lengthValue == lengthValue:
    let moveCount = sortedQueries[queryIndex].moveCount
    var gainSum: int64 = 0
    if moveCount >= totalCount:
      gainSum = totalSum
    else:
      let skipped = totalCount - moveCount
      var bitMask = 1
      while (bitMask shl 1) <= maxGain:
        bitMask = bitMask shl 1
      var lowerIndex = 0
      var accumulated = 0
      while bitMask > 0:
        let nextIndex = lowerIndex + bitMask
        if nextIndex <= maxGain and accumulated + countTree[nextIndex] <= skipped:
          accumulated += countTree[nextIndex]
          lowerIndex = nextIndex
        bitMask = bitMask shr 1
      let chosenIndex = lowerIndex + 1
      if chosenIndex > maxGain:
        gainSum = 0
      else:
        let pointCount = prefixCount(chosenIndex) - accumulated
        let takenAtChosen = pointCount - (skipped - accumulated)
        gainSum = (totalSum - prefixSum(chosenIndex)) +
                  int64(takenAtChosen) * int64(chosenIndex)
    let initialSum = int64(lengthValue) * int64(lengthValue + 1) div 2
    answers[sortedQueries[queryIndex].caseIndex] = initialSum - gainSum
    queryIndex += 1

for caseIndex in 0 .. caseCount - 1:
  appendOutput($answers[caseIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
