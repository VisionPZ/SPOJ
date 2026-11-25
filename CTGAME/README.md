# CTGAME — City Game (SPOJ)
<https://www.spoj.com/problems/CTGAME/>

## Problem

A city planner fills a grid-shaped district with buildings.
Each free cell earns 3 dollars, so the planner wants the largest rectangle of free cells.

Read `K` areas. Each area gives row count `M` and column count `N`.
The next `M` lines hold `N` symbols each, separated by spaces.
`F` marks a free cell and `R` marks a reserved cell.
A blank line follows each area. Print one integer per area: the largest free area times 3.

The judge bounds one area as follows.

| Item | Bound |
| --- | --- |
| Test cases `K` | not bounded in the statement |
| Rows `M` | at most 1000 |
| Columns `N` | at most 1000 |
| Cells per area | at most 1,000,000 |
| Rent per cell | 3 dollars |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

One million cells per area sets the work per case.

The sample input and expected output follow verbatim.

```
2
5 6
R F F F F F
F F F F F F
R R R F F F
F F F F F F
F F F F F F

5 5
R R R R R
R R R R R
R R R R R
R R R R R
R R R R R

```

```
45
0
```

The first area earns 45 dollars and the second area earns nothing.

## Idea

Stack the free cells above each row like books on a shelf.
Each row then becomes a histogram (a list of column heights), and one sweep finds its largest rectangle.

Treat row `k` as the bottom edge of a candidate rectangle.
`heights[col]` counts the free cells stacked upward in that column.
A monotone stack (column indices with increasing heights) pops a bar when a shorter bar appears.
That pop fixes the rectangle's width and height.

Cost per cell is one height update plus amortized (averaged over the sweep) constant stack work.
Checking every rectangle instead costs O(M²N²) per area.
One histogram pass per row finds the best rectangle in linear time.

## Why It Works

Four facts prove the method.

1. A rectangle ending at row `k` uses consecutive free cells in each column of its span.
   After row `k`, `heights` holds exactly those run lengths.
2. A shorter bar stops a taller bar from extending further right.
   Popping the taller bar fixes its right edge at the current column.
3. After the pop, the new stack top is the nearest column to the left with a shorter bar.
   That column gives the left edge.
4. A sentinel (a fake column of height zero at the end) flushes every remaining bar.
   Clearing the stack per row keeps stale bars from widening a span.

The area of each popped rectangle uses these terms.

| Term | Meaning |
| --- | --- |
| `l` | current column, one past the span |
| `leftLess` | nearest column to the left with a shorter bar |
| `l - leftLess - 1` | number of columns in the span |
| `barHeight * width` | candidate area |

The best candidate across all pops is the answer for that row.

A script rebuilds the heights of the first sample area and prints one line per row.

```
row  heights after row       best ending here   running best
  0  0 1 1 1 1 1                  5                  5
  1  1 2 2 2 2 2                 10                 10
  2  0 0 0 3 3 3                  9                 10
  3  1 1 1 4 4 4                 12                 12
  4  2 2 2 5 5 5                 15                 15
profit = area * 3 = 15 * 3 = 45
```

The last row reaches area 15, so the program prints 45.

## Code

**Constants.**

```nim
const firstDigitValue = 48
const rentPerUnit = 3
const flushBlockBytes = 1 shl 18
```

firstDigitValue turns a digit byte into its value. rentPerUnit converts an area into rent. The output block holds 256 KiB, so writes happen in batches.

**Bulk input and scanners.**

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

The read loop copies every input line into one buffer. nextInt skips letters and blank separators. nextSymbol advances past the returned cell, so no cell is read twice. Both scanners cost one pass over the bytes.

**Output buffer.**

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

appendOutput flushes once the buffer reaches flushBlockBytes. setLen 0 reuses the same allocation. No write happens per cell or per case.

**Height update and histogram sweep.**

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

heights is zeroed per case, so one area cannot lend cells to the next. The row loop runs rowCount times. The histogram loop makes one pass over columns plus a zero-height sentinel. The pragma removes bounds checks from this hot loop.

**Final flush.**

```nim
{.pop.}
stdout.write outputBuffer
outputBuffer.setLen 0
```

This write covers the last partial block after all cases. An empty tail produces no extra bytes. It runs once.

## Complexity

The phases and their costs for one area follow.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(total bytes) | one input buffer |
| Heights and histogram | O(M·N) | O(N) |
| Output | O(K) | one output block |

Total time is linear in the input size plus the answer count.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(total bytes + K) |
| Space | O(input bytes + N) |

Enumerating every rectangle costs O(M²N²) per area instead of O(M·N).
