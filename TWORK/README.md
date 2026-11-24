## Problem

Read several test cases. Each case lists n scientists and m acquaintance pairs. Each scientist knows 2 or 3 other scientists.
Print k three-person groups. Each group needs one leader whom all three members accept. That leader must know the other two members.
Leave at most 25% of the scientists without a group.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | at most 100 |
| Scientists per case | 4 to 20000, divisible by 4 |
| Acquaintance pairs | n to 20000 |
| Acquaintances per scientist | 2 or 3 |
| Time limit | 1028 ms |
| Memory limit | 1536 MB |

The 25% tolerance permits disjoint paths of length two instead of a perfect partition.

## Idea

Treat each group as a path of length two. The center knows both ends, so all three members accept the center as leader.
The program repeatedly takes a center and two available neighbors. It marks those three scientists used and continues.
Sixteen variants change the center order and the neighbor choice. The program keeps the packing with the most groups.

Each variant touches every scientist once and every acquaintance pair a constant number of times.

## Why It Works

A scientist tolerates themselves and their acquaintances. The leader of a group must know the other two members.
That condition is exactly a path of length two. Removing a group only lowers the remaining degree of surrounding scientists.
A scientist stops being a center once that degree falls below two.

For a center v, the printed group is (x, v, y).

- x is the first available neighbor of v.
- v is the center and knows x and y.
- y is the second available neighbor of v.

A center score is the sum of its two smallest remaining neighbor degrees. Five buckets hold centers by score.
The program takes centers from the lowest bucket first. That order saves low-degree neighbors for later groups.
Four bucket variants use different scan directions and neighbor choices. Four shuffled variants and eight ordered variants add more coverage.
The largest result meets the 25% bound on the generated families. A K4 leaves one scientist out of four, so 25% is tight.

The example below comes from the gen.py example mode on the sample graph.

```
center 1: neighbors 2, 3 -> group 2 1 3
center 4: neighbors 6, 8 -> group 6 4 8
assigned 6 of 8; uncovered 25%
```

## Code

The program reads all input into one string. The scanner walks digits with a byte position. Output waits in a buffer until it reaches the flush size.

```nim
{.define: release.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const variantCount = 16
const bucketCount = 5

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var rngState: uint32 = 2463534242'u32

proc nextRandom(): uint32 =
  rngState = rngState xor (rngState shl 13'u32)
  rngState = rngState xor (rngState shr 17'u32)
  rngState = rngState xor (rngState shl 5'u32)
  return rngState
```

The read loop runs until input ends. The scanner stops at the first non-digit. The buffer avoids a write per number. Its name avoids a Nim keyword.

The helpers compare neighbors and compute center scores. A score uses the two smallest available neighbor degrees. The bucket push writes into a reserved slice of one array.

```nim
proc pickBetter(candidate: int, current: int, degrees: seq[int], preferMax: bool,
                reverseTie: bool): bool =
  if preferMax:
    if degrees[candidate] > degrees[current]: return true
    if degrees[candidate] < degrees[current]: return false
  else:
    if degrees[candidate] < degrees[current]: return true
    if degrees[candidate] > degrees[current]: return false
  if reverseTie:
    return candidate > current
  return candidate < current

proc centerScore(scientist: int, edgeHead: seq[int], edgeTo: seq[int],
                 edgeLink: seq[int], available: seq[bool],
                 remainingDegree: seq[int]): int =
  var smallest = 4
  var second = 4
  var neighborTotal = 0
  var edgeIndex = edgeHead[scientist]
  while edgeIndex != -1:
    let neighbor = edgeTo[edgeIndex]
    if available[neighbor]:
      let value = remainingDegree[neighbor]
      if value < smallest:
        second = smallest
        smallest = value
      elif value < second:
        second = value
      neighborTotal += 1
    edgeIndex = edgeLink[edgeIndex]
  if neighborTotal < 2:
    return -1
  let score = smallest + second
  if score < 2:
    return 2
  if score > 6:
    return 6
  return score

proc pushBucket(slot: int, scientist: int, capacity: int, store: var seq[int],
                lengths: var array[bucketCount, int]) =
  store[slot * capacity + lengths[slot]] = scientist
  lengths[slot] += 1

```

The score returns -1 when a scientist has fewer than two available neighbors. Scores are clamped to the five buckets. A push costs constant time.

The packing procedure runs one variant. Bucket variants take the lowest available score. Ordered variants pop a stack. Shuffled variants pick random neighbors.

