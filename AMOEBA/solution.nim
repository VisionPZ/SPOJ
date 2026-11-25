const flushBlockBytes = 1 shl 17
const digitBase = 10
const growthFactor = 7
const tableKinds = 10

type
  AnswerTable = object
    modulus: int64
    period: int
    tableSize: int
    keys: seq[int64]
    days: seq[int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc buildTable(table: var AnswerTable, digitCount: int) =
  table.modulus = 1
  for digitIndex in 0 .. digitCount - 1:
    table.modulus = table.modulus * digitBase
  var powerValues = newSeq[int64]()
  var powerValue: int64 = 1
  powerValues.add powerValue
  while true:
    powerValue = (powerValue * growthFactor) mod table.modulus
    if powerValue == 1:
      break
    powerValues.add powerValue
  table.period = powerValues.len
  table.tableSize = 1
  while table.tableSize <= table.period:
    table.tableSize = table.tableSize shl 1
  table.keys = newSeq[int64](table.tableSize)
  table.days = newSeq[int](table.tableSize)
  for slotIndex in 0 .. table.tableSize - 1:
    table.keys[slotIndex] = -1
  for exponent in 0 .. table.period - 1:
    let storedValue = powerValues[exponent]
    var slotIndex = int(storedValue mod int64(table.tableSize))
    while table.keys[slotIndex] != -1:
      slotIndex = (slotIndex + 1) mod table.tableSize
    table.keys[slotIndex] = storedValue
    table.days[slotIndex] = exponent + 1

proc findDay(table: AnswerTable, target: int64): int =
  var slotIndex = int(target mod int64(table.tableSize))
  while table.keys[slotIndex] != -1:
    if table.keys[slotIndex] == target:
      return table.days[slotIndex]
    slotIndex = (slotIndex + 1) mod table.tableSize
  return -1

var answerTables = newSeq[AnswerTable](tableKinds)
var tableReady = newSeq[bool](tableKinds)
for tableIndex in 0 .. tableKinds - 1:
  tableReady[tableIndex] = false

while true:
  let queryToken = nextToken(inputData, scanPos)
  if queryToken.len == 0:
    break
  if queryToken.len < 1 or queryToken.len >= tableKinds:
    continue
  let digitCount = queryToken.len
  if not tableReady[digitCount]:
    buildTable(answerTables[digitCount], digitCount)
    tableReady[digitCount] = true
  var targetValue: int64 = 0
  for charIndex in 0 .. queryToken.len - 1:
    targetValue = targetValue * digitBase + int64(int(queryToken[charIndex]) - 48)
  let answerDay = findDay(answerTables[digitCount], targetValue)
  appendOutput($answerDay)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
