# FUCT_IF_CYLINDER — Geometric cylinder (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_CYLINDER/>

## Problem

A radius and a height arrive together, and both must be positive.
The first line holds the test count. Each later line holds two integers.
The integers name the radius r and the height h, separated by a space.
For each case, print the volume and total surface area separated by one space.
Use two digits after the decimal point and the value 3.14 for pi.
A zero or negative radius yields `the radius of cylinder must be greater than 0`.
A zero or negative height yields `the height of cylinder must be greater than 0`.

| Item | Bound |
|---|---|
| Test cases | 0 < t ≤ 1000 |
| Radius and height | integers, checked before formulas |
| Circle constant | 3.14 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
1 1
8 -2
4 10
0 7
12 18
```

```
3.14 12.56
the height of cylinder must be greater than 0
502.40 351.68
the radius of cylinder must be greater than 0
8138.88 2260.80
```

## Idea

Measure capacity and metal from the same two numbers.
Think of a soup can: one radius and one height fix both fill and wrapper.
The volume is pi times radius squared times height.
The total surface is two pi times radius times radius plus height.
Each case costs constant time with a few multiplications.
A numerical search over dimensions would add work without improving accuracy.

## Why It Works

1. The scanner skips spaces and reads a minus sign before digits.
2. The radius check comes first, matching the order in the statement.
3. The height check runs only after the radius passes.
4. The volume uses radius twice and height once.
5. The total surface uses both circular ends and the side band.
6. `formatFloat` writes two fixed decimals for every valid case.

| Term | Meaning |
|---|---|
| `circleConstant` | fixed value 3.14 from the statement comment |
| `volume` | capacity of the cylinder |
| `surface` | area of both ends plus the side |
| `rendered` | one complete output line before buffering |

For radius 4 and height 10, volume is 502.40.
The total surface is 351.68 with the same constant.

## Code

**Input and hand scanner.** This block loads input and reads signed integers.

```nim
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const circleConstant = 3.14

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value
```

The read loop stores every input line in one string.
The scanner handles a minus sign before the digits.
One pass over the buffer feeds all cases.

**Buffered output helper.** This block collects finished lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer writes to stdout once every 128 KiB.
A final write flushes any remaining bytes.

**Validation and formulas.** This block checks dimensions and renders answers.

```nim
let caseCount = nextSigned(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let radius = nextSigned(inputData, scanPos)
  let height = nextSigned(inputData, scanPos)
  var rendered = ""
  if radius <= 0:
    rendered.add "the radius of cylinder must be greater than 0"
  elif height <= 0:
    rendered.add "the height of cylinder must be greater than 0"
  else:
    let radiusValue = float(radius)
    let heightValue = float(height)
    let volume = circleConstant * radiusValue * radiusValue * heightValue
    let surface = 2.0 * circleConstant * radiusValue * (radiusValue + heightValue)
    rendered.add formatFloat(volume, ffDecimal, 2)
    rendered.add ' '
    rendered.add formatFloat(surface, ffDecimal, 2)
  rendered.add '\n'
  appendOutput rendered

stdout.write outputBuffer
outputBuffer.setLen 0
```

Radius and height checks precede the formulas.
Both results use two fixed decimals.
Each line is complete before it enters the buffer.

## Complexity

Each phase handles one pass over its own data.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scanning | one pass over digits | constant |
| Case work | constant per case | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(t) |
| Space | O(n) for n input bytes |

A naive search over possible dimensions would waste time.
The closed formulas keep every case constant.
