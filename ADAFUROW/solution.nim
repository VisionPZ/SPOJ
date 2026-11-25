const flushBlockBytes = 1 shl 17
const furrowLimit = 20000
const bitsPerWord = 64
const wordCount = furrowLimit div bitsPerWord + 1

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

proc skipSeparators(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1

proc countBits(value: uint64): int =
  var packedBits = value
  packedBits = packedBits - ((packedBits shr 1) and 0x5555555555555555'u64)
  packedBits = (packedBits and 0x3333333333333333'u64) + ((packedBits shr 2) and 0x3333333333333333'u64)
  packedBits = (packedBits + (packedBits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((packedBits * 0x0101010101010101'u64) shr 56)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let queryCount = nextInt(inputData, scanPos)
var furrowBits = newSeq[uint64]((furrowLimit + 1) * wordCount)

for queryIndex in 0 .. queryCount - 1:
  skipSeparators(inputData, scanPos)
  let operationChar = inputData[scanPos]
  scanPos += 1
  let firstFurrow = nextInt(inputData, scanPos)
  let secondFurrow = nextInt(inputData, scanPos)
  if operationChar == '+' or operationChar == '-':
    let wordOffset = firstFurrow * wordCount + secondFurrow div bitsPerWord
    let kindMask = 1'u64 shl (secondFurrow mod bitsPerWord)
    if operationChar == '+':
      furrowBits[wordOffset] = furrowBits[wordOffset] or kindMask
    else:
      furrowBits[wordOffset] = furrowBits[wordOffset] and not kindMask
  else:
    var kindTotal = 0
    let firstBase = firstFurrow * wordCount
    let secondBase = secondFurrow * wordCount
    if operationChar == 'v':
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] or furrowBits[secondBase + wordIndex])
    elif operationChar == '^':
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] and furrowBits[secondBase + wordIndex])
    elif operationChar == '!':
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] xor furrowBits[secondBase + wordIndex])
    else:
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] and not furrowBits[secondBase + wordIndex])
    appendOutput($kindTotal)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
