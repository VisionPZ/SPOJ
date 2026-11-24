## Problem

Read `K` areas. Each area gives `M` rows and `N` columns, then `M` lines of `R` and `F` symbols separated by spaces. Find the largest rectangle made only of `F` cells. Print its area times the rent of 3 dollars per cell, one answer per line.

The bounds on one area are:

| Quantity | Bound |
| --- | --- |
| Areas `K` | not bounded in the statement |
| Rows `M` | at most 1000 |
| Columns `N` | at most 1000 |
| Cells per area | at most 1 000 000 |
| Rent per cell | 3 dollars |
| Judge limits | 3 s, 1536 MB |

One million cells per area sets the work per case.

## Idea

Treat each row as the bottom edge of a candidate rectangle. Count the `F` cells stacked upward in each column to form a histogram. A monotone stack finds the largest rectangle in that histogram in one pass, so no rectangle is enumerated.

Cost per cell: one height update plus amortized constant stack work.

Checking every rectangle instead costs O(M²N²) per area.

## Why It Works

A rectangle that ends at row `k` uses consecutive `F` cells in each column of its span. The `heights` array holds exactly that run length after row `k` is read. When a bar is shorter than the current bar, the current rectangle ends at the current column.

The width of a rectangle at a popped bar is:

- `l` is the current column, one past the span when the bar pops.
- `leftLess` is the nearest column to the left with a shorter bar.
- `l - leftLess - 1` is the number of columns in the span.
- `barHeight * width` is the candidate area.

Stale bars would widen a span, so `barStack` is cleared before each row. The sentinel column makes the last bar pop and flush its rectangle.

The first sample area gives these heights and best areas after each row:

```
row  heights after row            best area
  0  0 1 1 1 1 1                   5
  1  1 2 2 2 2 2                  10
  2  0 0 0 3 3 3                  10
  3  1 1 1 4 4 4                  12
  4  2 2 2 5 5 5                  15
profit = area * 3 = 45
```

The last row reaches area 15, so the program prints 45.

## Code

Three constants set the digit base, the rent, and the output block size.

```nim
const firstDigitValue = 48
const rentPerUnit = 3
const flushBlockBytes = 1 shl 18
```

`firstDigitValue` converts a digit byte into its value. `rentPerUnit` converts area into profit. The output block holds 256 KiB, so writes happen in batches.

Read all input once, then scan digits and symbols by index.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextSymbol(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let symbol = data[pos]
  pos += 1
  return symbol
```

The `readLine` loop touches each input line once. `nextInt` skips the letters and the separating line. `nextSymbol` advances past the returned symbol, which prevents reading the same cell twice. Both scanners cost one pass over the input bytes.

Collect answers in one growable buffer and flush by size.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` flushes after the buffer reaches `flushBlockBytes`. `setLen 0` reuses the same allocation. No write happens per cell or per case.

The main loop updates heights and scans the histogram of each row.

```nim
{.push checks: off.}
let caseCount = nextInt(inputData, i)
var heights: seq[int]
var barStack: seq[int]

for j in 0..<caseCount:
  let rowCount = nextInt(inputData, i)
  let colCount = nextInt(inputData, i)
  heights.setLen colCount
  for l in 0..<colCount:
    heights[l] = 0
  barStack.setLen 0
  var bestArea = 0
  for k in 0..<rowCount:
    barStack.setLen 0
    for l in 0..<colCount:
      let symbol = nextSymbol(inputData, i)
      if symbol == 'F':
        heights[l] += 1
      else:
        heights[l] = 0
    for l in 0..colCount:
      let curHeight = if l == colCount: 0 else: heights[l]
      while barStack.len > 0 and heights[barStack[barStack.len - 1]] > curHeight:
        let barHeight = heights[barStack[barStack.len - 1]]
        barStack.setLen(barStack.len - 1)
        let leftLess = if barStack.len > 0: barStack[barStack.len - 1] else: -1
        let width = l - leftLess - 1
        let area = barHeight * width
        if area > bestArea:
          bestArea = area
      if l < colCount:
        barStack.add l
  appendOutput($(bestArea * rentPerUnit))
  outputBuffer.add '\n'
```

`heights` is zeroed for each case, so one case cannot lend cells to the next. The row loop runs `rowCount` times. The histogram loop makes one pass per column plus one sentinel column of height zero. The pragma removes runtime checks from this hot loop, and every index stays in range. The whole loop costs O(M·N) per area.

Write the final partial block after the last case.

```nim
{.pop.}
stdout.write outputBuffer
outputBuffer.setLen 0
```

This write covers the tail of the buffer. An empty tail produces no extra bytes. It runs once, after all cases.

## Complexity

The phases and their costs are:

| Phase | Time | Space |
| --- | --- | --- |
| Read input | O(total bytes) | O(total bytes) |
| Heights and histogram, per area | O(M·N) | O(N) |
| Output | O(K) | O(flush block) |

Total time is O(total input bytes + K), and total space is O(input bytes + N). Enumerating every rectangle would cost O(M²N²) per area instead of O(M·N).
