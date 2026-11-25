# HS12MBR — Minimum Bounding Rectangle (SPOJ)

<https://www.spoj.com/problems/HS12MBR/>

## Problem

Find the smallest axis-aligned rectangle containing a set of points, circles, and line segments. Report its lower-left corner and its upper-right corner.

The input starts with t, the number of cases. Each case begins with n, the object count, followed by n object lines. A point is `p x y`, a circle is `c x y r`, and a segment is `l x1 y1 x2 y2`. A blank line separates cases. Print four integers per case: minimum x, minimum y, maximum x, maximum y.

| Item | Bound |
|---|---|
| Test cases | t < 100 |
| Objects per case | n < 100 |
| Coordinates | integers, all objects within -1000 to 1000 |
| Judge limit | 200 ms, 1536 MB |

The sample:

```
3
1
p 3 3 

2
c 10 10 20
c 20 20 10

1
l 0 0 100 20
```

```
3 3 3 3 
-10 -10 30 30
0 0 100 20

```

## Idea

Picture a rubber band stretched around a handful of stickers. Each sticker may be a dot, a disc, or a short stroke.

The program keeps four running extremes while reading objects. A point contributes its two coordinates. A circle contributes its center plus and minus the radius. A segment contributes both endpoints. Each object costs one character read and a few comparisons.

Four numbers describe the final rectangle.

## Why It Works

1. An axis-aligned rectangle is fixed by its extreme x and y values.
2. Every object reveals its extreme coordinates from its parameters.
3. Taking minima and maxima over all objects gives the tight enclosing rectangle.
4. The sample circles give x from -10 to 30 and y from -10 to 30.

| Term | Meaning |
|---|---|
| `minimumX` | smallest x coordinate seen so far |
| `maximumY` | largest y coordinate seen so far |
| `leftEdge` | circle center x minus its radius |
| `lowX` | smaller endpoint x of a segment |
| `boundSentinel` | initial value outside the coordinate range |

Each object updates only the four extremes.

A traced run of the sample groups from `gen.py`:

```
group 1: point (3, 3) -> xs [3], ys [3]
group 2: circle (10, 10, 20) -> xs [-10, 30], ys [-10, 30]
group 2: circle (20, 20, 10) -> xs [10, 30], ys [10, 30]
group 2 extremes -> min x -10, min y -10, max x 30, max y 30
group 3: segment (0, 0) to (100, 20) -> xs [0, 100], ys [0, 20]
```

The trace gives the four sample output numbers in order.

## Code

**Input and scanner.** Lines enter one buffer, then a character and integer reader walk it.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const boundSentinel = 2000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextCharacter(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let symbol = data[pos]
  pos += 1
  return symbol

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1
  if data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

`nextCharacter` skips blank lines between cases. `nextInteger` handles negative coordinates.

**Output writer.** Integers are written as digits without temporary strings.

```nim
var outputBuffer = ""
var digitStorage: array[16, char]

proc appendInteger(value: int) =
  if value == 0:
    outputBuffer.add '0'
    return
  var magnitude = value
  if magnitude < 0:
    outputBuffer.add '-'
    magnitude = -magnitude
  var digitCount = 0
  while magnitude > 0:
    digitStorage[digitCount] = char(magnitude mod 10 + firstDigitValue)
    digitCount += 1
    magnitude = magnitude div 10
  while digitCount > 0:
    digitCount -= 1
    outputBuffer.add digitStorage[digitCount]

proc flushOutput() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`digitStorage` is a fixed array, so no allocation occurs. `flushOutput` writes large blocks.

**Case driver.** Four extremes are updated once per object.

```nim
let caseCount = nextInteger(inputData, scanPos)
for _ in 0 ..< caseCount:
  let objectCount = nextInteger(inputData, scanPos)
  var minimumX = boundSentinel
  var minimumY = boundSentinel
  var maximumX = -boundSentinel
  var maximumY = -boundSentinel
  for _ in 0 ..< objectCount:
    let kind = nextCharacter(inputData, scanPos)
    case kind
    of 'p':
      let pointX = nextInteger(inputData, scanPos)
      let pointY = nextInteger(inputData, scanPos)
      if pointX < minimumX: minimumX = pointX
      if pointX > maximumX: maximumX = pointX
      if pointY < minimumY: minimumY = pointY
      if pointY > maximumY: maximumY = pointY
    of 'c':
      let centerX = nextInteger(inputData, scanPos)
      let centerY = nextInteger(inputData, scanPos)
      let radius = nextInteger(inputData, scanPos)
      let leftEdge = centerX - radius
      let rightEdge = centerX + radius
      let lowerEdge = centerY - radius
      let upperEdge = centerY + radius
      if leftEdge < minimumX: minimumX = leftEdge
      if rightEdge > maximumX: maximumX = rightEdge
      if lowerEdge < minimumY: minimumY = lowerEdge
      if upperEdge > maximumY: maximumY = upperEdge
    of 'l':
      let firstX = nextInteger(inputData, scanPos)
      let firstY = nextInteger(inputData, scanPos)
      let secondX = nextInteger(inputData, scanPos)
      let secondY = nextInteger(inputData, scanPos)
      let lowX = min(firstX, secondX)
      let highX = max(firstX, secondX)
      let lowY = min(firstY, secondY)
      let highY = max(firstY, secondY)
      if lowX < minimumX: minimumX = lowX
      if highX > maximumX: maximumX = highX
      if lowY < minimumY: minimumY = lowY
      if highY > maximumY: maximumY = highY
    else:
      discard
  appendInteger(minimumX)
  outputBuffer.add ' '
  appendInteger(minimumY)
  outputBuffer.add ' '
  appendInteger(maximumX)
  outputBuffer.add ' '
  appendInteger(maximumY)
  outputBuffer.add '\n'
  flushOutput()
stdout.write outputBuffer
```

Each branch matches one object kind. The four appended numbers form one output line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Object update | constant work per object | four extremes |
| Output | one write per 128 KiB block | one output buffer |

The object count bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(total objects) |
| Space | O(input bytes) |

Collecting every corner and sorting would cost O(n log n) per case. Four running extremes finish in O(n).
