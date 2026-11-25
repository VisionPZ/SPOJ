# RF111 — LA TIENDA DE WALTER Grado 11 (SPOJ)
<https://www.spoj.com/problems/RF111/>

## Problem

Walter needs a price for each of his three main dishes at a new restaurant.
His dish prices are compared with the diners each dish can attract.
For every restaurant, multiply each matrix entry by its matching diner count.
Add those products to get that restaurant's total price.
Print the totals in braces, then the smallest total after an en dash.
Each input line holds a matrix and a weight vector separated by a semicolon.
Nested one-element groups in the vector are treated as plain weights.

| Item | Bound |
|---|---|
| Input lines | not stated |
| Matrix size | three dishes in the statement |
| Time limit | 1000 ms |
| Memory | 1536 MB |

The dot product per row drives the design, since the matrices are small.

The sample from the statement:

```
{{400,2500,30000,50000}, {5200,4300,6000,8500}, {400,504,520,6300}}; {10, 20, 100, 50}
```

```
"{5554000,1163000,381080} – 381080"
```

## Idea

Setting the price is like adding up a shopping receipt column by column.
Each restaurant row holds competitor prices, one per dish.
Each weight holds the diners that dish can bring.
The program reads all input once and scans every line by byte.
It collects the matrix numbers before the semicolon and the weights after it.
Then it multiplies matching pairs and keeps the smallest row total.
One output buffer flushes in blocks, so writes stay rare.

One pass over each row gives every price and the minimum.

## Why It Works

1. A dish contributes its price times the diners it can attract.
2. A restaurant's total is the sum of those contributions.
3. The semicolon separates the price matrix from the weight vector.
4. The vector length gives the number of columns in each row.
5. Updating the smallest total during the scan needs no second pass.

The main terms follow.

| Term | Meaning |
|---|---|
| `matrixValues` | all competitor prices before the semicolon |
| `weightValues` | diner counts after the semicolon |
| `columnCount` | number of weights, hence columns per row |
| `rowTotal` | sum of products for one restaurant |
| `lowestPrice` | smallest `rowTotal` seen so far |

Every row costs one multiplication and one addition per column.

A trace from `gen.py --trace` for the sample:

```
row 1: 400*10 + 2500*20 + 30000*100 + 50000*50 = 5554000
row 2: 5200*10 + 4300*20 + 6000*100 + 8500*50 = 1163000
row 3: 400*10 + 504*20 + 520*100 + 6300*50 = 381080
lowest: 381080
```

The trace matches the sample output exactly.

## Code

**Bulk input and line scanner.** This block reads stdin once and finds each line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const separatorMark = ';'

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
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
```

The read loop ends at end of input.
The semicolon constant names the separator byte.
Empty lines are skipped in the main loop.

**Number scanner.** This block parses signed integers inside a byte range.

```nim
proc nextNumberInRange(data: string, pos: var int, limit: int): int64 =
  while pos < limit and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    inc pos
  if pos >= limit:
    return 0
  var negative = false
  if data[pos] == '-':
    negative = true
    inc pos
  var value: int64 = 0
  while pos < limit and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    inc pos
  if negative:
    value = -value
  return value

proc collectNumbers(data: string, startPos: int, limit: int,
                    values: var seq[int64]) =
  var cursor = startPos
  while cursor < limit:
    while cursor < limit and (data[cursor] < '0' or data[cursor] > '9') and
        data[cursor] != '-':
      inc cursor
    if cursor >= limit:
      break
    values.add nextNumberInRange(data, cursor, limit)
```

Braces, commas, and spaces are skipped as plain bytes.
The pre-skip stops a phantom zero at the region boundary.
Accumulation uses `int64`, so large products stay exact.

**Output buffer.** This block buffers text and flushes in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
The last partial block is written after the loop.
No write happens per restaurant.

**Dot product and answer line.** This block pairs prices with weights and prints.

```nim
while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var hasContent = false
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ':
      hasContent = true
      break
  if not hasContent:
    continue

  var separator = lineStart
  while separator < lineEnd and inputData[separator] != separatorMark:
    inc separator
  if separator >= lineEnd:
    continue

  var matrixValues: seq[int64] = @[]
  var weightValues: seq[int64] = @[]
  collectNumbers(inputData, lineStart, separator, matrixValues)
  collectNumbers(inputData, separator + 1, lineEnd, weightValues)

  let columnCount = weightValues.len
  if columnCount == 0:
    continue

  var priceValues: seq[int64] = @[]
  var lowestPrice: int64 = 0
  var rowStart = 0
  var firstRow = true
  while rowStart + columnCount <= matrixValues.len:
    var rowTotal: int64 = 0
    for column in 0..<columnCount:
      rowTotal += matrixValues[rowStart + column] * weightValues[column]
    priceValues.add rowTotal
    if firstRow or rowTotal < lowestPrice:
      lowestPrice = rowTotal
      firstRow = false
    rowStart += columnCount

  if priceValues.len == 0:
    continue

  outputBuffer.add '"'
  outputBuffer.add '{'
  for priceIndex in 0..<priceValues.len:
    if priceIndex > 0:
      outputBuffer.add ','
    outputBuffer.add $(priceValues[priceIndex])
  outputBuffer.add '}'
  outputBuffer.add ' '
  outputBuffer.add "\xE2\x80\x93"
  outputBuffer.add ' '
  outputBuffer.add $(lowestPrice)
  outputBuffer.add '"'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops when fewer than `columnCount` values remain.
The escape sequence writes the en dash byte for byte.
Quotes and braces surround the list exactly as the sample shows.

## Complexity

Cost follows the number of prices and weights on each line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Parsing | one pass over each line | two number lists |
| Dot product | one product per matrix entry | one row total |
| Output | one write per block | block buffer |

Parsing and multiplying each run once keeps the work linear.

| Measure | Big O |
|---|---|
| Time | O(I + m) for m matrix entries |
| Space | O(I + m + B) |

Here I is input bytes, m is matrix entries, and B is block size.

Rebuilding each product list from scratch would waste work.
One row-wise dot product gives every price and the minimum directly.
