## Problem

Read t test cases. Each case gives a sum m, a component count n, and a rank k. A partition of m into n components is a non-decreasing sequence of n positive integers whose sum is m. Print the k-th partition in lexicographic order. Separate the printed values with spaces.

Here are the limits:

| Quantity | Bound |
| --- | --- |
| Test cases t | not bounded in the statement |
| Sum m | 1 to 220 |
| Component count n | 1 to 10 |
| Rank k | 1 to the number of partitions |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The small bounds on m and n let one counting table serve every case.

## Idea

Count the partitions that begin with each possible value, then skip whole groups at once. A table of partition counts gives each group size in constant time. The program walks candidate values from small to large and subtracts group sizes until the rank lands in one group. It repeats the walk for every component.

One case costs at most n times m candidate checks. Enumerating every partition costs far more.

## Why It Works

A non-decreasing sequence of L values, each at least v, has sum at least L times v. Subtract v from every value. The result is a partition of the leftover sum into at most L parts.

Partitions of T into at most L parts equal partitions of T into parts no larger than L. Call that count ways(T, L). The table partitionWays stores it. The fill uses these rules:

- ways(0, L) is 1, because one empty sum exists.
- ways(T, 0) is 0 when T is positive.
- ways(T, L) is ways(T, L-1) plus ways(T-L, L) when T is at least L.

After a prefix is fixed, keep remainingSum, partsLeft, and minValue. For a candidate v, partitionWays takes two indices:

- remainingSum minus partsLeft times v is the sum left after giving v to each open part.
- partsLeft minus 1 is the number of parts still open.

That table entry counts the completions of the prefix. If the rank exceeds the block, subtract the block and try the next value. Otherwise fix the value and move to the next component. The last part takes the whole remaining sum.

The script in gen.py prints this trace for the sample:

```
start remaining=9 partsLeft=4 minValue=1 rank=3
candidate 1: block 5, choose, rank 3 <= 5
candidate 1: block 3, choose, rank 3 <= 3
candidate 1: block 1, skip, rank 3 -> 2
candidate 2: block 1, skip, rank 2 -> 1
candidate 3: block 1, choose, rank 1 <= 1
last part = 4
```

The walk fixes 1, 1, and 3, then the final part 4. That matches the sample output.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSum = 220
const maxParts = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

The read loop ends when readLine fails, so all input lives in one string.
The scanner skips line breaks, so the three-line layout needs no special case.
It builds each 64-bit value by hand and allocates no token objects.
Cost: one pass over the input.

```nim
var partitionWays: array[0..maxSum, array[0..maxParts, int64]]
for i in 0..maxSum:
  for j in 0..maxParts:
    if i == 0:
      partitionWays[i][j] = 1
    elif j == 0:
      partitionWays[i][j] = 0
    else:
      partitionWays[i][j] = partitionWays[i][j - 1]
      if i >= j:
        partitionWays[i][j] += partitionWays[i - j][j]
```

The loops run i to 220 and j to 10.
The base at zero stores one way to form an empty sum.
The i check before the second term avoids a negative index.
Cost: 2201 cells, filled once before any case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

appendOutput writes only when the buffer reaches flushBlockBytes.
setLen reuses one string instead of allocating a new one.
Cost: one write per 256 KiB of output.

```nim
var chosenParts: array[0..maxParts - 1, int]

let caseCount = int(nextInt(inputData, i))
for j in 0..<caseCount:
  let totalSum = int(nextInt(inputData, i))
  let partCount = int(nextInt(inputData, i))
  var rank = nextInt(inputData, i)
  var remainingSum = totalSum
  var partsLeft = partCount
  var minValue = 1
  var k = 0
  while partsLeft > 0:
    if partsLeft == 1:
      chosenParts[k] = remainingSum
      k += 1
      partsLeft = 0
      break
```

chosenParts holds at most maxParts values.
rank stays 64-bit, so large counts never overflow.
The partsLeft == 1 branch ends the walk with the whole leftover sum.
Cost: constant work per component.

```nim
    var candidate = minValue
    var picked = false
    while candidate * partsLeft <= remainingSum:
      let shiftedSum = remainingSum - partsLeft * candidate
      let blockSize = partitionWays[shiftedSum][partsLeft - 1]
      if rank > blockSize:
        rank -= blockSize
        candidate += 1
      else:
        chosenParts[k] = candidate
        k += 1
        remainingSum -= candidate
        partsLeft -= 1
        minValue = candidate
        picked = true
        break
    if not picked:
      chosenParts[k] = remainingSum
      k += 1
      partsLeft = 0
  for l in 0..<partCount:
    if l > 0:
      outputBuffer.add ' '
    appendOutput($(chosenParts[l]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The candidate loop stops at remainingSum divided by partsLeft, the largest first value.
That bound keeps shiftedSum non-negative, so the table index stays valid.
The not picked branch handles invalid input and keeps the walk finite.
The output loop adds one space between values and one newline per case.
Cost: at most 220 checks per component, plus one final flush.

## Complexity

Filling the table takes O(220 * 10) time and O(220 * 10) space. Each case takes O(n * m) time and O(n) extra space. The total is O(t * n * m) time and O(m * n) space.

Enumerating partitions visits every partition before the answer, which is much slower for large ranks.
