# TREEII — Yet-Yet Another Counting Problem (SPOJ)

<https://www.spoj.com/problems/TREEII/>

## Problem

Count unlabeled rooted trees with n nodes where all nodes at the same depth have the same number of children. Report each answer modulo 1000000007.

Input contains one integer n per line until end of file. Output one line per case in the form `Case X: Y`, where X starts at one.

| item | bound |
|---|---|
| nodes n | 1 to 1000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The node bound allows a one-time table that answers every test case in constant time.

Sample input:

```
1
2
3
40
50
600
700
```

Sample output:

```
Case 1: 1
Case 2: 1
Case 3: 2
Case 4: 924
Case 5: 1998
Case 6: 315478277
Case 7: 825219749
```

## Idea

A level of equal-degree nodes acts like one stack of identical boxes: only its size matters. The root has c children, and each child subtree has the same shape, so removing the root leaves c identical trees. Dynamic programming over subtree size adds the divisor contributions once, and each size costs only its divisor count. Enumerating full tree shapes would cost far more. Takeaway: reduce a tree to a divisor sum over subtree sizes.

## Why It Works

1. Equal-depth nodes share a child count, so a level is described by one number.
2. The root has c children, and the remaining n-1 nodes split into c equal subtrees.
3. Each subtree has (n-1)/c nodes, so c must divide n-1.
4. Unlabeled subtrees of a fixed size are identical, so one subtree count suffices.
5. Hence g(n) equals the sum of g(d) over divisors d of n-1, with g(1) = 1.

| term | meaning |
|---|---|
| `treeCounts` | table of counts by subtree size |
| `largestSize` | biggest n in the input |
| `divisorSum` | sum over divisors of the current remainder |
| `modulusValue` | 1000000007, the output modulus |

A script trace of the first values:

```
size : count : divisors of size-1
1    : 1     : none
2    : 1     : 1
3    : 2     : 1, 2
4    : 3     : 1, 3
5    : 5     : 1, 2, 4
```

The count for size five is 1 + 1 + 3 = 5, matching the divisor rule.

Each divisor add reduces modulo `modulusValue`, so totals stay within int64.

## Code

**Input and maximum.** The reader stores all cases and records the largest size.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'i64

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

var largestSize = 0
while scanPos < inputData.len:
  let sizeValue = nextInt(inputData, scanPos)
  if sizeValue > largestSize:
    largestSize = sizeValue
  if scanPos >= inputData.len:
    break
```

The first pass scans all integers once.
The scanner ignores line breaks and spaces.
The maximum bounds the table allocation.

**Count table.** Each size adds the counts of all divisors of the previous size.

```nim
var treeCounts = newSeq[int64](largestSize + 2)
treeCounts[1] = 1
var treeSize = 2
while treeSize <= largestSize:
  var divisorSum: int64 = 0
  var divisorValue = 1
  let remainderValue = treeSize - 1
  while divisorValue * divisorValue <= remainderValue:
    if remainderValue mod divisorValue == 0:
      divisorSum = (divisorSum + treeCounts[divisorValue]) mod modulusValue
      let pairedDivisor = remainderValue div divisorValue
      if pairedDivisor != divisorValue:
        divisorSum = (divisorSum + treeCounts[pairedDivisor]) mod modulusValue
    divisorValue += 1
  treeCounts[treeSize] = divisorSum
  treeSize += 1
```

Divisors are found in pairs up to the square root.
The pair check avoids adding a square divisor twice.
Every addition reduces modulo `modulusValue`.

**Output.** The second pass emits one labeled answer per case.

```nim
scanPos = 0
var caseIndex = 0
while scanPos < inputData.len:
  let sizeValue = nextInt(inputData, scanPos)
  if sizeValue == 0 and scanPos >= inputData.len:
    break
  if sizeValue < 1:
    continue
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & $treeCounts[sizeValue])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan restarts at the first byte.
A trailing newline cannot create an extra case.
The buffer flushes once after all lines are built.

## Complexity

The table build dominates the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over case integers | one input string |
| count table | one divisor scan per size | one count per size |
| output | one line per case | block buffer |

The divisor loop stops at the square root of each remainder.

| measure | Big O |
|---|---|
| time | O(n_max sqrt(n_max) + cases) |
| space | O(n_max) |

Enumerating tree shapes would cost exponential time. Takeaway: the divisor recurrence builds all answers in one cheap table.
