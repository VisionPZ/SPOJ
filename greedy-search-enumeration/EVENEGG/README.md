# EVENEGG — Fuad the wild scientist (SPOJ)
<https://www.spoj.com/problems/EVENEGG/>

## Problem

Each case gives a starting height, a day, a daily growth, and a column size. Print the smallest door height above the dragon on that day.

The door starts at seven feet. Each column adds the given number of feet.
The four integers arrive on one line. One answer line follows for each input line.

| Item | Value |
|---|---|
| Input | four integers per line |
| Output | one integer door height per line |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The door must be strictly taller than the dragon.

The statement gives three sample cases verbatim.

```
10 2 4 1
16 5 7 10
5 1 1 4
```

```
19
57
7
```

## Idea

Think of stacking equal bricks on a seven-foot doorway until the opening clears the dragon.
Growth is linear, so day n height is the start plus n times the daily growth.
The program divides the gap by the column size, then adds one column when needed.
Adding columns one at a time would take many steps for a tall dragon.

Division gives the column count in one step.

## Why It Works

1. Daily growth adds the same amount each day, so height is start plus day times growth.
2. Possible door heights are seven plus a nonnegative multiple of the column size.
3. The answer is the first such height strictly above the dragon height.
4. Integer division truncates negative gaps toward zero, so the count is clamped to zero.
5. The extra check raises the count when the current height still ties the dragon.

The main names and values:

| Term | Meaning |
|---|---|
| `initialHeight` | dragon height before growth |
| `targetDay` | day whose height is requested |
| `columnHeight` | feet added by one column |
| `dragonHeight` | height on the requested day |
| `columnCount` | number of columns to add |

The clamp keeps small dragons inside the starting doorway.

A script trace of the first sample case lists the candidate heights.

```
dragon height: 18
door heights: [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
first height above dragon: 19
```

Nineteen is the first listed height above eighteen.

## Code

**Read the whole stream.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const baseDoorHeight = 7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

One string holds all bytes. The base door height is a named constant.

**Scan decimal integers.**
```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner walks the buffer by index. It skips separators between numbers.

**Buffer output in blocks.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB. The reset reuses the string.

**Compute the door height.**
```nim
var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let initialHeight = nextInt(inputData, scanPos)
  let targetDay = nextInt(inputData, scanPos)
  let dailyGrowth = nextInt(inputData, scanPos)
  let columnHeight = nextInt(inputData, scanPos)
  let dragonHeight = initialHeight + targetDay * dailyGrowth
  var columnCount = (dragonHeight - baseDoorHeight) div columnHeight
  if columnCount < 0:
    columnCount = 0
  if baseDoorHeight + columnCount * columnHeight <= dragonHeight:
    columnCount += 1
  let doorHeight = baseDoorHeight + columnCount * columnHeight
  appendOutput($(doorHeight))
  outputBuffer.add '\n'
```

The loop stops at the end of the buffer. A negative count is clamped to zero.
One tie check guarantees a strictly taller door.

**Emit the final partial block.**
```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last write clears the buffer. No write happens per column.

## Complexity

Each case uses a fixed number of arithmetic operations.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Door height | one division per case | constant |
| Output | one write per full block | block buffer |

Work does not depend on the dragon height.

| Measure | Big O |
|---|---|
| Time | O(input tokens) |
| Space | O(input bytes) |

Adding columns one by one would cost O(dragon height over column size) per case, so division wins.
