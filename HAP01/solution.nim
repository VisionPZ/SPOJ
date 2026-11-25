const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const chunkBits = 22
const chunkMask = 4194303

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextUint(data: string, pos: var int): uint64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: uint64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * uint64(10) + uint64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

const tableSize = 1 shl chunkBits
var parityTable = newSeq[int16](tableSize)
var tableIndex = 1
while tableIndex < tableSize:
  parityTable[tableIndex] = int16(tableIndex and 1) - parityTable[tableIndex shr 1]
  tableIndex += 1

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let lowerBound = nextUint(inputData, scanPos)
  let upperBound = nextUint(inputData, scanPos)
  let targetGap = nextInt(inputData, scanPos)
  var matchingCount = 0
  var currentNumber = lowerBound
  while currentNumber <= upperBound:
    let firstChunk = parityTable[int(currentNumber and uint64(chunkMask))]
    let secondChunk = parityTable[int((currentNumber shr chunkBits) and uint64(chunkMask))]
    let thirdChunk = parityTable[int(currentNumber shr (2 * chunkBits))]
    let parityGap = firstChunk + secondChunk + thirdChunk
    let absoluteGap = if parityGap < 0: -parityGap else: parityGap
    if absoluteGap == targetGap:
      matchingCount += 1
    currentNumber += 1
  appendOutput($matchingCount)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
