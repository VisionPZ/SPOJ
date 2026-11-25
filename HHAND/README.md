# HHAND — Hospital at Hands (SPOJ)

<https://www.spoj.com/problems/HHAND/>

## Problem

A tree of towns needs hospitals on one connected path of at most `L` roads. Put a hospital at every town on that path and report the smallest total distance from all towns to their nearest hospital.

A test gives `N` towns and reach `L`, then `N-1` roads. Input starts with a case count. Print one minimum total per test case.

| item | bound |
|---|---|
| test cases T | up to 30 |
| towns N | up to 10000 |
| reach L | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

The small reach bound allows a bounded-length tree scan.

Sample input:

```
2
3 1
0 1
1 2
4 1
0 1
1 2
2 3
```

Sample output:

```
1
2
```

## Idea

Think of the chosen path as a ridge with hospitals like lamps along it. Longer ridges light more towns, so the best path uses as many roads as the cap allows.

Root the tree and let the path's shallowest town be its peak. Both arms then run down into two different child subtrees, and a chain DP stores the best cost for every arm length.

Rescanning every path would cost far more than one bounded DP.

One chain table per town answers all peaks in linear time.

## Why It Works

1. Extending a hospital path by one town lowers total distance by that town's subtree size.
2. An optimal path therefore uses the largest length it can reach.
3. The shallowest path town is the peak, and both arms descend into distinct children.
4. A town on an arm pays its total distance minus the two neighbour subtrees on the path.
5. The two best arm lengths combine through a best and second-best table per peak.

| term | meaning |
|---|---|
| `totalDistance` | sum of distances from a town to all towns |
| `distanceSum` | sum of distances inside a town's subtree |
| `downChain` | best cost of a downward chain of a given length |
| `bestBranch` | cheapest arm of each length at a peak |

A worked trace follows for the first sample with `L = 1`.

```
hospitals at 0 and 1: town 2 walks 1 road
hospitals at 1 and 2: town 0 walks 1 road
minimum = 1
```

Either adjacent pair gives the sample answer of one.

## Code

**Input and buffered output.** The hand reader stores all test cases in one string.

