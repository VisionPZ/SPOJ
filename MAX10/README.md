# MAX10 — Maximum of Ten (SPOJ)
<https://www.spoj.com/problems/MAX10/>

## Problem

Read ten non-negative integers from one line and report the largest one with a fixed Indonesian label.

The input has one line with ten space-separated integers.
The output is one line: the text "Bilangan terbesar: " followed by the largest integer.

| item | bound |
|---|---|
| integer count | exactly 10 |
| each integer | 0 to 9999999999 |
| judge limit | 1000 ms, 1536 MB |

The label and the trailing space are part of the required output.

Sample input:

```
3 3 2 1 1 7 6 7 1 7
```

Sample output:

```
Bilangan terbesar: 7
```

## Idea

Keep a running champion, like a scoreboard that only changes for a new high score.

Start the champion at zero.
Read each value and replace the champion only when the value is larger.
After ten values the champion is the maximum.
Sorting all ten values would also work but needs more work.
The running champion uses one comparison per value.

This trick is the whole solution.

## Why It Works

1. All values are non-negative, so zero is a safe starting champion.
2. Each comparison keeps the largest value seen so far.
3. After the last value the champion equals the maximum of all ten.

| term | meaning |
|---|---|
| `largestValue` | the largest value seen so far |
| `candidate` | the value read in one pass |
| `expectedCount` | the fixed count of ten |

For the sample the running champion changes at values 3, 7.
It stays 7 through 6, 7, 1, 7.
The final line is "Bilangan terbesar: " followed by 7.

## Code

**Input and scanning.** The reader loads the single line into one string.

```nim
const flushBlockBytes = 1 shl 17
const expectedCount = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value
```

The scanner skips spaces and builds digits into an integer.
Values stay in int64 so the largest bound is safe.

**Champion scan and output.** Each value updates the champion when needed.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var largestValue: int64 = 0
var valueIndex = 0
while valueIndex < expectedCount:
  let candidate = nextInt(inputData, scanPos)
  if candidate > largestValue:
    largestValue = candidate
  valueIndex += 1

appendOutput("Bilangan terbesar: ")
appendOutput($largestValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The label is written before the number.
One final flush writes the short line.

## Complexity

Reading and comparing both scale with the fixed count of ten values.

| phase | time | space |
|---|---|---|
| input read | one pass over the line | one input string |
| champion scan | ten comparisons | one integer |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(1) |

Sorting ten values would cost more comparisons than one linear scan.

The champion scan is the smallest method that gives the exact answer.
