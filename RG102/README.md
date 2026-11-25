# RG102 — New Year Minutes (SPOJ)

<https://www.spoj.com/problems/RG102/>

## Problem

Each input line gives a clock time in `HH:MM` form, and the answer is the minutes left until midnight. The line `00:00` ends the input and produces no output.

| item | bound |
|---|---|
| time form | `HH:MM`, two digits each, 00:00 to 23:59 |
| line count | one time per line, ends at 00:00 |
| judge limit | 1000 ms, 1536 MB |

The day has 1440 minutes, so each time maps to exactly one answer.

Sample input:

```
23:45
21:30
00:01
00:00
```

Sample output:

```
15
150
1439
```

## Idea

Treat the day as a ruler with 1440 ticks: each clock time marks one tick, and the answer is the distance to the ruler's end. The program converts a time to minutes elapsed with one multiply and one add, then subtracts that count from 1440. The hand scanner reads digit runs and skips colons and newlines at no extra cost. Stepping one minute at a time toward midnight would take up to 1439 steps per line, while the formula uses constant work. One multiply, one add, and one subtract per time is the whole job.

## Why It Works

1. `hourValue * 60 + minuteValue` gives the minutes elapsed since midnight.
2. Every time before midnight has an elapsed count from 1 to 1439, so the difference from 1440 is positive.
3. `00:00` gives elapsed 0, which doubles as the stop signal.
4. The scanner skips the colon and newline because it only accepts digit runs.
5. A found flag distinguishes a real `00` from the end of input.

| term | meaning |
|---|---|
| `minutesPerDay` | 1440, the number of minutes in one day |
| `nextInt` | reads one digit run and reports whether it found one |
| `hourValue` | the digits before the colon |
| `minuteValue` | the digits after the colon |
| `minutesSoFar` | minutes elapsed since midnight |

The found flag lets the loop end cleanly even when no `00:00` line appears.

A script-traced example from the generator:

```
time 21:30
elapsed 21 * 60 + 30 = 1290
result 1440 - 1290 = 150
```

The trace matches the second sample answer.

## Code

**Input and scanner.** The hand reader loads all of stdin and parses one digit run per call.

```nim
const flushBlockBytes = 1 shl 17
const minutesPerDay = 1440

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, found: var bool): int =
  found = false
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
    found = true
  return value
```

The skip loop ignores colons and line breaks.
The found flag separates `00` from an exhausted buffer.
Scanning costs one pass over the consumed characters.

**Buffered output.** The loop converts each time and flushes answers in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  var hourFound = false
  let hourValue = nextInt(inputData, scanPos, hourFound)
  if not hourFound:
    break
  var minuteFound = false
  let minuteValue = nextInt(inputData, scanPos, minuteFound)
  let minutesSoFar = hourValue * 60 + minuteValue
  if minutesSoFar == 0:
    break
  appendOutput($(minutesPerDay - minutesSoFar))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Two scanner calls consume one clock time.
The zero test catches the `00:00` terminator.
Large answer sets flush before the final write.

## Complexity

Each line costs one conversion and one answer write.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input string |
| conversion | constant work per time line | scanner position |
| output | one append per answer | block buffer |

The phase table shows that scanning and writing dominate.

| measure | Big O |
|---|---|
| time | O(N) for N input lines |
| space | O(N) for the input buffer |

Minute-by-minute stepping would cost O(1439 × N); the formula keeps each line constant.
