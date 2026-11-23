import std/strutils

const firstDigitValue = 48
const tableSize = 101
const probeCount = 20
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextLine(data: string, position: var int): string =
  let startPos = position
  while position < data.len and data[position] != '\n':
    position += 1
  let result = data[startPos ..< position]
  if position < data.len:
    position += 1
  return result

proc hashKey(keyText: string): int =
  var weighted = 0
  for index in 0..<keyText.len:
    weighted += int(keyText[index]) * (index + 1)
  return (19 * weighted) mod tableSize

proc probeIndex(startIndex: int, probeStep: int): int =
  return (startIndex + probeStep * probeStep + 23 * probeStep) mod tableSize

var tableKeys = newSeq[string](tableSize)
var tableUsed = newSeq[bool](tableSize)

proc findKey(keyText: string): int =
  let startIndex = hashKey(keyText)
  for probeStep in 0..<probeCount:
    let slotIndex = probeIndex(startIndex, probeStep)
    if tableUsed[slotIndex] and tableKeys[slotIndex] == keyText:
      return slotIndex
  return -1

proc insertKey(keyText: string) =
  if findKey(keyText) >= 0:
    return
  let startIndex = hashKey(keyText)
  for probeStep in 0..<probeCount:
    let slotIndex = probeIndex(startIndex, probeStep)
    if not tableUsed[slotIndex]:
      tableUsed[slotIndex] = true
      tableKeys[slotIndex] = keyText
      return

proc deleteKey(keyText: string) =
  let foundIndex = findKey(keyText)
  if foundIndex >= 0:
    tableUsed[foundIndex] = false
    tableKeys[foundIndex] = ""

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0..<testCount:
  for slotIndex in 0..<tableSize:
    tableUsed[slotIndex] = false
    tableKeys[slotIndex] = ""
  let operationCount = nextInt(inputData, scanPos)
  if scanPos < inputData.len and inputData[scanPos] == '\n':
    scanPos += 1
  for operationIndex in 0..<operationCount:
    let operation = nextLine(inputData, scanPos)
    if operation.len < 4:
      continue
    let keyText = operation.substr(4)
    if operation.startsWith("ADD:"):
      insertKey(keyText)
    elif operation.startsWith("DEL:"):
      deleteKey(keyText)
  var keyCount = 0
  for slotIndex in 0..<tableSize:
    if tableUsed[slotIndex]:
      keyCount += 1
  appendOutput($keyCount)
  outputBuffer.add '\n'
  for slotIndex in 0..<tableSize:
    if tableUsed[slotIndex]:
      appendOutput($slotIndex)
      outputBuffer.add ':'
      appendOutput(tableKeys[slotIndex])
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
