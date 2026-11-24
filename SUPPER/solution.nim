const maxPermutationSize = 100000
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc lowerBound(tailValues: seq[int], tailCount: int, value: int): int =
  var i = 0
  var j = tailCount
  while i < j:
    let k = (i + j) div 2
    if tailValues[k] < value:
      i = k + 1
    else:
      j = k
  return i

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
var i = 0
var outputBuffer: string
while i < inputData.len:
  let size = nextInt(inputData, i)
  if size < 1: break
  for j in 0 ..< size:
    permutation[j] = nextInt(inputData, i)
  var tailCount = 0
  for j in 0 ..< size:
    let value = permutation[j]
    let k = lowerBound(tailValues, tailCount, value)
    endingLength[j] = k + 1
    tailValues[k] = value
    if k == tailCount: tailCount = tailCount + 1
  let longestLength = tailCount
  tailCount = 0
  for j in 0 ..< size:
    let k = size - 1 - j
    let value = -permutation[k]
    let l = lowerBound(tailValues, tailCount, value)
    startingLength[k] = l + 1
    tailValues[l] = value
    if l == tailCount: tailCount = tailCount + 1
  for value in 1 .. size:
    isSupernumber[value] = false
  var supernumberCount = 0
  for j in 0 ..< size:
    if endingLength[j] + startingLength[j] - 1 == longestLength:
      isSupernumber[permutation[j]] = true
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
