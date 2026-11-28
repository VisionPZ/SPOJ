# SHOCCUR — Most Occurrence (SPOJ)

<https://www.spoj.com/problems/SHOCCUR/>

## Problem

Each query names a range of positions in a lowercase string. The task is to report the letter that appears most often in that range, with ties going to the smallest letter.

Input gives the string length and query count, then the string, then one range per query. Output gives the winning letter and its count on one line per query.

| Item | Bound |
|---|---|
| String length | 1 ≤ n ≤ 10⁵ |
| Query count | 1 ≤ q ≤ 10⁵ |
| Range | 1 ≤ L ≤ R ≤ n |
| Judge limit | 1000 ms, 1536 MB |

The product of both bounds rules out scanning each range from scratch.

The sample case:

```
13 5
abbacccdefgha
1 13
1 10
3 6
11 12
8 12
```

```
a 3
c 3
c 2
g 1
d 1
```

## Idea

Store one running count per letter and per string prefix. Think of 26 tally sheets: each position adds one mark to a single sheet. A range count is the difference between two sheet rows. Scanning the whole range for every query costs O(nq). Prefix differences answer each query in fixed time.

## Why It Works

1. Row k of `prefixCounts` holds counts after the first k characters.
2. A letter's count inside [L, R] equals row R minus row L − 1.
3. Letters are tested from a to z, and only a strictly larger count wins a tie.
4. Each query reads 52 cells and runs in constant time.
5. int32 cells hold counts up to 10⁵ without overflow.

| Term | Meaning |
|---|---|
| `prefixCounts` | cumulative letter counts at each position |
| `leftIndex` | zero-based start of the query range |
| `rightIndex` | inclusive end of the query range |
| `bestLetter` | smallest letter with the top count |
| `alphabetSize` | number of lowercase letters |

Prefix differences reduce a range scan to table lookups.

A script-traced example from `gen.py`:

```
text abbacccdefgha
query 1 13
answer a 3
```

The trace matches the first sample answer.

## Code

**Input and hand scanners.** This block loads stdin and reads numbers or a word.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const alphabetSize = 26

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token
```

One readLine loop collects the whole input.
`nextToken` lifts the string before any integer scanner runs.
Both helpers cost one pass over their characters.

**Buffered output.** This block collects finished answer lines.

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

**Prefix table.** This block copies counts forward and adds one letter.

```nim
let textLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let sourceText = nextToken(inputData, scanPos)

var prefixCounts: seq[array[alphabetSize, int32]]
prefixCounts.setLen(textLength + 1)
for index in 0..<textLength:
  prefixCounts[index + 1] = prefixCounts[index]
  let letterIndex = ord(sourceText[index]) - ord('a')
  if letterIndex >= 0 and letterIndex < alphabetSize:
    prefixCounts[index + 1][letterIndex] += 1
```

The build loop runs exactly n times.
Copying the prior row keeps every prefix cumulative.
The table uses about 10 MB at the largest length.

**Query loop.** This block finds the top letter for every range.

```nim
for queryIndex in 0..<queryCount:
  let leftIndex = nextInt(inputData, scanPos) - 1
  let rightIndex = nextInt(inputData, scanPos)
  var bestLetter = 0
  var bestCount = int32(-1)
  for letterIndex in 0..<alphabetSize:
    let currentCount = prefixCounts[rightIndex][letterIndex] - prefixCounts[leftIndex][letterIndex]
    if currentCount > bestCount:
      bestCount = currentCount
      bestLetter = letterIndex
  appendOutput($(char(ord('a') + bestLetter)) & " " & $(int(bestCount)) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly q times.
A strict comparison preserves the smallest tied letter.
Each query costs 26 subtractions and one buffer append.

## Complexity

The cost splits into input, one prefix build, and one short pass per query.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Prefix build | O(n) row copies | 26 rows of length n + 1 |
| Queries | O(26) work each | output buffer |
| Output | one write per 128 KiB block | block buffer |

Each query stays constant regardless of its range length.

| Measure | Big O |
|---|---|
| Time | O(n + q) |
| Space | O(n) |

Scanning each queried range costs O(nq) and fails at the largest bounds.
