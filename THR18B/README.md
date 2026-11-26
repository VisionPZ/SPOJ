# THR18B — Dart Scoring (SPOJ)

<https://www.spoj.com/problems/THR18B/>

## Problem

A dartboard has ten scoring rings centered at the origin: a hit at distance `d` millimeters scores 10 for `d ≤ 10`, then 9, 8, and so on down to 1 for `d ≤ 190`, and 0 beyond that. The program sums the scores of all shots.

Input starts with the number of shots `N`, then `N` lines each hold two integers, the coordinates `(x, y)` of one dart in millimeters. Output holds one line with the total score.

| Item | Bound |
|---|---|
| Shots `N` | 1 ≤ N ≤ 100 |
| Coordinates | \|x\|, \|y\| ≤ 300 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
2
4 7
-31 -5
```

```
18
```

## Idea

Score every dart by comparing its squared distance from the origin against the squared ring radii 100, 900, 2500, ..., 36100 and stop at the first radius that covers the point. Think of sliding a ruler marked with squared radii: the first mark past the point names the ring. This avoids square roots and floating point entirely, and each shot costs at most ten integer comparisons instead of a distance computation plus a table lookup with rounding risk.

## Why It Works

1. A point lies inside a ring of radius 10, 30, 50, ..., 190 exactly when `x*x + y*y` is at most the square of that radius, so no square root is needed.
2. The squared ring radii 10, 30, 50, ..., 190 are exactly `ringSquaredLimits`.
3. Scanning the limits in increasing order finds the innermost ring that contains the point, which is the scored ring.
4. Points past the last limit fall through the loop and keep `shotScore = 0`.
5. Sums of squares up to 300² + 300² = 180000 fit in a 32-bit integer.

| Term | Meaning |
|---|---|
| `ringSquaredLimits` | squared radii 100, 900, ..., 36100 |
| `squaredDistance` | `xCoord * xCoord + yCoord * yCoord` |
| `shotScore` | 10 minus the ring index, or 0 |
| `totalScore` | running sum of shot scores |

The sample runs through the ladder as:

```
(4,7):   squared distance 16+49=65  <= 100  -> ring 0 -> 10
(-31,-5): squared distance 961+25=986 > 900, <= 2500 -> ring 2 -> 8
total 10 + 8 = 18
```

## Code

**Input and signed scanner.** This block loads stdin and reads integers that may be negative.

```nim
const flushBlockBytes = 1 shl 17
const ringSquaredLimits = [100, 900, 2500, 4900, 8100, 12100, 16900, 22500, 28900, 36100]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

One readLine loop collects all input bytes.
The minus branch handles coordinates left of or below the center.
Scanning costs one pass over the consumed characters.

**Ring lookup per shot.** This block scores each dart with integer squares.

```nim
let dartCount = nextInt(inputData, scanPos)
var totalScore = 0
for dartIndex in 0 .. dartCount - 1:
  let xCoord = nextInt(inputData, scanPos)
  let yCoord = nextInt(inputData, scanPos)
  let squaredDistance = xCoord * xCoord + yCoord * yCoord
  var shotScore = 0
  for ringIndex in 0 .. ringSquaredLimits.len - 1:
    if squaredDistance <= ringSquaredLimits[ringIndex]:
      shotScore = 10 - ringIndex
      break
  totalScore += shotScore
```

The break keeps the first, innermost matching ring.
`10 - ringIndex` turns the ring position into its score.
No square root is ever computed.

**Buffered output.** This block writes the total once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

## Complexity

The cost splits into input, ten comparisons per shot, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scoring | O(10) per shot | constant |
| Output | one small write | buffer |

| Measure | Big O |
|---|---|
| Time | O(N) |
| Space | O(N) for the input buffer |

A floating-point distance plus a rounding check would also work, but integer squares remove every rounding question.
