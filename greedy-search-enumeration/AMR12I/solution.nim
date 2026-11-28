const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const impossible = 1000000007

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
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let soldierCount = nextInt(inputData, scanPos)
  let strokeWidth = nextInt(inputData, scanPos)
  let colorText = nextWord(inputData, scanPos)
  var candidatePos: array[alphabetSize, seq[int]]
  var candidateValue: array[alphabetSize, seq[int]]
  var dequeHead: array[alphabetSize, int]
  var dequeTail: array[alphabetSize, int]
  for colorIndex in 0 .. alphabetSize - 1:
    candidatePos[colorIndex] = newSeq[int](soldierCount + 1)
    candidateValue[colorIndex] = newSeq[int](soldierCount + 1)
    dequeHead[colorIndex] = 0
    dequeTail[colorIndex] = 0
  var dp = newSeq[int](soldierCount + 1)
  dp[0] = 0
  let lastStart = soldierCount - strokeWidth
  for soldierIndex in 1 .. soldierCount:
    let colorIndex = int(colorText[soldierIndex - 1]) - int('a')
    if soldierIndex == 1 or int(colorText[soldierIndex - 2]) - int('a') != colorIndex:
      dequeHead[colorIndex] = 0
      dequeTail[colorIndex] = 0
    if soldierIndex - 1 <= lastStart and dp[soldierIndex - 1] < impossible:
      var tailIndex = dequeTail[colorIndex] - 1
      while tailIndex >= dequeHead[colorIndex] and candidateValue[colorIndex][tailIndex] >= dp[soldierIndex - 1]:
        tailIndex -= 1
      dequeTail[colorIndex] = tailIndex + 1
      candidatePos[colorIndex][dequeTail[colorIndex]] = soldierIndex - 1
      candidateValue[colorIndex][dequeTail[colorIndex]] = dp[soldierIndex - 1]
      dequeTail[colorIndex] += 1
    let earliestStart = soldierIndex - strokeWidth
    while dequeHead[colorIndex] < dequeTail[colorIndex] and candidatePos[colorIndex][dequeHead[colorIndex]] < earliestStart:
      dequeHead[colorIndex] += 1
    if dequeHead[colorIndex] < dequeTail[colorIndex]:
      dp[soldierIndex] = candidateValue[colorIndex][dequeHead[colorIndex]] + 1
    else:
      dp[soldierIndex] = impossible
  if dp[soldierCount] >= impossible:
    appendOutput("-1\n")
  else:
    appendOutput($dp[soldierCount])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
