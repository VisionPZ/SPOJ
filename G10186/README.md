# G10186 — Cumpleaños Grado 10 (SPOJ)
<https://www.spoj.com/problems/G10186/>

## Problem

A family holds a raffle with fewer than ten participants in a line.
Each participant says a number from 0 to 100, and a winning number is written down.
A participant with a prime number adds the next person's number; otherwise they subtract it.
The last person uses the previous person's number instead.
Use absolute values of the results, then print the name and original number of the winner.

The input has four lines: the count, the names, the numbers, and the winning number.

| Item | Bound |
|---|---|
| Participants | fewer than 10 |
| Numbers | 0 to 100 |
| Time limit | 1000 ms |
| Memory | not stated |

The winner is the result closest from above to the winning number.
When no result reaches it, the largest result wins.

The sample from the statement:

```
3
Juan Pedro Maria
58 31 76
88
```

```
Pedro 31
```

## Idea

Choosing the winner is like picking the shortest jump that still clears a bar.
Results below the bar do not qualify, and the smallest qualifying result wins.
The program reads four lines, then gives each participant one result.
A prime number adds its neighbor, and any other number subtracts its neighbor.
The neighbor is the next person, except for the last person who uses the previous one.
Each result becomes an absolute value before comparison.
The program keeps the smallest result at or above the target.
If none qualifies, it keeps the largest result instead.
Every step scans at most nine people, so the work is tiny.

The rule needs only one pass over the participants.

## Why It Works

1. A prime number adds the neighbor, and every other number subtracts it.
2. The last participant has no next neighbor, so they use the previous one.
3. Taking the absolute value removes the sign from a subtraction result.
4. A result at or above the target qualifies, and the smallest one wins.
5. If nothing qualifies, the largest result is the nearest one below.

The main terms follow.

| Term | Meaning |
|---|---|
| `enteredValues` | the original number of each participant |
| `neighborValue` | number used for the addition or subtraction |
| `result` | absolute value after adding or subtracting |
| `bestAbove` | smallest qualifying result found so far |
| `largestBelow` | largest result below the target |

The first participant wins a tie, because comparisons are strict.

A trace from `gen.py --trace` for the sample:

```
Juan 58 minus 31 -> 27
Pedro 31 plus 76 -> 107
Maria 76 minus 31 -> 45
```

Only 107 reaches the target 88, so Pedro wins.

## Code

**Bulk input and line scanners.** This block reads stdin once and finds lines by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc readLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)

proc nextNameToken(data: string, pos: var int, lineEnd: int): string =
  while pos < lineEnd and data[pos] <= ' ':
    inc pos
  if pos >= lineEnd:
    return ""
  let tokenStart = pos
  while pos < lineEnd and data[pos] > ' ':
    inc pos
  return data[tokenStart .. pos - 1]

proc nextNumberInLine(data: string, pos: var int, lineEnd: int): int =
  while pos < lineEnd and (data[pos] < '0' or data[pos] > '9'):
    inc pos
  var value = 0
  while pos < lineEnd and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    inc pos
  return value
```

Carriage returns and line feeds both end a line.
Names are cut at whitespace, and numbers are read digit by digit.
The cursor advances only by index, with no token objects.

**Primality test and output buffer.** This block tests divisors and buffers answer text.

```nim
proc isPrimeValue(value: int): bool =
  if value < 2:
    return false
  var divisor = 2
  while divisor * divisor <= value:
    if value mod divisor == 0:
      return false
    inc divisor
  return true

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

Trial division stops at the square root of the value.
Values below two are not prime.
The buffer leaves after reaching 131072 bytes.

**Four-line parse.** This block reads the count, names, numbers, and target.

```nim
var lineBounds = readLineBounds(inputData, scanPos)
var countCursor = lineBounds.first
let participantCount = nextNumberInLine(inputData, countCursor, lineBounds.last)

lineBounds = readLineBounds(inputData, scanPos)
var nameCursor = lineBounds.first
var names = newSeq[string](participantCount)
for index in 0..<participantCount:
  names[index] = nextNameToken(inputData, nameCursor, lineBounds.last)

lineBounds = readLineBounds(inputData, scanPos)
var valueCursor = lineBounds.first
var enteredValues = newSeq[int](participantCount)
for index in 0..<participantCount:
  enteredValues[index] = nextNumberInLine(inputData, valueCursor, lineBounds.last)

lineBounds = readLineBounds(inputData, scanPos)
var targetCursor = lineBounds.first
let targetValue = nextNumberInLine(inputData, targetCursor, lineBounds.last)
```

Each call takes the next non-empty line.
`names` and `enteredValues` keep the same participant order.
The target is the number on the fourth line.

**Winner scan.** This block computes every result and prints the winner.

```nim
var haveAbove = false
var bestAbove = 0
var bestIndex = 0
var largestBelow = -1
var largestBelowIndex = 0
for index in 0..<participantCount:
  let currentValue = enteredValues[index]
  var neighborValue: int
  if participantCount == 1:
    neighborValue = currentValue
  elif index == participantCount - 1:
    neighborValue = enteredValues[index - 1]
  else:
    neighborValue = enteredValues[index + 1]
  var result: int
  if isPrimeValue(currentValue):
    result = currentValue + neighborValue
  else:
    result = currentValue - neighborValue
  if result < 0:
    result = -result
  if result >= targetValue:
    if not haveAbove or result < bestAbove:
      haveAbove = true
      bestAbove = result
      bestIndex = index
  elif result > largestBelow:
    largestBelow = result
    largestBelowIndex = index

if not haveAbove:
  bestIndex = largestBelowIndex

appendOutput(names[bestIndex])
appendOutput(" ")
appendOutput($(enteredValues[bestIndex]))
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A single participant uses their own number as the neighbor.
The flag records whether any result reaches the target.
The final write flushes the buffered answer.

## Complexity

Cost follows the small participant count.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Primality and scan | at most nine values | two small arrays |
| Output | one write per 128 KiB block | block buffer |

The count never reaches ten, so the scan stays tiny.

| Measure | Big O |
|---|---|
| Time | O(n √v) for n participants and value v |
| Space | O(n) |

Testing every possible winner order would be needless work.
One pass with direct primality tests gives the answer.
