const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const bitsPerBase = 2

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

proc nextBaseChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let foundChar = data[pos]
  pos += 1
  return foundChar

proc mixKey(key: uint64): uint64 =
  var mixed = key
  mixed = mixed xor (mixed shr 30)
  mixed = mixed * 0xbf58476d1ce4e5b9'u64
  mixed = mixed xor (mixed shr 27)
  mixed = mixed * 0x94d049bb133111eb'u64
  mixed = mixed xor (mixed shr 31)
  return mixed

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let peopleCount = nextInt(inputData, scanPos)
  let sequenceLength = nextInt(inputData, scanPos)
  if peopleCount == 0 and sequenceLength == 0:
    break
  var tableCapacity = 1
  while tableCapacity < peopleCount * 4:
    tableCapacity = tableCapacity shl 1
  var keySlots = newSeq[uint64](tableCapacity)
  var countSlots = newSeq[int](tableCapacity)
  var usedSlots = newSeq[bool](tableCapacity)
  for personIndex in 0 .. peopleCount - 1:
    var sequenceKey: uint64 = 0
    for letterIndex in 0 .. sequenceLength - 1:
      let baseChar = nextBaseChar(inputData, scanPos)
      var letterCode = 0
      case baseChar
      of 'C': letterCode = 1
      of 'G': letterCode = 2
      of 'T': letterCode = 3
      else: letterCode = 0
      sequenceKey = (sequenceKey shl bitsPerBase) or uint64(letterCode)
    var slotIndex = int(mixKey(sequenceKey) and uint64(tableCapacity - 1))
    while usedSlots[slotIndex] and keySlots[slotIndex] != sequenceKey:
      slotIndex = (slotIndex + 1) and (tableCapacity - 1)
    if usedSlots[slotIndex]:
      countSlots[slotIndex] += 1
    else:
      usedSlots[slotIndex] = true
      keySlots[slotIndex] = sequenceKey
      countSlots[slotIndex] = 1
  var copyHistogram = newSeq[int](peopleCount + 1)
  for slotIndex in 0 .. tableCapacity - 1:
    if usedSlots[slotIndex]:
      copyHistogram[countSlots[slotIndex]] += 1
  for copies in 1 .. peopleCount:
    appendOutput($copyHistogram[copies])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
