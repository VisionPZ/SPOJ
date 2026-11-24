{.push checks: off.}
const firstDigitValue = 48
const firstLetterValue = 97
const flushBlockBytes = 1 shl 18
const tableBits = 15
const tableSize = 1 shl tableBits
const tableMask = uint64(tableSize - 1)
const baseA: uint64 = 1000003
const baseB: uint64 = 1000033
const maxMessageLength = 10000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i += 1
  return value

proc nextWord(): string =
  while i < inputData.len and (inputData[i] < 'a' or inputData[i] > 'z'):
    i += 1
  var startPos = i
  while i < inputData.len and inputData[i] >= 'a' and inputData[i] <= 'z':
    i += 1
  return inputData[startPos .. i - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type HashKey = tuple[firstHash: uint64; secondHash: uint64]

var powerA = newSeq[uint64](maxMessageLength + 1)
var powerB = newSeq[uint64](maxMessageLength + 1)
powerA[0] = 1
powerB[0] = 1
for k in 1 .. maxMessageLength:
  powerA[k] = powerA[k - 1] * baseA
  powerB[k] = powerB[k - 1] * baseB

var prefixA: seq[uint64]
var prefixB: seq[uint64]
var messages: seq[string]
var workKey: array[tableSize, HashKey]
var workMin: array[tableSize, int]
var workMax: array[tableSize, int]
var commonKey: array[tableSize, HashKey]
var commonUsed: array[tableSize, bool]
var commonCount = 0

proc slotOf(key: HashKey): int =
  return int(key.firstHash and tableMask)

proc putWork(key: HashKey, startPos: int) =
  var slot = slotOf(key)
  while workMin[slot] != -1:
    if workKey[slot].firstHash == key.firstHash and workKey[slot].secondHash == key.secondHash:
      if startPos < workMin[slot]: workMin[slot] = startPos
      if startPos > workMax[slot]: workMax[slot] = startPos
      return
    slot = (slot + 1) and (tableSize - 1)
  workKey[slot] = key
  workMin[slot] = startPos
  workMax[slot] = startPos

proc findWork(key: HashKey): int =
  var slot = slotOf(key)
  while workMin[slot] != -1:
    if workKey[slot].firstHash == key.firstHash and workKey[slot].secondHash == key.secondHash:
      return slot
    slot = (slot + 1) and (tableSize - 1)
  return -1

proc putCommon(key: HashKey) =
  var slot = slotOf(key)
  while commonUsed[slot]:
    if commonKey[slot].firstHash == key.firstHash and commonKey[slot].secondHash == key.secondHash:
      return
    slot = (slot + 1) and (tableSize - 1)
  commonKey[slot] = key
  commonUsed[slot] = true
  commonCount += 1

proc prepareWork(message: string, length: int) =
  for slot in 0 .. (tableSize - 1): workMin[slot] = -1
  let messageLen = message.len
  prefixA.setLen(messageLen + 1)
  prefixB.setLen(messageLen + 1)
  prefixA[0] = 0
  prefixB[0] = 0
  for k in 0 .. (messageLen - 1):
    let letter = uint64(ord(message[k]) - firstLetterValue)
    prefixA[k + 1] = prefixA[k] * baseA + letter
    prefixB[k + 1] = prefixB[k] * baseB + letter
  for k in 0 .. (messageLen - length):
    let key: HashKey = (prefixA[k + length] - prefixA[k] * powerA[length],
                        prefixB[k + length] - prefixB[k] * powerB[length])
    putWork(key, k)

proc feasible(length: int): bool =
  prepareWork(messages[0], length)
  for slot in 0 .. (tableSize - 1): commonUsed[slot] = false
  commonCount = 0
  for slot in 0 .. (tableSize - 1):
    if workMin[slot] != -1 and workMax[slot] - workMin[slot] >= length:
      putCommon(workKey[slot])
  if commonCount == 0: return false
  for messageIndex in 1 .. (messages.len - 1):
    prepareWork(messages[messageIndex], length)
    for slot in 0 .. (tableSize - 1):
      if commonUsed[slot]:
        let found = findWork(commonKey[slot])
        if found == -1 or workMax[found] - workMin[found] < length:
          commonUsed[slot] = false
          commonCount -= 1
    if commonCount == 0: return false
  return commonCount > 0

let caseCount = nextInt()
for j in 0 .. (caseCount - 1):
  let messageCount = nextInt()
  messages = newSeq[string](messageCount)
  var shortest = maxMessageLength
  for k in 0 .. (messageCount - 1):
    messages[k] = nextWord()
    if messages[k].len < shortest: shortest = messages[k].len
  var low = 0
  var high = shortest div 2
  while low < high:
    let middle = (low + high + 1) div 2
    if feasible(middle):
      low = middle
    else:
      high = middle - 1
  appendOutput($low)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
