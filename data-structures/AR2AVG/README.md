# AR2AVG — Input Array 2D and cal AVG (SPOJ)

<https://www.spoj.com/problems/AR2AVG/>

## Problem

Read a rectangular table of numbers and print the arithmetic mean of its entries.

Input: the first line holds `n` and `m`, then `n` times `m` entries follow in any whitespace layout. Output: one line with the mean, written with six digits after the decimal point.

The stated bounds are:

| item | bound |
|---|---|
| rows `n` | not stated in the statement |
| columns `m` | not stated in the statement |
| entry value | not stated in the statement |
| judge limit | 1000 ms, 1536 MB |

The sample uses a 2 by 3 table with small entries; spacing carries no meaning.

Sample input and output:

```
2 3
1 2 3
4 5 6
```

```
3.500000
```

The output is the total 21 divided by six entries.

## Idea

Add the entries, then split the total evenly, like sharing a restaurant bill. The hand scanner reads one token at a time and keeps a 64-bit running total. Keeping every entry in a table would add memory without changing the mean. One sum and one division give the answer.

## Why It Works

1. The first two integers give the row count and column count.
2. Exactly `n` times `m` entries follow, whatever the line breaks.
3. A 64-bit accumulator holds the total before any division happens.
4. Dividing that total by the entry count gives the arithmetic mean.
5. `formatFloat` with `ffDecimal` and precision 6 writes six places and rounds the tail.

The scanner computes with four values:

| term | meaning |
|---|---|
| `rowCount` | row count from the header |
| `columnCount` | column count from the header |
| `elementCount` | `rowCount` multiplied by `columnCount` |
| `totalSum` | running 64-bit total of all entries |

These names appear in the code below.

The sample tokens produce this arithmetic:

```
entries: 1, 2, 3, 4, 5, 6
total:   21
count:   6
21 / 6 = 3.5 -> 3.500000
```

Six digits after the point match the sample byte for byte.

The float conversion happens only after the total is complete, so rounding affects the printed answer only.

## Code

**Input and scanner.** The entire input is read once, then digits are scanned by index.

```nim
import strutils

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
```

`inputData` holds every byte, including newlines.
`nextInt` skips non-digits and builds a value one digit at a time.
`scanPos` advances across calls, so no token objects are created.

**Mean and output.** One loop adds the entries, then one division sets the printed value.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let elementCount = rowCount * columnCount
var totalSum: int64 = 0
for elementIndex in 0 .. elementCount - 1:
  totalSum = totalSum + int64(nextInt(inputData, scanPos))
let divisor = float64(elementCount)
let averageValue = float64(totalSum) / divisor
appendOutput(formatFloat(averageValue, ffDecimal, 6))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`totalSum` stays in 64 bits through the whole loop.
`divisor` and `averageValue` perform the single float division.
`formatFloat` rounds to six places, and one final write covers the tail.

## Complexity

Work by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| scanning | one pass over all tokens | constant |
| output | one line | one output buffer |

Reading and scanning dominate the runtime.

Asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(n m) in the number of entries |
| space | O(1) besides the input and output buffers |

Both bounds grow linearly with the entry count.

Storing a full table first would use O(n m) space and a second pass. One running total finishes in a single pass.
