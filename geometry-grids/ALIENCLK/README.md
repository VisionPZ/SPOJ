# ALIENCLK — Clock hands on a different planet (SPOJ)
<https://www.spoj.com/problems/ALIENCLK/>

## Problem

Report the smaller angle between the two hands of a 16-hour, 80-minute clock. Each answer is in degrees, rounded to one decimal place.

The first line gives the number of clock times. Each later line holds a time as HH:MM. Print one angle per time, between 0 and 359 degrees, with one digit after the decimal point.

| Constraint | Value |
| --- | --- |
| Hours per day | 16 |
| Minutes per hour | 80 |
| Angle output | one decimal place |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

Exact integer arithmetic keeps every answer free of drift.

The sample input and its expected output follow byte for byte.

```
3
12:00
06:00
13:15
```

```
90.0
135.0
130.8
```

The last answer rounds 130.78125 degrees to 130.8.

## Idea

Reading both hands on a shared ruler is like measuring them in thirty-seconds of a degree. The minute hand advances 144 units per minute and the hour hand advances 9 units per minute.

The program converts each time into those units, takes the absolute gap, and folds any gap above 180 degrees to its complement. It then divides by 32 and formats one decimal place.

Floating point trig functions would add rounding drift. Integer units keep the gap exact before the final formatting step.

## Why It Works

1. A full turn holds 360 times 32, or 11520, units.
2. The minute hand covers 360 degrees in 80 minutes, so it gains 144 units per minute.
3. The hour hand covers 360 degrees in 1280 minutes, so it gains 9 units per minute.
4. The absolute unit gap is the raw angle between the hands.
5. A raw gap above 5760 units means more than 180 degrees, so 11520 minus the gap is the smaller angle.

| Term | Value | Meaning |
| --- | --- | --- |
| `unitsPerDegree` | 32 | units in one degree |
| `unitsPerTurn` | 11520 | units in a full circle |
| `minuteUnitsPerMinute` | 144 | minute hand speed in units |
| `hourUnitsPerMinute` | 9 | hour hand speed in units |
| `separationUnits` | variable | smaller angle in units |

These constants turn the clock into exact integer arithmetic.

A script check on 13:15 gives 1055 minutes past midnight.

| Quantity | Calculation | Result |
| --- | --- | --- |
| hour units | 1055 times 9 | 9495 |
| minute units | 15 times 144 | 2160 |
| raw gap | 9495 minus 2160 | 7335 units |
| raw degrees | 7335 over 32 | 229.21875 |
| folded units | 11520 minus 7335 | 4185 units |
| answer | 4185 over 32 | 130.8 degrees |

The folded gap gives the reported angle.

Exact half tenths round to the nearest even digit under standard decimal formatting. All other values round to the closest tenth.

## Code

**Constants, reader and output buffer.** The hand speeds come from the clock layout, and the hand scanner reads each time as two integers.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const minutesPerHour = 80
const hoursPerDay = 16
const unitsPerDegree = 32
const unitsPerTurn = 360 * unitsPerDegree
const minuteUnitsPerMinute = 360 * unitsPerDegree div minutesPerHour
const hourUnitsPerMinute = 360 * unitsPerDegree div (hoursPerDay * minutesPerHour)

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

The colon in HH:MM is a separator for the scanner.
The buffer groups many answer lines into one write.

**Angle per time.** Each time produces an exact gap in units before formatting.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let clockHour = nextInt(inputData, scanPos)
  let clockMinute = nextInt(inputData, scanPos)
  let normalizedHour = clockHour mod hoursPerDay
  let minuteUnits = clockMinute * minuteUnitsPerMinute
  let hourUnits = (normalizedHour * minutesPerHour + clockMinute) * hourUnitsPerMinute
  var separationUnits = hourUnits - minuteUnits
  if separationUnits < 0:
    separationUnits = -separationUnits
  separationUnits = separationUnits mod unitsPerTurn
  if separationUnits > unitsPerTurn div 2:
    separationUnits = unitsPerTurn - separationUnits
  let angleDegrees = float(separationUnits) / float(unitsPerDegree)
  appendOutput(formatFloat(angleDegrees, ffDecimal, 1))
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The modulo handles a negative wrap before folding the gap.
The last write flushes any remaining answer lines.

## Complexity

Each clock time costs a fixed amount of arithmetic.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over the stream | one input string |
| angle conversion | constant work per time | a few counters |
| output | one line per time | block buffer |

No per-degree table is needed.

| Measure | Big O |
| --- | --- |
| time | O(test count) |
| space | O(1) besides input |

Simulating each hand minute by minute would cost O(1280) per time.

The unit formula gives the angle in constant time.
