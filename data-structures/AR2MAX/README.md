# AR2MAX — Nhap Mang Va Tim Max (SPOJ)

<https://www.spoj.com/problems/AR2MAX/>

## Problem

Read a rectangular table of numbers and print its largest entry.

Input: the first line holds `n` and `m`, then `n` times `m` entries follow in any whitespace layout. Output: one line with the maximum.

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
6
```

The output is the largest of the six entries.

## Idea

Keep the largest entry seen so far, like a judge holding the high score while the rounds play out. The hand scanner reads one token at a time and compares it with the current best. Sorting the table would cost more work and extra memory. One running value is enough.

## Why It Works

1. The first two integers give the row count and column count.
2. Exactly `n` times `m` entries follow, whatever the line breaks.
3. The first entry seeds the running maximum, so the starting value is always legal.
4. A later entry replaces the maximum only when it is strictly larger.
5. After all entries, the running maximum is the global maximum.

The scanner keeps five values:

| term | meaning |
|---|---|
| `rowCount` | row count from the header |
| `columnCount` | column count from the header |
| `elementCount` | `rowCount` multiplied by `columnCount` |
| `largestValue` | largest entry seen so far |
| `elementsRead` | number of entries consumed |

These names appear in the code below.

The sample tokens feed the comparison like this:

```
seed:    1
entries: 2, 3, 4, 5, 6
best:    1, 2, 3, 4, 5, 6
```

Each later entry raises the best, so the answer ends at 6.

No sign branch is needed because the statement uses non-negative entries.

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

**Maximum and output.** One loop compares each entry with the running best.

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
var largestValue = nextInt(inputData, scanPos)
var elementsRead = 1
while elementsRead < elementCount:
  let currentValue = nextInt(inputData, scanPos)
  if currentValue > largestValue:
    largestValue = currentValue
  elementsRead += 1
appendOutput($largestValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`largestValue` starts from the first token, never from an arbitrary bound.
`elementsRead` stops the loop after exactly `n` times `m` entries.
One final write covers the output tail.

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

Sorting the table first would cost O(n m log(n m)) time and O(n m) space. One running comparison finishes in a single pass.
