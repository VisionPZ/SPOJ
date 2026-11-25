# CYLINDER — Cylinder (SPOJ)

<https://www.spoj.com/problems/CYLINDER/>

## Problem

A rectangle of width `w` and height `h` is cut parallel to its short side.
One piece supplies the largest possible circular base, and the other rolls into the side wall.
Find the greatest cylinder volume, printed with three digits after the decimal point.

Each test case gives two integers `w h` with `1 ≤ w ≤ h ≤ 100`.
A final line `0 0` ends the input.
Print one volume per earlier line.

| Item | Bound |
|---|---|
| Width w | 1 to 100 |
| Height h | w to 100 |
| Rounding | three digits after the decimal point |
| Judge limit | 1000 ms, 1536 MB |

A cut at distance `x` from one edge leaves a strip `w` by `h-x`.
The base diameter is `min(w, x)`, so the radius is `r = min(w, x)/2`.
The required circumference is `π·min(w,x)`, where `π` is the circle constant.
The side strip can wrap along width `w` or along length `h-x`, with overlap allowed.

Sample input:

```
10 10
10 50
10 30
0 0
```

Sample output:

```
54.247
785.398
412.095
```

## Idea

Picture a paper strip wrapped around a can, like a label with extra overlap.
Only a few cuts matter: the ones where the base stops growing or the strip stops reaching around.
Evaluate those cuts, then keep the largest volume.
A cut `x` gives radius `min(w,x)/2` and required circumference `π·min(w,x)`.
Wrapping along `w` gives height `h-x`; wrapping along `h-x` gives height `w`.
Each candidate costs constant work, so a case is fast.

## Why It Works

1. The circular base fits inside the first strip, so its diameter cannot exceed `min(w,x)`.
2. The side strip has two possible roll directions, and each direction fixes the cylinder height.
3. A roll direction works only when its strip length reaches the required circumference.
4. While the cut stays within the width, the radius grows, and the wrap along `w` has height `h-x`.
5. The volume pi times x squared times h minus x, divided by four, grows until x equals two thirds of h.
6. The best cut is therefore at a feasibility boundary, where a strip length equals the circumference.
7. Checking every boundary plus a small neighbourhood covers all maximum points.

| Term | Meaning |
|---|---|
| `cutPosition` | distance x from the edge chosen for the cut |
| `diameter` | `min(w,x)`, the largest circle diameter in the first strip |
| `circumference` | `π` times `diameter`, the length the side must wrap |
| `rollHeight` | cylinder height from the chosen wrap direction |
| `bestVolume` | largest volume found for one test case |

For the first sample sheet, both width and height equal 10.
The wrap along `w` works while the width reaches the circumference, so the best cut is near 3.1831.
The radius is about 1.5915, the height is about 6.8169, and the volume is 54.247.
For the second sheet, the side of length 50 allows a radius of 5 and height 10, giving 785.398.

A tiny feasibility margin absorbs floating-point error at boundary cuts.
Candidate values include a small offset on both sides of each boundary.

## Code

**Input and hand scanner.** The reader loads all text once and parses integers directly.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const circleConstant = 3.141592653589793
const epsilonOffset = 0.0000001
const feasibilityMargin = 0.000000001

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

`circleConstant` holds the value of `π`.
`scanPos` moves over separators and digits.
The input string stays available until all cases are processed.

**Volume evaluation.** Each cut checks both roll directions and returns the larger volume.

```nim
proc cylinderVolume(sheetWidth: float, sheetHeight: float, cutPosition: float): float =
  var position = cutPosition
  if position < 0.0:
    position = 0.0
  if position > sheetHeight:
    position = sheetHeight
  let diameter = min(sheetWidth, position)
  let radius = diameter / 2.0
  let circumference = circleConstant * diameter
  var bestVolume = 0.0
  if sheetWidth + feasibilityMargin >= circumference:
    let rollHeight = sheetHeight - position
    let volume = circleConstant * radius * radius * rollHeight
    if volume > bestVolume:
      bestVolume = volume
  if sheetHeight - position + feasibilityMargin >= circumference:
    let rollHeight = sheetWidth
    let volume = circleConstant * radius * radius * rollHeight
    if volume > bestVolume:
      bestVolume = volume
  return bestVolume
```

`position` is clipped to the sheet height.
Each feasible wrap contributes `circleConstant * radius * radius * rollHeight`.
`feasibilityMargin` keeps boundary cuts available.

**Buffered answer loop.** Candidate cuts are tested with small offsets, then formatted once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let sheetWidth = float(nextInt(inputData, scanPos))
  let sheetHeight = float(nextInt(inputData, scanPos))
  if sheetWidth == 0.0 and sheetHeight == 0.0:
    break
  var bestVolume = 0.0
  var candidates = @[sheetWidth, sheetWidth / circleConstant,
                     sheetHeight / (circleConstant + 1.0),
                     sheetHeight - circleConstant * sheetWidth,
                     2.0 * sheetHeight / 3.0, sheetHeight / 2.0,
                     sheetHeight / 3.0, 0.0, sheetHeight]
  for candidate in candidates:
    for offsetIndex in 0 .. 2:
      var offset = 0.0
      if offsetIndex == 0:
        offset = -epsilonOffset
      elif offsetIndex == 2:
        offset = epsilonOffset
      let volume = cylinderVolume(sheetWidth, sheetHeight, candidate + offset)
      if volume > bestVolume:
        bestVolume = volume
  appendOutput(formatFloat(bestVolume, ffDecimal, 3))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops at the `0 0` terminator.
`candidates` lists the boundary and interior cuts that can maximize volume.
`formatFloat` writes exactly three decimals per case.
`appendOutput` flushes `stdout` only when the block buffer fills.

## Complexity

Each case evaluates a fixed number of cuts.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all integers | one input string |
| Cut evaluation | constant candidates per case | constant working space |
| Output | one formatted line per case | one block buffer |

| Measure | Big O |
|---|---|
| Time per case | O(1) |
| Space | O(input size) |

Scanning every possible cut at fine resolution would spend many evaluations on the same smooth curves.
A short candidate list reaches each maximum directly.
