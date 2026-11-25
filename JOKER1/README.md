# JOKER1 — Knifes Are Fun (SPOJ)

<https://www.spoj.com/problems/JOKER1/>

## Problem

Each knife accepts one integer from 1 up to its own cap. Count assignments where every knife gets a different integer, modulo 1,000,000,007. Print zero when no such assignment exists.

| item | bound |
|---|---|
| test cases | 1 to 666 |
| knives per case | 1 to 66 |
| cap per knife | 1 to 3000 |
| judge limit | 500 ms, 1536 MB |

Input starts with the test count. Each case gives the knife count, then one line of caps. Output has one answer per case, then the line `KILL BATMAN`.

Sample input:

```
3
1
7
2
5 8
3
2 1 2
```

Sample output:

```
7
35
0
KILL BATMAN
```

## Idea

Order the caps like lining up people by height, then give each person the number of shorter people as a discount. The smallest cap offers every value below it; each later cap loses one value for every knife already served. Use insertion sort on the caps, multiply the remaining choices, and reduce modulo the prime. Naive enumeration tries every assignment and explodes past a handful of knives.

Sorting makes each multiplication a constant-time step, so the whole case costs one sort. The final sentinel line closes the output.

## Why It Works

1. Sorting orders knives by cap, from smallest to largest.
2. Earlier knives only use values at or below their own caps, which are no larger than the current cap.
3. After `knifeIndex` earlier knives, exactly `knifeIndex` values at or below the current cap are gone.
4. The current knife therefore has `freeNumbers` choices, where `freeNumbers` is `maxNumbers[knifeIndex] - knifeIndex`.
5. A non-positive choice count means some knives share a value, so the case contributes zero.
6. Multiplying the choice counts gives the total, since each knife picks freely among its remaining values.

| term | meaning |
|---|---|
| `maxNumbers` | caps after insertion sort, in ascending order |
| `freeNumbers` | unused values available to one knife |
| `ways` | running product of choice counts |
| `modulusValue` | 1,000,000,007, the modular divisor |

The table names every value that drives the product.

A trace from the generator for caps `5 8` uses the value-sweep oracle. The oracle groups knives by cap and counts free values at each step.

```
cap 5: group size 1, free values 5, choices 5, loaded 1
cap 8: group size 1, free values 7, choices 7, loaded 2
product: 5 * 7 = 35
```

The oracle prints 35, matching the sample. For caps `1 2 2`, cap 2 has one free value for two knives, so the oracle prints zero.

## Code

**Input and scanning.** The hand reader loads every test case into one buffer.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

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

The scanner skips separators and returns one token.
Caps fit in a signed 32-bit value.
Reading once avoids per-line parsing overhead.

**Output buffer.** Large case counts share one write path.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB of text.
No write happens per case.
One final flush closes the output.

**Sorted product.** Insertion sort exposes the choice count for each knife.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let knifeCount = nextInt(inputData, scanPos)
  var maxNumbers = newSeq[int](knifeCount)
  for knifeIndex in 0 .. knifeCount - 1:
    maxNumbers[knifeIndex] = nextInt(inputData, scanPos)
  for rightIndex in 1 .. knifeCount - 1:
    let currentMax = maxNumbers[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and maxNumbers[leftIndex] > currentMax:
      maxNumbers[leftIndex + 1] = maxNumbers[leftIndex]
      leftIndex -= 1
    maxNumbers[leftIndex + 1] = currentMax
```

Insertion sort suits at most 66 values.
The inner loop shifts larger caps right.
Sorting costs at most a few thousand comparisons per case.

**Answer and sentinel.** The product is reduced at every step and written once.

```nim
  var ways: int64 = 1
  for knifeIndex in 0 .. knifeCount - 1:
    let freeNumbers = maxNumbers[knifeIndex] - knifeIndex
    if freeNumbers <= 0:
      ways = 0
    else:
      ways = (ways * int64(freeNumbers)) mod int64(modulusValue)
  appendOutput($ways)
  outputBuffer.add '\n'
appendOutput("KILL BATMAN")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The accumulator stays in `int64` before reduction.
A zero factor collapses the product immediately.
The sentinel follows the last answer on its own line.

## Complexity

Sorting drives the cost; the product pass is linear.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| insertion sort | up to 66 squared shifts per case | one cap array |
| product pass | one step per knife | constant |
| output | one flush per block | one output string |

The table shows that sorting dominates small cases.

| measure | Big O |
|---|---|
| time per case | O(N^2) for N knives |
| space per case | O(N) |

Enumerating every assignment would take O(maxNumber^N), so sorting and multiplying is the practical choice. The product of sorted free counts gives the exact answer.
