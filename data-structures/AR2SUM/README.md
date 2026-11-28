# AR2SUM — Nhap Mang Va Tinh Tong (SPOJ)

<https://www.spoj.com/problems/AR2SUM/>

## Problem

Read a rectangular table of numbers and print the sum of all its entries.

Input: the first line holds `n` and `m`, then `n` times `m` entries follow in any whitespace layout. Output: one line with the total.

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
21
```

The output equals the sum of the six entries.

## Idea

Add the entries as they arrive, like dropping coins into one jar. The hand scanner walks the input bytes once and keeps a running total.

Building a table first would allocate memory and add a second pass. One accumulator gives the answer, so nothing else is stored.

## Why It Works

1. The first two integers give the row count and column count.
2. Exactly `n` times `m` entries follow, whatever the line breaks.
3. The scanner skips non-digits, so entries on any number of lines still parse in order.
4. Adding each entry once to a 64-bit total gives the same result as any grouping.
5. The total is written once after the last entry.

The scanner keeps four values:

| term | meaning |
|---|---|
| `rowCount` | row count from the header |
| `columnCount` | column count from the header |
| `elementCount` | `rowCount` multiplied by `columnCount` |
| `totalSum` | running 64-bit total of all entries |

These names appear in the code below.

The sample tokens feed the accumulator like this:

```
header: 2, 3 -> elementCount = 6
entries: 1, 2, 3, 4, 5, 6
total:   1, 3, 6, 10, 15, 21
```

Six additions produce the printed total 21.

`totalSum` uses 64 bits, so large tables cannot overflow the accumulator.

## Code

**Input and scanner.** The entire input is read once, then digits are scanned by index.

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
```

`inputData` holds every byte, including newlines.
`nextInt` skips non-digits and builds a value one digit at a time.
`scanPos` advances across calls, so no token objects are created.

**Total and output.** One loop adds each entry and writes the answer.

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
appendOutput($totalSum)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`elementCount` stops the loop after exactly `n` times `m` entries.
`appendOutput` flushes every `flushBlockBytes` bytes, and one final write covers the tail.

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

Reading rows into a table first would use O(n m) space and a second pass. One running total finishes in a single pass.
