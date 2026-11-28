const flushBlockBytes = 1 shl 17

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

proc multiplyModulo(firstFactor, secondFactor, modulusValue: int64): int64 {.
    importc: "multiply_modulo_words", cdecl.}

{.emit: """
NI64 multiply_modulo_words(NI64 firstFactor, NI64 secondFactor, NI64 modulusValue) {
  return (NI64)((__int128)firstFactor * (__int128)secondFactor % (__int128)modulusValue);
}
""".}

let flowerCount = nextInt(inputData, scanPos)
let generationFactor = int64(nextInt(inputData, scanPos))
let generationOffset = int64(nextInt(inputData, scanPos))
let generationModulus = int64(nextInt(inputData, scanPos))
let startingDiameter = int64(nextInt(inputData, scanPos))

var smallestDiameter = high(int64)
var largestDiameter = -1'i64
var currentDiameter = startingDiameter
for flowerIndex in 0 .. flowerCount - 1:
  if currentDiameter < smallestDiameter:
    smallestDiameter = currentDiameter
  if currentDiameter > largestDiameter:
    largestDiameter = currentDiameter
  currentDiameter = (multiplyModulo(generationFactor, currentDiameter, generationModulus) + generationOffset) mod generationModulus

var largestGap: int64 = 0
if largestDiameter > smallestDiameter:
  let diameterSpan = largestDiameter - smallestDiameter
  var bucketWidth = diameterSpan div int64(flowerCount)
  if bucketWidth < 1'i64:
    bucketWidth = 1'i64
  let bucketCount = int(diameterSpan div bucketWidth) + 1
  var bucketMinimums = newSeq[int64](bucketCount)
  var bucketMaximums = newSeq[int64](bucketCount)
  for bucketIndex in 0 .. bucketCount - 1:
    bucketMinimums[bucketIndex] = high(int64)
    bucketMaximums[bucketIndex] = -1'i64
  currentDiameter = startingDiameter
  for flowerIndex in 0 .. flowerCount - 1:
    let bucketIndex = int((currentDiameter - smallestDiameter) div bucketWidth)
    if currentDiameter < bucketMinimums[bucketIndex]:
      bucketMinimums[bucketIndex] = currentDiameter
    if currentDiameter > bucketMaximums[bucketIndex]:
      bucketMaximums[bucketIndex] = currentDiameter
    currentDiameter = (multiplyModulo(generationFactor, currentDiameter, generationModulus) + generationOffset) mod generationModulus
  var previousMaximum = smallestDiameter
  var havePreviousBucket = false
  for bucketIndex in 0 .. bucketCount - 1:
    if bucketMaximums[bucketIndex] >= 0'i64:
      if havePreviousBucket:
        let bucketGap = bucketMinimums[bucketIndex] - previousMaximum
        if bucketGap > largestGap:
          largestGap = bucketGap
      previousMaximum = bucketMaximums[bucketIndex]
      havePreviousBucket = true

appendOutput($largestGap)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
