const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashBitCount = 18
const hashSize = 1 shl hashBitCount
const hashMask = hashSize - 1

var memoKeys = newSeq[int64](hashSize)
var memoUsed = newSeq[bool](hashSize)
var memoValues = newSeq[int64](hashSize)

proc slotFor(coinNumber: int64): int =
  var mixed = cast[uint64](coinNumber) * 1099511628211'u64
  mixed = mixed xor (mixed shr 29)
  var tableSlot = int(mixed and uint64(hashMask))
  while memoUsed[tableSlot] and memoKeys[tableSlot] != coinNumber:
    tableSlot = (tableSlot + 1) and hashMask
  return tableSlot

proc coinValue(coinNumber: int64): int64 =
  if coinNumber <= 1:
    return coinNumber
  var tableSlot = slotFor(coinNumber)
  if memoUsed[tableSlot] and memoKeys[tableSlot] == coinNumber:
    return memoValues[tableSlot]
  var candidate = coinValue(coinNumber div 2) + coinValue(coinNumber div 3) + coinValue(coinNumber div 4)
  if candidate < coinNumber:
    candidate = coinNumber
  tableSlot = slotFor(coinNumber)
  memoKeys[tableSlot] = coinNumber
  memoUsed[tableSlot] = true
  memoValues[tableSlot] = candidate
  return candidate

proc hasNext(inputData: string, scanPos: int): bool =
  var checkPos = scanPos
  while checkPos < inputData.len and (inputData[checkPos] < '0' or inputData[checkPos] > '9'):
    checkPos += 1
  return checkPos < inputData.len

proc nextInt(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value: int64 = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNext(inputData, scanPos):
  let coinNumber = nextInt(inputData, scanPos)
  appendOutput($(coinValue(coinNumber)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
