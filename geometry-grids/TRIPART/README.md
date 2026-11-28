# TRIPART — Triangle Partitioning (SPOJ)

<https://www.spoj.com/problems/TRIPART/>

## Problem

The input gives triangle side lengths. Repeatedly split each triangle by the median on its longest side, and count the distinct similarity classes that occur.

Input starts with `N`, where `0 < N < 35`. Each following line holds three integers `a b c`, the sides of a valid triangle with `0 < a, b, c < 100`. Output one integer per line, the style count `T`, which the statement promises stays below 100.

The small inputs keep the search bounded.

| Quantity | Bound |
| --- | --- |
| Test cases `N` | 0 < N < 35 |
| Side lengths | 0 < a, b, c < 100 |
| Styles per triangle `T` | less than 100 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The finite style count lets a queue visit each shape once.

The sample input and output follow verbatim.

```
2
3 4 5
12 84 90
```

```
3
41
```

## Idea

Store squared side lengths and reduce each triple by its gcd, like simplifying a fraction. A sorted, reduced triple names one style, so scaled copies collapse to one entry.

The program normalizes the starting triple, then runs a queue. For each shape it applies the median formula to get two children, normalizes them, and adds any new shape. A hash table rejects repeats in constant expected time.

Following real triangles with floating point would invite drift and duplicate shapes. Integer arithmetic keeps every split exact.

Exact integer triples make similarity a simple equality test.

## Why It Works

Four facts justify the reduction.

1. Apollonius' theorem gives the median on the longest side. With squared sides `x <= y <= z`, four times the median squared is `median4 = 2x + 2y - z`.
2. Scaling by four keeps the two children integral: their squared sides are `(4x, z, median4)` and `(4y, z, median4)`.
3. Two triangles are similar when their side ratios match. Their squared sides then share one ratio, so dividing by the gcd of all three yields the same primitive triple.
4. The queue adds a child only when `addShape` returns true. That test marks the child seen, so each style enters the queue once and the process terminates.

The table maps each parent triple to its children.

| Term | Meaning |
| --- | --- |
| `x, y, z` | squared sides in ascending order, with `z` longest |
| `median4` | `2x + 2y - z`, four times the median squared |
| first child | `normalize(4x, z, median4)` |
| second child | `normalize(4y, z, median4)` |
| `divisor` | `gcd(gcd(x, y), z)`, the common scale removed |

Three swaps sort a triple without a sort call, and linear probing resolves hash collisions.

For sides `3, 4, 5`, the squared triple starts at `(9, 16, 25)`. The trace lists every discovered shape.

```text
start (9, 16, 25)
process (9, 16, 25) -> child (25, 25, 36) new
process (9, 16, 25) -> child (25, 25, 64) new
process (25, 25, 36) -> child (9, 16, 25) seen
process (25, 25, 36) -> child (9, 16, 25) seen
process (25, 25, 64) -> child (9, 16, 25) seen
process (25, 25, 64) -> child (9, 16, 25) seen
styles 3
```

Every later child returns to the start, so three styles appear.

## Code

**Input setup.** The constants, bulk input, and digit scanner build one parse buffer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const tableBits = 15
const tableSize = 1 shl tableBits
const tableMask = tableSize - 1

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

The scanner skips separators and collects digits, allocating no token. Index `i` advances once per case. Reading costs one pass over the input.

**Output buffer.** The output buffer flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each case appends one number and a newline. `setLen 0` reuses the buffer after a flush.

**Shape table.** The hash table marks shapes with a generation stamp, and normalization reduces them.

```nim
var seenMark: array[tableSize, int]
var seenShape: array[tableSize, tuple[x, y, z: int]]
var generation = 0

proc gcd2(first, second: int): int =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

proc normalize(first, second, third: int): tuple[x, y, z: int] =
  var left = first
  var middle = second
  var right = third
  if left > middle: swap(left, middle)
  if middle > right: swap(middle, right)
  if left > middle: swap(left, middle)
  let divisor = gcd2(gcd2(left, middle), right)
  result.x = left div divisor
  result.y = middle div divisor
  result.z = right div divisor

proc shapeSlot(x, y, z: int): int =
  (x * 1000003 + y * 100003 + z * 1009) and tableMask

proc addShape(x, y, z: int): bool =
  var slot = shapeSlot(x, y, z)
  while seenMark[slot] == generation:
    if seenShape[slot].x == x and seenShape[slot].y == y and seenShape[slot].z == z:
      return false
    slot = (slot + 1) and tableMask
  seenMark[slot] = generation
  seenShape[slot].x = x
  seenShape[slot].y = y
  seenShape[slot].z = z
  return true
```

The generation counter replaces clearing the whole table per case. Three comparisons sort a triple, and the gcd removes its scale. A lookup costs constant expected time.

**Style queue.** The queue expands each style into its two children.

```nim
proc countStyles(firstSide, secondSide, thirdSide: int): int =
  let start = normalize(firstSide * firstSide, secondSide * secondSide, thirdSide * thirdSide)
  inc generation
  discard addShape(start.x, start.y, start.z)
  var work: seq[tuple[x, y, z: int]]
  work.add start
  var k = 0
  while k < work.len:
    let current = work[k]
    k += 1
    let median4 = 2 * current.x + 2 * current.y - current.z
    let firstChild = normalize(4 * current.x, current.z, median4)
    if addShape(firstChild.x, firstChild.y, firstChild.z):
      work.add firstChild
    let secondChild = normalize(4 * current.y, current.z, median4)
    if addShape(secondChild.x, secondChild.y, secondChild.z):
      work.add secondChild
  return work.len
```

Index `k` walks the queue forward. Both children use the same integer formula. The loop ends after `T` styles, with `T` below 100.

**Driver.** The driver reads three sides per case and prints the count.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let firstSide = nextInt(inputData, i)
  let secondSide = nextInt(inputData, i)
  let thirdSide = nextInt(inputData, i)
  appendOutput($(countStyles(firstSide, secondSide, thirdSide)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs `N` times, once per triangle. The final write emits any remaining bytes. Each case starts a fresh generation.

## Complexity

The table and queue bound every case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(input bytes) | one input string |
| Style search per case | O(T) expected | O(T) styles |
| Output | O(N) | one flush block |

The generation stamp keeps the hash table at constant expected cost, independent of past cases.

The totals use the case count and the style count.

| Measure | Big O |
| --- | --- |
| Time | O(N·T) expected |
| Space | O(max T) |

Scanning all previously seen shapes per child would cost `O(T^2)` per case.
