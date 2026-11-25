# FUCT_IF_CIRCLE — Geometric circle (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_CIRCLE/>

## Problem

A radius arrives, and the program must measure the boundary and the disk.
The first line holds the test count. Each later line holds one integer radius.
For each case, print the circumference and area separated by one space.
Use six digits after the decimal point for both values.
A zero or negative radius yields `the radius must be greater than 0`.
The sample uses the full circle constant, not a shortened value.

| Item | Bound |
|---|---|
| Test cases | 0 < t ≤ 1000 |
| Radius | integer, checked before formulas |
| Precision | six digits after the decimal point |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
5
-2
1
0
4
```

```
31.415927 78.539816
the radius must be greater than 0
6.283185 3.141593
the radius must be greater than 0
25.132741 50.265482
```

## Idea

Turn one radius into two related measurements with fixed formulas.
Like measuring a wheel with a tape, one span fixes both rim and face.
The circumference is two times pi times the radius.
The area is pi times the radius squared.
Each case costs constant time with two multiplications and two formatting calls.
A naive approximation loop would add error and time without helping.

## Why It Works

1. The scanner skips spaces and reads a minus sign before digits.
2. A nonpositive radius is rejected before any multiplication.
3. The circle constant in `math` gives the digits shown in the sample.
4. The circumference uses two pi times the radius.
5. The area uses pi times the radius times the radius.
6. `formatFloat` writes six fixed decimals for each positive case.

| Term | Meaning |
|---|---|
| `radius` | signed integer read for the current case |
| `circumference` | boundary length of the circle |
| `areaValue` | surface measure of the disk |
| `rendered` | one complete output line before buffering |

For radius 5, the circumference prints 31.415927.
The area prints 78.539816 with the same constant.

## Code

**Input and hand scanner.** This block loads input and reads signed integers.

```nim
import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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

**Validation and formulas.** This block rejects bad radii and renders answers.

```nim
let caseCount = nextSigned(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let radius = nextSigned(inputData, scanPos)
  var rendered = ""
  if radius <= 0:
    rendered.add "the radius must be greater than 0"
  else:
    let radiusValue = float(radius)
    let circumference = 2.0 * PI * radiusValue
    let areaValue = PI * radiusValue * radiusValue
    rendered.add formatFloat(circumference, ffDecimal, 6)
    rendered.add ' '
    rendered.add formatFloat(areaValue, ffDecimal, 6)
  rendered.add '\n'
  appendOutput rendered

stdout.write outputBuffer
outputBuffer.setLen 0
```

The radius check runs before either formula.
Both results use six fixed decimals.
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

A naive series expansion would cost time for no gain here.
The closed formulas keep every case constant.
