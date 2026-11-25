# ZOO — Zoo (SPOJ)

<https://www.spoj.com/problems/ZOO/>

## Problem

Choose which circular enclosures to empty so that the most children become happy. A child sees five consecutive enclosures and is happy when a feared animal is gone or a loved animal stays.

Input starts with the number of test cases. Each case gives N enclosures and C children. Each child then has one line. That line holds the first visible enclosure E, fear count F and love count L. It also lists the F feared and L loved enclosures. Children arrive sorted by E.

Output prints one integer per case: the largest possible number of happy children.

| item | bound |
|---|---|
| enclosures N | 10 to 10000 |
| children C | 1 to 50000 |
| visible enclosures | 5 per child |
| judge limit | 5000 ms, 1536 MB |

The five-enclosure window keeps the state space tiny.

Sample input and output:

```
2
14 5
2 1 2 4 2 6
3 1 1 6 4
6 1 2 9 6 8
8 1 1 9 12
12 3 0 12 13 2
12 7
1 1 1 1 5
5 1 1 5 7
5 0 3 5 7 9
7 1 1 7 9
9 1 1 9 11
9 3 0 9 11 1
11 1 1 11 1
```

```
5
6
```

The two blocks come from the statement and drive the checks.

## Idea

Think of a five-seat window sliding around a circle, like a train passing stations. Remember the last four removal choices, then try both choices for the new enclosure. Fix the first four choices to close the circle cleanly.

The program precomputes happy-child counts for every window mask, then runs a 16-state dynamic program for each of the 16 prefix choices. Each step costs 32 transitions. Brute force over all removal sets would test 2^N arrangements.

A tiny state mask handles both the circle and the large child count.

## Why It Works

1. A five-bit mask records which visible enclosures have been emptied.
2. A child is happy when a feared bit is set or a loved bit is clear.
3. Before choosing enclosure i, the state holds the last four removal choices.
4. Shifting that state left and appending the new bit builds the full window mask.
5. Keeping the low four bits produces the state for the next step.
6. The first four enclosures wrap into the last four steps, so trying all 16 prefixes covers the circle.

| term | meaning |
|---|---|
| `happyCounts` | happy children for each start and window mask |
| `currentDp` | best happy count for each state at the current step |
| `windowMask` | removal bits of the five visible enclosures |
| `prefixMask` | removal bits of enclosures 1 to 4 |

The mask arithmetic makes each transition a constant-time table lookup.

A traced example uses the first sample case:

```
first case: children = 5
remove enclosure 13: Ka-Shu sees a feared animal removed
enclosures 2, 6, 4, 9, 12 still show loved animals
happy count = 5
second case: best arrangement satisfied 6 of 7 children
```

The two counts match the sample output.

## Code

**Constants, input reader and output buffer.**

```nim
const flushBlockBytes = 1 shl 17
const windowSize = 5
const windowMasks = 32
const stateCount = 16
const prefixCount = 16
const unreachable = -1000000000

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

The window size fixes the 32 mask values.
unreachable marks states with no valid history.

**Child masks and happy-count table.**

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let enclosureCount = nextInt(inputData, scanPos)
  let childCount = nextInt(inputData, scanPos)
  var happyCounts = newSeq[int]((enclosureCount + 1) * windowMasks)
  for childIndex in 0 .. childCount - 1:
    let firstEnclosure = nextInt(inputData, scanPos)
    let fearTotal = nextInt(inputData, scanPos)
    let loveTotal = nextInt(inputData, scanPos)
    var fearMask = 0
    var loveMask = 0
    for fearIndex in 0 .. fearTotal - 1:
      let fearedEnclosure = nextInt(inputData, scanPos)
      var offset = fearedEnclosure - firstEnclosure
      if offset < 0:
        offset = offset + enclosureCount
      fearMask = fearMask or (1 shl (windowSize - 1 - offset))
    for loveIndex in 0 .. loveTotal - 1:
      let lovedEnclosure = nextInt(inputData, scanPos)
      var offset = lovedEnclosure - firstEnclosure
      if offset < 0:
        offset = offset + enclosureCount
      loveMask = loveMask or (1 shl (windowSize - 1 - offset))
    for windowMask in 0 .. windowMasks - 1:
      let fearRemoved = (fearMask and windowMask) != 0
      let loveKept = (loveMask and (windowMasks - 1 xor windowMask)) != 0
      if fearRemoved or loveKept:
        happyCounts[firstEnclosure * windowMasks + windowMask] += 1
  var bestResult = -1
  for prefixMask in 0 .. prefixCount - 1:
    var currentDp = newSeq[int](stateCount)
    var nextDp = newSeq[int](stateCount)
    for state in 0 .. stateCount - 1:
      currentDp[state] = unreachable
    var initialState = 0
```

Each feared or loved enclosure becomes a reversed mask bit.
All 32 masks are tested for every child.

**Sliding-window dynamic program.**

```nim
    for prefixIndex in 0 .. windowSize - 2:
      if (prefixMask and (1 shl prefixIndex)) != 0:
        initialState = initialState or (1 shl (windowSize - 2 - prefixIndex))
    currentDp[initialState] = 0
    for position in windowSize .. enclosureCount + windowSize - 1:
      let childStart = position - windowSize + 1
      for state in 0 .. stateCount - 1:
        nextDp[state] = unreachable
      var firstBit = 0
      var lastBit = 1
      if position > enclosureCount:
        firstBit = (prefixMask shr (position - enclosureCount - 1)) and 1
        lastBit = firstBit
      for state in 0 .. stateCount - 1:
        if currentDp[state] <= unreachable div 2:
          continue
        for removedBit in firstBit .. lastBit:
          let windowMask = (state shl 1) or removedBit
          let nextState = windowMask and (stateCount - 1)
          let gain = happyCounts[childStart * windowMasks + windowMask]
          let candidate = currentDp[state] + gain
          if candidate > nextDp[nextState]:
            nextDp[nextState] = candidate
      let previousDp = currentDp
      currentDp = nextDp
      nextDp = previousDp
    for state in 0 .. stateCount - 1:
      if currentDp[state] > bestResult:
        bestResult = currentDp[state]
  appendOutput($bestResult)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The 16 prefix choices cover wrap-around positions.
Each step shifts the state and adds the new removal bit.
Forced bits handle positions beyond N.

## Complexity

The mask table and the state sweep are both small constants per item.

| phase | time | space |
|---|---|---|
| input read | one pass over child lines | one input string |
| happy table | 32 masks per child | 32 counts per start |
| state sweep | 16 prefixes times 16 states times 2 bits per position | two 16-state arrays |
| output | one buffered line per case | block buffer |

The sweep over prefixes and positions dominates.

| measure | Big O |
|---|---|
| time | O(32*C + 512*N) |
| space | O(32*N) |

Trying every removal set would cost O(2^N) per case.
