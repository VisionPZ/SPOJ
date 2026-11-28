const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let initialCount = nextInt(inputData, scanPos)
let capacity = initialCount + 100000 + 3
var suffixSums = newSeq[int64](capacity)
let tailIndex = capacity - 1
let initialFront = tailIndex - initialCount
var frontIndex = initialFront
var currentIndex = initialFront
while currentIndex < tailIndex:
  let initialValue = int64(nextInt(inputData, scanPos))
  suffixSums[currentIndex] = initialValue
  currentIndex += 1
var runningSum: int64 = 0
var walkIndex = tailIndex
while walkIndex >= initialFront:
  runningSum = runningSum + suffixSums[walkIndex]
  suffixSums[walkIndex] = runningSum
  walkIndex -= 1
let queryCount = nextInt(inputData, scanPos)
var queryIndex = 0
while queryIndex < queryCount:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 1:
    let leftIndex = nextInt(inputData, scanPos)
    let rightIndex = nextInt(inputData, scanPos)
    let firstPosition = frontIndex + leftIndex - 1
    let afterLast = frontIndex + rightIndex
    let rangeTotal = suffixSums[firstPosition] - suffixSums[afterLast]
    appendOutput($rangeTotal)
    outputBuffer.add '\n'
  else:
    let insertedValue = int64(nextInt(inputData, scanPos))
    frontIndex -= 1
    suffixSums[frontIndex] = insertedValue + suffixSums[frontIndex + 1]
  queryIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
