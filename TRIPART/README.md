## Problem

Each case gives the three side lengths of a valid triangle. A median on the longest side splits it into two smaller triangles, and the process repeats forever. Print the number of distinct similarity classes, called styles, that ever appear.

The bounds keep every case small.

| Quantity | Bound |
| --- | --- |
| Test cases | 0 < N < 35 |
| Side lengths | 0 < a, b, c < 100 |
| Styles per triangle | T < 100 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

At most 34 cases arrive, so the subdivision drives the design.

## Idea

Work with squared side lengths so every split uses integers. A sorted triple divided by its gcd names one style. A queue visits each style once, and a hash table rejects repeats.

Cost per style: two children, two normalizations, and two hash lookups.

## Why It Works

Apollonius' theorem gives the median length on the longest side. With squared sides in ascending order, the formula stays in integers.

Each term maps a parent triple to its children.

```text
x, y, z                      squared sides in ascending order; z is the longest
median4 = 2*x + 2*y - z      four times the median squared
(4*x, z, median4)            squared child sides, scaled by four
divisor = gcd(gcd(x, y), z)  common scale removed before storage
```

The scaled child sides stay integer, so the program needs no floating point.

Two triangles are similar when their side ratios match. Their squared sides then share the same ratio, so dividing by the gcd yields the same primitive triple. The queue stops when every child is already known. The statement promises a finite style count.

For sides 3, 4, 5, the squared triple starts at (9, 16, 25). The trace lists each discovered shape and its children.

```text
start (9, 16, 25)
process (9, 16, 25) -> child (25, 25, 36) (new)
process (9, 16, 25) -> child (25, 25, 64) (new)
process (25, 25, 36) -> child (9, 16, 25) (seen)
process (25, 25, 36) -> child (9, 16, 25) (seen)
process (25, 25, 64) -> child (9, 16, 25) (seen)
process (25, 25, 64) -> child (9, 16, 25) (seen)
styles 3
```

Every later shape returns to the start, so three styles appear.

## Code

The scanner walks one input buffer built by line reads. Index `i` skips separators and collects digits. It allocates no tokens and runs once per case.

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

The output buffer flushes at 256 KiB. Each case appends one number and a newline. `setLen 0` reuses the same buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The table stores one shape per slot and marks it with a generation. Three swaps sort a triple without a sort call. Linear probing resolves collisions.

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

The queue holds each style once. Index `k` walks it forward. Both children use the same integer formula.

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

The loop reads three sides per case. `$` converts the count to text. The last write flushes the remaining bytes.

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

## Complexity

Reading costs O(N) time and O(input bytes) space. Each case visits T styles once with O(1) expected hashing: O(T) time and O(T) space. Total time is O(N·T), and total space is O(max T). A naive scan of all past shapes costs O(T²) per case.
