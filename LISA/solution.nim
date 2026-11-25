const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxDigitCount = 64
const tableSize = maxDigitCount * maxDigitCount
const largestValue = 18446744073709551615'u64

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
  return data[tokenStart .. pos - 1]

proc evaluateExpression(expression: string, minTable: var array[tableSize, uint64], maxTable: var array[tableSize, uint64]): (uint64, uint64) =
  var digits: array[maxDigitCount, uint64]
  var operators: array[maxDigitCount, char]
  var digitCount = 0
  var charPos = 0
  while charPos < expression.len:
    let currentChar = expression[charPos]
    if currentChar >= '0' and currentChar <= '9':
      digits[digitCount] = uint64(int(currentChar) - firstDigitValue)
      digitCount += 1
    else:
      operators[digitCount - 1] = currentChar
    charPos += 1

  for length in 1 .. digitCount:
    for left in 0 .. digitCount - length:
      let right = left + length - 1
      let tableIndex = left * maxDigitCount + right
      if length == 1:
        minTable[tableIndex] = digits[left]
        maxTable[tableIndex] = digits[left]
      else:
        var smallest = largestValue
        var largest = 0'u64
        for split in left .. right - 1:
          let splitOperator = operators[split]
          let leftMin = minTable[left * maxDigitCount + split]
          let leftMax = maxTable[left * maxDigitCount + split]
          let rightMin = minTable[(split + 1) * maxDigitCount + right]
          let rightMax = maxTable[(split + 1) * maxDigitCount + right]
          if splitOperator == '+':
            let candidateMin = leftMin + rightMin
            let candidateMax = leftMax + rightMax
            if candidateMin < smallest: smallest = candidateMin
            if candidateMax > largest: largest = candidateMax
          else:
            let candidateMin = leftMin * rightMin
            let candidateMax = leftMax * rightMax
            if candidateMin < smallest: smallest = candidateMin
            if candidateMax > largest: largest = candidateMax
        minTable[tableIndex] = smallest
        maxTable[tableIndex] = largest

  return (minTable[digitCount - 1], maxTable[digitCount - 1])

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var minTable: array[tableSize, uint64]
var maxTable: array[tableSize, uint64]
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let expression = nextToken(inputData, scanPos)
  let (smallestResult, largestResult) = evaluateExpression(expression, minTable, maxTable)
  outputBuffer.add $(largestResult)
  outputBuffer.add ' '
  outputBuffer.add $(smallestResult)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
