# TAUT — Tautology (SPOJ)

<https://www.spoj.com/problems/TAUT/>

## Problem

An algebra student checks whether a logic formula stays true for every choice of its letters. With up to sixteen letters, testing each choice one at a time takes too long.

Input: the first line gives the number of expressions, at most 35. Each following line holds one prefix-notation expression using `C`, `D`, `I`, `E`, `N`, and lowercase variables. Output: `YES` if the expression is a tautology, `NO` otherwise.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Expressions | at most 35 |
| Distinct variables | at most 16 |
| Expression length | at most 111 characters |
| Judge limit | 3463 ms, 1536 MB |

Sixteen variables produce 65,536 truth assignments, so the program evaluates them together.

The sample input and output:

```
7
IIpqDpNp
NCNpp
Iaz
NNNNNNNp
IIqrIIpqIpr
Ipp
Ezz
```

```
YES
YES
NO
NO
YES
YES
YES
```

## Idea

Check every assignment at once by flipping whole rows of a truth table, like stamping an entire page instead of writing each word. One bit per assignment packs 64 rows into a single machine word.

The program precomputes a truth table for each variable, then scans the prefix expression right to left. A stack of bit tables holds intermediate results. Each operator combines two tables with one bitwise operation per 64-bit word.

Evaluating the expression once per assignment repeats the same work 65,536 times. Bit packing cuts that work by a factor of 64.

Bit-parallel truth tables turn a 65,536-row check into 1,024 word operations per operator.

## Why It Works

Five facts prove the bit-parallel evaluation.

1. Sixteen variables give `2^16 = 65,536` assignments. At 64 bits per word, the table needs 1,024 words.
2. `variableTables[k]` has bit `i` set when variable `k` is true in assignment `i`.
3. Scanning prefix from right to left places each operand on a stack before its operator. `N` complements the top table; a binary operator replaces the top two with their combination.
4. The operators map to bitwise logic. `C` is AND, `D` is OR, `I` is `(not first) or second`, and `E` is `not (first xor second)`.
5. The expression is a tautology when all 1,024 words of the final table equal `allOnes`.

The arrays that hold the computation:

| Term | Meaning |
| --- | --- |
| `variableTables` | precomputed truth table for each of 16 variables |
| `expressionStack` | stack of intermediate truth tables |
| `variableIndex` | maps a letter to its table number |
| `tableWords` | 1,024 words of 64 assignments each |
| `allOnes` | 64-bit word with every bit set |

The first occurrence of a letter assigns it a table, so repeated letters share one column.

A generator truth table for the first sample expression:

```
p q | I p q | D p N p | whole
0 0 |   1   |    1    |   1
0 1 |   1   |    1    |   1
1 0 |   0   |    1    |   1
1 1 |   1   |    1    |   1
```

Every row of `whole` is one, so the answer is `YES`.

## Code

**Constants and variable tables.** Each variable gets a full 64-bit-packed truth table.

```nim
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
```

`assignmentCount` is `1 shl 16`, one per assignment.
`tableWords` is 1,024, since 65,536 divided by 64 is 1,024.
The setup loop sets one bit per assignment where the variable is true.

**Input and helpers.** One buffer holds the stream, and `nextToken` extracts each expression.

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

`nextToken` skips whitespace and returns one contiguous expression.
The output helper flushes at 256 KiB.
The scanner reads only the leading case count.

**Expression evaluation.** The driver scans each expression from its last character to the first.

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

`variableIndex` is reset to `-1` for all 26 letters before each case.
`N` flips the top table in place.

A binary operator writes into the second slot and reduces `stackTop` by one. The final loop checks every word against `allOnes`.

## Complexity

Each operator word is processed a fixed number of times.

| Phase | Time | Space |
| --- | --- | --- |
| Table setup | O(16 × 65,536) | 16 × 1,024 words |
| Input read | one pass over input bytes | input bytes |
| One expression | O(length × 1,024) word ops | O(1,024) stack words |
| Tautology test | O(1,024) word comparisons | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total, 35 cases | O(35 × 111 × 1,024) | fixed tables plus buffers |

At the length bound the driver performs about 4 million word operations per expression.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(L × 2^v / 64) per expression, with v ≤ 16 |
| Space | O(16 × 2^v / 64) for variable tables |

Evaluating each assignment separately costs `O(L × 2^v)` and repeats identical symbol work. The packed version handles 64 assignments per word operation.
