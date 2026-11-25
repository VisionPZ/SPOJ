# TCOUNT3 — Counting Triangles III (SPOJ)

<https://www.spoj.com/problems/TCOUNT3/>

## Problem

Twelve level N triangles join into a level N hexagram, the six-pointed star. Count every equilateral triangle, of any side length, that fits in that star.

The input starts with the number of test cases. Each next line contains one level N. Print one count per line. Every answer fits in a 64-bit integer.

| item | bound |
|---|---|
| test cases | given on the first line |
| level N | positive integer with a 64-bit answer |
| answer | unsigned 64-bit integer |
| judge limit | 1000 ms |

The count depends only on N, so one multiplication gives the answer.

Sample input:

```
1
1
```

Sample output:

```
20
```

## Idea

Picture the star as two huge overlapping triangles, like two rulers laid across each other at sixty degrees, and count the triangles they form with one product.

The algorithm evaluates the cubic formula N times (10 N squared plus 9 N plus 1). Each case costs three multiplications and two additions. Drawing and enumerating every triangle costs at least cubic work per case and grows with the level.

A direct product replaces picture counting.

## Why It Works

1. A level N hexagram is the union of two equilateral triangles of side 3N with a common centre.
2. Their overlap is a regular hexagon of side N, so the union contains 12 level N triangles.
3. Enumeration for levels 1 to 6 gives 20, 118, 354, 788, 1480, 2490.
4. Those values fit N(10 N squared plus 9 N plus 1) exactly.
5. The product grows monotonically, so unsigned 64-bit words hold every required answer.

| term | meaning |
|---|---|
| `levelValue` | level read from one input line |
| `triangleTotal` | count computed for that level |

The table lists all values used in the evaluation.

A trace for the first three levels:

```
level  inner factor  total
1      20            20
2      59            118
3      118           354
```

The trace matches both the sample and the next two enumerated levels.

## Code

**Input and output setup.** The program reads the stream once and buffers answer lines.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts any spacing between tokens.
All levels are parsed before output finishes.
The buffer flushes by size and once at the end.

**Level evaluation.** Each level becomes one product.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let levelValue = uint64(nextInt(inputData, scanPos))
  let triangleTotal = levelValue *
                      (10'u64 * levelValue * levelValue + 9'u64 * levelValue + 1'u64)
  appendOutput($triangleTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner factor is formed first and then multiplied by the level.
Unsigned 64-bit arithmetic keeps every digit of large answers.
No loop over triangle sizes is needed.

## Complexity

Every case uses a fixed number of multiplications.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| level evaluation | three multiplications per case | one count per case |
| output | one line per case | block buffer |

The phase table shows that the number of cases sets the run time.

| measure | Big O |
|---|---|
| time | O(input bytes) |
| space | O(input bytes) |

Enumerating triangles would cost cubic work per level, while the formula costs one step.
