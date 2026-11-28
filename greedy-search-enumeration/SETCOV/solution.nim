import algorithm

const flushBlockBytes = 1 shl 17
const wordCount = 5
const bitsPerWord = 64
const coveringSets = 300

type ColumnBits = object
  words: array[wordCount, uint64]

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

proc makeEmptyBits(): ColumnBits =
  for wordIndex in 0 .. wordCount - 1:
    result.words[wordIndex] = 0'u64

proc setBit(bits: var ColumnBits, bitIndex: int) =
  let wordIndex = bitIndex div bitsPerWord
  let bitOffset = bitIndex mod bitsPerWord
  bits.words[wordIndex] = bits.words[wordIndex] or (1'u64 shl bitOffset)

proc isEmptyBits(bits: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if bits.words[wordIndex] != 0'u64:
      return false
  return true

proc isSubsetBits(left: ColumnBits, right: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if (left.words[wordIndex] and not right.words[wordIndex]) != 0'u64:
      return false
  return true

proc intersectsBits(left: ColumnBits, right: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if (left.words[wordIndex] and right.words[wordIndex]) != 0'u64:
      return true
  return false

proc equalBits(left: ColumnBits, right: ColumnBits): bool =
  for wordIndex in 0 .. wordCount - 1:
    if left.words[wordIndex] != right.words[wordIndex]:
      return false
  return true

proc commonBits(left: ColumnBits, right: ColumnBits): ColumnBits =
  for wordIndex in 0 .. wordCount - 1:
    result.words[wordIndex] = left.words[wordIndex] and right.words[wordIndex]

proc lowestSetBit(bits: ColumnBits): int =
  for bitIndex in 0 .. coveringSets - 1:
    let wordIndex = bitIndex div bitsPerWord
    let bitOffset = bitIndex mod bitsPerWord
    if (bits.words[wordIndex] and (1'u64 shl bitOffset)) != 0'u64:
      return bitIndex
  return -1

let universeSize = nextInt(inputData, scanPos)
let collectionSize = nextInt(inputData, scanPos)
var columns = newSeq[ColumnBits](universeSize)
for columnIndex in 0 .. universeSize - 1:
  columns[columnIndex] = makeEmptyBits()

for setIndex in 0 .. collectionSize - 1:
  let memberCount = nextInt(inputData, scanPos)
  for memberIndex in 0 .. memberCount - 1:
    let elementIndex = nextInt(inputData, scanPos)
    setBit(columns[elementIndex], setIndex)

var hasUncovered = false
for columnIndex in 0 .. universeSize - 1:
  if isEmptyBits(columns[columnIndex]):
    hasUncovered = true

if hasUncovered:
  appendOutput("-1\n")
else:
  var minimalColumns = newSeq[ColumnBits]()
  for columnIndex in 0 .. universeSize - 1:
    var discardColumn = false
    for otherIndex in 0 .. universeSize - 1:
      if isSubsetBits(columns[otherIndex], columns[columnIndex]):
        if not equalBits(columns[columnIndex], columns[otherIndex]) or columnIndex < otherIndex:
          discardColumn = true
          break
    if not discardColumn:
      minimalColumns.add columns[columnIndex]

  let columnCount = minimalColumns.len
  var visited = newSeq[bool](columnCount)
  var chosenSets = newSeq[int]()
  for startColumn in 0 .. columnCount - 1:
    if visited[startColumn]:
      continue
    var orderedColumns = newSeq[int]()
    var pending = newSeq[int]()
    pending.add startColumn
    while pending.len > 0:
      let currentColumn = pending.pop()
      if visited[currentColumn]:
        continue
      visited[currentColumn] = true
      if orderedColumns.len <= 1:
        orderedColumns.add currentColumn
      else:
        var overlapIndex = 0
        while not intersectsBits(minimalColumns[currentColumn],
                                 minimalColumns[orderedColumns[overlapIndex]]):
          overlapIndex += 1
        if overlapIndex + 1 < orderedColumns.len and
           isSubsetBits(commonBits(minimalColumns[currentColumn],
                                   minimalColumns[orderedColumns[overlapIndex + 1]]),
                        commonBits(minimalColumns[currentColumn],
                                   minimalColumns[orderedColumns[overlapIndex]])):
          orderedColumns.insert(currentColumn, overlapIndex)
        else:
          while true:
            if overlapIndex == orderedColumns.len - 1 or
               not isSubsetBits(commonBits(minimalColumns[currentColumn],
                                           minimalColumns[orderedColumns[overlapIndex]]),
                                commonBits(minimalColumns[currentColumn],
                                           minimalColumns[orderedColumns[overlapIndex + 1]])):
              orderedColumns.insert(currentColumn, overlapIndex + 1)
              break
            overlapIndex += 1
      for otherColumn in 0 .. columnCount - 1:
        if otherColumn != startColumn and
           intersectsBits(minimalColumns[currentColumn], minimalColumns[otherColumn]):
          pending.add otherColumn

    let intervalCount = orderedColumns.len
    var endpoints = newSeq[tuple[first: int, second: int]](intervalCount)
    var cursors = newSeq[int](intervalCount)
    for intervalIndex in 0 .. intervalCount - 1:
      endpoints[intervalIndex].first = intervalIndex * intervalCount
      cursors[intervalIndex] = intervalIndex * intervalCount + 1
    for intervalIndex in 0 .. intervalCount - 1:
      var scanIndex = intervalIndex + 1
      while scanIndex < intervalCount and
            intersectsBits(minimalColumns[orderedColumns[intervalIndex]],
                           minimalColumns[orderedColumns[scanIndex]]):
        scanIndex += 1
      endpoints[intervalIndex].second = cursors[scanIndex - 1]
      cursors[scanIndex - 1] += 1

    var groupStart = 0
    while groupStart < intervalCount:
      var shared = minimalColumns[orderedColumns[groupStart]]
      var groupEnd = groupStart + 1
      while groupEnd < intervalCount and
            endpoints[groupEnd].first < endpoints[groupStart].second:
        shared = commonBits(shared, minimalColumns[orderedColumns[groupEnd]])
        groupEnd += 1
      groupStart = groupEnd
      chosenSets.add(lowestSetBit(shared))

  chosenSets.sort(proc(left, right: int): int =
    if left < right: -1
    elif left > right: 1
    else: 0)

  appendOutput($(chosenSets.len))
  appendOutput("\n")
  for chosenIndex in 0 .. chosenSets.len - 1:
    if chosenIndex > 0:
      appendOutput(" ")
    appendOutput($(chosenSets[chosenIndex]))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
