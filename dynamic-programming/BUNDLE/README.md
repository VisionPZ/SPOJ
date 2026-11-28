# BUNDLE — Bundling (SPOJ)
<https://www.spoj.com/problems/BUNDLE/>

## Problem

Given templates for three-slot bundles and a sequence of instructions with dependency links, pack the sequence into the fewest bundles. Then use the fewest stops that make those bundles valid.

Input starts with a case count. Each case gives a template count t and an instruction count n. Next come t templates: three type letters and a stop slot. Then come n instructions: one type letter and a dependency index. Output two integers: bundles and stops.

The limits force near constant work per instruction.

| Quantity | Bound |
| --- | --- |
| Templates per case | 1500 |
| Instructions per case | 100,000 |
| Instruction types | 10 |
| Time limit | 1053 ms |
| Memory limit | 1536 MB |

The largest case holds 100,000 instructions, so the state set must stay tiny.

The sample input and output:

```
1
4 9
ABB 0
BAD 1
AAB 0
ABB 2
B 0
B 1
A 1
A 1
B 4
D 0
A 0
B 3
B 0
```

```
4 3
```

The nine instructions fit into four bundles with three stops.

## Idea

Run a dynamic program over instruction prefixes. With only three slots, a bundle offers at most four stop positions. Keep the best state for each group size, ranked by fewest bundles, then fewest stops, then latest last stop. Think of packing boxes on a shelf: for each shelf length, remember only the arrangement that leaves the most room for later boxes.

Templates are looked up through a stamp table with wildcards, so a match costs O(1). Each state spawns about 30 transitions, and pruning keeps the frontier small. Trying all packings would be exponential.

Takeaway: three slots mean a handful of states per prefix.

## Why It Works

1. A stop in the gap range d_i to i - 1 separates instruction i from the instruction it depends on.
2. An empty slot accepts any letter, so a template matches all 2 to the k variants of its occupied slots.
3. `beforeCount` counts occupied slots at or before the template stop slot.
4. `templateStop` is the gap `bundleStart + beforeCount - 1`, where that template places its stop.
5. A state with more bundles loses immediately; among equal bundle counts, one with fewer stops and a later last stop dominates.
6. `pruneInPlace` keeps only the best states, so the frontier stays bounded.

The state records three values.

| Term | Meaning |
| --- | --- |
| `bundles` | number of bundles used so far |
| `stops` | number of stops placed so far |
| `lastStop` | rightmost gap already marked by a stop |
| `beforeMaxDep`, `afterMaxDep` | largest dependencies on each side of a template stop |

A state that dominates another covers every dependency the other covers.

A script packed the sample instructions as follows:

| Instructions | Slots | Template | Stop gap |
| --- | --- | --- | --- |
| 1-2 | 2, 3 | ABB p=2 | 1 |
| 3-4 | 1, 2 | AAB p=0 | none |
| 5-6 | 1, 3 | BAD p=1 | 5 |
| 7-9 | 1, 2, 3 | ABB p=0 | none |

Four bundles and three stops match the printed answer.

## Code

**Constants, state type, and scanners.**
```nim
{.checks: off.}
{.optimization: speed.}

const wildcardType = 10
const typeCount = 11
const stopCount = 3
const slotCount = 3
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const firstLetterValue = 65
const tableSize = stopCount * typeCount * typeCount * typeCount

type
  BundleState = object
    bundles: int
    stops: int
    lastStop: int

proc nextInteger(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - firstDigitValue)
    i += 1
  return value

proc nextType(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < 'A' or inputData[i] > 'J'):
    i += 1
  let typeValue = ord(inputData[i]) - firstLetterValue
  i += 1
  return typeValue
```
`BundleState` stores bundles, stops, and lastStop. `nextInteger` and `nextType` read the profile and instruction stream. `tableSize` fixes the wildcard stamp table.

**Pruning.**
```nim
proc pruneInPlace(states: var seq[BundleState]) =
  if states.len == 0:
    return
  var minBundles = high(int)
  for stateValue in states:
    if stateValue.bundles < minBundles:
      minBundles = stateValue.bundles
  var j = 0
  for stateValue in states:
    if stateValue.bundles == minBundles:
      states[j] = stateValue
      j += 1
  states.setLen j
  for k in 1 .. states.len - 1:
    let current = states[k]
    var i = k - 1
    while i >= 0 and (states[i].stops > current.stops or
          (states[i].stops == current.stops and
           states[i].lastStop < current.lastStop)):
      states[i + 1] = states[i]
      i -= 1
    states[i + 1] = current
  j = 0
  var bestLast = -2
  for stateValue in states:
    if stateValue.lastStop > bestLast:
      states[j] = stateValue
      j += 1
      bestLast = stateValue.lastStop
  states.setLen j
```
The routine keeps only states with the fewest bundles, sorts by stops and lastStop, then keeps the best lastStop value. Each pass shrinks the frontier in place.

