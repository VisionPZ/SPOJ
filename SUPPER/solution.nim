const maxPermutationSize = 100000
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos = scanPos + 1
  var value = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc lowerBound(tailValues: seq[int], tailCount: int, value: int): int =
  var leftIndex = 0
  var rightIndex = tailCount
  while leftIndex < rightIndex:
    let middleIndex = (leftIndex + rightIndex) div 2
    if tailValues[middleIndex] < value:
      leftIndex = middleIndex + 1
    else:
      rightIndex = middleIndex
  return leftIndex

var permutation = newSeq[int](maxPermutationSize + 1)
var endingLength = newSeq[int](maxPermutationSize + 1)
var startingLength = newSeq[int](maxPermutationSize + 1)
var tailValues = newSeq[int](maxPermutationSize + 1)
var isSupernumber = newSeq[bool](maxPermutationSize + 1)

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0
var outputBuffer: string
while scanPos < inputData.len:
  let size = nextInt(inputData, scanPos)
  if size < 1: break
  for index in 0 ..< size:
    permutation[index] = nextInt(inputData, scanPos)
  var tailCount = 0
  for index in 0 ..< size:
    let value = permutation[index]
    let insertPos = lowerBound(tailValues, tailCount, value)
    endingLength[index] = insertPos + 1
    tailValues[insertPos] = value
    if insertPos == tailCount: tailCount = tailCount + 1
  let longestLength = tailCount
  tailCount = 0
  for reverseIndex in 0 ..< size:
    let originalIndex = size - 1 - reverseIndex
    let value = -permutation[originalIndex]
    let insertPos = lowerBound(tailValues, tailCount, value)
    startingLength[originalIndex] = insertPos + 1
    tailValues[insertPos] = value
    if insertPos == tailCount: tailCount = tailCount + 1
  for value in 1 .. size:
    isSupernumber[value] = false
  var supernumberCount = 0
  for index in 0 ..< size:
    if endingLength[index] + startingLength[index] - 1 == longestLength:
      isSupernumber[permutation[index]] = true
  for value in 1 .. size:
    if isSupernumber[value]: supernumberCount = supernumberCount + 1
  outputBuffer.add $supernumberCount
  outputBuffer.add "\n"
  var written = 0
  for value in 1 .. size:
    if isSupernumber[value]:
      if written > 0: outputBuffer.add " "
      outputBuffer.add $value
      written = written + 1
      if outputBuffer.len >= flushBlockBytes:
        stdout.write outputBuffer
        outputBuffer.setLen 0
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