```nim
proc runPacking(variant: int, caseIndex: int, scientistCount: int,
                edgeHead: seq[int], edgeTo: seq[int], edgeLink: seq[int],
                baseDegree: seq[int], available: var seq[bool],
                remainingDegree: var seq[int], stack: var seq[int],
                stackLength: var int, bucketStore: var seq[int],
                bucketLengths: var array[bucketCount, int], bucketCapacity: int,
                groupLeft: var seq[int], groupCenter: var seq[int],
                groupRight: var seq[int]): int =
  var index = 0
  while index < scientistCount:
    available[index] = true
    remainingDegree[index] = baseDegree[index]
    index += 1

  let bucketMode = variant >= 12
  let preferMax = (variant mod 2) == 1
  let reverseTie = (variant div 4) mod 2 == 1
  let useRandom = variant >= 8 and variant < 12
  var groupCount = 0

  if bucketMode:
    index = 0
    while index < bucketCount:
      bucketLengths[index] = 0
      index += 1
    if (variant div 2) mod 2 == 0:
      index = 0
      while index < scientistCount:
        let score = centerScore(index, edgeHead, edgeTo, edgeLink,
                                available, remainingDegree)
        if score >= 2:
          pushBucket(score - 2, index, bucketCapacity, bucketStore, bucketLengths)
        index += 1
    else:
      index = scientistCount - 1
      while index >= 0:
        let score = centerScore(index, edgeHead, edgeTo, edgeLink,
                                available, remainingDegree)
        if score >= 2:
          pushBucket(score - 2, index, bucketCapacity, bucketStore, bucketLengths)
        index -= 1
  else:
    stackLength = 0
    if useRandom:
      rngState = uint32(362437 + variant * 7919 + caseIndex * 104729 + 1)
      index = 0
      while index < scientistCount:
        stack[stackLength] = index
        stackLength += 1
        index += 1
      index = scientistCount - 1
      while index > 0:
        let swapIndex = int(nextRandom() mod uint32(index + 1))
        let held = stack[index]
        stack[index] = stack[swapIndex]
        stack[swapIndex] = held
        index -= 1
    elif (variant div 2) mod 2 == 0:
      index = 0
      while index < scientistCount:
        stack[stackLength] = index
        stackLength += 1
        index += 1
    else:
      index = scientistCount - 1
      while index >= 0:
        stack[stackLength] = index
        stackLength += 1
        index -= 1

  while true:
    var center = -1
    if bucketMode:
      var slot = 0
      while slot < bucketCount and bucketLengths[slot] == 0:
        slot += 1
      if slot == bucketCount:
        break
      bucketLengths[slot] -= 1
      let candidate = bucketStore[slot * bucketCapacity + bucketLengths[slot]]
      if not available[candidate]:
        continue
      let score = centerScore(candidate, edgeHead, edgeTo, edgeLink,
                              available, remainingDegree)
      if score == -1:
        continue
      if score != slot + 2:
        pushBucket(score - 2, candidate, bucketCapacity,
                   bucketStore, bucketLengths)
        continue
      center = candidate
    else:
      if stackLength == 0:
        break
      stackLength -= 1
      let candidate = stack[stackLength]
      if not available[candidate] or remainingDegree[candidate] < 2:
        continue
      center = candidate

    var neighborBuf: array[3, int]
    var neighborCount = 0
    var edgeIndex = edgeHead[center]
    while edgeIndex != -1:
      let neighbor = edgeTo[edgeIndex]
      if available[neighbor]:
        neighborBuf[neighborCount] = neighbor
        neighborCount += 1
      edgeIndex = edgeLink[edgeIndex]
    if neighborCount < 2:
      continue

    var left: int
    var right: int
    if useRandom:
      let firstSlot = int(nextRandom() mod uint32(neighborCount))
      var secondSlot = int(nextRandom() mod uint32(neighborCount - 1))
      if secondSlot >= firstSlot:
        secondSlot += 1
      left = neighborBuf[firstSlot]
      right = neighborBuf[secondSlot]
    else:
      var firstSlot = 0
      var slot = 1
      while slot < neighborCount:
        if pickBetter(neighborBuf[slot], neighborBuf[firstSlot],
                      remainingDegree, preferMax, reverseTie):
          firstSlot = slot
        slot += 1
      var secondSlot = -1
      slot = 0
      while slot < neighborCount:
        if slot != firstSlot and (secondSlot == -1 or
            pickBetter(neighborBuf[slot], neighborBuf[secondSlot],
                       remainingDegree, preferMax, reverseTie)):
          secondSlot = slot
        slot += 1
      left = neighborBuf[firstSlot]
      right = neighborBuf[secondSlot]

    groupLeft[groupCount] = left
    groupCenter[groupCount] = center
    groupRight[groupCount] = right
    groupCount += 1

    available[center] = false
    available[left] = false
    available[right] = false

    var removedIndex = 0
    while removedIndex < 3:
      var removed: int
      case removedIndex
      of 0:
        removed = center
      of 1:
        removed = left
      else:
        removed = right
      var linkIndex = edgeHead[removed]
      while linkIndex != -1:
        let neighbor = edgeTo[linkIndex]
        if available[neighbor]:
          remainingDegree[neighbor] -= 1
          if bucketMode:
            let score = centerScore(neighbor, edgeHead, edgeTo, edgeLink,
                                    available, remainingDegree)
            if score >= 2:
              pushBucket(score - 2, neighbor, bucketCapacity,
                         bucketStore, bucketLengths)
          elif remainingDegree[neighbor] >= 2:
            stack[stackLength] = neighbor
            stackLength += 1
        linkIndex = edgeLink[linkIndex]
      removedIndex += 1

  return groupCount

```

