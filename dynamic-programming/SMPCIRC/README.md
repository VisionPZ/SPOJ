# SMPCIRC — Two Circles (SPOJ)

<https://www.spoj.com/problems/SMPCIRC/>

## Problem

Decide whether one of two circles lies strictly inside the other, touches it from the inside, or neither.

Input starts with a test count `t`. Each next line holds `x1 y1 r1 x2 y2 r2`, the centers and radii of the two circles. Print one character per case: `I` for strict containment, `E` for internal tangency, `O` for all other positions.

| Item | Bound |
|---|---|
| Test cases `t` | t < 1000 |
| Center coordinates | 0 <= x1, y1, x2, y2 <= 10000 |
| Radii | 0 < r1, r2 <= 10000 |
| Judge limit | 1000 ms, 1536 MB |

Sample:

```
2
103 104 5 100 100 10
103 104 10 100 100 10
```

```
E
O
```

## Idea

Think of two coins on a table: the small coin fits strictly inside the large one, or touches its rim from inside.

The program reads all lines into one string, scans six integers per case, and compares squared distances. Let `gap` be the difference between the radii. If the squared center distance is below `gap*gap`, the smaller circle is inside; if equal, the circles are internally tangent; otherwise the answer is `O`.

Each case costs six scans, two subtractions, and a few multiplications. Computing a square root with floating point would add work and a rounding risk.

## Why It Works

1. The smaller circle lies strictly inside the larger one when the center distance plus its radius is below the larger radius.
2. Subtracting the smaller radius turns that into `d < gap`, where `gap` is the difference of the radii.
3. Both `d` and `gap` are non-negative, so comparing `d*d` with `gap*gap` gives the same result without a square root.
4. Equality means the centers are exactly `gap` apart, which is internal tangency. A larger distance gives `O`.
5. Center coordinates and radii are integers at most 10000, so every square fits an `int`.

| Term | Meaning |
|---|---|
| `deltaX` | horizontal distance between centers |
| `deltaY` | vertical distance between centers |
| `distanceSquared` | `deltaX*deltaX + deltaY*deltaY` |
| `largerRadius` | the larger of the two radii |
| `smallerRadius` | the smaller of the two radii |
| `gap` | radius difference, `largerRadius - smallerRadius` |
| `gapSquared` | `gap*gap`, the comparison threshold |

The two squared quantities decide every answer, with no floating point involved.

A traced run of the first sample case, produced by the generator:

```
centers (103,104) r=5 and (100,100) r=10
deltaX=3 deltaY=4 -> distanceSquared=9+16=25
largerRadius=10 smallerRadius=5 -> gap=5 -> gapSquared=25
25 == 25 -> "E"
```

The trace matches the first sample output line.

## Code

**Constants.** The digit byte offset and the output block size.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
```

`firstDigitValue` is the byte of `0`. The block size caps output memory before a write.

**Input read.** Every line is appended to one string.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

`readLine` works on the judge compiler. Padded lines become whitespace in the buffer.

**Digit scanner.** Each call advances `scanPos` past one integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The `var` parameter keeps the position between calls. No substring or parse call is needed.

**Output buffer.** Appends collect bytes and flush a full block.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a flush. One character per case keeps the buffer small.

**Case loop.** Six scans, one squared comparison, one character.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let firstCenterX = nextInt(inputData, scanPos)
  let firstCenterY = nextInt(inputData, scanPos)
  let firstRadius = nextInt(inputData, scanPos)
  let secondCenterX = nextInt(inputData, scanPos)
  let secondCenterY = nextInt(inputData, scanPos)
  let secondRadius = nextInt(inputData, scanPos)
  let deltaX = firstCenterX - secondCenterX
  let deltaY = firstCenterY - secondCenterY
  let distanceSquared = deltaX * deltaX + deltaY * deltaY
  var largerRadius = firstRadius
  var smallerRadius = secondRadius
  if secondRadius > firstRadius:
    largerRadius = secondRadius
    smallerRadius = firstRadius
  let gap = largerRadius - smallerRadius
  let gapSquared = gap * gap
  if distanceSquared < gapSquared:
    appendOutput("I")
  elif distanceSquared == gapSquared:
    appendOutput("E")
  else:
    appendOutput("O")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
```

The two radius variables are ordered by one comparison, with no `min` or `max` call. The newline after each case gives exactly one answer line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Case scan | one pass over six integers per case | constant |
| Comparison | a few integer multiplications per case | constant |
| Output | one buffered write | one buffer |

Each case has the same fixed cost, independent of the coordinate values.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes plus O(t) comparisons |
| Space | O(N) for the input buffer plus one output block |

A square-root comparison would compute a transcendental value per case and could round a true equality into an inequality. Squaring keeps the decision exact.
