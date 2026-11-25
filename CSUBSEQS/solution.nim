const flushBlockBytes = 1 shl 17
const textCount = 4
const letterCount = 26

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var texts = newSeq[string](textCount)
for textIndex in 0 .. textCount - 1:
  texts[textIndex] = nextWord(inputData, scanPos)
var textLengths = newSeq[int](textCount)
for textIndex in 0 .. textCount - 1:
  textLengths[textIndex] = texts[textIndex].len
var letterStrides = newSeq[int](textCount)
for textIndex in 0 .. textCount - 1:
  letterStrides[textIndex] = textLengths[textIndex] + 1
var nextPositions = newSeq[seq[int]](textCount)
for textIndex in 0 .. textCount - 1:
  let letterStride = letterStrides[textIndex]
  nextPositions[textIndex] = newSeq[int](letterCount * letterStride)
  for letterIndex in 0 .. letterCount - 1:
    var lastPosition = textLengths[textIndex]
    nextPositions[textIndex][letterIndex * letterStride + textLengths[textIndex]] = lastPosition
    for charIndex in countdown(textLengths[textIndex] - 1, 0):
      if int(texts[textIndex][charIndex]) - 97 == letterIndex:
        lastPosition = charIndex
      nextPositions[textIndex][letterIndex * letterStride + charIndex] = lastPosition
let fourthStride = 1
let thirdStride = letterStrides[3]
let secondStride = letterStrides[2] * thirdStride
let firstStride = letterStrides[1] * secondStride
let stateSpaceSize = letterStrides[0] * firstStride
var maximumIndexSum = 0
for textIndex in 0 .. textCount - 1:
  maximumIndexSum += textLengths[textIndex]
var counts = newSeq[int64](stateSpaceSize)
counts[0] = 1
var stateBuckets = newSeq[seq[int]](maximumIndexSum + 1)
stateBuckets[0].add(0)
var totalDistinct: int64 = 0
for currentSum in 0 .. maximumIndexSum:
  for statePosition in 0 .. stateBuckets[currentSum].len - 1:
    let stateCode = stateBuckets[currentSum][statePosition]
    let stateWeight = counts[stateCode]
    var remainder = stateCode
    let firstIndex = remainder div firstStride
    remainder = remainder mod firstStride
    let secondIndex = remainder div secondStride
    remainder = remainder mod secondStride
    let thirdIndex = remainder div thirdStride
    let fourthIndex = remainder mod thirdStride
    for letterIndex in 0 .. letterCount - 1:
      let nextFirst = nextPositions[0][letterIndex * letterStrides[0] + firstIndex] + 1
      if nextFirst > textLengths[0]:
        continue
      let nextSecond = nextPositions[1][letterIndex * letterStrides[1] + secondIndex] + 1
      if nextSecond > textLengths[1]:
        continue
      let nextThird = nextPositions[2][letterIndex * letterStrides[2] + thirdIndex] + 1
      if nextThird > textLengths[2]:
        continue
      let nextFourth = nextPositions[3][letterIndex * letterStrides[3] + fourthIndex] + 1
      if nextFourth > textLengths[3]:
        continue
      let nextCode = nextFirst * firstStride + nextSecond * secondStride +
          nextThird * thirdStride + nextFourth * fourthStride
      let nextSum = nextFirst + nextSecond + nextThird + nextFourth
      if counts[nextCode] == 0:
        stateBuckets[nextSum].add(nextCode)
      counts[nextCode] += stateWeight
      totalDistinct += stateWeight
appendOutput($totalDistinct)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
