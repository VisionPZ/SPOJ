# SECLAZY — Jisan the lazy person (SPOJ)
<https://www.spoj.com/problems/SECLAZY/>

## Problem

Each case gives a contestant count and four prize counts. Print YES when prizes reach half the contestants, and NO otherwise.

The lazy contestant is not counted in N. He joins only when at least half of those N contestants win a prize.
Every input line holds five integers. One answer line follows for each input line.

| Item | Value |
|---|---|
| Input | five integers per line |
| Output | YES or NO per line |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Doubling the prize sum avoids fractions and rounding.

The statement sample follows verbatim.

```
80 20 20 10 10
105 10 25 05 05
```

```
YES
NO
```

## Idea

Think of filling four prize boxes and checking whether the pile covers half a row of seats.
The program adds the four counts, then compares twice that sum with N.
Whole numbers keep the test exact for odd N.
Computing a fraction per case would need division and rounding.

A single integer comparison gives each verdict.

## Why It Works

1. Each prize goes to one person, so the awarded count is the sum.
2. Twice the awarded count reaches N exactly when the awarded share reaches half.
3. An odd N needs a sum of at least (N + 1) / 2, which the doubled test enforces.
4. Leading zeros parse as ordinary decimal digits.
5. Skipping whitespace lets cases span any number of lines.

The main names and values:

| Term | Meaning |
|---|---|
| `contestantCount` | the N value for the case |
| `awardedCount` | the sum of the four prize counts |
| `nextInt` | reads the next decimal integer by index |
| `appendOutput` | adds text and flushes a full block |

The doubled comparison needs no floating point.

A script trace of the first sample case shows the test.

```
contestants: 80
prizes: [20, 20, 10, 10]
awarded: 60, threshold: 40
verdict: YES
```

Sixty awarded places exceed the threshold of forty.

## Code

**Read the whole stream.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

All input bytes sit in one string. The constants name the digit offset and flush size.

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

Non-digits are skipped first. Each digit updates the running value by index.

**Buffer output in blocks.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB. A reset reuses the same string.

**Decide each case.**
```nim
var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let contestantCount = nextInt(inputData, scanPos)
  let firstPrizeCount = nextInt(inputData, scanPos)
  let secondPrizeCount = nextInt(inputData, scanPos)
  let thirdPrizeCount = nextInt(inputData, scanPos)
  let fourthPrizeCount = nextInt(inputData, scanPos)
  let awardedCount = firstPrizeCount + secondPrizeCount + thirdPrizeCount + fourthPrizeCount
  if awardedCount * 2 >= contestantCount:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
```

Whitespace at the end stops the loop. Twice the sum decides the answer without division.

**Emit the final partial block.**
```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

One last write clears the buffer. Cases never write directly to the stream.

## Complexity

Parsing and decisions are both linear in the token count.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Decision | four additions per case | constant |
| Output | one write per full block | block buffer |

Each case uses a fixed amount of work.

| Measure | Big O |
|---|---|
| Time | O(input tokens) |
| Space | O(input bytes) |

Forming a fraction and rounding per case would add slower arithmetic, so integer comparison wins.
