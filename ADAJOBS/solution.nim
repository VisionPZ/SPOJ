const flushBlockBytes = 1 shl 17
const firstBase = 1000003
const secondBase = 1000033
const mixingFactor = 11995408973635179863'u64

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fillHashes(word: string, firstHashes: var seq[uint64], secondHashes: var seq[uint64]) =
  firstHashes.setLen(word.len + 1)
  secondHashes.setLen(word.len + 1)
  firstHashes[0] = uint64(0)
  secondHashes[0] = uint64(0)
  for charIndex in 0 .. word.len - 1:
    firstHashes[charIndex + 1] = firstHashes[charIndex] * uint64(firstBase) + uint64(int(word[charIndex]))
    secondHashes[charIndex + 1] = secondHashes[charIndex] * uint64(secondBase) + uint64(int(word[charIndex]))

proc slotStart(patternLength: int, hashOne: uint64, hashTwo: uint64, slotCount: int): int =
  let mixedValue = hashOne + hashTwo * mixingFactor + uint64(patternLength) * uint64(97)
  return int(mixedValue mod uint64(slotCount))

proc patternPresent(patternLength: int, hashOne: uint64, hashTwo: uint64, slotLengths: seq[int], slotFirsts: seq[uint64], slotSeconds: seq[uint64], slotOccupied: seq[bool]): bool =
  var probeIndex = slotStart(patternLength, hashOne, hashTwo, slotOccupied.len)
  while slotOccupied[probeIndex]:
    if slotLengths[probeIndex] == patternLength and slotFirsts[probeIndex] == hashOne and slotSeconds[probeIndex] == hashTwo:
      return true
    probeIndex = (probeIndex + 1) mod slotOccupied.len
  return false

proc addPattern(patternLength: int, hashOne: uint64, hashTwo: uint64, slotLengths: var seq[int], slotFirsts: var seq[uint64], slotSeconds: var seq[uint64], slotOccupied: var seq[bool]) =
  var probeIndex = slotStart(patternLength, hashOne, hashTwo, slotOccupied.len)
  while slotOccupied[probeIndex]:
    if slotLengths[probeIndex] == patternLength and slotFirsts[probeIndex] == hashOne and slotSeconds[probeIndex] == hashTwo:
      return
    probeIndex = (probeIndex + 1) mod slotOccupied.len
  slotOccupied[probeIndex] = true
  slotLengths[probeIndex] = patternLength
  slotFirsts[probeIndex] = hashOne
  slotSeconds[probeIndex] = hashTwo

let queryCount = nextInt(inputData, scanPos)
var queryKinds = newSeq[int](queryCount)
var queryWords = newSeq[string](queryCount)
var maximumLength = 0
for queryIndex in 0 .. queryCount - 1:
  queryKinds[queryIndex] = nextInt(inputData, scanPos)
  queryWords[queryIndex] = nextWord(inputData, scanPos)
  if queryWords[queryIndex].len > maximumLength:
    maximumLength = queryWords[queryIndex].len

var firstPowers = newSeq[uint64](maximumLength + 1)
var secondPowers = newSeq[uint64](maximumLength + 1)
firstPowers[0] = uint64(1)
secondPowers[0] = uint64(1)
for powerIndex in 1 .. maximumLength:
  firstPowers[powerIndex] = firstPowers[powerIndex - 1] * uint64(firstBase)
  secondPowers[powerIndex] = secondPowers[powerIndex - 1] * uint64(secondBase)

var slotCount = 8
while slotCount < queryCount * 4 + 8:
  slotCount = slotCount * 2
var slotLengths = newSeq[int](slotCount)
var slotFirsts = newSeq[uint64](slotCount)
var slotSeconds = newSeq[uint64](slotCount)
var slotOccupied = newSeq[bool](slotCount)
var activeLengths = newSeq[int](maximumLength + 1)
var firstHashes = newSeq[uint64](1)
var secondHashes = newSeq[uint64](1)

for queryIndex in 0 .. queryCount - 1:
  let queryWord = queryWords[queryIndex]
  if queryWord.len == 0:
    continue
  fillHashes(queryWord, firstHashes, secondHashes)
  if queryKinds[queryIndex] == 0:
    let wordLength = queryWord.len
    addPattern(wordLength, firstHashes[wordLength], secondHashes[wordLength], slotLengths, slotFirsts, slotSeconds, slotOccupied)
    activeLengths[wordLength] = 1
  else:
    var foundMatch = false
    for patternLength in 1 .. queryWord.len:
      if activeLengths[patternLength] == 0:
        continue
      let substringCount = queryWord.len - patternLength
      for startPos in 0 .. substringCount:
        let hashOne = firstHashes[startPos + patternLength] - firstHashes[startPos] * firstPowers[patternLength]
        let hashTwo = secondHashes[startPos + patternLength] - secondHashes[startPos] * secondPowers[patternLength]
        if patternPresent(patternLength, hashOne, hashTwo, slotLengths, slotFirsts, slotSeconds, slotOccupied):
          foundMatch = true
          break
      if foundMatch:
        break
    if foundMatch:
      appendOutput("YES\n")
    else:
      appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
