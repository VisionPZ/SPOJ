# FINAL1 — Desfile (SPOJ)

<https://www.spoj.com/problems/FINAL1/>

## Problem

A parade has columns, each holding soldiers who start marching on the left or right. Beauty is the absolute difference between the left total and the right total. Swap the two counts in at most one column to maximize beauty.

Input: one line with the column count, then one line per column with its left and right counts.
Output: the 1-based column to swap, or 0 when beauty is already maximal. Any optimum is accepted.

| Item | Bound |
|---|---|
| Columns | 1 to 100000 |
| Count per side | 1 to 500 |
| Judge limit | 1000 ms |

Only the difference between side totals drives the choice.

Sample input:

```
3
5 6
8 9
10 3
```

Sample output:

```
3
```

## Idea

Think of two team scores with one group that can switch sides. Let d be left total minus right total. Swapping column i removes its left count from the left side and adds its right count. The right side changes the opposite way, so the new difference is d minus twice the column difference. Beauty is the absolute value of that number.

Store both count lists, compute d once, then scan the columns. Each column costs one subtraction, one multiplication, and one absolute value. The scan runs in O(1) time per column and O(n) time overall.

## Why It Works

1. Beauty equals the absolute value of left total minus right total.
2. Swapping column i removes its left count and adds its right count to the left total.
3. The right total changes the opposite way, giving new difference d - 2(li - ri).
4. A swap helps only when its beauty exceeds the current beauty; otherwise 0 is correct.

| Term | Meaning |
|---|---|
| `d` | left total minus right total |
| `change` | li - ri for one column |
| `beauty` | absolute value of a difference |
| `answer` | index of the best swap, or 0 |

The first column with the largest beauty is printed, which satisfies the any-optimum rule.

Script-generated example from `gen.py`:

```
columns: (5,6) (8,9) (10,3)
left total 23 right total 18
current difference 5 beauty 5
column 1 change -1 swapped beauty 7
column 2 change -1 swapped beauty 7
column 3 change 7 swapped beauty 9
best column 3
```

The traced best column matches the sample answer `3`.

## Code

**Input scanner and output buffer.** This block reads input into one string and provides index-based scanning.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips whitespace and consumes decimal digits by index. `nextToken` handles string tokens. The buffer flushes at 128 KiB.

**Beauty scan.** This block totals both sides, then finds the best single swap.

```nim
let columnCount = nextInt(inputData, scanPos)
var leftCounts: seq[int] = @[]
var rightCounts: seq[int] = @[]
var leftTotal = 0
var rightTotal = 0
for columnIndex in 0..<columnCount:
  let leftCount = nextInt(inputData, scanPos)
  let rightCount = nextInt(inputData, scanPos)
  leftCounts.add leftCount
  rightCounts.add rightCount
  leftTotal += leftCount
  rightTotal += rightCount

let currentDifference = leftTotal - rightTotal
var bestBeauty = abs(currentDifference)
var bestColumn = 0
for columnIndex in 0..<columnCount:
  let change = leftCounts[columnIndex] - rightCounts[columnIndex]
  let swappedDifference = currentDifference - 2 * change
  let swappedBeauty = abs(swappedDifference)
  if swappedBeauty > bestBeauty:
    bestBeauty = swappedBeauty
    bestColumn = columnIndex + 1

appendOutput($(bestColumn))
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first pass computes both totals and stores counts. The second pass uses the closed-form difference. A strict comparison leaves 0 when no swap improves beauty.

## Complexity

Both passes are linear, and the stored counts use linear space.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Total pass | one pass over columns | two count lists |
| Swap scan | one pass over columns | constant |
| Output | one write per 128 KiB block | block buffer |

The two count lists dominate auxiliary space.

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(n) |

A naive method recomputes both totals for every column and costs O(n^2); the closed form costs O(n).
