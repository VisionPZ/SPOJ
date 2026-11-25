# CONTPACK — How to pack containers (SPOJ)

<https://www.spoj.com/problems/CONTPACK/>

## Problem

Boxes have heights that are powers of two and each has a value. Choose boxes that exactly fill the given containers at the least total value, or report failure.

Input: one integer for the case count, then a box count. Each box gives a size and value. Then come a kind count and one size-count pair per kind.

Output: the smallest total value of boxes that fills every container, or `No` when no choice works.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Boxes in one case | at most 10000 |
| Box and container size | at most 1000 |
| Box value | at most 10000 |
| Containers of one size | at most 5000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The value bound keeps any answer below 100000000, which fits one integer.

The sample input and output:

```
1
5
1 3
1 2
3 5
2 1
1 4
2
1 1
2 1
```

```
3
```

## Idea

Stack boxes into tokens of equal height, like pairing identical tubes on a shelf. At each size, spend the cheapest tokens on that size's containers, then pair the leftovers into tokens of the next size.

The program sweeps sizes from zero upward. It sorts the pool of available tokens, takes the cheapest ones for the current containers, and merges the rest two at a time.

Each box enters the pool once and leaves through one merge, so the sweep costs O(n log n) per case. Trying every subset of boxes takes exponential time.

Spending cheapest first keeps larger sizes supplied with cheap tokens.

## Why It Works

A token of size i represents boxes whose heights sum to `2^i`.

1. Spending need tokens of size i fills need containers, because every token has height `2^i`.
2. Two size-i tokens merge into one size-(i+1) token, because `2 × 2^i = 2^(i+1)`.
3. Sorting the pool makes the cheapest tokens fill containers first, which minimizes the total value.
4. Pairing sorted leftovers side by side keeps the smallest merged tokens small, so larger sizes still have cheap tokens.

The sweep uses the following terms:

| Term | Meaning |
| --- | --- |
| `boxValues[size]` | values of boxes with height `2^size` |
| `needCount[size]` | containers requesting that size |
| `pool` | sorted token values available at the current size |
| `nextPool` | pair sums carried to the next size |
| `touchedSizes` | sizes used by the current case |

Marks let the program clear only the sizes a case uses.

A script traces the sample case:

```
top size = 3
size 0: add []       -> sorted []      need 0 take []       total 0 pair []    -> []
size 1: add [3,2,4]  -> sorted [2,3,4] need 1 take [2]      total 2 pair [3,4] -> [7]
size 2: add [1]      -> sorted [1,7]   need 1 take [1]      total 3 pair [7]   -> []
size 3: add [5]      -> sorted [5]     need 0 take []       total 3 pair []    -> []
answer = 3
```

The cheapest size-1 box costs 2. The size-2 box costs 1, so the total is 3.

## Code

**Input and buffers.** One buffer holds the stream, and a hand scanner reads each integer.

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

The read loop ends at the end of the stream. The scanner skips blank lines between cases. The flush guard avoids writing one result at a time.

**Per-size storage.** Marks track touched sizes, so clearing a case costs only those sizes.

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

The reset loop runs once per touched size. A mark stops a size from appearing twice in one case. The comparator orders tokens cheapest first.

**Size sweep.** Each level adds boxes, spends the cheapest tokens, and pairs the rest.

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

The outer loop runs up to the largest size in the case. The size check catches a shortage of tokens and prints `No`. The pairing loop halves the pool at each level, which keeps the total work linear in the box count.

## Complexity

Sorting the pool dominates each level of the size sweep.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Case setup | O(n + S) per case | O(n + S) |
| Pool sorts | O(n log n) per case | O(n) pool |
| Pairing | O(n + S) per case | O(n) pool |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n log n + S) | O(n + S) |

Here n is the box count and S is the largest size present.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(n log n + S) per case |
| Space | O(n + S) per case |

Choosing a subset of boxes by brute force would cost O(2^n) per case.
