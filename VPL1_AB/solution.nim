const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const dieFaces = 6
const largestDiceCount = 3

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
var boardSizes = newSeq[int](caseCount)
var diceCounts = newSeq[int](caseCount)
for caseIndex in 0 .. caseCount - 1:
  boardSizes[caseIndex] = nextInt(inputData, scanPos)
  diceCounts[caseIndex] = nextInt(inputData, scanPos)

var sumTables = newSeq[seq[int]](largestDiceCount + 1)
for diceCount in 1 .. largestDiceCount:
  var tupleTotal = 1
  for dieIndex in 1 .. diceCount:
    tupleTotal *= dieFaces
  var stepSums = newSeq[int](tupleTotal)
  for tupleIndex in 0 .. tupleTotal - 1:
    var encodedTuple = tupleIndex
    var diceSum = 0
    for dieIndex in 1 .. diceCount:
      diceSum += encodedTuple mod dieFaces + 1
      encodedTuple = encodedTuple div dieFaces
    stepSums[tupleIndex] = diceSum
  sumTables[diceCount] = stepSums

for caseIndex in 0 .. caseCount - 1:
  let boardSize = boardSizes[caseIndex]
  let diceCount = diceCounts[caseIndex]
  if boardSize == 1:
    appendOutput("Scenario #" & $(caseIndex + 1) & ": 1")
    outputBuffer.add '\n'
    continue
  let stepSums = sumTables[diceCount]
  let tupleTotal = stepSums.len
  var ways = newSeq[seq[int64]](boardSize + 1)
  for position in 0 .. boardSize:
    ways[position] = newSeq[int64](tupleTotal)
  for tupleIndex in 0 .. tupleTotal - 1:
    let landing = 1 + stepSums[tupleIndex]
    if landing <= boardSize:
      ways[landing][tupleIndex] = 1
  for position in 1 .. boardSize - 1:
    var totalWays: int64 = 0
    for tupleIndex in 0 .. tupleTotal - 1:
      totalWays += ways[position][tupleIndex]
    totalWays = totalWays mod answerModulus
    for tupleIndex in 0 .. tupleTotal - 1:
      let addedWays = totalWays - ways[position][tupleIndex]
      if addedWays == 0:
        continue
      let landing = position + stepSums[tupleIndex]
      if landing <= boardSize:
        var updated = (ways[landing][tupleIndex] + addedWays) mod answerModulus
        if updated < 0:
          updated += answerModulus
        ways[landing][tupleIndex] = updated
  var answer: int64 = 0
  for tupleIndex in 0 .. tupleTotal - 1:
    answer = (answer + ways[boardSize][tupleIndex]) mod answerModulus
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