```nim
const flushBlockBytes = 1 shl 17
const infiniteCost = int64(1) shl 60

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

All tokens use the same integer scanner.
Output lines accumulate in one buffer.
The scanner ignores road-line breaks.

**Tree measures.** Each town stores its subtree size and distance totals.

```nim
proc solveCase(townCount: int, reachLimit: int, edgeCount: int, scanPosition: var int): int64 =
  var edgeHead = newSeq[int](townCount)
  for headIndex in 0 .. townCount - 1:
    edgeHead[headIndex] = -1
  var edgeTo = newSeq[int](2 * edgeCount)
  var edgeNext = newSeq[int](2 * edgeCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstTown = nextInt(inputData, scanPosition)
    let secondTown = nextInt(inputData, scanPosition)
    let forwardIndex = 2 * edgeIndex
    let backwardIndex = 2 * edgeIndex + 1
    edgeTo[forwardIndex] = secondTown
    edgeTo[backwardIndex] = firstTown
    edgeNext[forwardIndex] = edgeHead[firstTown]
    edgeNext[backwardIndex] = edgeHead[secondTown]
    edgeHead[firstTown] = forwardIndex
    edgeHead[secondTown] = backwardIndex

  var parentTown = newSeq[int](townCount)
  for townIndex in 0 .. townCount - 1:
    parentTown[townIndex] = -1
  parentTown[0] = -2
  var queue = newSeq[int](townCount)
  var queueHead = 0
  var queueTail = 0
  queue[queueTail] = 0
  queueTail += 1
  while queueHead < queueTail:
    let currentTown = queue[queueHead]
    queueHead += 1
    var edgeIndex = edgeHead[currentTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == -1:
        parentTown[neighborTown] = currentTown
        queue[queueTail] = neighborTown
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]

  var subtreeSize = newSeq[int](townCount)
  var distanceSum = newSeq[int64](townCount)
  for townIndex in 0 .. townCount - 1:
    subtreeSize[townIndex] = 1
  var orderIndex = townCount - 1
  while orderIndex >= 0:
    let currentTown = queue[orderIndex]
    var edgeIndex = edgeHead[currentTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == currentTown:
        subtreeSize[currentTown] = subtreeSize[currentTown] + subtreeSize[neighborTown]
        distanceSum[currentTown] = distanceSum[currentTown] + distanceSum[neighborTown] + int64(subtreeSize[neighborTown])
      edgeIndex = edgeNext[edgeIndex]
    orderIndex -= 1

  var totalDistance = newSeq[int64](townCount)
  totalDistance[0] = distanceSum[0]
  for forwardIndex in 0 .. townCount - 1:
    let currentTown = queue[forwardIndex]
    var edgeIndex = edgeHead[currentTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == currentTown:
        totalDistance[neighborTown] = totalDistance[currentTown] + int64(townCount) - 2 * int64(subtreeSize[neighborTown])
      edgeIndex = edgeNext[edgeIndex]

  var distanceToParent = newSeq[int64](townCount)
  for townIndex in 1 .. townCount - 1:
    distanceToParent[townIndex] = totalDistance[townIndex] - distanceSum[townIndex]
```

Breadth-first order gives parents without recursion.
Subtree sums are computed in reverse order.
Total distances follow the standard rerooting shift.

**Chain table.** Each town keeps the best downward chain for every length.

```nim
  let chainWidth = reachLimit + 1
  var downChain = newSeq[int64](townCount * chainWidth)
  for chainIndex in 0 .. downChain.len - 1:
    downChain[chainIndex] = infiniteCost
  for townIndex in 0 .. townCount - 1:
    downChain[townIndex * chainWidth] = 0
    downChain[townIndex * chainWidth + 1] = totalDistance[townIndex] - distanceToParent[townIndex]

  orderIndex = townCount - 1
  while orderIndex >= 0:
    let currentTown = queue[orderIndex]
    for chainLength in 2 .. reachLimit:
      var bestBranch = infiniteCost
      var edgeIndex = edgeHead[currentTown]
      while edgeIndex >= 0:
        let neighborTown = edgeTo[edgeIndex]
        if parentTown[neighborTown] == currentTown:
          let candidate = downChain[neighborTown * chainWidth + chainLength - 1] - (distanceSum[neighborTown] + int64(subtreeSize[neighborTown]))
          if candidate < bestBranch:
            bestBranch = candidate
        edgeIndex = edgeNext[edgeIndex]
      if bestBranch < infiniteCost div 2:
        downChain[currentTown * chainWidth + chainLength] = totalDistance[currentTown] - distanceToParent[currentTown] + bestBranch
    orderIndex -= 1
```

A chain of one town pays its whole distance sum.
Longer chains pick the cheapest child arm.
Infinite cost marks a chain too short to exist.

**Peak combination.** Two arms meet at the shallowest town.

```nim
  var bestCost = infiniteCost
  for apexTown in 0 .. townCount - 1:
    var bestBranch = newSeq[int64](chainWidth)
    var bestChild = newSeq[int](chainWidth)
    var secondBranch = newSeq[int64](chainWidth)
    var secondChild = newSeq[int](chainWidth)
    for chainLength in 0 .. reachLimit:
      bestBranch[chainLength] = infiniteCost
      secondBranch[chainLength] = infiniteCost
      bestChild[chainLength] = -1
      secondChild[chainLength] = -1
    bestBranch[0] = 0
    secondBranch[0] = 0
    var edgeIndex = edgeHead[apexTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == apexTown:
        let childDistance = distanceSum[neighborTown] + int64(subtreeSize[neighborTown])
        for chainLength in 1 .. reachLimit:
          let candidate = downChain[neighborTown * chainWidth + chainLength] - childDistance
          if candidate < bestBranch[chainLength]:
            secondBranch[chainLength] = bestBranch[chainLength]
            secondChild[chainLength] = bestChild[chainLength]
            bestBranch[chainLength] = candidate
            bestChild[chainLength] = neighborTown
          elif candidate < secondBranch[chainLength]:
            secondBranch[chainLength] = candidate
            secondChild[chainLength] = neighborTown
      edgeIndex = edgeNext[edgeIndex]

    var totalLength = reachLimit
    while totalLength >= 0:
      var combined = infiniteCost
      for leftLength in 0 .. totalLength:
        let rightLength = totalLength - leftLength
        var branchTotal: int64
        if bestChild[leftLength] != bestChild[rightLength]:
          branchTotal = bestBranch[leftLength] + bestBranch[rightLength]
        else:
          let firstChoice = bestBranch[leftLength] + secondBranch[rightLength]
          let secondChoice = secondBranch[leftLength] + bestBranch[rightLength]
          branchTotal = firstChoice
          if secondChoice < branchTotal:
            branchTotal = secondChoice
        if branchTotal < combined:
          combined = branchTotal
      if combined < infiniteCost div 2:
        let candidateCost = totalDistance[apexTown] + combined
        if candidateCost < bestCost:
          bestCost = candidateCost
        break
      totalLength -= 1

```

Best and second-best arms keep the children distinct.
Lengths from the cap downward find the first feasible path.
The cheapest total becomes the test case answer.

**Case loop.** Each test yields one answer line.

```nim

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let townCount = nextInt(inputData, scanPos)
  let reachLimit = nextInt(inputData, scanPos)
  appendOutput($solveCase(townCount, reachLimit, townCount - 1, scanPos))
  outputBuffer.add '\n'

stdout.write outputBuffer
```

The scan position advances past every road.
Buffered writes avoid one syscall per case.
The final flush ends the output.

## Complexity

The chain table and peak scan dominate.

| phase | time | space |
|---|---|---|
| input read | one pass over road bytes | input string |
| tree measures | O(N) | adjacency and sums |
| chain table | O(NL) | chain table |
| peak scan | O(NL) | best and second arrays |
| output | one buffered write per block | block buffer |

The reach bound keeps the chain table narrow.

| measure | Big O |
|---|---|
| time | O(NL) per test case |
| space | O(NL) |

Checking every path separately would cost far more than one bounded chain table.

The bounded DP handles the largest tree quickly, even across thirty cases.
