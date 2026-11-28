const flushBlockBytes = 1 shl 17
const maxPersonIndex = 999999
const maxCubePosition: int64 = 999999'i64 * 999999'i64 * 999999'i64
const tableCapacity = 11000000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var golombTable = newSeq[uint32](tableCapacity)
golombTable[0] = 0'u32
golombTable[1] = 1'u32
var tableIndex = 1
var productTotal: int64 = 1
while productTotal < maxCubePosition:
  tableIndex += 1
  let previousValue = golombTable[tableIndex - 1]
  let nestedValue = golombTable[int(previousValue)]
  let targetIndex = tableIndex - int(nestedValue)
  let currentValue = 1'u32 + golombTable[targetIndex]
  golombTable[tableIndex] = currentValue
  productTotal += int64(tableIndex) * int64(currentValue)

var baseValues = newSeq[int64](maxPersonIndex + 1)
var prefixBase = newSeq[int64](maxPersonIndex + 1)
var blockIndex = 1
var sumTerms: int64 = 1
var productTerms: int64 = 1
var previousSum: int64 = 0
var previousProduct: int64 = 0
for personIndex in 1 .. maxPersonIndex:
  let cubePosition = int64(personIndex) * int64(personIndex) * int64(personIndex)
  while productTerms < cubePosition:
    blockIndex += 1
    previousSum = sumTerms
    previousProduct = productTerms
    let golombValue = int64(golombTable[blockIndex])
    sumTerms += golombValue
    productTerms += int64(blockIndex) * golombValue
  let offsetValue = (cubePosition - previousProduct + int64(blockIndex) - 1) div int64(blockIndex)
  baseValues[personIndex] = previousSum + offsetValue
  prefixBase[personIndex] = prefixBase[personIndex - 1] + baseValues[personIndex]

var bitOne = newSeq[int64](maxPersonIndex + 2)
var bitTwo = newSeq[int64](maxPersonIndex + 2)

proc bitAdd(bitValues: var seq[int64], indexValue: int, deltaValue: int64) =
  var cursor = indexValue
  while cursor <= maxPersonIndex + 1:
    bitValues[cursor] += deltaValue
    cursor += cursor and -cursor

proc bitPrefix(bitValues: seq[int64], indexValue: int): int64 =
  var cursor = indexValue
  result = 0'i64
  while cursor > 0:
    result += bitValues[cursor]
    cursor -= cursor and -cursor

proc addRange(leftIndex: int, rightIndex: int, incrementValue: int64) =
  bitAdd(bitOne, leftIndex, incrementValue)
  bitAdd(bitOne, rightIndex + 1, -incrementValue)
  bitAdd(bitTwo, leftIndex, incrementValue * int64(leftIndex - 1))
  bitAdd(bitTwo, rightIndex + 1, -incrementValue * int64(rightIndex))

proc prefixIncrement(indexValue: int): int64 =
  bitPrefix(bitOne, indexValue) * int64(indexValue) - bitPrefix(bitTwo, indexValue)

let updateCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
for updateIndex in 0 .. updateCount - 1:
  var leftIndex = nextInt(inputData, scanPos)
  var rightIndex = nextInt(inputData, scanPos)
  let incrementValue = int64(nextInt(inputData, scanPos))
  if leftIndex > rightIndex:
    let swapIndex = leftIndex
    leftIndex = rightIndex
    rightIndex = swapIndex
  addRange(leftIndex, rightIndex, incrementValue)
for queryIndex in 0 .. queryCount - 1:
  var leftIndex = nextInt(inputData, scanPos)
  var rightIndex = nextInt(inputData, scanPos)
  if leftIndex > rightIndex:
    let swapIndex = leftIndex
    leftIndex = rightIndex
    rightIndex = swapIndex
  let baseTotal = prefixBase[rightIndex] - prefixBase[leftIndex - 1]
  let addedTotal = prefixIncrement(rightIndex) - prefixIncrement(leftIndex - 1)
  appendOutput($(baseTotal + addedTotal))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
