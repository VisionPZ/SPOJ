const flushBlockBytes = 1 shl 17
const limbMask: uint64 = 0xffffffff'u64

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

proc multiplyAdd(magnitude: var seq[uint32], multiplier: uint64, addend: uint64) =
  var carry = addend
  if magnitude.len > 0:
    for limbIndex in 0 .. magnitude.len - 1:
      let product = uint64(magnitude[limbIndex]) * multiplier + carry
      magnitude[limbIndex] = uint32(product and limbMask)
      carry = product shr 32
  while carry != 0'u64:
    magnitude.add uint32(carry and limbMask)
    carry = carry shr 32

proc divideSmall(magnitude: var seq[uint32], divisor: uint64): uint64 =
  var remainder: uint64 = 0
  var limbIndex = magnitude.len - 1
  while limbIndex >= 0:
    let current = (remainder shl 32) + uint64(magnitude[limbIndex])
    magnitude[limbIndex] = uint32(current div divisor)
    remainder = current mod divisor
    limbIndex -= 1
  while magnitude.len > 0 and magnitude[magnitude.len - 1] == 0:
    magnitude.setLen(magnitude.len - 1)
  return remainder

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
let firstBase = nextInt(inputData, scanPos)
let secondBase = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let sourceCount = nextInt(inputData, scanPos)
  var sourceDigits = newSeq[int](sourceCount)
  for digitIndex in 0 .. sourceCount - 1:
    sourceDigits[digitIndex] = nextInt(inputData, scanPos)
  var magnitude = newSeq[uint32]()
  var sourcePosition = sourceCount - 1
  while sourcePosition >= 0:
    multiplyAdd(magnitude, uint64(firstBase), uint64(sourceDigits[sourcePosition]))
    sourcePosition -= 1
  var groupDivisor: uint64 = 1
  var groupSize = 0
  while groupDivisor * uint64(secondBase) <= limbMask:
    groupDivisor = groupDivisor * uint64(secondBase)
    groupSize += 1
  var targetDigits = newSeq[int]()
  while magnitude.len > 0:
    var chunk = divideSmall(magnitude, groupDivisor)
    for groupIndex in 0 .. groupSize - 1:
      targetDigits.add(int(chunk mod uint64(secondBase)))
      chunk = chunk div uint64(secondBase)
  while targetDigits.len > 1 and targetDigits[targetDigits.len - 1] == 0:
    targetDigits.setLen(targetDigits.len - 1)
  appendOutput($targetDigits.len)
  outputBuffer.add '\n'
  for targetIndex in 0 .. targetDigits.len - 1:
    if targetIndex > 0:
      outputBuffer.add ' '
    appendOutput($targetDigits[targetIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
