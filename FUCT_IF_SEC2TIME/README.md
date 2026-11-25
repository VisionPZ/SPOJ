# FUCT_IF_SEC2TIME — Second to time hh_mm_ss (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_SEC2TIME/>

## Problem

Convert a count of seconds into a clock reading.
The input holds a total number of seconds.
Print it as hh:mm:ss, with every field at least two digits.
Hours may exceed two digits when the total is large.
A negative total has no valid clock reading.
For that case print `total second must be a positive integer`.
A total of zero is a valid reading: `00:00:00`.

| Item | Bound |
|---|---|
| Input | one integer total, negative values allowed |
| Format | hh:mm:ss with zero padding |
| Judge limit | 1000 ms, 1536 MB |

One division by 3600 and one by 60 settle the format.

The sample cases:

```
1986
```

```
00:33:06
```

```
-5
```

```
total second must be a positive integer
```

## Idea

Trade seconds for hours, then trade the remainder for minutes.
Think of changing coins: swap 3600 small coins for one big coin, then 60 for the next.
Integer division counts the big coins, and the remainder carries the rest.
Padding adds a leading zero only when a field has one digit.

## Why It Works

1. One hour is 3600 seconds, so integer division yields whole hours.
2. The remainder after hours is below 3600, so division by 60 yields minutes.
3. The final remainder is the seconds field, always below 60.
4. Padding adds one leading zero for fields below ten and keeps larger fields intact.
5. A negative total fails the sign test, so the fixed error text is printed. Zero passes and yields three zero fields.

| Term | Meaning |
|---|---|
| `secondsPerHour` | 3600 seconds in one hour |
| `secondsPerMinute` | 60 seconds in one minute |
| `totalSeconds` | signed integer read from input |
| `appendTimePart` | writes one padded field to the buffer |
| `hasNext` | reports whether another token remains |

The two divisions replace any loop over seconds.

A script-traced example from `gen.py`:

```
0 33 6
00:33:06
```

The quotient and remainders become 00, 33, and 06.

## Code

**Input, constants, and hand scanner.** This block loads stdin and reads signed integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const secondsPerMinute = 60
const secondsPerHour = 3600

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc hasNext(data: string, position: int): bool =
  var cursor = position
  while cursor < data.len and data[cursor] <= ' ':
    cursor += 1
  return cursor < data.len

proc nextInteger(data: string, position: var int): int64 =
  while position < data.len and data[position] <= ' ':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(ord(data[position]) - firstDigitValue)
    position += 1
  if negative:
    return -value
  return value
```

The scanner handles the minus sign from the second sample.
Values use int64, so large totals still parse.
The loop reads whitespace-separated tokens until none remain.

**Buffered output and padding.** This block writes fields with a leading zero when needed.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendTimePart(part: int64) =
  if part < 10:
    appendOutput("0")
  appendOutput($(part))
```

Padding applies to values below ten only.
The buffer flushes after reaching 128 KiB.

**Conversion loop.** This block splits each total and emits one line.

```nim
while hasNext(inputData, scanPos):
  let totalSeconds = nextInteger(inputData, scanPos)
  if totalSeconds < 0:
    appendOutput("total second must be a positive integer\n")
  else:
    let hours = totalSeconds div int64(secondsPerHour)
    let minutes = (totalSeconds mod int64(secondsPerHour)) div int64(secondsPerMinute)
    let seconds = totalSeconds mod int64(secondsPerMinute)
    appendTimePart(hours)
    appendOutput(":")
    appendTimePart(minutes)
    appendOutput(":")
    appendTimePart(seconds)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sign test guards both divisions.
Zero is kept, so it prints as `00:00:00`.
Three fields join with colons in the required order.
The final write flushes remaining bytes.

## Complexity

The cost is one scan of the tokens and one write per output block.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Conversion | O(1) divisions per token | output buffer |
| Output | one write per 128 KiB block | block buffer |

Each token needs only a handful of arithmetic steps.

| Measure | Big O |
|---|---|
| Time | O(P) for P input bytes |
| Space | O(P) for the input string |

Subtracting one second at a time costs O(n) per value, so division wins.
