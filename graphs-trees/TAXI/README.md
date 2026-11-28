# TAXI — Taxi (SPOJ)

<https://www.spoj.com/problems/TAXI/>

## Problem

Each case lists people and taxis waiting at street crossings, with a taxi speed and a collection time. Report the largest number of people a taxi can collect within that time.

Input: `k`, then `k` cases. Each case gives `p`, `t`, `s`, `c`, followed by `p` person positions and `t` taxi positions. Each position holds two integer grid coordinates.

Output: one line per case with the maximum number of people collected.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `k` | at most 250 |
| People `p` | 1 to 400 |
| Taxis `t` | 1 to 200 |
| Speed `s` | 1 to 2000 meters per second |
| Collection time `c` | 1 to 1000000 seconds |
| Grid spacing | 200 meters |
| Judge limit | 22 seconds, 1536 MB |

The largest case holds 400 people and 200 taxis, so the answer never exceeds 200.

The sample from the statement:

```
1
2 3 10 40
2 5
5 2
2 3
4 1
4 4
```

```
2
```

Both people get a taxi, so the answer is 2.

## Idea

Turn the street grid until each diamond-shaped reach area becomes a square, then match people to taxis. Think of rotating a tilted photograph until its edges line up with the page.

For each position, write `coordX + coordY` and `coordX - coordY`. In these two axes, walking distance becomes the larger coordinate gap. A taxi reaches a person when both gaps fit the time budget.

The program builds one graph per case and runs Hopcroft–Karp bipartite matching on it. Graph construction costs one distance check per person–taxi pair, at most 80 000 checks. Each matching phase scans the edge table once, and a few dozen phases finish a dense case.

Trying every taxi assignment grows exponentially, and a plain one-path augmenting search repeats scans. Layered search finds many shortest paths in one phase, so it finishes sooner.

One rotation turns street distances into a square graph, and the square graph yields fast matching.

## Why It Works

Four facts carry the proof.

1. Streets meet at right angles, so the walk length is the horizontal gap plus the vertical gap.
2. For gaps a and b, the larger of a + b and a - b equals |a| + |b|. The two new axes keep every distance exactly.
3. A taxi reaches a person exactly when `gridSpacingMeters * walkingDistance <= reachLimit`.
4. Each taxi carries one person, so the reachable pairs form a bipartite graph. Hopcroft–Karp returns its largest matching.

The formula table names each piece:

| Term | Meaning |
|---|---|
| `coordX + coordY` | first axis after rotation |
| `coordX - coordY` | second axis after rotation |
| `walkingDistance` | larger gap between two positions |
| `gridSpacingMeters * walkingDistance <= reachLimit` | reachable pair test |
| `searchLayers()` | builds layers of shortest augmenting paths |
| `augment(personIdx)` | flips one matched path |

Every edge means the taxi arrives before the time limit.

Here is the sample case traced by a script:

```
sample: speed 10, time 40, reach 400 m = 2 blocks
person (2,5) u=  7 v= -3  taxi (2,3) u=  5 v= -1  gap=2  reach=OK
person (2,5) u=  7 v= -3  taxi (4,1) u=  5 v=  3  gap=6  reach=no
person (2,5) u=  7 v= -3  taxi (4,4) u=  8 v=  0  gap=3  reach=no
person (5,2) u=  7 v=  3  taxi (2,3) u=  5 v= -1  gap=4  reach=no
person (5,2) u=  7 v=  3  taxi (4,1) u=  5 v=  3  gap=2  reach=OK
person (5,2) u=  7 v=  3  taxi (4,4) u=  8 v=  0  gap=3  reach=no
edges: (2,5)-(2,3), (5,2)-(4,1)
matching size: 2
```

The two edges form a matching of size 2, which is the sample answer.

## Code

**Input reader.** `nextLong` scans digits by index, so no token object is built.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unassigned = -1
const gridSpacingMeters: int64 = 200

