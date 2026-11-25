# CALENTAMIENTO — La tarea (SPOJ)

<https://www.spoj.com/problems/CALENTAMIENTO/>

## Problem

Pispirito has a list of non-negative integers. He picks one integer step, then adds that step to some entries, subtracts it from others, or leaves entries alone. Each entry changes at most once. All entries must end equal. Decide whether some step exists.

Input: one line with the entry count, then one line with the entries.
Output: `Si` when a step exists, otherwise `No`. The sample uses Spanish words.

| Item | Bound |
|---|---|
| Entries | 1 to 100000 |
| Entry value | 0 to 10^9 |
| Judge limit | 1000 ms |

Only the count and spacing of distinct values matter.

Sample input:

```
5
1 3 3 2 1
```

Sample output:

```
Si
```

## Idea

Think of sliding marks on a ruler by one fixed gap until all marks stack at one point. Call the shared endpoint V. An entry starting at V - step moves up, one at V + step moves down, and one at V stays. No other starting value can reach V.

So the distinct starting values form at most three equally spaced points. Keep up to four distinct values while scanning. Sort three stored values, then test whether the outer values sum to twice the middle. Each entry costs four comparisons at most, which is constant time.

## Why It Works

1. Every entry ends at one shared value V.
2. An entry moves by at most one step, so it starts at V - step, V, or V + step.
3. Distinct starting values therefore fit a three-point arithmetic progression.
4. Two or fewer distinct values always admit a step; three need equal spacing.

| Term | Meaning |
|---|---|
| `step` | the chosen integer x |
| `V` | the final common value |
| `levels` | distinct starting values |
| `middle` | median of three levels |

Equal spacing makes the step an integer, since the outer difference is even.

Script-generated example from `gen.py`:

```
values: 1 3 3 2 1
distinct levels seen: 1 3 2
sorted levels: 1 2 3
outer plus inner: 1 + 3 = 4
twice middle: 2 * 2 = 4
verdict: Si
```

The traced sample matches the sample answer `Si`.

## Code

**Input scanner and output buffer.** This block reads every line into one string and provides index-based scanning.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and consumes decimal digits by index. `nextToken` handles string tokens. The buffer flushes at 128 KiB.

**Distinct-level decision.** This block collects distinct values and decides the answer.

```nim
let elementCount = nextInt(inputData, scanPos)
var distinctValues: array[4, int]
var distinctCount = 0
for elementIndex in 0..<elementCount:
  let currentValue = nextInt(inputData, scanPos)
  var alreadySeen = false
  for slotIndex in 0..<distinctCount:
    if distinctValues[slotIndex] == currentValue:
      alreadySeen = true
      break
  if not alreadySeen and distinctCount < 4:
    distinctValues[distinctCount] = currentValue
    distinctCount += 1

var canEqualize = false
if distinctCount <= 2:
  canEqualize = true
elif distinctCount == 3:
  var firstValue = distinctValues[0]
  var secondValue = distinctValues[1]
  var thirdValue = distinctValues[2]
  if firstValue > secondValue:
    swap firstValue, secondValue
  if secondValue > thirdValue:
    swap secondValue, thirdValue
  if firstValue > secondValue:
    swap firstValue, secondValue
  canEqualize = firstValue + thirdValue == 2 * secondValue

if canEqualize:
  appendOutput("Si\n")
else:
  appendOutput("No\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops storing after four distinct values. Three comparisons sort the stored levels. The final write clears any remaining bytes.

## Complexity

Input is read once, and each entry costs a bounded number of comparisons.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Distinct scan | one pass, four comparisons per entry | four slots |
| Decision | constant time | constant |
| Output | one write per 128 KiB block | block buffer |

The scan dominates, and the stored levels use fixed space.

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(n) for input, O(1) auxiliary |

A naive search tries each candidate step and rebuilds the list; our single scan avoids that cost.
