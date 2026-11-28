const flushBlockBytes = 1 shl 17
const modValue = 1000000007

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

proc modularPower(baseValue: int, exponentValue: int): int =
  var baseRest = int64(baseValue)
  var exponentRest = exponentValue
  result = 1
  while exponentRest > 0:
    if (exponentRest and 1) == 1:
      result = int(result * baseRest mod int64(modValue))
    baseRest = baseRest * baseRest mod int64(modValue)
    exponentRest = exponentRest div 2

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var largestQuery = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > largestQuery:
    largestQuery = queries[caseIndex]
let tableLimit = 2 * largestQuery
var factorials = newSeq[int](tableLimit + 1)
var inverseFactorials = newSeq[int](tableLimit + 1)
factorials[0] = 1
for tableIndex in 1 .. tableLimit:
  factorials[tableIndex] = int(int64(factorials[tableIndex - 1]) *
                               int64(tableIndex) mod int64(modValue))
inverseFactorials[tableLimit] = modularPower(factorials[tableLimit], modValue - 2)
var tableIndex = tableLimit
while tableIndex >= 1:
  inverseFactorials[tableIndex - 1] = int(int64(inverseFactorials[tableIndex]) *
                                          int64(tableIndex) mod int64(modValue))
  tableIndex -= 1
for caseIndex in 0 .. caseCount - 1:
  let queryValue = queries[caseIndex]
  let upperIndex = 2 * queryValue - 1
  let chooseValue = int(int64(factorials[upperIndex]) *
                        int64(inverseFactorials[queryValue - 1]) mod int64(modValue))
  let scaledValue = int64(queryValue) * int64(chooseValue) mod int64(modValue)
  let answerValue = int(scaledValue * int64(inverseFactorials[queryValue]) mod int64(modValue))
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
