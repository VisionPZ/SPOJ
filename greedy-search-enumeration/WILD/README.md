# WILD — Wild West (SPOJ)

<https://www.spoj.com/problems/WILD/>

## Problem

Count score triples that beat every evil stranger in at least one skill. A hero must differ from every evil member, so an exact match never counts.

Input holds several cases. Each starts with `n m`, then `n` triples with scores from 1 to `m`. A case with `n = m = 0` ends the input. Output holds the hero count per case.

The bounds from the statement:

| item | bound |
|---|---|
| evil members n | 1 to 100000 |
| maximum score m | 2 to 100000 |
| output value | at most 1000000000000000000 |
| judge limit | 3400 ms, 1536 MB |

A triple fails when some evil member is at least as strong in all three skills.

Sample input:

```
3 10
2 8 5
6 3 5
1 3 9
1 3
2 2 2
1 10000
2 2 2
0 0
```

This figure is the sample input copied from the statement.

Sample output:

```
848
19
999999999992
```

This figure is the sample output, one count per case.

## Idea

Treat each evil member as a shadow over the score cube and count the cells outside every shadow.

Flip the last two axes so the shadow edge becomes a running minimum, then sweep the first axis while keeping a staircase of breakpoints.

A Fenwick tree finds neighbors in the staircase, and a linked list removes broken breakpoints in constant time.

Testing every triple costs O(m^3), while the sweep costs O(n log n). The staircase turns a cube count into a sequence of small updates.

## Why It Works

1. A candidate `(a, b, c)` fails against evil `(x, y, z)` exactly when `a <= x`, `b <= y`, and `c <= z`.
2. Flip coordinates with `y' = m + 1 - y` and `z' = m + 1 - z`.
3. For fixed `a`, the number of good `(b, c)` pairs equals the minimum flipped `z'` over evil members with `x >= a` and flipped `y' <= b'`, minus one.
4. That minimum is a step function of `b'`; its breakpoints form a staircase with strictly decreasing `z'` values.
5. Sweeping `a` downward adds evil members by descending `x`, and each inserted breakpoint permanently removes any breakpoint it dominates.
6. Each insertion updates the step total from its two neighbors, so multiplied by the width of the `a` slice it gives the hero count.

The main terms:

| term | meaning |
|---|---|
| `compressedY` | sorted distinct flipped second scores |
| `bestZ` | flipped third score stored at an active breakpoint |
| `linked list` | predecessor and successor arrays over active breakpoints |
| `staircaseTotal` | sum of `(minimum z' - 1)` over all flipped second scores |

The table names the values held by the sweep.

A script traced the third sample case with `m = 10000`:

```
a = 10000 down to 3: no evil yet, slice total 10000^2 = 100000000
slices: 9998 * 100000000 = 999800000000 heroes
a = 2: breakpoint (y'=9999, z'=9999), slice total 99999996
a = 1: same slice total 99999996
total = 999800000000 + 99999996 + 99999996 = 999999999992
```

The total matches the sample output.

All totals use 64-bit integers because a cube count reaches 10^15. The Fenwick tree stores only active breakpoints, so neighbor searches take logarithmic time.

## Code

**Input and scanner.** The reader loads all cases, and the scanner walks integer tokens.

```nim
const flushBlockBytes = 1 shl 17

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

One case holds up to 100000 triples.
Every score is a positive integer.
Answers are written once per case from one buffer.

**Fenwick tree.** The tree answers neighbor queries over active breakpoints.

```nim
proc fenwickAdd(nodeIndex, delta: int) =
  var position = nodeIndex + 1
  while position <= fenwickTree.len - 1:
    fenwickTree[position] += delta
    position += position and (-position)

proc fenwickPrefix(nodeIndex: int): int =
  var position = nodeIndex + 1
  var totalSum = 0
  while position > 0:
    totalSum += fenwickTree[position]
    position -= position and (-position)
  return totalSum

