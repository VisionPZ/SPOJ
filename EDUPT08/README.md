# EDUPT08 — Conjuntos (SPOJ)

<https://www.spoj.com/problems/EDUPT08/>

## Problem

Two sorted sets of numbers are given. Print their intersection on one line and their union on the next line.

Input starts with the sizes n and m, followed by the n values of the first set and the m values of the second set. An empty set is a blank line. Each output line ends with a space followed by a newline, and an empty line holds that space alone.

The sets stay small.

| item | bound |
|---|---|
| sizes n and m | 0 to 30 |
| each element | 0 to 1000, sorted ascending |
| judge limit | 1000 ms, 1536 MB |

Sorted input lets one pass over both lists produce each answer.

Sample input:

```
5 6
3 4 5 7 22
5 7 9 18 22 25
```

Sample output:

```
5 7 22 
3 4 5 7 9 18 22 25 
```

## Idea

Walk two sorted lines like two zippers, like matching names on two sorted guest lists.

The real algorithm is a two-pointer merge. Equal values go to the intersection and once to the union. Smaller values go only to the union. A nested search would compare every pair, while the merge advances each cursor once. The takeaway is to exploit the given sort order.

## Why It Works

1. Both `firstSet` and `secondSet` arrive in ascending order.
2. When the two cursor values match, the value belongs to both sets.
3. When they differ, the smaller value belongs only to the union.
4. Advancing the smaller cursor keeps both lists aligned.
5. Remaining tail values append directly to the union.

| term | meaning |
|---|---|
| `firstCursor` | position in the first set |
| `secondCursor` | position in the second set |
| `intersectionText` | common values with a trailing space each |
| `unionText` | all distinct values with a trailing space each |

Each cursor moves forward only, so no value is compared twice.

For the sample the cursors meet at 5, then 7, then 22. Those three values form the intersection. The merge also emits 3, 4, 9, 18 and 25 on the union line.

An empty result line is written as a single space before the newline. This matches the stated output contract exactly.

## Code

**Input and scanner.** One read loop collects the stream, and a digit scanner yields each value.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
```

The scanner skips spaces and blank lines.
Each set element is read as a plain integer.
Values are sorted, so no sorting step appears.

**Input and first pass.** The reader loads both sets and computes the intersection with matched cursors.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let firstSetSize = nextInt(inputData, scanPos)
let secondSetSize = nextInt(inputData, scanPos)
var firstSet = newSeq[int](firstSetSize)
for elementIndex in 0 .. firstSetSize - 1:
  firstSet[elementIndex] = nextInt(inputData, scanPos)
var secondSet = newSeq[int](secondSetSize)
for elementIndex in 0 .. secondSetSize - 1:
  secondSet[elementIndex] = nextInt(inputData, scanPos)

var intersectionText = ""
var firstCursor = 0
var secondCursor = 0
while firstCursor < firstSetSize and secondCursor < secondSetSize:
  if firstSet[firstCursor] == secondSet[secondCursor]:
    intersectionText.add $(firstSet[firstCursor])
    intersectionText.add ' '
    firstCursor += 1
    secondCursor += 1
  elif firstSet[firstCursor] < secondSet[secondCursor]:
    firstCursor += 1
  else:
    secondCursor += 1
```

Equal values advance both cursors together.
A smaller value advances only its own cursor.
Every emitted value carries a trailing space.

**Second pass and output.** A fresh merge builds the union, then both lines are buffered.

```nim
var unionText = ""
firstCursor = 0
secondCursor = 0
while firstCursor < firstSetSize or secondCursor < secondSetSize:
  if secondCursor >= secondSetSize or (firstCursor < firstSetSize and firstSet[firstCursor] < secondSet[secondCursor]):
    unionText.add $(firstSet[firstCursor])
    unionText.add ' '
    firstCursor += 1
  elif firstCursor >= firstSetSize or secondSet[secondCursor] < firstSet[firstCursor]:
    unionText.add $(secondSet[secondCursor])
    unionText.add ' '
    secondCursor += 1
  else:
    unionText.add $(firstSet[firstCursor])
    unionText.add ' '
    firstCursor += 1
    secondCursor += 1

if intersectionText.len == 0:
  appendOutput(" ")
appendOutput(intersectionText)
outputBuffer.add '\n'
if unionText.len == 0:
  appendOutput(" ")
appendOutput(unionText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Exhausted sets fall through to the other side.
Matched values are added once to the union.
An empty line still writes one space.

## Complexity

Both passes walk the two sets once each.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | two integer arrays |
| intersection pass | up to n plus m cursor steps | one text buffer |
| union pass | up to n plus m cursor steps | one text buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(n + m) |
| space | O(n + m) |

Testing every value of one set against every value of the other would take O(n times m), while the merge finishes in linear time.
