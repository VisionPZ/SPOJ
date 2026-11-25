# ANIL_PRO — Anils Proposal (SPOJ)

<https://www.spoj.com/problems/ANIL_PRO/>

## Problem

Maintain an array under range updates and range sum queries. An update adds Fibonacci numbers 1, 1, 2, 3 and so on starting again at the left edge of the given range. A query returns the sum over a range modulo 1000000007.

Input starts with the array size n and operation count q. Each of the next q lines holds an operation type, l and r, with type 0 for update and type 1 for query. Output one line per query.

| item | bound |
|---|---|
| array size n | 1 to 1000000 |
| operations q | 1 to 50000 |
| modulus | 1000000007 |
| judge limit | 500 ms, 1536 MB |

The million positions rule out touching the array during an update.

Sample input:

```
5 6
0 1 5
0 2 4
0 1 3
1 2 4
1 1 5
1 4 5
```

Sample output:

```
13
20
10
```

## Idea

Each range update lays down a fresh Fibonacci staircase, like stamping a ramp onto a shelf. The real algorithm writes that ramp as a fixed pair of Fibonacci basis sequences and stores four Fenwick trees of coefficients. Every operation costs O(log n), while rebuilding the affected range costs O(n) per update.

The restarting sequence is the trap; a global Fibonacci index gives wrong sums.

## Why It Works

1. A ramp starting at l puts F1 at l, F2 at l plus 1, and so on up to r.
2. Start with F0 = 0 and F minus 1 = 1. The identity holds for every k at least l. It writes F at k minus l plus 1 as alpha times F at k minus 1 plus beta times F at k.
3. For l at least 2, alpha is the sign of l times F at l minus 1. Beta is the opposite sign times F at l minus 2.
4. Adding the negative of that same ramp at r plus 1 stops it, so the array stays unchanged beyond r.
5. Summing F from i to x gives F at x plus 1 minus F at i. Summing the shifted version gives F at x plus 2 minus F at i plus 1.

| term | meaning |
|---|---|
| `fibonacci` | Fibonacci values up to n plus 2 |
| `alphaTree` | Fenwick sums of alpha coefficients |
| `betaTree` | Fenwick sums of beta coefficients |
| `alphaWeightTree` | alpha coefficients times F at their start |
| `betaWeightTree` | beta coefficients times the next Fibonacci value |

For the sample, the three updates produce the array 2, 3, 5, 5, 5. Its prefix sums are 2, 5, 10, 15 and 20. The query on positions 2 through 4 gives 15 minus 2, which is 13.

All Fenwick arithmetic stays modulo 1000000007, so products fit in int64.

## Code

**Input and scanner.** The reader loads all operations and parses three integers each.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips whitespace between operation fields.
The buffer flushes after many query lines accumulate.
One read pass covers all 50000 operations.

**Fenwick trees.** Four trees hold the ramp coefficients and their weights.

```nim
proc treeAdd(tree: var seq[int64], index: int, delta: int64) =
  var position = index
  while position < tree.len:
    tree[position] = (tree[position] + delta) mod modulusValue
    if tree[position] < 0:
      tree[position] += modulusValue
    position += position and (-position)

proc treeSum(tree: seq[int64], index: int): int64 =
  var position = index
  var total: int64 = 0
  while position > 0:
    total = (total + tree[position]) mod modulusValue
    position -= position and (-position)
  return total

proc addRampEvent(index: int, alphaValue: int64, betaValue: int64,
                  fibonacci: seq[int64], alphaTree: var seq[int64],
                  betaTree: var seq[int64], alphaWeightTree: var seq[int64],
                  betaWeightTree: var seq[int64]) =
  let alphaWeight = alphaValue * fibonacci[index] mod modulusValue
  let betaWeight = betaValue * fibonacci[index + 1] mod modulusValue
  treeAdd(alphaTree, index, alphaValue)
  treeAdd(betaTree, index, betaValue)
  treeAdd(alphaWeightTree, index, alphaWeight)
  treeAdd(betaWeightTree, index, betaWeight)

proc prefixTotal(limitIndex: int, fibonacci: seq[int64],
                 alphaTree: seq[int64], betaTree: seq[int64],
                 alphaWeightTree: seq[int64], betaWeightTree: seq[int64]): int64 =
  if limitIndex <= 0:
    return 0
  let leadingAlpha = fibonacci[limitIndex + 1] * treeSum(alphaTree, limitIndex)
  let leadingBeta = fibonacci[limitIndex + 2] * treeSum(betaTree, limitIndex)
  var total = leadingAlpha + leadingBeta -
              treeSum(alphaWeightTree, limitIndex) -
              treeSum(betaWeightTree, limitIndex)
  total = total mod modulusValue
  if total < 0:
    total += modulusValue
  return total
```

Each event updates four trees at one index.
The weighted trees remove the part of each ramp before its start.
Every tree query walks at most twenty levels.

**Precomputation and operations.** Fibonacci values are built once, then each operation is a few tree walks.

```nim
let arraySize = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)
var fibonacci = newSeq[int64](arraySize + 3)
fibonacci[1] = 1
fibonacci[2] = 1
for index in 3 .. arraySize + 2:
  fibonacci[index] = (fibonacci[index - 1] + fibonacci[index - 2]) mod modulusValue
var alphaTree = newSeq[int64](arraySize + 2)
var betaTree = newSeq[int64](arraySize + 2)
var alphaWeightTree = newSeq[int64](arraySize + 2)
var betaWeightTree = newSeq[int64](arraySize + 2)

for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  let leftBound = nextInt(inputData, scanPos)
  let rightBound = nextInt(inputData, scanPos)
  if operationType == 0:
    let stopIndex = rightBound + 1
    if leftBound == 1:
      addRampEvent(leftBound, 0, int64(1), fibonacci, alphaTree, betaTree,
                   alphaWeightTree, betaWeightTree)
      addRampEvent(stopIndex, 0, int64(-1), fibonacci, alphaTree, betaTree,
                   alphaWeightTree, betaWeightTree)
    else:
      let leftSign = if leftBound mod 2 == 0: int64(1) else: int64(-1)
      let alphaValue = leftSign * fibonacci[leftBound - 1] mod modulusValue
      let betaValue = -leftSign * fibonacci[leftBound - 2] mod modulusValue
      addRampEvent(leftBound, alphaValue, betaValue, fibonacci, alphaTree,
                   betaTree, alphaWeightTree, betaWeightTree)
      addRampEvent(stopIndex, -alphaValue, -betaValue, fibonacci, alphaTree,
                   betaTree, alphaWeightTree, betaWeightTree)
  else:
    let answer = (prefixTotal(rightBound, fibonacci, alphaTree, betaTree,
                              alphaWeightTree, betaWeightTree) -
                  prefixTotal(leftBound - 1, fibonacci, alphaTree, betaTree,
                               alphaWeightTree, betaWeightTree) +
                  modulusValue) mod modulusValue
    appendOutput($answer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A left bound of one uses the plain Fibonacci ramp.
The stop event cancels the ramp past the right bound.
A query subtracts two prefix sums and prints the result.

## Complexity

Precomputation is linear in the array size and each operation walks trees.

| phase | time | space |
|---|---|---|
| input read | one pass over operation fields | one input string |
| Fibonacci table | one step per array position | one million integers |
| each operation | four Fenwick walks | four tree arrays |
| output | one flush per block | block buffer |

At most 50000 operations keep the tree work small.

| measure | Big O |
|---|---|
| time | O(n + q log n) |
| space | O(n) for the table and four trees |

Updating the range one position at a time would cost O(n) per operation.

The four trees answer every query inside the time limit.
