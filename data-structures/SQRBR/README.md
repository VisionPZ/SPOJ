# SQRBR — Square Brackets (SPOJ)

<https://www.spoj.com/problems/SQRBR/>

## Problem

Given length 2n and k required opening-bracket positions, count the proper bracket expressions of length 2n whose opening brackets sit exactly at those positions.

Input: the first line gives `d` data sets. Each data set has a line with `n` and `k`, then a line with `k` increasing positions. Output: one integer per data set, the count of proper expressions of length `2n` that open at all `k` positions.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Data sets `d` | 1 to 10 |
| Pairs `n` | 1 to 19 |
| Fixed positions `k` | 1 to `n` |
| Judge limit | 3000 ms, 1536 MB |

The pair count caps the table at twenty balances.

The sample input and output:

```
5
1 1
1
1 1
2
2 1
1
3 1
2
4 2
5 7
```

```
1
0
2
3
2
```

## Idea

Walk the row left to right and keep one tally per current balance. Think of a tightrope walker who steps up or down but never goes below the ground.

This is dynamic programming over positions and balance. Each of the `2n` positions updates `n + 1` balances, so the cost is `O(n²)` per data set. Listing every bracket string costs `O(4ⁿ)` and stalls at `n = 19`.

Counting partial walks collapses a huge list into a small table of balances.

## Why It Works

Four facts justify the update rule.

1. The balance is openings minus closings in the prefix so far.
2. A closing bracket is legal only when the balance is positive. An opening bracket is legal only when fewer than `n` openings have been placed.
3. At a fixed position, the closing branch is skipped. Every counted row therefore opens there.
4. After `2n` positions, a balance of zero means all brackets match. The zero entry of the final table is the answer.

The terms used by the update:

| Term | Meaning |
| --- | --- |
| `mustOpen[k]` | true when position `k` is reserved |
| `ways[balance]` | rows reaching `balance` before this position |
| `nextWays[balance - 1]` | rows that placed a closing bracket on this step |
| `nextWays[balance + 1]` | rows that placed an opening bracket on this step |
| `ways[0]` | rows that end with all brackets matched |

Copying `nextWays` into `ways` keeps only the current column of the table.

A script trace for `n = 4` with reserved positions 5 and 7:

```
| position | fixed | balance counts 0..4 |
| --- | --- | --- |
| 1 | no | [0, 1, 0, 0, 0] |
| 2 | no | [1, 0, 1, 0, 0] |
| 3 | no | [0, 2, 0, 1, 0] |
| 4 | no | [2, 0, 3, 0, 1] |
| 5 | yes | [0, 2, 0, 3, 0] |
| 6 | no | [2, 0, 5, 0, 3] |
| 7 | yes | [0, 2, 0, 5, 0] |
| 8 | no | [2, 0, 7, 0, 5] |
answer ways[0] = 2
```

Reserved positions push every row up one balance. The last row leaves two matched rows.

## Code

**Input and scanner.** One buffer holds the data set, and a digit scanner walks it.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

Every input number is positive, so the scanner needs no sign branch.
Reading into one string avoids a read call per line.
Parsing one integer visits each digit once.

**Buffered output.** One string collects the answers and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The block size is 256 KiB.
`setLen 0` reuses the allocation instead of creating a new string.
Each data set adds one line.

**Balance sweep.** The driver swaps two tally rows at every position.

```nim
let dataSetCount = nextInt(inputData, i)
for j in 0..<dataSetCount:
  let pairCount = nextInt(inputData, i)
  let fixedCount = nextInt(inputData, i)
  var mustOpen = newSeq[bool](2 * pairCount + 1)
  for k in 0..<fixedCount:
    let l = nextInt(inputData, i)
    mustOpen[l] = true
  var ways = newSeq[int64](pairCount + 1)
  ways[0] = 1
  for k in 1..(2 * pairCount):
    var nextWays = newSeq[int64](pairCount + 1)
    for balance in 0..pairCount:
      if ways[balance] == 0:
        continue
      if not mustOpen[k]:
        if balance > 0:
          nextWays[balance - 1] += ways[balance]
      if balance < pairCount:
        nextWays[balance + 1] += ways[balance]
    ways = nextWays
  appendOutput($ways[0])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`mustOpen` has `2 * pairCount + 1` slots, so index `2n` is valid.
The inner loop spans balances `0..pairCount`, which is `n + 1` entries.
The answer is `ways[0]` after the last position.

## Complexity

The program performs one sweep of `2n` positions with a small balance table.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Fixed position marks | O(k) | O(n) for `mustOpen` |
| Balance sweep | O(n²) per data set | O(n) for two tally rows |
| Output | one write per 256 KiB block | 256 KiB |
| Total per data set | O(n²) | O(n) |

At `n = 19` the sweep visits about 720 balance cells.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n²) per data set, O(d × n²) overall |
| Space | O(n) per data set, plus buffers |

Enumerating all `2^(2n)` bracket strings grows far faster than the quadratic sweep.
