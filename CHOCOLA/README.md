# CHOCOLA — Chocolate (SPOJ)

<https://www.spoj.com/problems/CHOCOLA/>

## Problem

A rectangular bar is split by vertical and horizontal cuts, each with a fixed price. Find the least total cost to separate every square.

Input: one integer for the test count, a blank line, then one case per test. Each case starts with `columnCount rowCount`, then lists `columnCount - 1` cut costs and `rowCount - 1` cut costs. A blank line separates cases.

Output: one integer per case, the minimum total cost to separate every square.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Test cases | at most 20 |
| Bar side | 2 to 1000 |
| Cut cost | 1 to 1000 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

One case holds nearly 2000 costs, so the program avoids sorting them.

The sample input and output:

```
1

6 4
2
1
3
1
4
4
1
2

```

```
42
```

## Idea

Cut the dearest line first, like paying the largest bills before the small ones. A cut spans the whole bar, so its price is paid once per perpendicular piece.

The program counts how many cuts sit at each price. Two downward scans read the two cost groups from high to low and merge them into one greedy order. Each cut costs constant work after the scans reach the next nonempty price.

Sorting every cut would cost O(c log c) for c cuts. Counting by price costs one pass over the 1000 possible prices instead.

Counting by price keeps the greedy order linear in the bar size.

## Why It Works

The greedy order follows from one fact about piece counts.

1. A cut crosses every perpendicular piece that already exists, so its price multiplies that piece count.
2. Piece counts only grow, so an early cheap cut raises the count that multiplies a later dear cut.
3. Equal prices give the same total in either order, so a tie needs no special rule.
4. A count array indexed by price lists cuts from high to low when its index walks downward.

The arrays and counters carry the following facts:

| Term | Meaning |
| --- | --- |
| `verticalCount[cost]` | uncut lines in the first direction at that price |
| `horizontalCount[cost]` | uncut lines in the second direction at that price |
| `verticalPieces` | strips in the first direction after the cuts so far |
| `horizontalPieces` | strips in the second direction after the cuts so far |
| `remainingVertical` | uncut lines left in the first direction |

Both counts stay below the price bound, so the scans remain short.

A script prints one row per cut in the sample case:

```
step cut multiplier added total vertical/horizontal pieces
1    V4  1          4     4     2/1
2    H4  2          8     12    2/2
3    V3  2          6     18    3/2
4    V2  2          4     22    4/2
5    H2  4          8     30    4/3
6    V1  3          3     33    5/3
7    V1  3          3     36    6/3
8    H1  6          6     42    6/4
```

The eight cuts add to 42, which matches the sample output.

## Code

**Setup and input.** One buffer holds the stream, and a scanner reads each price by hand.

```nim
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumCutCost = 1000

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
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop runs once per input line and appends a newline each time. The scanner skips the blank lines between cases because it ignores non-digits. One pass over the buffer supplies every price.

**Output helper and price counts.** Both direction arrays have 1001 slots, one per legal price.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var verticalCount: array[maximumCutCost + 1, int]
var horizontalCount: array[maximumCutCost + 1, int]
```

The helper flushes at 256 KiB and reuses the same storage. No write happens per answer. The two arrays cover prices from 0 through 1000.

**Greedy cut loop.** Two downward scans find the next price, and one comparison picks the direction.

```nim
let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  for k in 0..maximumCutCost:
    verticalCount[k] = 0
    horizontalCount[k] = 0
  var remainingVertical = columnCount - 1
  var remainingHorizontal = rowCount - 1
  for k in 0..<remainingVertical:
    let cutCost = nextInt(inputData, scanPos)
    verticalCount[cutCost] += 1
  for k in 0..<remainingHorizontal:
    let cutCost = nextInt(inputData, scanPos)
    horizontalCount[cutCost] += 1
  var verticalValue = maximumCutCost
  var horizontalValue = maximumCutCost
  var verticalPieces = 1
  var horizontalPieces = 1
  var totalCost: int64 = 0
  while remainingVertical > 0 or remainingHorizontal > 0:
    if remainingVertical > 0:
      while verticalCount[verticalValue] == 0:
        verticalValue -= 1
    if remainingHorizontal > 0:
      while horizontalCount[horizontalValue] == 0:
        horizontalValue -= 1
    if remainingVertical > 0 and (remainingHorizontal == 0 or verticalValue >= horizontalValue):
      totalCost += int64(verticalValue) * int64(horizontalPieces)
      verticalPieces += 1
      verticalCount[verticalValue] -= 1
      remainingVertical -= 1
    else:
      totalCost += int64(horizontalValue) * int64(verticalPieces)
      horizontalPieces += 1
      horizontalCount[horizontalValue] -= 1
      remainingHorizontal -= 1
  appendOutput($(totalCost))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The two read loops stop at `remainingVertical` and `remainingHorizontal`, so a case never eats the next case's data. The scans descend at most 1000 steps each. The total uses `int64`, which covers the largest legal bar.

## Complexity

Each case reads its costs once and scans at most 1000 prices per direction.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Price reset | O(1000) slots | O(1000) |
| Scans and cuts | O(1000 + cuts) per case | O(1000) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(1000 + columns + rows) | O(1000) |

The price bound, not the bar area, limits the scan.

With T (test count) cases, the asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(T × (1000 + columns + rows)) |
| Space | O(1000) plus buffers |

Sorting every cut would cost O(c log c) per case instead of one bounded scan.
