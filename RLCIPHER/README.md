# RLCIPHER — Robert Langdon & Cipher (SPOJ)

<https://www.spoj.com/problems/RLCIPHER/>

## Problem

Each gate section shows a number. Keep subtracting 3 or 4 until the number turns negative, and write down the smallest negative value you can reach.

Input starts with the case count T. Each case gives a section count N, then N signed integers on the next line.

Output one line per case with the N entered values, separated by single spaces.

| item | bound |
|---|---|
| cases T | 1 to 1000 |
| sections N | 1 to 100000 |
| sum of N per file | at most 100000 |
| section values | -1000000000 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

The value range is wide, so the answer comes from a rule, not a search.

Sample input:

```
2
3
0 2 1
4
3 2 1 -1
```

Sample output:

```
-4 -2 -3
-4 -2 -3 -1
```

## Idea

Walk down stairs in strides of 3 or 4 and stop the moment you step below the ground floor. Your goal is the lowest step you can stop on.

The stopping rule caps the jump below zero at four. The deepest possible landing is -4 for almost every start, with only 1, 2, and 5 landing higher. A naive recursion branches into two paths per stride and grows exponentially.

A three-way check per number gives the answer in constant time.

## Why It Works

1. Every stride subtracts 3 or 4, so the final value is the start minus a sum of strides.
2. The process stops at the first negative value, so that sum passes the start by at most 4.
3. A landing of -4 needs a final stride of 4 after strides adding up to the start.
4. Every integer from 6 up is a sum of 3s and 4s, so those starts reach -4.
5. Starts 0, 3, and 4 also reach -4 through an empty sum, a 3, or a 4.
6. Start 5 cannot be written as a stride sum, so the deepest landing is -3.
7. Start 1 lands at -3, and start 2 lands at -2, by the same stride limit.
8. A negative start is below zero already, so the process stops at once.

| term | meaning |
|---|---|
| `sectionValue` | the number printed on one section |
| `enteredValue` | the smallest reachable negative value |
| `sectionCount` | number of sections in the case |
| `caseCount` | number of cases in the file |
| `outputBuffer` | block buffer holding the output line |

The table names the values the program carries from token to answer.

A script-traced run on the sample shows the rule at work:

```
section values: [0, 2, 1, 3, 2, 1, -1]
  0 -> -4
  2 -> -2
  1 -> -3
  3 -> -4
  2 -> -2
  1 -> -3
 -1 -> -1
final line: -4 -2 -3 -4 -2 -3 -1
```

The trace matches the first sample case, and the trailing -1 shows a negative input.

The check order matters: negative values keep their sign, then the two exceptions, then the default.
The space guard prints a leading space only after the first value of a line.

## Code

**Input and scanner.** The reader accepts negative tokens and buffers written text.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const smallMinusFour = -4
const smallMinusThree = -3
const smallMinusTwo = -2
const exceptionTwo = 2
const exceptionOne = 1
const exceptionFive = 5

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner stops on a minus sign and folds it into the value.
The named constants keep the three landing values clear at the call site.
The buffer flushes in blocks, so large lines cost one write.

**Landing rule.** Each section maps to its deepest reachable negative value.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sectionCount = nextInt(inputData, scanPos)
  for sectionIndex in 0 .. sectionCount - 1:
    let sectionValue = nextInt(inputData, scanPos)
    var enteredValue = smallMinusFour
    if sectionValue < 0:
      enteredValue = sectionValue
    elif sectionValue == exceptionTwo:
      enteredValue = smallMinusTwo
    elif sectionValue == exceptionOne or sectionValue == exceptionFive:
      enteredValue = smallMinusThree
    if sectionIndex > 0:
      appendOutput(" ")
    appendOutput($enteredValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop bound is the section count from the case header.
Negative inputs return unchanged, before the two exceptions are tested.
Each value costs a constant number of comparisons.

## Complexity

The program scans each input token once and writes one answer per token.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| landing rule | constant work per section | one running value |
| output | one line per case | block buffer |

The total work tracks the number of sections across the file.

| measure | Big O |
|---|---|
| time | O(total N) |
| space | O(1) beyond input and output buffers |

A recursive stride search branches into two paths per step.
The landing rule replaces that search with one decision per value.
