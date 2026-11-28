# PAREN — COUNT PAREN (SPOJ)

<https://www.spoj.com/problems/PAREN/>

## Problem

A boolean expression uses the words `T`, `F`, `and`, `or`, and `xor`. Count the full parenthesizations that evaluate to true, with all operators treated at the same priority.

Input starts with the test count. Each case is one space-separated expression on its own line. Output one count per line.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| expression length | under 100 characters |
| operators | `and`, `or`, `xor`, equal priority |
| judge limit | 1000 ms, 1536 MB |

A single operand counts as one parenthesization of itself. The expression `T and F` has one operator.

Sample input:

```
1
T and F
```

Sample output:

```
0
```

## Idea

Every legal grouping splits at one final operator, like choosing the last joint in a chain. For each interval of operands, store how many groupings give true and how many give false. Combine two intervals through their connecting operator.

Interval dynamic programming costs O(p³) for p operands. Listing every grouping costs Catalan(p−1) evaluations, which grows far faster.

One table of true and false counts covers every grouping.

## Why It Works

1. An interval is a consecutive run of operands between two split points.
2. Every full grouping has exactly one last operator inside that interval.
3. Splitting at that operator gives a left interval and a right interval.
4. `and` is true only when both sides are true.
5. `or` is false only when both sides are false.
6. `xor` is true when exactly one side is true.

| term | meaning |
|---|---|
| `trueWays` | number of groupings of an interval that evaluate to true |
| `falseWays` | number of groupings of an interval that evaluate to false |
| `operatorKinds` | operator code between each pair of operands |
| `splitIndex` | position of the final operator in a grouping |

For `T and F`, the only split gives left true and right false. The `and` rule gives zero true groupings.

The answer matches the sample output.

## Code

**Input and word scanner.** Hand readers load integers and the words on each case line.

```nim
const flushBlockBytes = 1 shl 17
const maxOperands = 55

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

proc skipLineBreaks(data: string, pos: var int) =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    pos += 1

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\t' and
      data[pos] != '\n' and data[pos] != '\r':
    word.add data[pos]
    pos += 1
  return word
```

The word reader stops at a line break, so cases stay separate.

The first character of each word identifies its token kind.

**Output buffer and case parsing.** Words become operand values and operator codes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var trueWays = newSeq[int64](maxOperands * maxOperands)
var falseWays = newSeq[int64](maxOperands * maxOperands)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  skipLineBreaks(inputData, scanPos)
  var operandValues = newSeq[int](0)
  var operatorKinds = newSeq[int](0)
  while scanPos < inputData.len and inputData[scanPos] != '\n' and
      inputData[scanPos] != '\r':
    let word = nextWord(inputData, scanPos)
    if word.len == 0:
      break
    let initial = word[0]
    if initial == 'T' or initial == 't':
      operandValues.add 1
    elif initial == 'F' or initial == 'f':
      operandValues.add 0
    elif initial == 'a':
      operatorKinds.add 0
    elif initial == 'o':
      operatorKinds.add 1
    else:
      operatorKinds.add 2
  let operandCount = operandValues.len
  if operandCount == 1:
    appendOutput($(int64(operandValues[0])))
    outputBuffer.add '\n'
    continue
```

Single operands bypass the interval table.

Operator codes 0, 1, and 2 mean and, or, and xor.

**Interval table.** Each span combines all possible final operators.

```nim
  for operandIndex in 0 .. operandCount - 1:
    let cellIndex = operandIndex * maxOperands + operandIndex
    trueWays[cellIndex] = int64(operandValues[operandIndex])
    falseWays[cellIndex] = 1 - int64(operandValues[operandIndex])
  for spanLength in 2 .. operandCount:
    for leftIndex in 0 .. operandCount - spanLength:
      let rightIndex = leftIndex + spanLength - 1
      let cellIndex = leftIndex * maxOperands + rightIndex
      trueWays[cellIndex] = 0
      falseWays[cellIndex] = 0
      for splitIndex in leftIndex .. rightIndex - 1:
        let leftCell = leftIndex * maxOperands + splitIndex
        let rightCell = (splitIndex + 1) * maxOperands + rightIndex
        let leftTrue = trueWays[leftCell]
        let leftFalse = falseWays[leftCell]
        let rightTrue = trueWays[rightCell]
        let rightFalse = falseWays[rightCell]
        case operatorKinds[splitIndex]:
          of 0:
            trueWays[cellIndex] += leftTrue * rightTrue
            falseWays[cellIndex] += (leftTrue + leftFalse) * (rightTrue + rightFalse) -
              leftTrue * rightTrue
          of 1:
            falseWays[cellIndex] += leftFalse * rightFalse
            trueWays[cellIndex] += (leftTrue + leftFalse) * (rightTrue + rightFalse) -
              leftFalse * rightFalse
          else:
            trueWays[cellIndex] += leftTrue * rightFalse + leftFalse * rightTrue
            falseWays[cellIndex] += leftTrue * rightTrue + leftFalse * rightFalse
  appendOutput($(trueWays[operandCount - 1]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Shorter spans are filled before longer ones.

Counts fit in int64 for expressions under 100 characters.

## Complexity

Each case parses tokens, then fills one interval table in increasing span length.

| phase | time | space |
|---|---|---|
| input read | one pass over case lines | one input string |
| parsing | O(p) words per case | O(p) token arrays |
| interval table | O(p³) split work | O(p²) count cells |
| output | one buffered write per block | block buffer |

The two count arrays are reused across all cases.

| measure | Big O |
|---|---|
| time per case | O(p³) |
| space per case | O(p²) |

Enumerating all Catalan groupings would need exponential time.

The interval table counts them without listing any grouping.
