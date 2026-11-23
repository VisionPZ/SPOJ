## Problem

Read `t` cases. Each case gives `n` inputs and `m` sorters. A sorter `(i, j)` sorts positions `i` through `j` in nondecreasing order and leaves other positions unchanged. Keep the fewest sorters, in their original order, so the last output always holds the maximum of all inputs. Print one integer per case.

The judge bounds set the size of the work:

| Quantity | Bound |
| --- | --- |
| Inputs `n` | 2 to 50,000 |
| Sorters `m` | 1 to 500,000 |
| Time limit | 1,500 ms |
| Memory limit | 1,536 MB |

The sorter count drives the run time; the input count sizes the tree.

## Idea

bestCosts[x] is the fewest sorters that put the maximum of inputs `1` through `x` at position `x`. A sorter `(i, j)` moves that collected maximum to `j` when `i` is at most `x` and `x` is at most `j`. Each sorter sets bestCosts[j] to one plus the smallest earlier cost in [i, j], using a tree that answers the smallest value in a range. Each sorter costs `O(log n)`. Rescanning the whole range for every sorter would cost `O(mn)`.

## Why It Works

A sorter places the largest value of its window at the right edge. The value bestCosts[x] means the maximum of inputs `1` through `x` sits at position `x` after a certain number of sorters. Every sorter used for that state ends no later than `x`, so positions `1` through `x` hold exactly inputs `1` through `x`.

When leftEdge <= x <= rightEdge, the sorter window contains that collected maximum. The window also contains inputs x + 1 through `rightEdge` at their own positions. The window maximum is then the maximum of inputs `1` through `rightEdge`, and it lands at `rightEdge`.

The update formula is bestCosts[rightEdge] = min(bestCosts[x]) + 1 over every position `x` from `leftEdge` to `rightEdge`.

Three tree rules make the query and the update fast:

- tree[baseSize + position] stores the cost for `position`.
- `baseSize` is the smallest power of two larger than `n`.
- The parent of `nodeIndex` stores the smaller of its two children.

The following trace uses six inputs and five sorters.

| Sorter | Smallest earlier cost in range | Cost at right edge after the sorter |
| --- | --- | --- |
| (5, 6) | unreachable | unreachable |
| (1, 3) | 0 | 1 |
| (2, 4) | 1 | 2 |
| (3, 5) | 1 | 2 |
| (4, 6) | 2 | 3 |

The last sorter reaches position six with three sorters.

## Code

```
{.push checks: off.}

const firstDigitValue = 48
const largeSentinel = 1000000000
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  let inputLength = inputData.len
  while scanPos < inputLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var numberValue = 0
  while scanPos < inputLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    numberValue = numberValue * 10 + (int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return numberValue
```

The scanner skips every non-digit byte, so spaces and line breaks need no special case. It visits each digit once.

```
let inputData = readAll(stdin)
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let inputCount = nextInt(inputData, scanPos)
  let sorterCount = nextInt(inputData, scanPos)
  var baseSize = 1
  while baseSize <= inputCount:
    baseSize = baseSize shl 1
  var tree = newSeq[int](baseSize shl 1)
  for nodeIndex in 0 ..< tree.len:
    tree[nodeIndex] = largeSentinel
  tree[baseSize + 1] = 0
  var walkIndex = baseSize + 1
  walkIndex = walkIndex shr 1
  while walkIndex >= 1:
    tree[walkIndex] = 0
    walkIndex = walkIndex shr 1
  var bestCosts = newSeq[int](inputCount + 1)
  for position in 0 .. inputCount:
    bestCosts[position] = largeSentinel
  bestCosts[1] = 0
```

`baseSize` is the first power of two above `inputCount`, so every leaf fits inside the tree. The initial zero at `tree[baseSize + 1]` gives position one zero sorters.

```
  for sorterIndex in 0 ..< sorterCount:
    let leftEdge = nextInt(inputData, scanPos)
    let rightEdge = nextInt(inputData, scanPos)
    var lowNode = leftEdge + baseSize
    var highNode = rightEdge + baseSize
    var bestEarlier = largeSentinel
    while lowNode <= highNode:
      if (lowNode and 1) != 0:
        if tree[lowNode] < bestEarlier:
          bestEarlier = tree[lowNode]
        lowNode += 1
      if (highNode and 1) == 0:
        if tree[highNode] < bestEarlier:
          bestEarlier = tree[highNode]
        highNode -= 1
      lowNode = lowNode shr 1
      highNode = highNode shr 1
    let trialCost = bestEarlier + 1
    if trialCost < bestCosts[rightEdge]:
      bestCosts[rightEdge] = trialCost
      var nodeIndex = rightEdge + baseSize
      tree[nodeIndex] = trialCost
      nodeIndex = nodeIndex shr 1
      while nodeIndex >= 1:
        let leftChild = tree[nodeIndex shl 1]
        let rightChild = tree[(nodeIndex shl 1) + 1]
        var childMinimum = leftChild
        if rightChild < childMinimum:
          childMinimum = rightChild
        if childMinimum == tree[nodeIndex]:
          break
        tree[nodeIndex] = childMinimum
        nodeIndex = nodeIndex shr 1
```

The query visits at most two nodes per level, so its bound is `2 log baseSize`. The update stops when a parent keeps its value and touches one root-to-leaf path. The sentinel leaves `bestCosts[rightEdge]` unchanged while the range is unreachable.

```
  outputBuffer.add $bestCosts[inputCount]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

{.pop.}
```

Output leaves the buffer in blocks of `flushBlockBytes` bytes.

## Complexity

Reading the input takes `O(total tokens)` and stores the bytes once. Building a tree costs `O(n)` per case. Each of the `m` sorters costs `O(log n)` for the query and the update. Writing the answers costs `O(t)`.

Total time is `O(sum of n + sum of m log n)` over all cases. Space is `O(n)` per case plus the input buffer. A rescan of the whole range for every sorter would cost `O(mn)`.
