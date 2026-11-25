# RG102 — New Year Minutes (SPOJ)

<https://www.spoj.com/problems/RG102/>

## Problem

Lukas counts the minutes left before midnight on New Year's Eve. Each input line holds one clock time in 24-hour `HH:MM` form. For every time before midnight, print how many minutes remain until midnight. The line `00:00` ends the input and is not processed.

| Item | Bound |
|---|---|
| Time form | `HH:MM`, two digits each, 00:00 to 23:59 |
| Line count | one time per line, ends at 00:00 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
23:45
21:30
00:01
00:00
```

```
15
150
1439
```

## Idea

A day holds 1440 minutes, so the answer is 1440 minus the minutes already spent. Think of the day as a ruler with 1440 ticks: each clock time is one tick, and the answer is the distance from that tick to the end. The program converts each time to minutes since midnight with one multiply and one add, then subtracts from 1440. That is constant work per line. Stepping one minute at a time toward midnight costs up to 1439 steps per line.

## Why It Works

1. `hourValue * 60 + minuteValue` is the minutes elapsed since midnight.
2. Every time before midnight has an elapsed count from 1 to 1439, so `1440 - elapsed` is a positive minute count.
3. `00:00` gives elapsed 0, which doubles as the stop signal.
4. The scanner skips the colon and newlines because it only reads digit runs.

| Term | Meaning |
|---|---|
| `minutesPerDay` | 1440, the minutes in one day |
| `nextNumber` | reads one digit run, returns value, position, found flag |
| `hourValue` | the two digits before the colon |
| `minuteValue` | the two digits after the colon |
| `minutesSoFar` | minutes elapsed since midnight |

The found flag tells the loop when the input ran out, so a missing `00:00` still ends cleanly.

A script-traced example from `gen.py`:

```
time 21:30
elapsed 21 * 60 + 30 = 1290
result 1440 - 1290 = 150
```

The trace matches the second sample answer.

## Code

**Hand scanner.** This block reads one integer at a time from the byte buffer.

```python
def nextNumber(data, position):
    length = len(data)
    while position < length and not (firstDigitValue <= data[position] <= firstDigitValue + 9):
        position += 1
    value = 0
    found = position < length
    while position < length and firstDigitValue <= data[position] <= firstDigitValue + 9:
        value = value * 10 + data[position] - firstDigitValue
        position += 1
    return value, position, found
```

The first while loop jumps over colons and newlines.
The found flag distinguishes a real `00` from end of input.
Scanning costs one pass over the consumed characters.

**Main loop.** This block converts each time and stops at midnight.

```python
inputData = sys.stdin.buffer.read()
scanPos = 0
answerLines = []
while True:
    hourValue, scanPos, hourFound = nextNumber(inputData, scanPos)
    if not hourFound:
        break
    minuteValue, scanPos, _ = nextNumber(inputData, scanPos)
    minutesSoFar = hourValue * 60 + minuteValue
    if minutesSoFar == 0:
        break
    answerLines.append(str(minutesPerDay - minutesSoFar))
```

Two scanner calls read one clock time.
The `minutesSoFar == 0` test catches the `00:00` terminator.
Each line costs one multiply, one add, one subtract.

**Buffered output.** This block writes all answers at once.

```python
sys.stdout.write("\n".join(answerLines))
if answerLines:
    sys.stdout.write("\n")
```

One join plus one write keeps output syscalls at two.
The trailing newline appears only when answers exist.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Conversion | O(1) per line | answer strings |
| Output | one write | joined buffer |

| Measure | Big O |
|---|---|
| Time | O(lines) |
| Space | O(N) for the input buffer |

Minute-by-minute stepping would cost O(1439 × lines); this stays constant per line.
