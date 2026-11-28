# SIMPLPRBLM — A Simple Problem (SPOJ)

<https://www.spoj.com/problems/SIMPLPRBLM/>

## Problem

Given an array of integers and a target `S`, count the pairs of positions whose values add up to `S`.

Input: test count `T`; each case has `n` and `S`, then `n` array values. Output: `Case X: Y`, where `Y` is the pair count for case `X`.

| Item | Bound |
|---|---|
| Test count `T` | 1 to 50 |
| Array size `n` | 1 to 100 000 |
| Target `S` | 1 to 10 000 000 000 |
| Array value | 1 to 1 000 000 000 |
| Judge limit | 1 s, 1536 MB |

The answer can reach about five billion, so it needs a 64-bit integer.

Sample input:

```
3
4 8
1 2 4 9
3 7
3 4 4
3 8
4 4 4
```

Sample output:

```
Case 1: 0
Case 2: 2
Case 3: 3
```

## Idea

Sort the array, then walk inward from both ends like two people closing a zipper.
If the current sum is too small, move the left finger right; if too large, move the right finger left.
On a match, count the whole run of equal values at each end in one step.
The naive scan tries every pair and costs O(n^2); the sorted walk costs O(n) after sorting.

## Why It Works

1. Sorting puts every value in order, so the sum changes monotonically when either finger moves.
2. If the sum is below `S`, no later value on the left can help, so advancing the left finger loses nothing. The right case is symmetric.
3. Equal values run together after sorting, so counting the whole run at once gives every valid pairing exactly once.
4. When both runs hold the same value, the pairs inside one run are `r * (r - 1) / 2`.

| Term | Meaning |
|---|---|
| `values` | sorted array of 64-bit values |
| `leftPos`, `rightPos` | the two inward-moving indices |
| `leftRun`, `rightRun` | sizes of equal-value groups at the ends |
| `pairCount` | running 64-bit answer |

The trace below comes from `gen.py` on the sample case:

```
trace: Case 2 target 7 with [3,4,4] -> two pairs -> 2
```

That matches the second output line.

## Code

**Scanner and comparator.** Parses 64-bit values by index, with an explicit sort comparator.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc compareValues(first, second: int64): int =
  if first < second: return -1
  if first > second: return 1
  return 0
```

`nextInt` skips separators, so line breaks and spaces are equivalent. `compareValues` is the explicit comparator Nim 0.19.4 needs for `sort`.

**Input and buffer.** Keeps the whole input in one string and writes in 128 KiB blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen` reuses the buffer storage, so flushing does not reallocate. Cost is one pass over input bytes.

**Two-pointer count.** Sorts once, then counts matching runs.

```nim
let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 1..caseCount:
  let itemCount = int(nextInt(inputData, scanPos))
  let targetSum = nextInt(inputData, scanPos)
  var values: seq[int64] = @[]
  values.setLen(itemCount)
  for idx in 0..<itemCount:
    values[idx] = nextInt(inputData, scanPos)
  values.sort(compareValues)

  var pairCount: int64 = 0
  var leftPos = 0
  var rightPos = itemCount - 1
  while leftPos < rightPos:
    let pairSum = values[leftPos] + values[rightPos]
    if pairSum == targetSum:
      let leftValue = values[leftPos]
      var leftRun = 0
      while leftPos <= rightPos and values[leftPos] == leftValue:
        leftPos += 1
        leftRun += 1
      let rightValue = values[rightPos]
      var rightRun = 0
      while rightPos >= leftPos and values[rightPos] == rightValue:
        rightPos -= 1
        rightRun += 1
      if leftValue == rightValue:
        pairCount += int64(leftRun) * int64(leftRun - 1) div 2
      else:
        pairCount += int64(leftRun) * int64(rightRun)
    elif pairSum < targetSum:
      leftPos += 1
    else:
      rightPos -= 1

  appendOutput("Case " & $caseIndex & ": " & $pairCount & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The two inner `while` loops move the fingers past an equal run, which prevents double counting. The sum and the answer both use `int64`, so `S = 10^10` and large counts stay exact. Cost is O(n) per case after the sort.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sort | O(n log n) comparisons per case | n values |
| Two-pointer walk | O(n) per case | none |
| Output | one write per 128 KiB block | block buffer |

Sorting dominates each case; the walk touches each index at most once.

| Measure | Big O |
|---|---|
| Time | O(T * n log n) |
| Space | O(n) for the value array, plus input and output buffers |

The naive nested loop costs O(T * n^2), which is impossible at n = 100 000. The sorted walk keeps the whole test inside the limit.
