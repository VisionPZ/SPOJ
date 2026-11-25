<https://www.spoj.com/problems/AKVOD05/>

## Problem

Ross writes N numbers. The first K numbers are given. Every later number is the smallest non-negative integer absent from the previous K numbers. Report the Nth number.

Input starts with T, the number of cases. Each case gives N and K, then K integers on the next line. Output prints one integer per case.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| known values K | 1 to 100000 |
| target position N | K+1 to 100000000 |
| known value | 0 to 100000000 |
| judge limit | 2000 ms, 1536 MB |

The previous K numbers form a sliding window. A generated value is at most K, since the window holds only K entries.

Sample input:

```
2
7 4
0 4 3 2
8 5
4 7 2 3 0
```

Sample output:

```
4
5
```

## Idea

After K+1 generated values the sliding window holds K+1 different numbers, like a full set of numbered tickets with one ticket missing. That window then repeats every K+1 steps, so remote positions need only one lookup. Generate 2K+1 values, use a frequency table to track the smallest missing value, and map large N into one stored period. Simulating up to N would take too long, since N reaches 1e8.

## Why It Works

1. The mex of a window never exceeds K, because the window has K entries.
2. The window for position t contains positions t-K through t-1.
3. Compute the mex, then slide the window by removing position t-K and adding the new value.
4. When a value below the current mex disappears, it becomes the new mex.
5. By position 2K+1 the last K+1 values form one full period of length K+1.
6. Any later position maps into that period with one modulo operation.

| term | meaning |
|---|---|
| `windowSize` | K, the number of previous values in the window |
| `frequency` | count of each value from 0 to K inside the window |
| `currentMex` | smallest value with zero count |
| `sequence` | generated values stored up to one full period past `periodStart` |
| `periodStart` | index 2K+1, where repetition has begun |

With K=4 and values 0 4 3 2, the mex sequence starts 1, 0, 4, 3, 2. The window at index 9 again holds 1, 0, 4, 3, 2, so position 7 has value 4 and position 100000000 maps into that same cycle. Values above K are ignored by the frequency table because no mex can equal them.

## Code

**Input and scanner.** The reader loads all input and parses integers by hand.

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

The scanner skips whitespace and line breaks.
It builds each integer one digit at a time.
The buffer flushes only after a large block.

**Generation and lookup.** Each case slides the window up to one period past the start.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let targetPosition = nextInt(inputData, scanPos)
  let windowSize = nextInt(inputData, scanPos)
  let periodStart = 2 * windowSize + 1
  let simulationEnd = periodStart + windowSize + 1
  var sequence = newSeq[int](simulationEnd + 1)
  var frequency = newSeq[int](windowSize + 2)
  for position in 0 .. windowSize - 1:
    let knownValue = nextInt(inputData, scanPos)
    sequence[position] = knownValue
    if knownValue >= 0 and knownValue <= windowSize:
      frequency[knownValue] += 1
  var currentMex = 0
  while frequency[currentMex] > 0:
    currentMex += 1
  for position in windowSize .. simulationEnd:
    let generatedValue = currentMex
    sequence[position] = generatedValue
    let expiredValue = sequence[position - windowSize]
    if expiredValue >= 0 and expiredValue <= windowSize:
      frequency[expiredValue] -= 1
      if frequency[expiredValue] == 0 and expiredValue < currentMex:
        currentMex = expiredValue
    frequency[generatedValue] += 1
    while frequency[currentMex] > 0:
      currentMex += 1
  let targetIndex = targetPosition - 1
  if targetIndex < periodStart:
    appendOutput($sequence[targetIndex])
  else:
    let periodLength = windowSize + 1
    let withinPeriod = (targetIndex - periodStart) mod periodLength
    appendOutput($sequence[periodStart + withinPeriod])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The mex is read before the window slides.
Removing a small value can lower the mex immediately.
The final modulo maps large positions into the stored period.

## Complexity

Generation runs once per case and stops after three K values.

| phase | time | space |
|---|---|---|
| read input | one scan of all tokens | one input string |
| build frequency | K increments | array of K+2 counters |
| generate period | 2K+2 steps | array of 3K+2 values |
| answer lookup | constant time | none extra |

| measure | Big O |
|---|---|
| time per case | O(K) |
| space per case | O(K) |

Simulating each step up to N would cost O(N) per case and fail for N=1e8. The period removes that dependence on N.
