# AROUND — Around the World (SPOJ)

<https://www.spoj.com/problems/AROUND/>

## Problem

Farms sit at integer longitudes on a circle. Given flights along shortest arcs, find the shortest walk from farm 1 to itself whose clockwise distance differs from its counterclockwise distance.

Input begins with the test count `t`. Each case gives `N` and `M`, then `N` longitudes, then `M` lines of farm index pairs. Output one integer per case: the fewest flights, or `-1` when no such walk exists.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | first input line |
| Farms `N` | 1 ≤ N ≤ 5000 |
| Flights `M` | 1 ≤ M ≤ 25000 |
| Longitude | integer from 0 to 359 |
| Judge limit | 9000 ms, 1536 MB |

The flight count and the 360-degree circle drive the state design.

The sample case:

```
1
3 3
0
120
240
1 2
2 3
1 3
```

```
3
```

The answer is three flights.

## Idea

Record a signed degree total for every step, then search walks from farm 1 while remembering that total. The first return with a nonzero total is the answer. Think of a pedometer that reads 360 degrees after one lap instead of zero.

The algorithm is breadth-first search over states made of a farm and an exact degree total. A hash set marks states already reached, so each generated flight costs one average O(1) lookup. Enumerating walks of length k grows exponentially with k, while this search visits each state once and stops at the first valid return.

Track the signed total, not the farm longitude modulo 360.

## Why It Works

Four facts prove the search.

1. A flight follows the shorter arc, so its signed step lies strictly between -180 and 180. The spec forbids antipodal pairs, so the forward arc is never 180.
2. A closed walk returns to its starting longitude, so its signed total is a multiple of 360. Zero means equal travel in both directions. A nonzero multiple means the trip circles Earth.
3. Breadth-first search visits walks in increasing flight count. The first return to farm 1 with a nonzero total therefore uses the fewest flights.
4. Reaching the same farm with the same total and more flights never helps. Marking that state once is safe.

The main terms:

| Term | Meaning |
|---|---|
| `forward` | clockwise degrees from the start longitude to the end longitude |
| `signedStep` | `forward` when below 180, otherwise `forward - 360` |
| `stateKey` | `int64(updatedDegrees) * keyStride + int64(neighbourFarm)`, unique for every state |
| `travelledFlights` | flights used to reach the current state |

The key packs a state into one integer, so the visited set stays flat.

The sample produces this trace:

```
level 0: (1,0)
level 1: (2,120) (3,-120)
level 2: (3,240) (2,-240)
level 3: reach farm 1 with 360 degrees -> answer 3
```

The walk 1 → 2 → 3 → 1 adds 360 degrees and wins in three flights.

## Code

**Constants and bulk read.**

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const keyStride = 5001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```
The loop appends every line to one `inputData` string.
`firstDigitValue` supports the scanner, and `flushBlockBytes` sets the write block.
Cost: one pass over the input bytes.

**Integer scanner.**

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```
`nextInt` skips separators and builds values from digit bytes.
No token object or parse call is created.
Cost: one pass over each token digits.

**Output buffer.**

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```
`appendOutput` flushes when the buffer reaches `flushBlockBytes`.
`setLen 0` reuses the same allocation.
Cost: one append per answer line.

**Hash position.**

```nim
var hashSlots = newSeq[int64](1 shl 16)
var hashGenerations = newSeq[int](1 shl 16)
var hashMask = (1 shl 16) - 1
var hashUsed = 0
var currentGeneration = 1

proc hashPosition(key: int64): int =
  var mixed = cast[uint64](key) * 11400714819323198485'u64
  mixed = mixed xor (mixed shr 31)
  return int(mixed and uint64(hashMask))
```
`hashPosition` mixes the packed key into a power-of-two table.
`hashMask` replaces a slow modulo operation.
Cost: a few integer operations per lookup.

**Insertion and growth.**

```nim
proc rawInsert(key: int64) =
  var slot = hashPosition(key)
  while true:
    if hashGenerations[slot] != currentGeneration:
      hashGenerations[slot] = currentGeneration
      hashSlots[slot] = key
      hashUsed += 1
      return
    if hashSlots[slot] == key: return
    slot = (slot + 1) and hashMask

proc growHash() =
  let oldSlots = hashSlots
  let oldGenerations = hashGenerations
  let oldSize = oldSlots.len
  let oldGeneration = currentGeneration
  let newSize = oldSize shl 1
  hashSlots = newSeq[int64](newSize)
  hashGenerations = newSeq[int](newSize)
  hashMask = newSize - 1
  hashUsed = 0
  currentGeneration += 1
  for slot in 0 ..< oldSize:
    if oldGenerations[slot] == oldGeneration:
      rawInsert(oldSlots[slot])
