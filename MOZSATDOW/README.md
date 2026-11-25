# MOZSATDOW — Sharmeen and the day of week (SPOJ)

<https://www.spoj.com/problems/MOZSATDOW/>

## Problem

Today is Friday. Given a number of days X, the task is to name the weekday after X days.

Input holds an integer X; the statement shows one value per example. Output holds the weekday name, starting from Friday at X = 0.

| Item | Bound |
|---|---|
| Offset X | 0 ≤ X ≤ 10⁹ |
| Week length | 7 days |
| Judge limit | 1000 ms, 1536 MB |

The weekly cycle reduces a huge offset to one small remainder.

The sample cases from the statement:

```
0
```

```
Friday
```

```
1
```

```
Saturday
```

## Idea

Take X modulo seven and index a fixed weekday list. Think of a seven-day wheel: after a full turn the same day returns. The program reads every integer token and writes one weekday each. Advancing one day at a time would cost X steps. Modular indexing answers each token in constant time.

## Why It Works

1. Weekdays repeat every seven days, so only X mod 7 matters.
2. Index zero names Friday, and later indices name the following days.
3. The scanner returns −1 at the end, so trailing whitespace adds no answer.
4. The offset fits in an int, and modulo keeps the index from 0 to 6.
5. The block buffer flushes after 128 KiB of output.

| Term | Meaning |
|---|---|
| `dayNames` | fixed list of weekdays in order |
| `dayOffset` | one scanned value of X |
| `nextInt` | hand scanner with an end-of-input sentinel |
| `appendOutput` | adds a line and flushes a full block |
| `flushBlockBytes` | size that triggers a write |

One remainder replaces all day-by-day stepping.

A script-traced example from `gen.py`:

```
X 0 -> Friday
X 1 -> Saturday
X 1000000000 -> Thursday
```

The trace shows that a billion days still needs one modulo.

## Code

**Input and hand scanner.** This block loads stdin and reads integer tokens.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const dayNames = ["Friday", "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    return -1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects the entire stream.
The sentinel prevents an extra answer after trailing whitespace.
Scanning costs one pass over the input digits.

**Buffered output.** This block collects finished weekday lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Answer loop.** This block maps each offset to a weekday.

```nim
while true:
  let dayOffset = nextInt(inputData, scanPos)
  if dayOffset < 0:
    break
  appendOutput(dayNames[dayOffset mod 7] & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop ends when the scanner reports no more digits.
Modulo seven keeps the list index valid.
Each answer costs one scan, one index, and one append.

## Complexity

The cost splits into input, constant work per token, and block output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Answer loop | O(1) per integer token | block buffer |
| Output | one write per 128 KiB block | block buffer |

A billion-day offset costs the same as a zero-day offset.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes |
| Space | O(N) for the input buffer |

Stepping one day at a time costs O(X), which reaches a billion steps.
