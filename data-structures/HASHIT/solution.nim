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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc nextLine(data: string, i: var int): string =
  let j = i
  while i < data.len and data[i] != '\n':
    i += 1
  let result = data[j ..< i]
  if i < data.len:
    i += 1
  return result

proc hashKey(keyText: string): int =
  var weighted = 0
  for i in 0..<keyText.len:
    weighted += int(keyText[i]) * (i + 1)
  return (19 * weighted) mod tableSize

proc probeIndex(i: int, probeStep: int): int =
  return (i + probeStep * probeStep + 23 * probeStep) mod tableSize

var tableKeys = newSeq[string](tableSize)
var tableUsed = newSeq[bool](tableSize)

proc findKey(keyText: string): int =
  let i = hashKey(keyText)
  for probeStep in 0..<probeCount:
    let k = probeIndex(i, probeStep)
    if tableUsed[k] and tableKeys[k] == keyText:
      return k
  return -1

proc insertKey(keyText: string) =
  if findKey(keyText) >= 0:
    return
  let i = hashKey(keyText)
  for probeStep in 0..<probeCount:
    let k = probeIndex(i, probeStep)
    if not tableUsed[k]:
      tableUsed[k] = true
      tableKeys[k] = keyText
      return

proc deleteKey(keyText: string) =
  let i = findKey(keyText)
  if i >= 0:
    tableUsed[i] = false
    tableKeys[i] = ""

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, i)
for j in 0..<testCount:
  for k in 0..<tableSize:
    tableUsed[k] = false
    tableKeys[k] = ""
  let operationCount = nextInt(inputData, i)
  if i < inputData.len and inputData[i] == '\n':
    i += 1
  for l in 0..<operationCount:
    let operation = nextLine(inputData, i)
    if operation.len < 4:
      continue
    let keyText = operation.substr(4)
    if operation.startsWith("ADD:"):
      insertKey(keyText)
    elif operation.startsWith("DEL:"):
      deleteKey(keyText)
  var keyCount = 0
  for k in 0..<tableSize:
    if tableUsed[k]:
      keyCount += 1
  appendOutput($keyCount)
  outputBuffer.add '\n'
  for k in 0..<tableSize:
    if tableUsed[k]:
      appendOutput($k)
      outputBuffer.add ':'
      appendOutput(tableKeys[k])
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
