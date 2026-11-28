const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  maxRepresentationLength = 8
  maxQueryValue = 32000
  hashCapacity = 1 shl 16
  hashMultiplier = 1103515245

const readChunkBytes = 1 shl 20

var inputData = newString(readChunkBytes)
var filledBytes = 0
while true:
  if filledBytes + readChunkBytes > inputData.len:
    inputData.setLen(inputData.len + readChunkBytes)
  let bytesRead = stdin.readBuffer(addr inputData[filledBytes], readChunkBytes)
  if bytesRead <= 0: break
  filledBytes += bytesRead
inputData.setLen(filledBytes)

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  LengthTable = object
    occupied: seq[bool]
    keys: seq[int]
    lengths: seq[int]

proc newLengthTable(): LengthTable =
  result.occupied = newSeq[bool](hashCapacity)
  result.keys = newSeq[int](hashCapacity)
  result.lengths = newSeq[int](hashCapacity)

proc clearLengthTable(table: var LengthTable) =
  for i in 0..<hashCapacity:
    table.occupied[i] = false

proc slotFor(key: int): int =
  var magnitude = key
  if magnitude < 0: magnitude = -magnitude
  return (magnitude * hashMultiplier) and (hashCapacity - 1)

proc getLength(table: var LengthTable, key: int): int =
  var slot = slotFor(key)
  while table.occupied[slot]:
    if table.keys[slot] == key: return table.lengths[slot]
    slot = (slot + 1) and (hashCapacity - 1)
  return 0

proc putLength(table: var LengthTable, key, value: int) =
  var slot = slotFor(key)
  while table.occupied[slot]:
    if table.keys[slot] == key:
      table.lengths[slot] = value
      return
    slot = (slot + 1) and (hashCapacity - 1)
  table.occupied[slot] = true
  table.keys[slot] = key
  table.lengths[slot] = value

var lengthTable = newLengthTable()
var valueBuckets: array[maxRepresentationLength + 1, seq[int]]
var currentTotal = 0

proc noteValue(value: int) =
  let existing = getLength(lengthTable, value)
  if existing == 0 or existing > currentTotal:
    putLength(lengthTable, value, currentTotal)
    valueBuckets[currentTotal].add value

proc buildAnswers(digit: int): seq[int] =
  clearLengthTable(lengthTable)
  for i in 0..maxRepresentationLength:
    valueBuckets[i].setLen 0
  var repdigit = 0
  for i in 1..maxRepresentationLength:
    repdigit = repdigit * 10 + digit
    putLength(lengthTable, repdigit, i)
    valueBuckets[i].add repdigit
  for totalLength in 2..maxRepresentationLength:
    currentTotal = totalLength
    for leftLength in 1..<totalLength:
      let rightLength = totalLength - leftLength
      for leftValue in valueBuckets[leftLength]:
        if getLength(lengthTable, leftValue) != leftLength: continue
        for rightValue in valueBuckets[rightLength]:
          if getLength(lengthTable, rightValue) != rightLength: continue
          noteValue(leftValue + rightValue)
          noteValue(leftValue - rightValue)
          noteValue(leftValue * rightValue)
          if rightValue != 0 and leftValue mod rightValue == 0:
            noteValue(leftValue div rightValue)
  result = newSeq[int](maxQueryValue + 1)
  for value in 1..maxQueryValue:
    result[value] = getLength(lengthTable, value)

var answers: array[10, seq[int]]
for digit in 1..9:
  answers[digit] = buildAnswers(digit)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let digit = nextInt(inputData, scanPos)
  let numberCount = nextInt(inputData, scanPos)
  let answerRow = answers[digit]
  for j in 0..<numberCount:
    let queryValue = nextInt(inputData, scanPos)
    let representationLength = answerRow[queryValue]
    if representationLength == 0:
      appendOutput("NO\n")
    else:
      appendOutput($representationLength)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