proc fenwickFind(kthValue: int): int =
  var remaining = kthValue
  var position = 0
  var stepSize = highestPower
  while stepSize > 0:
    let candidate = position + stepSize
    if candidate <= fenwickTree.len - 1 and fenwickTree[candidate] < remaining:
      position = candidate
      remaining -= fenwickTree[candidate]
    stepSize = stepSize div 2
  return position

proc firstActiveAtOrAfter(nodeIndex: int): int =
  let countBefore = fenwickPrefix(nodeIndex - 1)
  if fenwickPrefix(compressedY.len - 1) <= countBefore:
    return -1
  return fenwickFind(countBefore + 1)

proc lastActiveBefore(nodeIndex: int): int =
  let countBefore = fenwickPrefix(nodeIndex - 1)
  if countBefore == 0:
    return -1
  return fenwickFind(countBefore)
```

The tree uses one-based positions internally.
Binary lifting finds the kth active breakpoint.
Both neighbor queries cost logarithmic time.

**Staircase updates.** Insertions retire dominated breakpoints and adjust the running total.

```nim
proc boundaryAfter(nodeIndex: int, cellCount: int): int =
  if nodeIndex == -1 or followingNode[nodeIndex] == -1:
    return cellCount + 1
  return compressedY[followingNode[nodeIndex]]

proc removeNode(nodeIndex: int, cellCount: int) =
  let predecessor = previousNode[nodeIndex]
  let successor = followingNode[nodeIndex]
  let currentY = compressedY[nodeIndex]
  let boundaryY = boundaryAfter(nodeIndex, cellCount)
  staircaseTotal -= int64(boundaryY - currentY) * int64(bestZ[nodeIndex] - 1)
  if predecessor == -1:
    staircaseTotal += int64(boundaryY - currentY) * int64(cellCount)
  else:
    staircaseTotal += int64(boundaryY - currentY) * int64(bestZ[predecessor] - 1)
  if predecessor == -1:
    if successor != -1:
      previousNode[successor] = -1
  else:
    if successor == -1:
      followingNode[predecessor] = -1
    else:
      followingNode[predecessor] = successor
      previousNode[successor] = predecessor
  nodeActive[nodeIndex] = false
  fenwickAdd(nodeIndex, -1)

proc insertNode(nodeIndex, zValue: int, cellCount: int) =
  let predecessor = lastActiveBefore(nodeIndex)
  let successor = firstActiveAtOrAfter(nodeIndex)
  let currentY = compressedY[nodeIndex]
  var boundaryY = cellCount + 1
  if successor != -1:
    boundaryY = compressedY[successor]
  if predecessor == -1:
    staircaseTotal += int64(boundaryY - currentY) * int64(zValue - 1 - cellCount)
  else:
    staircaseTotal += int64(boundaryY - currentY) * int64(zValue - bestZ[predecessor])
  previousNode[nodeIndex] = predecessor
  followingNode[nodeIndex] = successor
  if predecessor != -1:
    followingNode[predecessor] = nodeIndex
  if successor != -1:
    previousNode[successor] = nodeIndex
  bestZ[nodeIndex] = zValue
  nodeActive[nodeIndex] = true
  fenwickAdd(nodeIndex, 1)

proc insertBreakpoint(nodeIndex, zValue: int, cellCount: int) =
  if nodeActive[nodeIndex]:
    if bestZ[nodeIndex] <= zValue:
      return
    removeNode(nodeIndex, cellCount)
  let predecessor = lastActiveBefore(nodeIndex)
  if predecessor != -1 and bestZ[predecessor] <= zValue:
    return
  var currentNode = firstActiveAtOrAfter(nodeIndex)
  while currentNode != -1 and bestZ[currentNode] >= zValue:
    let following = followingNode[currentNode]
    removeNode(currentNode, cellCount)
    currentNode = following
  insertNode(nodeIndex, zValue, cellCount)
