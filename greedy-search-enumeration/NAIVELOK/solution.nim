const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue = 1000000007

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var palindromeTable: array[101, array[101, int64]]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let secretString = nextToken(inputData, scanPos)
  let stringLength = secretString.len
  for spanLength in 0 ..< stringLength:
    for leftIndex in 0 ..< stringLength - spanLength:
      let rightIndex = leftIndex + spanLength
      if spanLength == 0:
        palindromeTable[leftIndex][rightIndex] = 2
      else:
        var innerCount: int64 = 1
        if spanLength >= 2:
          innerCount = palindromeTable[leftIndex + 1][rightIndex - 1]
        var cellValue = palindromeTable[leftIndex + 1][rightIndex] + palindromeTable[leftIndex][rightIndex - 1] - innerCount
        if secretString[leftIndex] == secretString[rightIndex]:
          cellValue = cellValue + innerCount
        palindromeTable[leftIndex][rightIndex] = (cellValue + modulusValue) mod modulusValue
  let palindromeSubsets = palindromeTable[0][stringLength - 1]
  var totalSubsets: int64 = 1
  for bitIndex in 0 ..< stringLength:
    totalSubsets = (totalSubsets * 2) mod modulusValue
  var nonPalindromeWays = (totalSubsets - palindromeSubsets + modulusValue) mod modulusValue
  appendOutput($nonPalindromeWays)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
