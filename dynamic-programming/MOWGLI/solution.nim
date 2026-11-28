const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxSkipAllowed = 50

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

let testCount = nextInt(inputData, scanPos)
var skipLimits = newSeq[int]()
var stoneCounts = newSeq[int]()
var maxStoneCount = 0
for testIndex in 0 .. testCount - 1:
  let riverCount = nextInt(inputData, scanPos)
  let maxSkip = nextInt(inputData, scanPos)
  for riverIndex in 0 .. riverCount - 1:
    let stoneCount = nextInt(inputData, scanPos)
    skipLimits.add maxSkip
    stoneCounts.add stoneCount
    if stoneCount > maxStoneCount:
      maxStoneCount = stoneCount

var skipSeen = newSeq[bool](maxSkipAllowed + 1)
for queryIndex in 0 .. skipLimits.len - 1:
  skipSeen[skipLimits[queryIndex]] = true

var answers = newSeq[int](stoneCounts.len)
for skipValue in 0 .. maxSkipAllowed:
  if not skipSeen[skipValue]:
    continue
  var ways = newSeq[int](maxStoneCount + 2)
  ways[0] = 1
  var windowTotal: int64 = 1
  for totalStones in 1 .. maxStoneCount + 1:
    ways[totalStones] = int(windowTotal mod int64(answerModulus))
    windowTotal += int64(ways[totalStones])
    let dropIndex = totalStones - (skipValue + 1)
    if dropIndex >= 0:
      windowTotal -= int64(ways[dropIndex])
  for queryIndex in 0 .. skipLimits.len - 1:
    if skipLimits[queryIndex] == skipValue:
      answers[queryIndex] = ways[stoneCounts[queryIndex] + 1]

for answerIndex in 0 .. answers.len - 1:
  appendOutput($answers[answerIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
