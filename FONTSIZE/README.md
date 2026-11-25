# FONTSIZE — Font Size (SPOJ)

<https://www.spoj.com/problems/FONTSIZE/>

## Problem

Find the largest font size that fits a message on a billboard, where each line costs one font size of height and each character costs two thirds of that width. Words break only at spaces.

The first line gives the billboard width W and height H in inches. A following line holds the non-empty message of alphanumeric words separated by single spaces. Print the largest feasible size; answers within 0.001 of the true value are accepted.

| item | bound |
|---|---|
| billboard width W | between 0 and 7500 inches |
| billboard height H | between 0 and 7500 inches |
| message length | at most 10000 characters |
| judge limit | 500 ms, 1536 MB |

The first sample input:

```
60 25
The lazy brown dog
```

The first sample output:

```
10
```

## Idea

Try a size, pack words greedily, then search for the largest size that still fits. This works like choosing the biggest text that fits a shelf: measure one candidate, then shift the guess up or down.

The algorithm scales sizes by 1000 and searches an integer range. Greedy packing puts as many words as possible on each line, which minimizes the line count. The number of available lines is the floor of H divided by the size. A linear sweep over every thousandth would test up to millions of sizes, while binary search tests about twenty-four.

Scaling by 1000 turns the whole search into exact integer arithmetic.

## Why It Works

1. A character at size S is 2S/3 inches wide, so scaling S by 1000 makes a character 2 times the scaled size wide in units of 1/3000 inch.
2. Greedy packing minimizes lines because every word has the same width per character and spaces have fixed width.
3. A line with L characters and a leading space costs 2 times the scaled size multiplied by L plus one separator.
4. The billboard holds floor(H times 1000 divided by the scaled size) lines of that size.
5. Feasibility decreases as the size grows, so binary search finds the largest feasible scaled size.

| term | meaning |
|---|---|
| `sizeScaled` | font size multiplied by 1000 |
| `widthScaled` | billboard width multiplied by 3000 |
| `allowedLines` | number of lines that fit the height |
| `wordWidth` | scaled width of one word |
| `fractionText` | trimmed decimal part of the answer |

The scaled units keep every comparison exact.

A script trace for the two examples with the same message:

```
W=60 H=25 size=10 char=6.6667 lines=2 widths=53.3333,60.0 allowed=2 fits=yes
W=60 H=25 size=12.5 char=8.3333 lines=4 widths=25,33.3333,41.6667,25 allowed=2 fits=no
W=50 H=50 size=12.5 char=8.3333 lines=4 widths=25,33.3333,41.6667,25 allowed=4 fits=yes
```

The last row explains why the second sample reaches 12.5.

## Code

**Input and message extraction.** The reader takes the two sizes, then the message line after any blank lines.

```nim
const flushBlockBytes = 1 shl 17

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

let billboardWidth = nextInt(inputData, scanPos)
let billboardHeight = nextInt(inputData, scanPos)
var messageStart = scanPos
while messageStart < inputData.len and inputData[messageStart] != '\n':
  messageStart += 1
while messageStart < inputData.len and (inputData[messageStart] == '\n' or
    inputData[messageStart] == '\r' or inputData[messageStart] == ' ' or
    inputData[messageStart] == '\t'):
  messageStart += 1
var messageEnd = messageStart
while messageEnd < inputData.len and inputData[messageEnd] != '\n' and
    inputData[messageEnd] != '\r':
  messageEnd += 1
let message = inputData[messageStart .. messageEnd - 1]
```

Blank lines before the message are skipped.
The message keeps its single spaces for the packing loop.
`appendOutput` buffers the one answer line.

**Scaled feasibility and search.** The packing loop tests one size, then the binary search narrows the range.

```nim
proc fits(sizeScaled: int64): bool =
  if sizeScaled <= 0:
    return true
  let widthScaled = int64(billboardWidth) * 3000
  let heightScaled = int64(billboardHeight) * 1000
  let allowedLines = heightScaled div sizeScaled
  if allowedLines <= 0:
    return false
  var usedLines: int64 = 1
  var usedWidth: int64 = 0
  var wordStart = 0
  while wordStart < message.len:
    var wordEnd = wordStart
    while wordEnd < message.len and message[wordEnd] != ' ':
      wordEnd += 1
    let wordWidth = 2 * sizeScaled * int64(wordEnd - wordStart)
    if wordWidth > widthScaled:
      return false
    if usedWidth == 0:
      usedWidth = wordWidth
    elif usedWidth + 2 * sizeScaled + wordWidth <= widthScaled:
      usedWidth = usedWidth + 2 * sizeScaled + wordWidth
    else:
      usedLines += 1
      if usedLines > allowedLines:
        return false
      usedWidth = wordWidth
    wordStart = wordEnd
    while wordStart < message.len and message[wordStart] == ' ':
      wordStart += 1
  return true

var lowSize = int64(0)
var highSize = int64(billboardHeight) * 1000
let widthCap = int64(billboardWidth) * 1500
if widthCap < highSize:
  highSize = widthCap
while lowSize < highSize:
  let middleSize = lowSize + (highSize - lowSize + 1) div 2
  if fits(middleSize):
    lowSize = middleSize
  else:
    highSize = middleSize - 1

let wholeInches = lowSize div 1000
let fraction = lowSize mod 1000
if fraction == 0:
  appendOutput($wholeInches)
else:
  var fractionText = $fraction
  while fractionText.len > 0 and fractionText[fractionText.len - 1] == '0':
    fractionText.setLen(fractionText.len - 1)
  appendOutput($wholeInches & "." & fractionText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first word always opens a fresh line.
A word wider than the billboard ends the search at once.
Trailing zeros are dropped so the output matches the sample style.

## Complexity

Each feasibility test walks the message once, and the search tests a logarithmic number of sizes.

| phase | time | space |
|---|---|---|
| input read | one pass over the message | one input string |
| feasibility | one pass over words per trial size | message slice |
| search | about 24 trials for the largest bound | a few integers |
| output | one line | block buffer |

The message length sets the cost of every trial.

| measure | Big O |
|---|---|
| time | O(message length times log size bound) |
| space | O(message length) |

A sweep over every thousandth would cost O(message length times size bound) and grow far beyond the judge limit.
