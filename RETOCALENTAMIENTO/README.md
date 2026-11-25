# RETOCALENTAMIENTO — Pertre (SPOJ)

<https://www.spoj.com/problems/RETOCALENTAMIENTO/>

## Problem

The visible moon repeats a fixed 30-day cycle of sizes from 0 up to 15 and back to 1. Given several consecutive observations, decide whether the next size must grow, must shrink, or cannot be determined.

The input starts with the observation count. The next line holds that many sizes. Print CRECIENTE for certain growth, MENGUANTE for certain shrink, or -1.

| item | bound |
|---|---|
| observations n | 1 to 92 |
| observed size | 0 to 15 |
| judge limit | 1000 ms, 1536 MB |

The input is guaranteed consistent with some point in the cycle.

Sample input:

```
5
3 4 5 6 7
```

Sample output:

```
CRECIENTE
```

## Idea

Try every starting point on the moon's calendar, like sliding a printed year of phases under a fixed window of observations. Keep only starting points that reproduce all records. Look at the next day for each survivor. If every survivor grows, print growth; if every survivor shrinks, print shrink; otherwise the answer is undecided.

## Why It Works

1. The cycle has 30 positions, so only 30 starting points exist.
2. A starting point survives when every observed size matches its phase.
3. Consistent input guarantees at least one survivor.
4. All survivors agree on the next move exactly when the answer is certain.

| term | meaning |
|---|---|
| `moonSize` | visible size at one phase of the 30-day cycle |
| `startPhase` | phase assigned to the first observed day |
| `sawIncrease` | some survivor predicts a larger next size |
| `sawDecrease` | some survivor predicts a smaller next size |

Both flags together mean the records cannot settle the question.

Script-generated trace for the first sample:

```
observation | 3 | 4 | 5 | 6 | 7
phase | 3 | 4 | 5 | 6 | 7
next phase | 8, next size 8 -> growth
```

Only one start phase fits, so the verdict is CRECIENTE.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

```nim
const flushBlockBytes = 1 shl 17
const cycleLength = 30
const peakDay = 15

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

proc moonSize(dayPhase: int): int =
  if dayPhase <= peakDay:
    return dayPhase
  return cycleLength - dayPhase
```

The two constants describe the fixed cycle.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Survivor search and output.** Every possible start phase is checked once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dayCount = nextInt(inputData, scanPos)
var observed = newSeq[int](dayCount)
for dayIndex in 0 .. dayCount - 1:
  observed[dayIndex] = nextInt(inputData, scanPos)

var sawIncrease = false
var sawDecrease = false
for startPhase in 0 .. cycleLength - 1:
  var matches = true
  for dayIndex in 0 .. dayCount - 1:
    if moonSize((startPhase + dayIndex) mod cycleLength) != observed[dayIndex]:
      matches = false
      break
  if not matches:
    continue
  let lastSize = moonSize((startPhase + dayCount - 1) mod cycleLength)
  let nextSize = moonSize((startPhase + dayCount) mod cycleLength)
  if nextSize > lastSize:
    sawIncrease = true
  else:
    sawDecrease = true

if sawIncrease and not sawDecrease:
  appendOutput("CRECIENTE")
elif sawDecrease and not sawIncrease:
  appendOutput("MENGUANTE")
else:
  appendOutput("-1")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop covers exactly 30 start phases.
A mismatch stops that start phase early.
One verdict is written from the block buffer.

## Complexity

Thirty fixed starts keep the work small.

| phase | time | space |
|---|---|---|
| input read | one pass over n sizes | one input string |
| survivor search | at most 30 times n comparisons | array of n observations |
| output | one line | block buffer |

The cycle length is constant, so cost grows only with observations.

| measure | Big O |
|---|---|
| time | O(30 n) |
| space | O(n) |

Trying every calendar beyond one cycle would repeat the same 30 phases.
