<https://www.spoj.com/problems/VLN/>

## Problem

A farm has n trees in one row, spaced 3 metres apart. Choose one tree as a standing point and collect fruit from every tree within H metres of that point. Report the largest possible harvest.

| item | bound |
|---|---|
| trees n | 1 to 100 |
| reach H | 1 to 1000000000 metres |
| fruit per tree | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Distance between trees i and j is 3 times their index difference, so only nearby trees qualify.

Sample input:

```
5 3
1 2 2 2 1
```

Sample output:

```
6
```

## Idea

Reach in tree positions is H divided by 3, like counting posts inside a fixed rope length. Sum every centered window of trees and keep the largest total. Rescanning fruit for each stand point repeats work, but n never exceeds 100.

## Why It Works

1. Trees i and j are 3 times the absolute index difference metres apart.
2. A tree is reachable when 3 times that difference is at most H.
3. Equivalent reach in tree positions is H integer-divided by 3.
4. The reachable trees for one center form a single contiguous window.
5. The maximum window sum over all centers is the required harvest.

| term | meaning |
|---|---|
| `reachTrees` | H divided by 3, the reach measured in tree positions |
| `fruitCounts` | fruit amount stored for each tree |
| `windowTotal` | sum of fruit for one standing point |
| `bestHarvest` | largest window total found so far |

Centered windows cover every legal standing point exactly once.

## Code

**Input and scanning.** The hand reader loads both header values and the fruit list.

```nim
const flushBlockBytes = 1 shl 17
const metersPerGap = 3

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

Large reach values fit in a 64-bit sum after division.
Token parsing ignores spacing and line breaks.
The scanner advances one index per number.

**Centered window scan.** Each center defines one clipped window of trees.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let treeCount = nextInt(inputData, scanPos)
let reachMeters = nextInt(inputData, scanPos)
let reachTrees = reachMeters div metersPerGap
var fruitCounts = newSeq[int](treeCount)
for treeIndex in 0 .. treeCount - 1:
  fruitCounts[treeIndex] = nextInt(inputData, scanPos)
var bestHarvest: int64 = 0
for centerTree in 0 .. treeCount - 1:
  var leftTree = centerTree - reachTrees
  if leftTree < 0:
    leftTree = 0
  var rightTree = centerTree + reachTrees
  if rightTree >= treeCount:
    rightTree = treeCount - 1
  var windowTotal: int64 = 0
  var currentTree = leftTree
  while currentTree <= rightTree:
    windowTotal = windowTotal + int64(fruitCounts[currentTree])
    currentTree += 1
  if windowTotal > bestHarvest:
    bestHarvest = windowTotal
appendOutput($bestHarvest)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Bounds are clipped to the first and last tree.
The total uses int64 to hold sums up to 1e11.
The best total is written once.

## Complexity

Each center scans at most all n trees.

| phase | time | space |
|---|---|---|
| input read | one pass over n fruit counts | one input string |
| window scan | up to n sums of n trees | array of n integers |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(n^2) worst case |
| space | O(n) |

Skipping the division by 3 would consider trees beyond H and inflate every window.