```
`rawInsert` places a key in the first free slot.
`growHash` doubles the table and rehashes live keys.
Generation stamps avoid clearing the whole table per case.

**Visited-state test.**

```nim
proc seenOrAdd(key: int64): bool =
  if (hashUsed + 1) * 10 > (hashMask + 1) * 7: growHash()
  var slot = hashPosition(key)
  while true:
    if hashGenerations[slot] != currentGeneration:
      hashGenerations[slot] = currentGeneration
      hashSlots[slot] = key
      hashUsed += 1
      return false
    if hashSlots[slot] == key: return true
    slot = (slot + 1) and hashMask
```
`seenOrAdd` returns true when the state was already reached.
A generation stamp marks slots belonging to the current case.
Cost: one probe sequence per generated state.

**Flight representation.**

```nim
var longitudeOfFarm: seq[int]
var adjacencyHead: seq[int]
var adjacencyTarget: seq[int]
var adjacencyStep: seq[int]
var adjacencyNext: seq[int]
var currentNodes: seq[int]
var currentTotals: seq[int]
var nextNodes: seq[int]
var nextTotals: seq[int]

proc signedStep(startLongitude, endLongitude: int): int =
  let forward = (endLongitude - startLongitude + 360) mod 360
  if forward > 180: forward - 360 else: forward

proc addFlight(fromFarm, toFarm: int, edgeIndex: var int) =
  adjacencyTarget[edgeIndex] = toFarm
  adjacencyStep[edgeIndex] = signedStep(longitudeOfFarm[fromFarm], longitudeOfFarm[toFarm])
  adjacencyNext[edgeIndex] = adjacencyHead[fromFarm]
  adjacencyHead[fromFarm] = edgeIndex
  edgeIndex += 1
```
`signedStep` takes the shorter arc between two longitudes.
When `forward` exceeds 180, the step becomes negative.
Flat adjacency arrays hold two arcs per flight.

**Layered search.**

```nim
proc shortestTour(): int =
  currentGeneration += 1
  hashUsed = 0
  discard seenOrAdd(int64(1))
  currentNodes.setLen 1
  currentNodes[0] = 1
  currentTotals.setLen 1
  currentTotals[0] = 0
  var travelledFlights = 0
  while currentNodes.len > 0:
    nextNodes.setLen 0
    nextTotals.setLen 0
    for position in 0 ..< currentNodes.len:
      let currentFarm = currentNodes[position]
      let accumulatedDegrees = currentTotals[position]
      var edgeIndex = adjacencyHead[currentFarm]
      while edgeIndex != -1:
        let neighbourFarm = adjacencyTarget[edgeIndex]
        let updatedDegrees = accumulatedDegrees + adjacencyStep[edgeIndex]
        if neighbourFarm == 1 and updatedDegrees != 0:
          return travelledFlights + 1
        let stateKey = int64(updatedDegrees) * keyStride + int64(neighbourFarm)
        if not seenOrAdd(stateKey):
          nextNodes.add neighbourFarm
          nextTotals.add updatedDegrees
        edgeIndex = adjacencyNext[edgeIndex]
    swap currentNodes, nextNodes
    swap currentTotals, nextTotals
    travelledFlights += 1
  return -1
```
`travelledFlights` counts the layers of the search.
The test `neighbourFarm == 1 and updatedDegrees != 0` rejects a zero-winding return.
`swap` reuses both frontier arrays instead of allocating new ones.

**Driver.**

```nim
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let farmCount = nextInt(inputData, scanPos)
  let flightCount = nextInt(inputData, scanPos)
  longitudeOfFarm.setLen farmCount + 1
  for farm in 1 .. farmCount:
    longitudeOfFarm[farm] = nextInt(inputData, scanPos)
  adjacencyHead.setLen farmCount + 1
  for farm in 1 .. farmCount:
    adjacencyHead[farm] = -1
  adjacencyTarget.setLen flightCount * 2
  adjacencyStep.setLen flightCount * 2
  adjacencyNext.setLen flightCount * 2
  var edgeIndex = 0
  for flight in 0 ..< flightCount:
    let departureFarm = nextInt(inputData, scanPos)
    let arrivalFarm = nextInt(inputData, scanPos)
    addFlight(departureFarm, arrivalFarm, edgeIndex)
    addFlight(arrivalFarm, departureFarm, edgeIndex)
  appendOutput($(shortestTour()))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
The driver reads `farmCount`, `flightCount`, longitudes, then flights.
Each flight adds both travel directions.
The final `stdout.write` emits the tail of the buffer.

## Complexity

Here `S` is the number of distinct farm and degree states reached.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Graph build | two arcs per flight | 2M integers plus farm heads |
| Search | one hash lookup per generated state | reached states plus frontier |
| Output | one write per 128 KiB block | block buffer |

The work follows visited states, not the test count alone.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(S + input bytes + output bytes) |
| Space | O(S + N + M) |

Enumerating walks to depth d costs exponential time, while this search stops at the first valid return.
