# TRECOUNT — Tree Count (SPOJ)

<https://www.spoj.com/problems/TRECOUNT/>

## Problem

Count binary search trees whose left and right subtree heights differ by at most one at every node, and print the count modulo one billion as nine digits. Empty trees have height minus one, and one node has height zero.

Input is a stream of integers, one per line. Each integer is a tree size between 1 and 1427. Read until end of file. Output one nine-digit line per input size, with leading zeros kept.

| item | bound |
|---|---|
| tree size | 1 to 1427 |
| modulo | 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The size bound drives the table size, and the modulo keeps products in 64-bit range.

Sample input:

```
1
3
6
21
```

Sample output:

```
000000001
000000001
000000004
000036900
```

## Idea

Group trees by height before counting them, like sorting mail into pigeonholes before adding each pile. A balanced root has child heights that differ by zero or one, so counts at one height come from two neighbouring piles.

The `convolve` proc combines child sizes in one sweep. Each height uses two convolutions instead of testing every split again. Naive tree enumeration rebuilds the same subtrees many times.

This table fills once and answers every line from memory.

## Why It Works

1. `countsByHeight` stores trees with exactly `n` nodes and height `h`.
2. The root adds one node, so child sizes `i` and j satisfy i + j + 1 = n.
3. A height `h` root uses child heights (h-1,h-1), (h-1,h-2), or (h-2,h-1).
4. `addShifted` applies the extra root node by moving convolution results up one size.
5. `totals` adds every height, and the code pads each answer to nine digits.

| term | meaning |
|---|---|
| `countsByHeight` | count of trees by exact height and node count |
| `minimumByHeight` | smallest tree size possible at a given height |
| `heightLimit` | largest height that can fit the largest query |
| `modulusValue` | one billion, the requested modulus |

The table skips sizes below `minimumByHeight`, so impossible subtrees cost no work.

A trace from the oracle for size 21 gives height 4 count 14372 and height 5 count 22528. Their sum is 36900, printed as 000036900.

```
n=21: h=4 -> 14372
n=21: h=5 -> 22528
total -> 36900 -> 000036900
```

The trace matches the sample line for 21 nodes.

## Code

**Input and helpers.** The scanner reads all lines and defines buffered output.

```nim
const modulusValue = 1000000000
const flushBlockBytes = 1 shl 17
const maximumHeight = 40

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

The reader makes one pass over stdin.

`hasNextInt` stops the query loop at end of input.

Output stays in one buffer until a full block is ready.

**Convolution.** Child size pairs combine into parent counts.

```nim
proc convolve(firstCounts: seq[int], secondCounts: seq[int], maxSize: int,
              firstMin: int, secondMin: int): seq[int] =
  var products = newSeq[int](maxSize + 1)
  var firstIndex = firstMin
  while firstIndex <= maxSize:
    if firstCounts[firstIndex] != 0:
      var secondIndex = secondMin
      while secondIndex + firstIndex <= maxSize:
        if secondCounts[secondIndex] != 0:
          var combined = int64(products[firstIndex + secondIndex])
          combined += int64(firstCounts[firstIndex]) * int64(secondCounts[secondIndex])
          products[firstIndex + secondIndex] = int(combined mod int64(modulusValue))
        secondIndex += 1
    firstIndex += 1
  return products

proc addShifted(target: var seq[int], source: seq[int]) =
  for sizeIndex in 0 .. target.len - 2:
    target[sizeIndex + 1] = (target[sizeIndex + 1] + source[sizeIndex]) mod modulusValue
```

The lower bounds skip empty child ranges.

Products use `int64` before the modulo.

`addShifted` accounts for the root node.

**Height sweep and output.** Each height builds on the previous two heights.

```nim
var queryCounts = newSeq[int]()
while hasNextInt(inputData, scanPos):
  queryCounts.add nextInt(inputData, scanPos)

var largestQuery = 0
for requestedSize in queryCounts:
  if requestedSize > largestQuery:
    largestQuery = requestedSize
```

The sweep stops when the smallest tree at a height exceeds `largestQuery`.

```nim
var totals = newSeq[int](largestQuery + 1)
for levelCounts in countsByHeight:
  for sizeIndex in 1 .. largestQuery:
    totals[sizeIndex] = (totals[sizeIndex] + levelCounts[sizeIndex]) mod modulusValue

for requestedSize in queryCounts:
  var digits = $totals[requestedSize]
  while digits.len < 9:
    digits = "0" & digits
  appendOutput(digits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Every height contributes to the answer.

Padding keeps nine digits even for small counts.

## Complexity

The table fills once for the largest requested size.

| phase | time | space |
|---|---|---|
| input read | one pass over all query integers | input string |
| height sweep | two convolutions per height | table of heights |
| output | one padded line per query | block buffer |

The height sweep dominates because each convolution visits size pairs.

| measure | Big O |
|---|---|
| time | O(H * N^2) |
| space | O(H * N) |

Here H is the number of AVL heights, at most 16 for N = 1427.

Enumerating every tree shape is exponential, so the height table is the practical choice.
