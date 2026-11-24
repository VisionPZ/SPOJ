## Problem

Read up to 35 logical expressions in prefix notation. Operators C, D, I, E and N mean and, or, implies, equivalence and not. Variables are lowercase letters, with at most 16 distinct letters per expression. Each expression has at most 111 characters. Print YES when the expression is true for every assignment of its variables, and NO otherwise.

The statement sets these limits.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 35 |
| Expression length | at most 111 characters |
| Distinct variables | at most 16 |
| Time limit | 3463 ms |
| Memory limit | 1536 MB |

The 16-variable bound lets one truth table cover every assignment.

## Idea

Build one truth table for the whole expression, then inspect every bit of it. Each variable starts as a 65536-bit pattern. Each operator combines two patterns with bitwise word operations. Checking all bits leaves the answer after one pass over 1024 words. Trying assignments one at a time repeats the same evaluation 65536 times per expression.

Cost per operator: 1024 word operations, regardless of assignment count.

## Why It Works

One bit position is reserved for each of the 16 possible variables. Bit index i describes the assignment whose binary digits give the variable values. The table of variable v has bit i set when bit v of i is set.

Each operator maps its two operand tables to one result table:

| Symbol | Result bit |
| --- | --- |
| C | first and second |
| D | first or second |
| I | (not first) or second |
| E | not (first xor second) |
| N | not operand |

A set result bit means the expression holds for that assignment. The scan runs from the last character to the first. A variable pushes its table. The first argument of an operator is on top of the stack, and the second argument sits below it. The result replaces the lower argument, so a binary operator removes one stack slot. The final table is all ones exactly when no assignment makes the expression false.

The generator prints the sample expression IIpqDpNp over p and q:

```
p q | I p q | D p N p | whole
0 0 |   1   |    1    |   1
0 1 |   1   |    1    |   1
1 0 |   0   |    1    |   1
1 1 |   1   |    1    |   1
```

The whole column is 1 for every assignment, so the answer is YES.

## Code

Input and output use one buffer each.

```nim
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
```

The loop covers 16 variables and 65536 bit positions, so it runs once at startup. It marks one bit per true assignment and reuses the tables for every case. Startup cost is 524288 bit sets.

```nim
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
```

The line loop reads all input into one string. `nextToken` skips spaces and collects each expression without allocating per operator. `appendOutput` flushes only after 262144 bytes, which 35 cases never reach.

```nim
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
```

The outer loop runs caseCount times, and the inner loop runs once per character. `nextInt` skips non-digits, and the statement has no signed numbers. Each operator costs 1024 word operations, and the final check costs the same.

## Complexity

Startup builds 16 tables of 1024 words. It takes O(16 * 2^16) time and 128 KB of space. Each expression scans at most 111 characters and applies at most 55 operators. Each operator touches 1024 words, so the whole run costs O(35 * 111 * 1024) word steps, about 4 million. Space stays at O(2^16) bits for the variable tables. Trying assignments directly would cost 65536 full expression evaluations per case.