The loop ends when every bucket or stack is empty. Stale bucket entries are skipped or repushed. One pass costs O(n+m) for n scientists and m pairs.

The main loop builds adjacency for each case. All sixteen variants reuse those arrays. The best group list is copied only after an improvement.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let scientistCount = nextInt(inputData, scanPos)
  let relationCount = nextInt(inputData, scanPos)

  var edgeHead = newSeq[int](scientistCount)
  var edgeTo = newSeq[int](relationCount * 2)
  var edgeLink = newSeq[int](relationCount * 2)
  var baseDegree = newSeq[int](scientistCount)
  var edgeCursor = 0
  var index = 0
  while index < scientistCount:
    edgeHead[index] = -1
    index += 1
  index = 0
  while index < relationCount:
    let firstScientist = nextInt(inputData, scanPos) - 1
    let secondScientist = nextInt(inputData, scanPos) - 1
    edgeTo[edgeCursor] = secondScientist
    edgeLink[edgeCursor] = edgeHead[firstScientist]
    edgeHead[firstScientist] = edgeCursor
    edgeCursor += 1
    edgeTo[edgeCursor] = firstScientist
    edgeLink[edgeCursor] = edgeHead[secondScientist]
    edgeHead[secondScientist] = edgeCursor
    edgeCursor += 1
    baseDegree[firstScientist] += 1
    baseDegree[secondScientist] += 1
    index += 1

  var available = newSeq[bool](scientistCount)
  var remainingDegree = newSeq[int](scientistCount)
  var stack = newSeq[int](scientistCount * 4 + 8)
  var stackLength = 0
  let bucketCapacity = scientistCount * 8 + 16
  var bucketStore = newSeq[int](bucketCapacity * bucketCount)
  var bucketLengths: array[bucketCount, int]
  let groupCapacity = scientistCount div 3
  var trialLeft = newSeq[int](groupCapacity)
  var trialCenter = newSeq[int](groupCapacity)
  var trialRight = newSeq[int](groupCapacity)
  var bestLeft = newSeq[int](groupCapacity)
  var bestCenter = newSeq[int](groupCapacity)
  var bestRight = newSeq[int](groupCapacity)
  var bestCount = 0

  var variant = 0
  while variant < variantCount:
    let found = runPacking(variant, caseIndex, scientistCount, edgeHead, edgeTo,
                           edgeLink, baseDegree, available, remainingDegree,
                           stack, stackLength, bucketStore, bucketLengths,
                           bucketCapacity, trialLeft, trialCenter, trialRight)
    if found > bestCount:
      bestCount = found
      index = 0
      while index < found:
        bestLeft[index] = trialLeft[index]
        bestCenter[index] = trialCenter[index]
        bestRight[index] = trialRight[index]
        index += 1
    variant += 1

  appendOutput($(bestCount))
  outputBuffer.add '\n'
  index = 0
  while index < bestCount:
    appendOutput($(bestLeft[index] + 1))
    outputBuffer.add ' '
    appendOutput($(bestCenter[index] + 1))
    outputBuffer.add ' '
    appendOutput($(bestRight[index] + 1))
    outputBuffer.add '\n'
    index += 1
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The case loop runs t times. The variant loop runs sixteen times. Input numbers become zero-based at read time. Output goes to one block-flushed buffer.

## Complexity

The table lists the cost of each phase.

| Phase | Time per case | Space per case |
| --- | --- | --- |
| Input | O(input bytes) | O(input bytes) |
| Graph build | O(n+m) | O(n+m) |
| Packing | 16 × O(n+m) | O(n+m) |
| Output | O(k) | O(flush block) |

Packing dominates the time bound. The total time is linear in the input size, and total space is linear in the largest case.
Trying every triple costs O(n³) per case and cannot handle n = 20000.
