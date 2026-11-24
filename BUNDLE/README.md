## Problem

Read a bundling profile and an instruction sequence. Each template allows one type in each of three slots and may force one stop. Pack every run of one to three successive instructions into a bundle that matches a template. Print the fewest bundles, then the fewest stops for that bundle count.

| Quantity | Bound |
| --- | --- |
| Templates per case | 1500 |
| Instructions per case | 100000 |
| Instruction types | 10 |
| Time limit | 1053 ms |
| Memory limit | 1536 MB |

The largest case holds 100000 instructions, so the program does constant work per instruction.

## Idea

Each bundle puts its one to three instructions into any slots of a three-slot container, and a template may force one stop. With only three slots, a bundle offers at most four stop positions, so a dynamic program can try them all. It keeps the best state after each prefix: fewest bundles, then fewest stops, then the latest last stop.

Each state expands into about 30 transitions. A state with no more stops and a later last stop makes other states unnecessary.

## Why It Works

A gap sits between two consecutive instructions. Instruction i depends on instruction d_i, so a stop in the gap range d_i to i-1 separates them. An empty slot accepts any letter in the template.

The program counts the occupied slots at or before the template's stop slot. It calls that count `beforeCount`. The stop lands at gap `bundleStart + beforeCount - 1`. The instructions before that gap need dependencies at most `lastStop`. The instructions after it need dependencies at most `templateStop`.

- `beforeCount` counts occupied slots at or before the template stop slot
- `templateStop` marks the gap where that template places its stop
- `beforeMaxDep` holds the largest dependency before the template stop
- `afterMaxDep` holds the largest dependency after the template stop
- `lastStop` holds the rightmost gap already marked by a stop

A state with more bundles loses at once. The program adds one boundary stop and copies the rest of the packing at the same bundle cost. Among states with equal bundles, one with no more stops and a later last stop covers every dependency the other covers.

The sample packs as follows.

| Instructions | Slots | Template | Stop gap |
| --- | --- | --- | --- |
| 1-2 | 2,3 | ABB p=2 | 1 |
| 3-4 | 1,2 | AAB p=0 | none |
| 5-6 | 1,3 | BAD p=1 | 5 |
| 7-9 | 1,2,3 | ABB p=0 | none |

The boundary stop at gap 4 joins the two template stops, so the answer is 4 bundles and 3 stops.

## Code

```nim
proc nextInteger(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (ord(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return value

proc nextType(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < 'A' or inputData[scanPos] > 'J'):
    scanPos += 1
  let typeValue = ord(inputData[scanPos]) - firstLetterValue
  scanPos += 1
  return typeValue
```

The first loop stops at the end of a digit run, so it reads one integer. The second loop reads one type letter. Both skip the other characters, which avoids token objects. Each call advances the pointer once per consumed character.

```nim
proc pruneInPlace(states: var seq[BundleState]) =
  if states.len == 0:
    return
  var minBundles = high(int)
  for stateValue in states:
    if stateValue.bundles < minBundles:
      minBundles = stateValue.bundles
  var writePos = 0
  for stateValue in states:
    if stateValue.bundles == minBundles:
      states[writePos] = stateValue
      writePos += 1
  states.setLen writePos
  for indexValue in 1 .. states.len - 1:
    let current = states[indexValue]
    var leftIndex = indexValue - 1
    while leftIndex >= 0 and (states[leftIndex].stops > current.stops or
          (states[leftIndex].stops == current.stops and
           states[leftIndex].lastStop < current.lastStop)):
      states[leftIndex + 1] = states[leftIndex]
      leftIndex -= 1
    states[leftIndex + 1] = current
  writePos = 0
  var bestLast = -2
  for stateValue in states:
    if stateValue.lastStop > bestLast:
      states[writePos] = stateValue
      writePos += 1
      bestLast = stateValue.lastStop
  states.setLen writePos
```

The first pass keeps the smallest bundle count. Insertion sort orders the few survivors without a comparator. The last pass keeps a state only when its last stop moves later. The sort and both passes reuse the same storage.

```nim
  for bundleEnd in 0 .. instructionCount - 1:
    pruneInPlace stateLists[0]
    let bundleStart = bundleEnd + 1

    var canSkipStop = [false, false, false, false]
    var canPlaceStop = [false, false, false, false, false, false, false, false,
                        false, false, false, false, false, false, false, false]
    for slotMask in 1 .. 7:
      var groupSize = 0
      for slotIndex in 0 .. slotCount - 1:
        if (slotMask and (1 shl slotIndex)) != 0:
          groupSize += 1
      if bundleStart + groupSize - 1 > instructionCount:
        continue
      var slotLetters = [wildcardType, wildcardType, wildcardType]
      var filledCount = 0
      for slotIndex in 0 .. slotCount - 1:
        if (slotMask and (1 shl slotIndex)) != 0:
          slotLetters[slotIndex] = instructionTypes[bundleStart + filledCount]
          filledCount += 1
      for stopPosition in 0 .. stopCount - 1:
        let tableIndex = ((stopPosition * typeCount + slotLetters[0]) * typeCount +
                          slotLetters[1]) * typeCount + slotLetters[2]
        if templateStamp[tableIndex] == currentStamp:
          if stopPosition == 0:
            canSkipStop[groupSize] = true
          else:
            var beforeCount = 0
            for slotIndex in 0 .. stopPosition - 1:
              if (slotMask and (1 shl slotIndex)) != 0:
                beforeCount += 1
            canPlaceStop[groupSize * 4 + beforeCount] = true

    var relevantDep = [-1, -1, -1, -1]
    for ahead in 0 .. 2:
      let position = bundleStart + ahead
      if position <= instructionCount and dependencyIndices[position] > 0:
        relevantDep[ahead] = dependencyIndices[position]
```

The mask loop visits all seven nonempty slot subsets, so group sizes 1 to 3 are covered. Wildcards in `slotLetters` let a template match a partially filled bundle. A stamp in `templateStamp` marks the current case, which avoids clearing the table. The cost is 21 lookups per prefix.

```nim
    for stateIndex in 0 .. stateLists[0].len - 1:
      let stateValue = stateLists[0][stateIndex]
      for groupSize in 1 .. 3:
        let nextEnd = bundleEnd + groupSize
        if nextEnd > instructionCount:
          continue
        var bundleMaxDep = -1
        for ahead in 0 .. groupSize - 1:
          if relevantDep[ahead] > bundleMaxDep:
            bundleMaxDep = relevantDep[ahead]
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
          for ahead in 0 .. beforeCount - 1:
            if relevantDep[ahead] > beforeMaxDep:
              beforeMaxDep = relevantDep[ahead]
          var afterMaxDep = -1
          for ahead in beforeCount .. groupSize - 1:
            if relevantDep[ahead] > afterMaxDep:
              afterMaxDep = relevantDep[ahead]
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

The loop tries each group size and each possible template stop. It checks both dependency halves before adding a state. Every template with a stop adds one count at that gap. The swaps move the state lists one prefix forward without copying.

```nim
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

The buffer flushes when it passes `flushBlockBytes`. The final flush emits the remainder. Writes stay in blocks, so the cost is one write per 256 KiB.

## Complexity

Input scanning costs one pass over the buffer, and the profile stamps use 3993 entries. Option precompute costs 21 lookups per instruction. The dynamic program expands a few states per prefix, so it costs O(n) time with a small constant. The whole program uses O(n) time and O(n) space.

A direct search tries every template at every prefix and costs O(n t). The profile stamps remove that factor by answering each template check in one lookup.
