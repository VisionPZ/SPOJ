## Problem

A box of size `i` has height `2^i`. A container of size `s` needs boxes whose heights add to `2^s`. Choose a subset of the warehouse boxes that fills every container exactly and has the smallest total value. Print `No` when no subset works.

The table lists the input bounds and the judge limits.

| Quantity | Bound |
| --- | --- |
| Boxes in one case | at most 10000 |
| Box and container size | at most 1000 |
| Box value | at most 10000 |
| Containers of one size | at most 5000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The value bound keeps any answer below 10^8, which fits in one integer.

## Idea

Treat each size-i block as a token of height `2^i`. Sweep sizes from zero upward. At each size, add that size's boxes to a pool of tokens. Spend the cheapest tokens on that size's containers. Then merge the leftover tokens in adjacent pairs. Two size-i tokens merge into one size-(i+1) token, and the new token carries the sum of the values behind it. Spending the cheapest tokens first keeps the pool cheap for larger sizes. Trying every subset of boxes takes exponential time.

Each box enters the pool once and leaves through one merge, so the sweep costs O(n log n) time per case.

## Why It Works

A token of size i holds boxes whose heights sum to `2^i`.

- Spending need tokens of size i fills need containers, since every token has height `2^i`.
- Two size-i tokens merge into one size-(i+1) token because 2 times `2^i` equals `2^(i+1)`.
- Sorting the pool makes the cheapest tokens fill containers first.
- Pairing sorted leftovers side by side keeps the smallest merged tokens small, so larger sizes still have cheap tokens.

The generator prints this walkthrough of the sample.

```
top size = 3
size 0: add [] -> sorted []; need 0; take [] (total 0); pair [] -> []
size 1: add [2, 3, 4] -> sorted [2, 3, 4]; need 1; take [2] (total 2); pair [3, 4] -> [7]
size 2: add [1] -> sorted [1, 7]; need 1; take [1] (total 3); pair [7] -> []
size 3: add [5] -> sorted [5]; need 0; take [] (total 3); pair [5] -> []
answer = 3
```

The two cheapest size-1 boxes cost 2 and 3. The sweep spends 2 on the size-1 container and merges 3 with 4 into a token worth 7. The size-2 box worth 1 fills the size-2 container, so the answer is 3.

## Code

The program reads all input into one buffer, then parses integers with a hand scanner. Output collects in one buffer and flushes in blocks.

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxBoxSize = 1000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop ends at the end of the input, so the stream is read once. The scanner skips spaces and blank lines between cases. The flush guard avoids writing one result at a time.

Marks track the sizes used by a case, so the next case clears only those sizes.

```nim
var boxValues: array[maxBoxSize + 1, seq[int]]
var needCount: array[maxBoxSize + 1, int]
var visitMark: array[maxBoxSize + 1, int]
var currentMark = 0
var touchedSizes: seq[int] = @[]

proc touch(size: int) =
  if visitMark[size] != currentMark:
    visitMark[size] = currentMark
    touchedSizes.add size

proc resetCase() =
  for size in touchedSizes:
    boxValues[size].setLen 0
    needCount[size] = 0
  touchedSizes.setLen 0
  currentMark += 1

proc byValue(leftValue, rightValue: int): int =
  result = system.cmp(leftValue, rightValue)
```

The reset loop runs once per size touched by the previous case. Marks stop a size from appearing twice in one case. The comparator orders tokens cheapest first. This block costs O(touched sizes) per case.

The main sweep fills containers and builds tokens for the next size.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  resetCase()
  var topSize = 0
  let boxTotal = nextInt(inputData, scanPos)
  for j in 0..<boxTotal:
    let size = nextInt(inputData, scanPos)
    let value = nextInt(inputData, scanPos)
    touch(size)
    boxValues[size].add value
    if size > topSize:
      topSize = size
  let kindCount = nextInt(inputData, scanPos)
  for k in 0..<kindCount:
    let size = nextInt(inputData, scanPos)
    let count = nextInt(inputData, scanPos)
    touch(size)
    needCount[size] = count
    if size > topSize:
      topSize = size

  var pool: seq[int] = @[]
  var total: int = 0
  var feasible = true
  for size in 0..topSize:
    for value in boxValues[size]:
      pool.add value
    pool.sort(byValue)
    let need = needCount[size]
    if need > pool.len:
      feasible = false
      break
    for l in 0..<need:
      total += pool[l]
    let restCount = pool.len - need
    var nextPool: seq[int] = @[]
    nextPool.setLen restCount div 2
    for m in 0..<(restCount div 2):
      nextPool[m] = pool[need + 2 * m] + pool[need + 2 * m + 1]
    pool = nextPool

  if feasible:
    appendOutput($total)
  else:
    appendOutput("No")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs up to the largest size present in the case. The size check catches a case with too few tokens and prints `No`. The pairing loop halves the pool at each level, so the total work stays linear in the number of boxes.

## Complexity

Reading the input costs O(total tokens) time and O(input size) space. Sorting the pools costs O(n log n) time per case with n boxes. Merging and all per-level work cost O(n + S) time, where S is the largest size present. Space per case is O(n + S).

Across all cases the total time is O(T log n + total sizes) for T boxes, and peak space is O(n). The naive subset search costs O(2^n) per case.
