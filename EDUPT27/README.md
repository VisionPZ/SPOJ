# EDUPT27 — Eliminando uma sequencia várias vezes (SPOJ)

<https://www.spoj.com/problems/EDUPT27/>

## Problem

A list of integers and a pattern of integers are given, each ended by the value -1. Remove every consecutive block that matches the pattern exactly, in the same order, and print what remains.

Input has two lines. The first line holds the list, and the second holds the pattern. Both lines stop at -1, which is not part of either sequence. A pattern may be empty, and it may appear many times.

The values are bounded.

| item | bound |
|---|---|
| list and pattern values | 0 to 32000 |
| terminator | -1 |
| list length | thousands of elements |
| judge limit | 1000 ms, 1536 MB |

The pattern must appear as one unbroken run. Removing a block may create a new block at the join.

Sample input:

```
3 5 1 8 9 5 7 -1
5 1 8 -1
```

Sample output:

```
3 9 5 7
```

## Idea

Keep a stack of kept values, like a line of boxes that collapses whenever a matching group reaches the end.

The real algorithm is a single left-to-right pass with a stack and a suffix check. Each value is pushed once. When the last pattern-length values match the pattern, they are popped together. A repeated search from the start would rescan the list after every deletion and cost far more. The takeaway is to notice that every removable block ends at the value currently read.

## Why It Works

1. A removable block ends at the value currently being read.
2. Before that value, the stack holds all earlier values with prior blocks already removed.
3. If the last `patternLength` values equal `patternValues`, that block is removed now.
4. Popping exposes earlier values, so a new match at the join is caught on the next push.
5. Values that never form a block stay on the stack in their original order.

| term | meaning |
|---|---|
| `listValues` | values read from the first line |
| `patternValues` | values read from the second line |
| `survivingValues` | stack of values after all removals |
| `matchesPattern` | true when the stack suffix equals the pattern |

Each value enters the stack once and is popped at most once.

For the first sample the list is 3, 5, 1, 8, 9, 5, 7 and the pattern is 5, 1, 8. The stack reaches 3, 5, 1, 8 and the suffix matches. Those three values are popped, leaving 3, then 9, 5 and 7 join. The result is 3, 9, 5, 7.

The cascade case uses list 10, 4, 6, 8, 4, 6, 8, 12, 12, 9, 1, 3 and pattern 4, 6, 8, 12. The first match pops out, and the second 12 completes a new match. The result is 10, 9, 1, 3.

An empty pattern triggers no check, so the list is printed unchanged. The output separates values with single spaces and ends with a newline.

## Code

**Input and signed scanner.** The scanner accepts the -1 terminator, and both sequences are read until it appears.

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
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

The minus sign is handled because -1 ends each line.
All other values are read as positive integers.
Scanning skips the spaces between values.

**Buffered output and sequence reads.** Each sequence is collected until a scanned value equals -1.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var listValues = newSeq[int]()
while true:
  let scannedValue = nextInt(inputData, scanPos)
  if scannedValue == -1:
    break
  listValues.add scannedValue

var patternValues = newSeq[int]()
while true:
  let scannedValue = nextInt(inputData, scanPos)
  if scannedValue == -1:
    break
  patternValues.add scannedValue
```

The first loop fills the main list.
The second loop fills the pattern.
The terminator is never stored.

**Stack removal and output.** A suffix check after each push removes a completed block.

```nim
let patternLength = patternValues.len
var survivingValues = newSeq[int]()
for listValue in listValues:
  survivingValues.add listValue
  if patternLength > 0 and survivingValues.len >= patternLength:
    var matchesPattern = true
    for patternIndex in 0 .. patternLength - 1:
      if survivingValues[survivingValues.len - patternLength + patternIndex] != patternValues[patternIndex]:
        matchesPattern = false
        break
    if matchesPattern:
      survivingValues.setLen(survivingValues.len - patternLength)

var firstValueWritten = true
for survivingValue in survivingValues:
  if not firstValueWritten:
    appendOutput(" ")
  appendOutput($survivingValue)
  firstValueWritten = false
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The check starts only when the stack is long enough.
A match shortens the stack by one pattern length.
The remaining values are written as one space-separated line.

## Complexity

The pass pushes each list value once and checks a pattern-length suffix.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | two integer arrays |
| stack pass | one push per list value | one integer stack |
| suffix check | up to pattern length per value | constant |
| output | one line | one output buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(list length times pattern length) |
| space | O(list length plus pattern length) |

Restarting a full scan after every deletion would repeat work on the same prefix, while the stack settles each block as soon as it forms.
