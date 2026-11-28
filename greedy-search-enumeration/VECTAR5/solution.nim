const flushBlockBytes = 1 shl 17
const moduloValue = 1000000007

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

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var maximumQuery = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > maximumQuery:
    maximumQuery = queries[caseIndex]

var powersOfTwo = newSeq[int64](maximumQuery + 1)
var powersOfThree = newSeq[int64](maximumQuery + 1)
var powersOfFour = newSeq[int64](maximumQuery + 1)
powersOfTwo[0] = 1
powersOfThree[0] = 1
powersOfFour[0] = 1
for exponent in 1 .. maximumQuery:
  powersOfTwo[exponent] = powersOfTwo[exponent - 1] * 2 mod moduloValue
  powersOfThree[exponent] = powersOfThree[exponent - 1] * 3 mod moduloValue
  powersOfFour[exponent] = powersOfFour[exponent - 1] * 4 mod moduloValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  let query = queries[caseIndex]
  var answer = powersOfFour[query] - 2 * powersOfThree[query] + powersOfTwo[query]
  answer = (answer + 2 * int64(moduloValue)) mod int64(moduloValue)
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
