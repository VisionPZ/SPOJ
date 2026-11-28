# MOZSAMSA — Sharmmen and Max Subarray (SPOJ)

<https://www.spoj.com/problems/MOZSAMSA/>

## Problem

Find the longest consecutive block whose neighboring values are all equal. In other words, report the longest run of identical values in each array.

The input starts with the test count. Each case gives the array length, then the array values. Print one run length per case.

| item | bound |
|---|---|
| tests t | 1 to 50 |
| array length n | 1 to 100000 |
| array value | -10^18 to 10^18 |
| judge limit | 1000 ms, 1536 MB |

Values fit in a 64-bit integer and may be negative.

Sample input:

```
1
5
1 1 1 2 2
```

Sample output:

```
3
```

## Idea

Measure runs like counting how many identical stamps sit side by side on a sheet. Walk the array once and lengthen the current run when a value repeats its neighbor. Reset the run when the value changes. The largest run seen is the answer, with no array stored.

## Why It Works

1. Adjacent values differ by zero exactly when they are equal.
2. A block with zero differences is a run of one repeated value.
3. A new value starts a fresh run of length one.
4. Tracking the longest run during one pass gives the required length.

| term | meaning |
|---|---|
| `currentRun` | length of the identical run ending at the current value |
| `longestRun` | largest run seen so far |
| `previousValue` | value immediately before the current one |

The scanner reads a minus sign so negative values parse correctly.

Script-generated trace for the sample array:

```
position | value | currentRun | longestRun
1 | 1 | 1 | 1
2 | 1 | 2 | 2
3 | 1 | 3 | 3
4 | 2 | 1 | 3
5 | 2 | 2 | 3
```

The last row keeps 3, matching the sample output.

## Code

**Bulk input and scanner.** The whole stream is read once; the scanner accepts minus signs.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value
```

The sign branch keeps negative values intact.
All cases are parsed before output begins.
Parsing costs one pass over the input bytes.

**Run scan and output.** One pass tracks the current and best run.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  var longestRun = 0
  var currentRun = 0
  var previousValue: int64 = 0
  for numberIndex in 0 .. numberCount - 1:
    let currentValue = int64(nextInt(inputData, scanPos))
    if numberIndex > 0 and currentValue == previousValue:
      currentRun += 1
    else:
      currentRun = 1
    if currentRun > longestRun:
      longestRun = currentRun
    previousValue = currentValue
  appendOutput($longestRun)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each value updates two counters and moves on.
Only the previous value is kept in memory.
Each case writes one buffered line.

## Complexity

One linear scan replaces checking every subarray.

| phase | time | space |
|---|---|---|
| input read | one pass over n values | one input string |
| run scan | one comparison per value | three counters |
| output | one line per case | block buffer |

No array of values is stored.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(1) apart from input bytes |

Checking all subarrays would cost O(n squared) and still find the same run.