**Input and template stamps.**
```nim
var inputData = readStreamBytes()
var i = 0
let caseCount = nextInteger(inputData, i)
var templateStamp = newSeq[int](tableSize)
var currentStamp = 0
var outputBuffer = ""

for j in 0 .. caseCount - 1:
  currentStamp += 1
  let templateCount = nextInteger(inputData, i)
  let instructionCount = nextInteger(inputData, i)
  for k in 0 .. templateCount - 1:
    let firstLetter = nextType(inputData, i)
    let secondLetter = nextType(inputData, i)
    let thirdLetter = nextType(inputData, i)
    let l = nextInteger(inputData, i)
    for slotOne in [firstLetter, wildcardType]:
      for slotTwo in [secondLetter, wildcardType]:
        for slotThree in [thirdLetter, wildcardType]:
          let tableIndex = ((l * typeCount + slotOne) * typeCount + slotTwo) * typeCount + slotThree
          templateStamp[tableIndex] = currentStamp

  var instructionTypes = newSeq[int](instructionCount + 1)
  var dependencyIndices = newSeq[int](instructionCount + 1)
  for k in 1 .. instructionCount:
    instructionTypes[k] = nextType(inputData, i)
    dependencyIndices[k] = nextInteger(inputData, i)

  var stateLists: array[0 .. 3, seq[BundleState]]
  for k in 0 .. 3:
    stateLists[k] = newSeqOfCap[BundleState](16)
```
The code reads templates and marks every wildcard variant with `currentStamp`. Instruction types and dependencies fill two arrays. `stateLists` starts with one empty state.

**Transition loop.**
```nim
  for k in 0 .. instructionCount - 1:
    pruneInPlace stateLists[0]
    let bundleStart = k + 1

    var canSkipStop = [false, false, false, false]
    var canPlaceStop = [false, false, false, false, false, false, false, false,
                        false, false, false, false, false, false, false, false]
    for slotMask in 1 .. 7:
      var groupSize = 0
      for l in 0 .. slotCount - 1:
        if (slotMask and (1 shl l)) != 0:
          groupSize += 1
      if bundleStart + groupSize - 1 > instructionCount:
        continue
      var slotLetters = [wildcardType, wildcardType, wildcardType]
      var filledCount = 0
      for l in 0 .. slotCount - 1:
        if (slotMask and (1 shl l)) != 0:
          slotLetters[l] = instructionTypes[bundleStart + filledCount]
          filledCount += 1
      for i in 0 .. stopCount - 1:
        let tableIndex = ((i * typeCount + slotLetters[0]) * typeCount +
                          slotLetters[1]) * typeCount + slotLetters[2]
        if templateStamp[tableIndex] == currentStamp:
          if i == 0:
            canSkipStop[groupSize] = true
          else:
            var beforeCount = 0
            for j in 0 .. i - 1:
              if (slotMask and (1 shl j)) != 0:
                beforeCount += 1
            canPlaceStop[groupSize * 4 + beforeCount] = true

    var relevantDep = [-1, -1, -1, -1]
    for l in 0 .. 2:
      let position = bundleStart + l
      if position <= instructionCount and dependencyIndices[position] > 0:
        relevantDep[l] = dependencyIndices[position]

    for j in 0 .. stateLists[0].len - 1:
      let stateValue = stateLists[0][j]
      for groupSize in 1 .. 3:
        let nextEnd = k + groupSize
        if nextEnd > instructionCount:
          continue
        var bundleMaxDep = -1
        for l in 0 .. groupSize - 1:
          if relevantDep[l] > bundleMaxDep:
            bundleMaxDep = relevantDep[l]
        if canSkipStop[groupSize] and bundleMaxDep <= stateValue.lastStop:
          stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
              stops: stateValue.stops, lastStop: stateValue.lastStop)
          if nextEnd < instructionCount:
            stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
                stops: stateValue.stops + 1, lastStop: nextEnd)
        for beforeCount in 0 .. groupSize:
          if not canPlaceStop[groupSize * 4 + beforeCount]:
            continue
          let templateStop = bundleStart + beforeCount - 1
          var beforeMaxDep = -1
          for l in 0 .. beforeCount - 1:
            if relevantDep[l] > beforeMaxDep:
              beforeMaxDep = relevantDep[l]
          var afterMaxDep = -1
          for l in beforeCount .. groupSize - 1:
            if relevantDep[l] > afterMaxDep:
              afterMaxDep = relevantDep[l]
          if beforeMaxDep > stateValue.lastStop or afterMaxDep > templateStop:
            continue
          let extraStops = 1
          stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
              stops: stateValue.stops + extraStops, lastStop: templateStop)
          if nextEnd < instructionCount and nextEnd != templateStop:
            stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
                stops: stateValue.stops + extraStops + 1, lastStop: nextEnd)

    swap stateLists[0], stateLists[1]
    swap stateLists[1], stateLists[2]
    swap stateLists[2], stateLists[3]
    stateLists[3].setLen 0
```
Each group size from one to three is tested against the template stamp. Valid placements add new states to `stateLists`, then the four lists rotate by swap to advance one instruction.

**Final choice and output.**
```nim
  pruneInPlace stateLists[0]
  var bestBundles = high(int)
  var bestStops = high(int)
  for stateValue in stateLists[0]:
    if stateValue.bundles < bestBundles or
       (stateValue.bundles == bestBundles and stateValue.stops < bestStops):
      bestBundles = stateValue.bundles
      bestStops = stateValue.stops

  outputBuffer.add $bestBundles
  outputBuffer.add " "
  outputBuffer.add $bestStops
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```
After the last instruction, the program picks the best bundles and stops. Both values go into `outputBuffer`, which flushes at the block boundary.

## Complexity

Each instruction processes a bounded state set.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Template stamping | O(t times 8) | tableSize integers |
| Transitions | O(n times states times 30) | four state lists |
| Pruning | O(states log states) | same lists |
| Output | one write per block | flushBlockBytes |

The state count depends on the three-slot limit, not on n.

| Measure | Big O |
| --- | --- |
| Time per case | O(t + n times k) for small constant k |
| Space per case | O(t + n + states) |

Packing every subset of instructions would be exponential, while bounded-state dynamic programming scales linearly.