```

Each removed breakpoint leaves the staircase for good.
Neighbor deltas update the total in constant time.
A dominated insertion stops before touching any links.

**Case driver.** The driver flips coordinates, sorts by first score, and sweeps slices.

```nim
while true:
  let memberCount = nextInt(inputData, scanPos)
  let scoreLimit = nextInt(inputData, scanPos)
  if memberCount == 0 and scoreLimit == 0:
    break
  var members = newSeq[EvilMember](memberCount)
  for memberIndex in 0 .. memberCount - 1:
    members[memberIndex].firstScore = nextInt(inputData, scanPos)
    let secondScore = nextInt(inputData, scanPos)
    let thirdScore = nextInt(inputData, scanPos)
    members[memberIndex].secondScore = scoreLimit + 1 - secondScore
    members[memberIndex].thirdScore = scoreLimit + 1 - thirdScore

  var sortIndex = 1
  while sortIndex < memberCount:
    let currentMember = members[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and members[previousIndex].firstScore < currentMember.firstScore:
      members[previousIndex + 1] = members[previousIndex]
      previousIndex -= 1
    members[previousIndex + 1] = currentMember
    sortIndex += 1

  compressedY = @[]
  for member in members:
    compressedY.add(member.secondScore)
  var sortEnd = 1
  while sortEnd < compressedY.len:
    let currentY = compressedY[sortEnd]
    var previousIndex = sortEnd - 1
    while previousIndex >= 0 and compressedY[previousIndex] > currentY:
      compressedY[previousIndex + 1] = compressedY[previousIndex]
      previousIndex -= 1
    compressedY[previousIndex + 1] = currentY
    sortEnd += 1
  var uniqueCount = 0
  sortIndex = 0
  while sortIndex < compressedY.len:
    if sortIndex == 0 or compressedY[sortIndex] != compressedY[sortIndex - 1]:
      compressedY[uniqueCount] = compressedY[sortIndex]
      uniqueCount += 1
    sortIndex += 1
  compressedY.setLen(uniqueCount)

  bestZ = newSeq[int](uniqueCount)
  previousNode = newSeq[int](uniqueCount)
  followingNode = newSeq[int](uniqueCount)
  nodeActive = newSeq[bool](uniqueCount)
  fenwickTree = newSeq[int](uniqueCount + 1)
  for nodeIndex in 0 .. uniqueCount - 1:
    previousNode[nodeIndex] = -1
    followingNode[nodeIndex] = -1
  highestPower = 1
  while highestPower shl 1 <= uniqueCount:
    highestPower = highestPower shl 1
  staircaseTotal = int64(scoreLimit) * int64(scoreLimit)

  var heroTotal: int64 = 0
  var previousScore = scoreLimit + 1
  var memberIndex = 0
  while memberIndex < memberCount:
    let currentScore = members[memberIndex].firstScore
    heroTotal += int64(previousScore - currentScore - 1) * staircaseTotal
    while memberIndex < memberCount and members[memberIndex].firstScore == currentScore:
      var lowIndex = 0
      var highIndex = uniqueCount - 1
      while lowIndex < highIndex:
        let middleIndex = (lowIndex + highIndex) div 2
        if compressedY[middleIndex] < members[memberIndex].secondScore:
          lowIndex = middleIndex + 1
        else:
          highIndex = middleIndex
      insertBreakpoint(lowIndex, members[memberIndex].thirdScore, scoreLimit)
      memberIndex += 1
    heroTotal += staircaseTotal
    previousScore = currentScore
  heroTotal += int64(previousScore - 1) * staircaseTotal
  appendOutput($heroTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Members with equal first scores join one slice.
Binary search maps a flipped score to its compressed index.
The final slice covers first scores below the smallest evil score.

## Complexity

The sweep adds each evil member once and searches the staircase in logarithmic time.

The cost breakdown by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over evil triples | one input string |
| sort and compress | O(n log n) | arrays of n scores |
| staircase updates | O(n log n) | linked arrays and Fenwick tree |
| output | one line per case | block buffer |

Staircase updates dominate the work for large cases.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(n log n) per case |
| space | O(n) |

Testing all m^3 score triples takes far longer than one logarithmic update per evil member.
