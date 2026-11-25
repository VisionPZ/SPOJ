# MINIMAX — Minimizing maximizer (SPOJ)

<https://www.spoj.com/problems/MINIMAX/>

## Problem

A row of sorters can rearrange a prefix of the input. Keep enough of them so the last position always holds the maximum.

Read `t` cases. Each gives `n` inputs and `m` sorters. A sorter `(i, j)` sorts positions `i` through `j` in nondecreasing order and leaves other positions fixed.

Keep the fewest sorters in their original order so the last output holds the maximum of all inputs. Print one integer per case.

The judge bounds set the size of the work:

| Quantity | Bound |
| --- | --- |
| Inputs `n` | 2 to 50000 |
| Sorters `m` | 1 to 500000 |
| Time limit | 1500 ms |
| Memory limit | 1536 MB |

The sorter count drives the run time, and the input count sizes the tree.

The sample case:

```
1
40 6 
20 30 
1 10 
10 20 
20 30 
15 25 
30 40 
```

```
4
```

## Idea

Track the cheapest way to deliver the maximum of inputs `1..x` to position `x`.

Think of a baton passed through relay stations. A sorter hands the baton forward only when its range includes the current position. A segment tree (a tree holding the minimum value of each range) finds the cheapest earlier baton in that range.

Each sorter costs one range query and one point update, both O(log n). Rescanning the whole range for every sorter costs O(mn), which fails at 500000 sorters.

## Why It Works

Five facts prove the cost recurrence.

1. A sorter places the largest value of its window at the right edge of that window.
2. `bestCosts[x]` means the maximum of inputs `1..x` sits at position `x` after some sorters. Every sorter used for that state ends no later than `x`, so positions `1..x` hold inputs `1..x`.
3. When `leftEdge <= x <= rightEdge`, the window contains that collected maximum and inputs `x + 1..rightEdge` at their own positions. The window maximum is then the maximum of inputs `1..rightEdge`, and it lands at `rightEdge`.
4. The update is `bestCosts[rightEdge] = min(bestCosts[x]) + 1` over every `x` from `leftEdge` to `rightEdge`.
5. The tree stores the smaller child at each parent. A query visits at most two nodes per level, and an update stops when a parent keeps its value.

The arrays and their roles:

| Term | Meaning |
| --- | --- |
| `bestCosts` | fewest sorters placing the prefix maximum at each position |
| `baseSize` | smallest power of two above `n` |
| `tree` | segment tree of range minimums |
| `bestEarlier` | smallest cost found inside a sorter window |
| `largeSentinel` | value standing for an unreachable position |
| `leftEdge` | first position of the current sorter |

One leaf of `tree` mirrors one entry of `bestCosts`.

A script traces the sample through all six sorters:

```
initial: best[1]=0, others INF
sorter (20,30): min in range=unreachable, best[30]=unreachable
sorter (1,10): min in range=0, best[10]=1
sorter (10,20): min in range=1, best[20]=2
sorter (20,30): min in range=2, best[30]=3
sorter (15,25): min in range=2, best[25]=3
sorter (30,40): min in range=3, best[40]=4
answer: 4
```

The last sorter reaches position 40 with four sorters, which matches the sample.

## Code

**Scanner and constants.** One read loads the stream, and a hand scanner parses tokens.

```nim
{.push checks: off.}

const firstDigitValue = 48
const largeSentinel = 1000000000
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  let inputLength = inputData.len
  while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var numberValue = 0
  while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
    numberValue = numberValue * 10 + (int(inputData[i]) - firstDigitValue)
    i += 1
  return numberValue
```

The scanner skips every non-digit byte, so spaces and line breaks need no special case. It visits each digit once. `largeSentinel` leaves unreachable positions unchanged.

**Tree setup.** A power-of-two base gives every leaf a slot.

```nim
let inputData = readAll(stdin)
var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< caseCount:
  let inputCount = nextInt(inputData, i)
  let sorterCount = nextInt(inputData, i)
  var baseSize = 1
  while baseSize <= inputCount:
    baseSize = baseSize shl 1
  var tree = newSeq[int](baseSize shl 1)
  for k in 0 ..< tree.len:
    tree[k] = largeSentinel
  tree[baseSize + 1] = 0
  var l = baseSize + 1
  l = l shr 1
  while l >= 1:
    tree[l] = 0
    l = l shr 1
  var bestCosts = newSeq[int](inputCount + 1)
  for k in 0 .. inputCount:
    bestCosts[k] = largeSentinel
  bestCosts[1] = 0
```

`baseSize` is the first power of two above `inputCount`, so every leaf fits. The zero at `tree[baseSize + 1]` gives position one zero sorters. Its ancestors also start at zero.

**Sorter loop.** Each sorter queries its window, then updates one leaf.

```nim
  for l in 0 ..< sorterCount:
    let leftEdge = nextInt(inputData, i)
    let rightEdge = nextInt(inputData, i)
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
      var k = rightEdge + baseSize
      tree[k] = trialCost
      k = k shr 1
      while k >= 1:
        let leftChild = tree[k shl 1]
        let rightChild = tree[(k shl 1) + 1]
        var childMinimum = leftChild
        if rightChild < childMinimum:
          childMinimum = rightChild
        if childMinimum == tree[k]:
          break
        tree[k] = childMinimum
        k = k shr 1
```

The query visits at most two nodes per level, so its bound is `2 log baseSize`. The update touches one root-to-leaf path. The sentinel keeps an unreachable window from producing a cost.

**Output.** One answer leaves the buffer in large blocks.

```nim
  outputBuffer.add $bestCosts[inputCount]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

{.pop.}
```

The program prints the cost at the final position. Output leaves the buffer in blocks of `flushBlockBytes` bytes. The final write flushes the tail.

## Complexity

Building the tree and processing sorters dominate each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(total tokens) | one input buffer |
| Tree and cost setup | O(n) | O(n) tree and cost arrays |
| One sorter | O(log n) query and update | O(1) extra |
| Output | O(t) | one output block |

The power-of-two tree keeps every query logarithmic.

| Measure | Big O |
| --- | --- |
| Time | O(sum of n + sum of m log n) |
| Space | O(n) per case plus the input buffer |

A rescan of the whole window for every sorter costs O(mn) instead of O(m log n).
