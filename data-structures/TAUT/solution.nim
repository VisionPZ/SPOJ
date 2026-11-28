{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const variableCapacity = 16
const tableWords = 1024
const assignmentCount = 1 shl 16
const stackCapacity = 128
const firstLetterValue = 97
const allOnes: uint64 = not 0'u64

type TruthTable = array[tableWords, uint64]

var variableTables: array[variableCapacity, TruthTable]
for variableNumber in 0..<variableCapacity:
  for assignmentIndex in 0..<assignmentCount:
    if ((assignmentIndex shr variableNumber) and 1) == 1:
      let wordIndex = assignmentIndex shr 6
      let bitInWord = assignmentIndex and 63
      variableTables[variableNumber][wordIndex] =
        variableTables[variableNumber][wordIndex] or (uint64(1) shl bitInWord)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  result = ""
  while position < data.len and data[position] > ' ':
    result.add data[position]
    position += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var expressionStack: array[stackCapacity, TruthTable]
var variableIndex: array[26, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let expression = nextToken(inputData, scanPos)
  for letterNumber in 0..<26:
    variableIndex[letterNumber] = -1
  var variableCount = 0
  var stackTop = 0
  for pos in countdown(expression.len - 1, 0):
    let symbol = expression[pos]
    if symbol >= 'a' and symbol <= 'z':
      let letterNumber = int(symbol) - firstLetterValue
      if variableIndex[letterNumber] < 0:
        variableIndex[letterNumber] = variableCount
        variableCount += 1
      expressionStack[stackTop] = variableTables[variableIndex[letterNumber]]
      stackTop += 1
    elif symbol == 'N':
      let topIndex = stackTop - 1
      for k in 0..<tableWords:
        expressionStack[topIndex][k] = not expressionStack[topIndex][k]
    else:
      let firstIndex = stackTop - 1
      let secondIndex = stackTop - 2
      case symbol
      of 'C':
        for k in 0..<tableWords:
          expressionStack[secondIndex][k] =
            expressionStack[firstIndex][k] and expressionStack[secondIndex][k]
      of 'D':
        for k in 0..<tableWords:
          expressionStack[secondIndex][k] =
            expressionStack[firstIndex][k] or expressionStack[secondIndex][k]
      of 'I':
        for k in 0..<tableWords:
          expressionStack[secondIndex][k] =
            (not expressionStack[firstIndex][k]) or expressionStack[secondIndex][k]
      of 'E':
        for k in 0..<tableWords:
          expressionStack[secondIndex][k] =
            not (expressionStack[firstIndex][k] xor expressionStack[secondIndex][k])
      else:
        discard
      stackTop = secondIndex + 1
  var isTautology = true
  for k in 0..<tableWords:
    if expressionStack[0][k] != allOnes:
      isTautology = false
      break
  if isTautology:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
