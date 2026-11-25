# PERIOD — Period (SPOJ)
<https://www.spoj.com/problems/PERIOD/>

## Problem

A string can repeat a smaller block: `ababab` is `ab` three times. For each prefix, find the largest repetition count and its block length.

You receive up to ten long strings. For every prefix longer than one, report the repetition only when the whole prefix is an exact copy of one block repeated. Print a blank line after each case.

Input: the first integer is T, the number of cases. Each case gives N and then a string of N lowercase characters. Output: `Test case #x`, then one line `i K` per periodic prefix, then a blank line.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases T | 1 to 10 |
| String length N | 2 to 1000000 |
| Character codes | 97 to 126 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The sample has a short string and a longer one:

```
2
3
aaa
12
aabaabaabaab
```

```
Test case #1
2 2
3 3

Test case #2
2 2
6 2
9 3
12 4
```

The prefix `aabaab` of the second string repeats `aab` twice.

## Idea

Measure how much of each prefix echoes at its end, then read off the repeat count. Picture comparing each prefix with the preceding text and noting the longest ending that matches the start.

The program builds the prefix function (also called a border array) with the KMP (Knuth–Morris–Pratt string matching) method. Entry `border[i − 1]` is the longest proper prefix of the length-i prefix that is also its suffix.

The smallest period of that prefix is `i − border[i − 1]`. The prefix repeats a block only when this period divides i; the repetition count is then `i / period`. Each character costs amortized O(1), so one case costs O(N).

Testing every candidate period and comparing characters costs O(N²), far too slow for a million characters.

Takeaway: one border array answers every prefix question in a single left-to-right pass.

## Why It Works

Four facts prove the test.

1. `border[i − 1]` is the length of the longest proper border of the prefix of length i. KMP falls back from length m to `border[m − 1]` when a character mismatches, so the total number of steps stays linear.
2. The smallest period of that prefix is `periodLength = i − border[i − 1]`. Every other period is a multiple of it.
3. A string of length i equals a block of length p repeated k times only when p divides i. Then k = i / p, and the block is the first p characters.
4. The program reports the case k > 1, which is exactly when a shorter block exists. Prefixes that do not divide evenly are skipped.

These are the values in the scan:

| Term | Meaning |
| --- | --- |
| `border[position]` | longest proper border length of the prefix ending there |
| `matched` | current border length while reading a character |
| `prefixLength` | length i of the prefix being tested |
| `periodLength` | prefixLength − border[prefixLength − 1] |
| `repetitionCount` | prefixLength / periodLength, printed when above one |

A script derives the periodic prefixes of the second sample string:

```
prefix border period repetition (periodic only)
     2      1      1      2
     6      3      3      2
     9      6      3      3
    12      9      3      4
```

The prefix `aabaab` has border 3 and period 3, so `aab` repeats twice. No rounding appears; the division test is exact integer arithmetic.

## Code

**Input.** The whole stream goes into one buffer and is scanned by index.

```nim
{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextTokenStart(data: string, pos: var int, length: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  length = pos - startPos
  return startPos
```

`nextTokenStart` returns an offset and length, so the string itself is never copied. The scanner uses a shared cursor. Cost is one pass over the input bytes.

**Output.** Integer answers are written digit by digit into one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendNumber(value: int) =
  let oldLen = outputBuffer.len
  outputBuffer.setLen(oldLen + 12)
  var pos = oldLen
  var rest = value
  if rest == 0:
    outputBuffer[pos] = '0'
    pos += 1
  else:
    let firstPos = pos
    while rest > 0:
      outputBuffer[pos] = char(firstDigitValue + rest mod 10)
      rest = rest div 10
      pos += 1
    var lowPos = firstPos
    var highPos = pos - 1
    while lowPos < highPos:
      swap outputBuffer[lowPos], outputBuffer[highPos]
      lowPos += 1
      highPos -= 1
  outputBuffer.setLen(pos)
```

`appendNumber` reserves twelve bytes, then trims to the digits it uses. Writing digits in place avoids one string allocation per number. Each number costs O(log value) work.

**Driver.** One border array serves every prefix of a case.

```nim
var border: seq[int] = @[]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let stringLength = nextInt(inputData, scanPos)
  var tokenLength = 0
  let tokenStart = nextTokenStart(inputData, scanPos, tokenLength)

  appendOutput("Test case #")
  appendNumber(caseIndex + 1)
  appendOutput("\n")

  border.setLen(stringLength)
  border[0] = 0
  var matched = 0
  for position in 1..<stringLength:
    let currentChar = inputData[tokenStart + position]
    while matched > 0 and currentChar != inputData[tokenStart + matched]:
      matched = border[matched - 1]
    if currentChar == inputData[tokenStart + matched]:
      matched += 1
    border[position] = matched

  for prefixLength in 1..stringLength:
    let periodLength = prefixLength - border[prefixLength - 1]
    if prefixLength mod periodLength == 0:
      let repetitionCount = prefixLength div periodLength
      if repetitionCount > 1:
        appendNumber(prefixLength)
        outputBuffer.add ' '
        appendNumber(repetitionCount)
        outputBuffer.add '\n'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`matched` falls back through earlier borders on a mismatch, which keeps the pass linear. The second loop reads `prefixLength` from 1, so it never indexes a negative border. The final `appendOutput("\n")` prints the required blank line.

## Complexity

The border pass and the prefix test are linear.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Border array | O(N) amortized | O(N) |
| Prefix reporting | O(N) | O(1) |
| Output | O(periodic prefixes) | O(block size) |

The border array dominates, with O(N) time and O(N) space per string.

| Measure | Big O |
| --- | --- |
| Time per case | O(N) |
| Total time | O(sum of N over cases) |
| Working space | O(N) |

Trying each possible period and comparing all characters takes O(N²) time.
