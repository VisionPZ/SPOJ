# MOZSATC — Sharmeen and the commas (SPOJ)

<https://www.spoj.com/problems/MOZSATC/>

## Problem

Given one string of letters, digits, and commas, report the length of its longest contiguous piece that holds at most K commas. Keep one window of the string and slide it while counting commas.

Input has exactly two lines: the string of length n, then the integer K. Output is one line with the winning length.

| item | bound |
|---|---|
| string length n | 1 to 100000 |
| allowed commas K | 0 to n |
| characters | a-z, 0-9, comma |
| judge limit | 1000 ms, 1536 MB |

The comma count, not the character mix, limits each window.

Sample input:

```
a,b,a0,3hg,0,,,sdfghijfh06
3
```

Sample output:

```
15
```

## Idea

Think of a zipper sliding along the string: you open it past one comma and close it when a fourth comma appears. That is the two-pointer sliding window, costing one look at each character. Rebuilding every substring from scratch costs quadratic time and cannot handle n = 100000.

A growing right edge and a shrinking left edge keep the comma count in range. Print the largest window length seen.

## Why It Works

1. Moving the right edge forward adds at most one comma.
2. When the count passes K, moving the left edge forward removes commas until the count returns to K.
3. After each repair step, the window is the longest one ending at the current right edge.
4. The running maximum therefore visits every possible best window.

| term | meaning |
|---|---|
| `sourceText` | the string read from the first line |
| `allowedCommas` | K, the comma budget |
| `leftBound` | left edge of the current window |
| `commaCount` | commas inside the current window |
| `bestLength` | largest valid window length found |

The sample has commas at indices 1, 3, 6, 10, 12, 13, 14 in a string of length 26. The table below lists the longest window that ends before the comma four places ahead.

| window left | window right | commas | length |
|---|---|---|---|
| 0 | 9 | 3 | 10 |
| 2 | 11 | 3 | 10 |
| 4 | 12 | 3 | 9 |
| 7 | 13 | 3 | 7 |
| 11 | 25 | 3 | 15 |

The last row starts at index 11 and gives the reported answer 15.

## Code

**Input and scanning.** The reader loads the whole stream, then extracts the string and K.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word
```

The token reader stops at whitespace and keeps every comma. The integer reader skips the newline between lines. Both use one position index.

**Sliding window.** One pass moves the right edge and repairs the left edge.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sourceText = nextToken(inputData, scanPos)
let allowedCommas = nextInt(inputData, scanPos)
var leftBound = 0
var commaCount = 0
var bestLength = 0
for rightBound in 0 .. sourceText.len - 1:
  if sourceText[rightBound] == ',':
    commaCount += 1
  while commaCount > allowedCommas:
    if sourceText[leftBound] == ',':
      commaCount -= 1
    leftBound += 1
  let windowLength = rightBound - leftBound + 1
  if windowLength > bestLength:
    bestLength = windowLength
appendOutput($bestLength)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The left edge never moves backward, so each character leaves the window once. The count stays at most K after the inner loop. One final flush writes the single answer line.

## Complexity

Each edge of the window advances at most n times.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| window scan | two edge moves per character | constant |
| output | one buffered line | block buffer |

The scan dominates the other phases.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) for input, O(1) for the scan |

Checking every substring would take O(n^2) time, while this window never revisits a character. The sliding window handles the full length bound.
