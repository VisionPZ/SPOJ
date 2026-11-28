# IITWPC4A — Maggu and Strings (SPOJ)

<https://www.spoj.com/problems/IITWPC4A/>

## Problem

Find the shortest and longest string reachable by repeatedly trading m consecutive letters a for n consecutive letters b.

Input starts with T. Each case gives a string, then a line with m and n. Output one line per case with minimum then maximum length.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| string length | 1 to 1e5 per case |
| total string length | at most 1e6 |
| m and n | 1 to 1e5 |
| judge limit | 1000 ms, 1536 MB |

The total length bound keeps a single pass over all strings affordable.

Sample input:

```
3
abc
1 2
aa
1 2
aba
1 1
```

Sample output:

```
3 4
2 4
3 3
```

The first case can stay abc or become bbbc, so lengths three and four.

## Idea

Treat each run of a as a stack of coupons, and each move trades one bundle for a new batch of b.

Trades never create new a, so each run shrinks on its own. A run of length L permits floor of L over m trades. Each trade changes total length by n minus m. A positive change raises the maximum; a negative change lowers the minimum. Searching all reachable strings would explore exponentially many states.

## Why It Works

1. A trade needs m adjacent a characters and replaces them with b characters.
2. Replacement creates no a, so runs only shrink and never merge.
3. Taking bundles from one end leaves one shorter run, giving floor L over m trades.
4. All runs contribute additively to the number of trades.
5. Multiplying trades by n minus m gives the total length change from the original string.

| term | meaning |
|---|---|
| `sourceText` | the string given in the case |
| `groupSize` | m, the number of a characters consumed per trade |
| `producedSize` | n, the number of b characters produced per trade |
| `replacementCount` | total trades possible across all runs |
| `lengthDelta` | n minus m, the length change per trade |

The run scan is one pass; the trade count uses only integer division.

A script traces the second sample case:

```
source aa, m = 1, n = 2
runs: [2], trades = 2
delta = +1
minimum = 2, maximum = 2 + 2*1 = 4
```

The trace matches the printed second line, 2 4.

## Code

**Input, scanner, and word reader.** The reader loads stdin once and tokenizes it by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word
```

The word reader stops at the first whitespace character.
Integer parsing resumes at the following line.

**Buffered output.** One string collects all case answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each line holds two integers separated by one space.
The block flush keeps writes infrequent.

**Run scan and extremes.** The program counts trades and applies the length change.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sourceText = nextWord(inputData, scanPos)
  let groupSize = nextInt(inputData, scanPos)
  let producedSize = nextInt(inputData, scanPos)
  var replacementCount: int64 = 0
  var runLength = 0
  for character in sourceText:
    if character == 'a':
      runLength += 1
    else:
      replacementCount += int64(runLength div groupSize)
      runLength = 0
  replacementCount += int64(runLength div groupSize)
  let originalLength = int64(sourceText.len)
  let lengthDelta = int64(producedSize) - int64(groupSize)
  var minimumLength = originalLength
  var maximumLength = originalLength
  if lengthDelta > 0:
    maximumLength += lengthDelta * replacementCount
  elif lengthDelta < 0:
    minimumLength += lengthDelta * replacementCount
  appendOutput($minimumLength & " " & $maximumLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final run is counted after the loop ends.
Lengths use 64-bit integers because trades can reach 1e10.
A zero length change leaves both answers at the original length.

## Complexity

Each string is scanned once, and each case does constant arithmetic afterwards.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| run scan | one pass over string characters | constant |
| arithmetic | one multiply per case | constant |
| output | one line per case | block buffer |

The word reader allocates only the current string.

| measure | Big O |
|---|---|
| time | O(total string length) |
| space | O(longest string) |

State-space search over reachable strings grows exponentially and loses.
Counting trades per run is the takeaway.
