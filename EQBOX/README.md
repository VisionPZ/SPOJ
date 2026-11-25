# EQBOX — Equipment Box (SPOJ)
<https://www.spoj.com/problems/EQBOX/>

## Problem

A mechanic crosses a tiled floor carrying a rigid box.
A single touch on a tile edge springs a trap, so the placement must be exact.

Read `T` cases. Each gives tile sides `A` and `B` and box sides `X` and `Y`.
The box may rotate.
Print `Escape is possible.` when the box fits on one tile without crossing its border.
Print `Box cannot be dropped.` otherwise.
Touching an edge counts as fitting.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Test cases `T` | about 10000 |
| Each side | 1 to 50000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |
| Source limit | 50000 B |

These bounds keep one case in a few integer variables.

The sample input and expected output follow verbatim.

```
2
10 10 8 8
8 8 10 10
```

```
Escape is possible.
Box cannot be dropped.
```

An 8 by 8 box fits a 10 by 10 tile, but not the reverse.

## Idea

Sort each shape's sides so the short side comes first, like fitting a book into a sleeve.
If the box cannot lie straight, test one tilted placement using the box diagonal and three angle functions.

The straight test compares short with short and long with long.
The tilted test uses arcsin and arccos on the diagonal.
Each case costs a few comparisons and three math calls.
Scanning trial angles would multiply the work by the angle count.
Sort, test straight, then test one tilt.

## Why It Works

Four facts prove the method.

1. A rectangle fits a tile when all four corners stay inside.
   The tight fit touches all four tile sides.
2. If the box short side exceeds the tile short side, no tilt helps.
   Every straight slice of a rectangle is at least its short side.
3. The box diagonal and three angles describe the tilted placement.
4. The factor two in the angle test accounts for the two box diagonals.
   The small tolerance handles rounding at exact edge contact.

The angle terms and their roles follow.

| Term | Meaning |
| --- | --- |
| `boxDiagonal` | hypotenuse of the box sides |
| `boxAngle` | arctan of short over long for the box |
| `wideAngle` | arcsin of tile long side over the diagonal |
| `requiredAngle` | arccos of tile short side over the diagonal |

The fit holds when `wideAngle - 2.0 * boxAngle >= requiredAngle - 1e-12`.

A script evaluates the forum example with a 100 by 50 tile and a 105 by 9 box.

```
tile 100 by 50, box 105 by 9
sorted: tile 50 by 100, box 9 by 105
boxDiagonal   = 105.385008
boxAngle      = 0.085505
wideAngle     = 1.249737
requiredAngle = 1.076456
wideAngle - 2*boxAngle = 1.078726139
requiredAngle          = 1.076456308
Escape is possible.
```

The difference is positive, so the box escapes.

## Code

**Scanner and constants.**

```nim
import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i += 1
  return value
```

firstDigitValue converts a digit byte into its value. The flush threshold is 128 KiB. nextInt stops at both ends of the buffer. No token string is allocated.

**Input setup.**

```nim
var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""
```

The read loop stores every input line in one buffer. Adding a newline keeps adjacent numbers apart. The case count is read before the loop.

**Sort and fit test.**

```nim
var j = 0
while j < caseCount:
  let tileFirst = nextInt(inputData, i)
  let tileSecond = nextInt(inputData, i)
  let boxFirst = nextInt(inputData, i)
  let boxSecond = nextInt(inputData, i)

  var tileShort = tileFirst
  var tileLong = tileSecond
  if tileShort > tileLong:
    swap tileShort, tileLong
  var boxShort = boxFirst
  var boxLong = boxSecond
  if boxShort > boxLong:
    swap boxShort, boxLong

  var escapePossible = false
  if boxShort <= tileShort and boxLong <= tileLong:
    escapePossible = true
  elif boxShort > tileShort:
    escapePossible = false
  else:
    let boxDiagonal = sqrt(float(boxShort) * float(boxShort) + float(boxLong) * float(boxLong))
    let boxAngle = arctan(float(boxShort) / float(boxLong))
    let wideAngle = arcsin(float(tileLong) / boxDiagonal)
    let requiredAngle = arccos(float(tileShort) / boxDiagonal)
    if wideAngle - 2.0 * boxAngle >= requiredAngle - 1e-12:
      escapePossible = true
```

The loop runs once per case. A pair of swaps sorts each shape. The straight test runs first. The tilted branch runs only when the box is too long to lie flat.

**Write the verdict.**

```nim
  if escapePossible:
    outputBuffer.add "Escape is possible.\n"
  else:
    outputBuffer.add "Box cannot be dropped.\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  j += 1

stdout.write outputBuffer
```

Each case appends one fixed sentence to the output buffer. A full block is flushed immediately. The final write emits the remaining bytes.

## Complexity

The phases and their costs follow.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(input bytes) | one input buffer |
| Per-case test | O(1) with three math calls | O(1) |
| Output | O(output bytes) | one output block |

Total time is linear in the input size plus the output size.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(N + M) for N input and M output bytes |
| Space | O(N) |

A scan over trial angles multiplies the per-case work by the number of angles tried.
