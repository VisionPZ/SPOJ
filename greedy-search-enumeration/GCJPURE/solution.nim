const flushBlockBytes = 1 shl 17
const modulusValue = 100003

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

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var largestQuery = 2
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > largestQuery:
    largestQuery = queries[caseIndex]

let tableWidth = largestQuery + 2
let binomWidth = largestQuery + 1
var binom = newSeq[int](binomWidth * binomWidth)
for row in 0 .. largestQuery:
  binom[row * binomWidth] = 1
  binom[row * binomWidth + row] = 1
  for column in 1 .. row - 1:
    binom[row * binomWidth + column] = (binom[(row - 1) * binomWidth + column - 1] + binom[(row - 1) * binomWidth + column]) mod modulusValue

var pureWays = newSeq[int]((largestQuery + 1) * tableWidth)
pureWays[tableWidth] = 1
var answerByValue = newSeq[int](largestQuery + 1)
answerByValue[1] = 1
for value in 2 .. largestQuery:
  pureWays[value * tableWidth + 1] = 1
  for setSize in 2 .. value:
    let upper = value - 1 - setSize
    if upper < 0:
      continue
    var total: int64 = 0
    for subsetSize in 1 .. setSize:
      let needed = setSize - 1 - subsetSize
      if needed >= 0 and needed <= upper:
        total = total + int64(pureWays[setSize * tableWidth + subsetSize]) * int64(binom[upper * binomWidth + needed])
    pureWays[value * tableWidth + setSize] = int(total mod int64(modulusValue))
  var answer: int64 = 0
  for setSize in 1 .. value:
    answer = answer + int64(pureWays[value * tableWidth + setSize])
  answerByValue[value] = int(answer mod int64(modulusValue))

for caseIndex in 0 .. caseCount - 1:
  let query = queries[caseIndex]
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $answerByValue[query] & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