proc nextLong(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var negative = false
  if scanPos < inputData.len and inputData[scanPos] == '-':
    negative = true
    scanPos += 1
  var value: int64 = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  if negative:
    return -value
  return value

proc absLong(value: int64): int64 =
  if value < 0: -value else: value
```

The sign branch keeps negative coordinates correct. `firstDigitValue` converts one digit byte. The reader touches each input byte once.

**Matching engine.** `augment` and `searchLayers` grow a layered matching.

```nim
var personU: seq[int64]
var personV: seq[int64]
var taxiU: seq[int64]
var taxiV: seq[int64]
var edgeTargets: seq[int]
var edgeStarts: seq[int]
var pairPerson: seq[int]
var pairTaxi: seq[int]
var distPerson: seq[int]
var queuePersons: seq[int]
var nilPersonIndex = 0

proc augment(personIdx: int): bool =
  for edgeIdx in edgeStarts[personIdx] ..< edgeStarts[personIdx + 1]:
    let taxiIdx = edgeTargets[edgeIdx]
    let matchedPerson = pairTaxi[taxiIdx]
    let nextPerson = if matchedPerson == unassigned: nilPersonIndex else: matchedPerson
    if distPerson[nextPerson] == distPerson[personIdx] + 1:
      if matchedPerson == unassigned or augment(matchedPerson):
        pairPerson[personIdx] = taxiIdx
        pairTaxi[taxiIdx] = personIdx
        return true
  distPerson[personIdx] = high(int)
  return false

proc searchLayers(): bool =
  var queueHead = 0
  var queueTail = 0
  for personIdx in 0 ..< nilPersonIndex:
    if pairPerson[personIdx] == unassigned:
      distPerson[personIdx] = 0
      queuePersons[queueTail] = personIdx
      queueTail += 1
    else:
      distPerson[personIdx] = high(int)
  distPerson[nilPersonIndex] = high(int)
  while queueHead < queueTail:
    let personIdx = queuePersons[queueHead]
    queueHead += 1
    if distPerson[personIdx] >= distPerson[nilPersonIndex]:
      continue
    for edgeIdx in edgeStarts[personIdx] ..< edgeStarts[personIdx + 1]:
      let taxiIdx = edgeTargets[edgeIdx]
      let matchedPerson = pairTaxi[taxiIdx]
      let nextPerson = if matchedPerson == unassigned: nilPersonIndex else: matchedPerson
      if distPerson[nextPerson] == high(int):
        distPerson[nextPerson] = distPerson[personIdx] + 1
        if matchedPerson != unassigned:
          queuePersons[queueTail] = matchedPerson
          queueTail += 1
  return distPerson[nilPersonIndex] != high(int)
```

`nilPersonIndex` is the free-taxi endpoint, so one distance array serves both sides. `augment` flips a path and marks dead ends. `searchLayers` stops at the shortest path, so one phase costs one edge scan.

**Driver.** One read, one flat edge table per case, and block writes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
let caseCount = int(nextLong(inputData, scanPos))
var outputBuffer = ""

for caseIdx in 0 ..< caseCount:
  let personCount = int(nextLong(inputData, scanPos))
  let taxiCount = int(nextLong(inputData, scanPos))
  let speedMetersPerSecond = nextLong(inputData, scanPos)
  let collectSeconds = nextLong(inputData, scanPos)
  let reachLimit = speedMetersPerSecond * collectSeconds

  personU.setLen(personCount)
  personV.setLen(personCount)
  for personIdx in 0 ..< personCount:
    let coordX = nextLong(inputData, scanPos)
    let coordY = nextLong(inputData, scanPos)
    personU[personIdx] = coordX + coordY
    personV[personIdx] = coordX - coordY

  taxiU.setLen(taxiCount)
  taxiV.setLen(taxiCount)
  for taxiIdx in 0 ..< taxiCount:
    let coordX = nextLong(inputData, scanPos)
    let coordY = nextLong(inputData, scanPos)
    taxiU[taxiIdx] = coordX + coordY
    taxiV[taxiIdx] = coordX - coordY

  edgeTargets.setLen(0)
  edgeStarts.setLen(personCount + 1)
  edgeStarts[0] = 0
  for personIdx in 0 ..< personCount:
    for taxiIdx in 0 ..< taxiCount:
      let deltaU = absLong(personU[personIdx] - taxiU[taxiIdx])
      let deltaV = absLong(personV[personIdx] - taxiV[taxiIdx])
      let walkingDistance = if deltaU > deltaV: deltaU else: deltaV
      if gridSpacingMeters * walkingDistance <= reachLimit:
        edgeTargets.add taxiIdx
    edgeStarts[personIdx + 1] = edgeTargets.len

  nilPersonIndex = personCount
  pairPerson.setLen(personCount)
  pairTaxi.setLen(taxiCount)
  distPerson.setLen(personCount + 1)
  queuePersons.setLen(personCount)
  for personIdx in 0 ..< personCount:
    pairPerson[personIdx] = unassigned
  for taxiIdx in 0 ..< taxiCount:
    pairTaxi[taxiIdx] = unassigned

  while searchLayers():
    for personIdx in 0 ..< nilPersonIndex:
      if pairPerson[personIdx] == unassigned:
        discard augment(personIdx)

  var matchedCount = 0
  for personIdx in 0 ..< nilPersonIndex:
    if pairPerson[personIdx] != unassigned:
      matchedCount += 1

  outputBuffer.add $matchedCount
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

`edgeStarts` holds offsets into `edgeTargets`, so no per-person list is built. The reach test uses 64-bit products. `outputBuffer` flushes at `flushBlockBytes`, then one final write emits the tail.

## Complexity

The work splits into input parsing, graph building, and matching.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the stream | input bytes |
| Graph build | p × t checks per case | up to 80 000 edge slots |
| Matching | about sqrt(p + t) edge scans per case | two arrays and one queue |
| Output | one block write and one tail write | block buffer |

The largest case uses 80 000 edges and a few hundred matching steps.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(k · p · t · sqrt(p + t)) |
| Space | O(p · t + input bytes) |

Trying every taxi assignment costs O(t^p), while layered matching stays polynomial. The polynomial bound keeps all 250 cases practical.
