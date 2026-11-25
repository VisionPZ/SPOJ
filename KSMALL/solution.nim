const flushBlockBytes = 1 shl 17
const sequenceLength = 5000000
const histogramSize = 1 shl 16
const lowMask = 65535'u32

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

let firstSeed = uint32(nextInt(inputData, scanPos))
let secondSeed = uint32(nextInt(inputData, scanPos))
let modulus = uint32(nextInt(inputData, scanPos))
let targetRank = nextInt(inputData, scanPos)

var generated = newSeq[uint32](sequenceLength)
var highCounts = newSeq[int32](histogramSize)
var stateFirst = firstSeed
var stateSecond = secondSeed
for valueIndex in 0 .. sequenceLength - 1:
  stateFirst = 31014'u32 * (stateFirst and 65535'u32) + (stateFirst shr 16)
  stateSecond = 17508'u32 * (stateSecond and 65535'u32) + (stateSecond shr 16)
  let generatedValue = ((stateFirst shl 16) + stateSecond) mod modulus
  generated[valueIndex] = generatedValue
  highCounts[int(generatedValue shr 16)] += 1

var selectedHigh = 0
var seenBefore = 0
for highPart in 0 .. histogramSize - 1:
  let nextSeen = seenBefore + int(highCounts[highPart])
  if nextSeen >= targetRank:
    selectedHigh = highPart
    break
  seenBefore = nextSeen
let withinRank = targetRank - seenBefore

var lowCounts = newSeq[int32](histogramSize)
for valueIndex in 0 .. sequenceLength - 1:
  let generatedValue = generated[valueIndex]
  if int(generatedValue shr 16) == selectedHigh:
    lowCounts[int(generatedValue and lowMask)] += 1

var selectedLow = 0
var lowSeen = 0
for lowPart in 0 .. histogramSize - 1:
  let nextSeen = lowSeen + int(lowCounts[lowPart])
  if nextSeen >= withinRank:
    selectedLow = lowPart
    break
  lowSeen = nextSeen

let answer = (uint32(selectedHigh) shl 16) + uint32(selectedLow)
appendOutput($int64(answer))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
