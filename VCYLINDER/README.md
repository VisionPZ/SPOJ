# VCYLINDER — Volume of a cylinder (SPOJ)

<https://www.spoj.com/problems/VCYLINDER/>

## Problem

Given the diameter and height of a cylinder, print its volume using 3.14 for pi. Show two decimal places followed by the unit text.

The input holds two integers on one line. Print one line with the volume and the suffix.

| item | bound |
|---|---|
| diameter d | 1 to 100 |
| height t | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

The fixed pi value keeps the calculation short.

Sample input:

```
3 10
```

Sample output:

```
70.65 cm^3
```

## Idea

Apply the textbook volume rule, like filling a can and measuring the result to the nearest hundredth. Radius is half the diameter. Multiply pi by radius squared and by height. Format the result to two decimal places and append the unit text. One calculation answers the only case.

## Why It Works

1. Radius equals diameter divided by two.
2. Cylinder volume equals pi times radius squared times height.
3. The problem fixes pi at 3.14.
4. Two-decimal formatting matches the required accuracy.

| term | meaning |
|---|---|
| `radius` | half of the given diameter |
| `volume` | pi times radius squared times height |
| `circlePi` | fixed value 3.14 |

Both inputs are small, so ordinary floating-point arithmetic is exact enough.

Script-generated trace for the sample case:

```
quantity | value
diameter | 3
height | 10
radius | 1.5
3.14 * 1.5 * 1.5 * 10 | 70.65
```

The printed line matches the sample byte for byte.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const circlePi = 3.14
const diameterHalves = 2.0

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

The constants name every fixed number.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Volume formula and output.** One expression produces the formatted line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let diameter = float(nextInt(inputData, scanPos))
let height = float(nextInt(inputData, scanPos))
let radius = diameter / diameterHalves
let volume = circlePi * radius * radius * height
appendOutput(formatFloat(volume, ffDecimal, 2))
appendOutput(" cm^3")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Formatting supplies both decimal places.
The unit text follows immediately.
The finished line is written once from the block buffer.

## Complexity

One case needs a fixed number of arithmetic operations.

| phase | time | space |
|---|---|---|
| input read | two integers | one input string |
| volume formula | a few float operations | four variables |
| output | one line | block buffer |

No loop or table is needed.

| measure | Big O |
|---|---|
| time | O(1) apart from input bytes |
| space | O(1) apart from buffers |

Manually assembling decimal digits would add work without improving accuracy.
