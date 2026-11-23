## Problem

Read T cases. Each case gives the tile sides A and B and the box sides X and Y, all from 1 to 50000. Rotate the box and place it on one tile without crossing the tile border. Print "Escape is possible." when it fits, and "Box cannot be dropped." when it does not. Touching an edge counts as fitting, so a 10 by 10 box fits a 10 by 10 tile.

The table lists the input bounds and the judge limits.

| Quantity | Value |
| --- | --- |
| Test cases T | about 10000 |
| Each side | 1 to 50000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |
| Source limit | 50000 B |

These bounds keep one case in a few integer variables.

## Idea

Sort each shape's sides so the short side comes first, then compare the box with the tile. If the box cannot lie straight, the program checks one tilted placement using the box diagonal and three angle functions. Each case costs a few comparisons and three math calls, while a scan over trial angles costs far more.

## Why It Works

A rectangle fits a tile when its four corners stay inside the tile. The tightest fit touches all four tile sides. If the box short side exceeds the tile short side, no tilt helps. Every straight slice of a rectangle is at least its short side.

The tilted check uses the box diagonal and three angles.

- `boxDiagonal` holds the diagonal of the box.
- `boxAngle` is `arctan` of the short side over the long side.
- `wideAngle` is `arcsin` of the tile long side over the diagonal.
- `requiredAngle` is `arccos` of the tile short side over the diagonal.
- The box fits when `wideAngle - 2.0 * boxAngle >= requiredAngle - 1e-12`.

The factor two comes from the two box diagonals. Both diagonals leave the box center at the same angle, so the usable tilt shrinks by twice `boxAngle`. Small rounding error needs the tiny tolerance; exact edge contact still counts as a fit.

The worked example uses a tile of 100 by 50 and a box of 105 by 9.

> tile 100 by 50, box 105 by 9
> sorted: tile 50 by 100, box 9 by 105
> boxDiagonal   = 105.385008
> boxAngle      = 0.085505
> wideAngle     = 1.249737
> requiredAngle = 1.076456
> wideAngle - 2*boxAngle = 1.078726139
> requiredAngle          = 1.076456308
> Escape is possible.

The left value exceeds the right value by 0.0023, so the box fits.

## Code

```
import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

Both loops stop at `dataLength`, the end of the buffer. Skipping non-digits avoids one allocated token per number. The cost is linear in the input bytes.

```
var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
```

The loop runs once per input line, so the whole stream stays in memory. Adding a newline keeps two adjacent numbers from merging. Reading costs one pass over the input.

```
var caseIndex = 0
while caseIndex < caseCount:
  let tileFirst = nextInt(inputData, scanPos)
  let tileSecond = nextInt(inputData, scanPos)
  let boxFirst = nextInt(inputData, scanPos)
  let boxSecond = nextInt(inputData, scanPos)

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

The loop runs exactly `caseCount` times, once per case. Sorting each pair first removes two later comparisons. The tilted branch runs only when the box is too long to lie straight.

```
  if escapePossible:
    outputBuffer.add "Escape is possible.\n"
  else:
    outputBuffer.add "Box cannot be dropped.\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
```

The block flushes when the buffer reaches `flushBlockBytes`. Flushing in blocks avoids one write per case. The final write emits the remaining bytes.

## Complexity

Reading costs O(N) time and O(N) space, where N is the input byte count. Each case costs O(1) time and O(1) space, with three math calls. Writing costs O(M) time for M output bytes, and the buffer holds at most `flushBlockBytes` bytes. Total time is O(N + M), and total space is O(N). A scan over trial angles would multiply the per-case work by the number of angles.
