# NDS — Increasing numbers (SPOJ)

<https://www.spoj.com/problems/NDS/>

## Problem

Given an array, find the smallest possible last value of a strictly increasing subsequence of length L. Print -1 when no such subsequence exists.

Each test case holds the array size N, then N array values, then the length L. Values lie from 0 to 1000000.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | up to 10 |
| array size N | up to 1000000 |
| array value a[i] | 0 to 1000000 |
| judge limit | 100 ms, 1536 MB |

The large array size calls for a logarithmic step per element.

Sample input:

```
1
7
9 7 2 5 4 11 12 
3
```

Sample output:

```
11
```

## Idea

Keep the smallest possible ending value for each subsequence length, like a row of markers that slides left whenever a smaller tail appears.

For each array value, find the longest length whose stored tail is strictly smaller. The value then becomes a candidate tail for the next length. Binary search locates that length because the tails increase with length. A quadratic check over all earlier elements would repeat work for every pair. The marker array gives one logarithmic step per element.

## Why It Works

1. The stored tail for length l is the smallest ending value among all increasing subsequences of length l.
2. Those tails strictly increase with l, so binary search finds the longest tail below the current value.
3. Appending the current value to that subsequence yields a valid length l plus one subsequence.
4. Replacing a larger tail by the current value never hurts future extensions.
5. If length L never appears, no increasing subsequence of that length exists.

The main terms:

| term | meaning |
|---|---|
| `tails` | smallest ending value for each subsequence length |
| `currentLength` | longest subsequence found so far |
| `targetLength` | requested length L |
| `lowBound` | binary search cursor over lengths |

The invariant on `tails` makes each update exact.

A worked trace from the oracle for the sample array:

```
value  9  tails[1]=9
value  7  tails[1]=7
value  2  tails[1]=2
value  5  tails[2]=5
value  4  tails[2]=4
value 11  tails[3]=11
value 12  tails[4]=12
```

The tail for length 3 is 11, which is the sample answer.

## Code

**Input and scanning.** All numbers enter one string and the hand parser walks them.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The parser skips spaces and line breaks.
Array values are nonnegative.
One pass reads the whole input.

**Output buffer.** Answers are written in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush threshold is 131072 bytes.
The minus sign in -1 is written as text only.
A final flush handles the last lines.

**Main loop.** Each value updates one tail via binary search.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = nextInt(inputData, scanPos)
  let targetLength = nextInt(inputData, scanPos)
  if targetLength > elementCount:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  var tails = newSeq[int](elementCount + 1)
  tails[0] = -1
  var currentLength = 0
  for value in values:
    var lowBound = 0
    var highBound = currentLength
    while lowBound < highBound:
      let middle = (lowBound + highBound + 1) div 2
      if tails[middle] < value:
        lowBound = middle
      else:
        highBound = middle - 1
    let newLength = lowBound + 1
    tails[newLength] = value
    if newLength > currentLength:
      currentLength = newLength
  if currentLength >= targetLength:
    appendOutput($tails[targetLength])
  else:
    appendOutput("-1")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sentinel at index zero is below every array value.
The search uses an upper midpoint to find the last valid length.
A request beyond the array size is rejected before allocation.

## Complexity

Each array element performs one binary search over the current subsequence lengths.

| phase | time | space |
|---|---|---|
| input read | one pass over array values | one input string |
| tail updates | one binary search per value | one tail per length |
| output | one write per block | block buffer |

The tail array is sized to the input case, not to the number of cases.

The asymptotic bounds:

| measure | Big O |
|---|---|
| time per case | O(N log N) |
| space per case | O(N) |

Checking every earlier element per value costs O(N squared), while binary search reduces each step to logarithmic time.
