const flushBlockBytes = 1 shl 17
const answerModulus = 100000007
const maximumPresses = 400000

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
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc buildCounts(cycleLength: int): seq[int] =
  var counts = newSeq[int](maximumPresses + 1)
  counts[0] = 1
  for pressCount in 1 .. maximumPresses:
    var windowTotal = 0
    for partSize in 1 .. cycleLength:
      if pressCount - partSize >= 0:
        windowTotal = (windowTotal + counts[pressCount - partSize]) mod answerModulus
    counts[pressCount] = windowTotal
  return counts

proc buildWays(counts: seq[int], cycleLength: int): seq[int] =
  var ways = newSeq[int](maximumPresses + 1)
  for pressCount in 1 .. maximumPresses:
    var earlier = 0
    if pressCount > cycleLength:
      earlier = ways[pressCount - cycleLength]
    ways[pressCount] = (earlier + counts[pressCount]) mod answerModulus
  return ways

let countsThree = buildCounts(3)
let countsFour = buildCounts(4)
let waysThree = buildWays(countsThree, 3)
let waysFour = buildWays(countsFour, 4)

var letterKeys = newSeq[int](26)
var letterPresses = newSeq[int](26)
var letterCycles = newSeq[int](26)
var letterIndex = 0
for keyValue in [2, 3, 4, 5, 6, 7, 8, 9]:
  let cycleLength = if keyValue == 7 or keyValue == 9: 4 else: 3
  for offsetValue in 0 .. cycleLength - 1:
    letterKeys[letterIndex] = keyValue
    letterPresses[letterIndex] = offsetValue + 1
    letterCycles[letterIndex] = cycleLength
    letterIndex += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let word = nextWord(inputData, scanPos)
  var currentKey = -1
  var currentCycle = 0
  var runPresses = 0
  var answerValue: int64 = 1
  for character in word:
    let alphabetIndex = int(character) - 97
    let keyValue = letterKeys[alphabetIndex]
    if runPresses > 0 and keyValue != currentKey:
      let ways = if currentCycle == 3: waysThree[runPresses] else: waysFour[runPresses]
      answerValue = answerValue * int64(ways) mod answerModulus
      runPresses = 0
    currentKey = keyValue
    currentCycle = letterCycles[alphabetIndex]
    runPresses += letterPresses[alphabetIndex]
  if runPresses > 0:
    let ways = if currentCycle == 3: waysThree[runPresses] else: waysFour[runPresses]
    answerValue = answerValue * int64(ways) mod answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
