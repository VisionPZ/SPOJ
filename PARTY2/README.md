# PARTY2 — Party of Cloaked Killers (SPOJ)

<https://www.spoj.com/problems/PARTY2/>

## Problem

N killers are split into M nonempty groups numbered 1 through M. A killer in group x can see killers in group x mod M plus 1, even when they are cloaked. Given some reported sightings, find the largest and smallest M consistent with every report, or report contradiction.

The reports are incomplete, so a missing sighting gives no information. A report A to B forces the group of B to be one step after the group of A, counted cyclically. Groups are nonempty, so M never exceeds N.

Input holds ten blocks in sequence. Each block starts with N and E, followed by E lines of two killer numbers, A and B, meaning A can see B. There is no leading test count. Output has one line per block: largest M first, then smallest M, or `-1 -1` when the reports contradict each other. Here `-1 -1` is an exact output string defined by this contract.

The statement prints two concrete cases and abbreviates the remaining eight.

The bounds size the graph:

| item | bound |
|---|---|
| killers N | 1 to 100000 |
| sightings E | 1 to 180000 |
| groups M | at least 3, at most N |
| test blocks | exactly 10 |
| judge limit | 500 ms, 1536 MB |

The edge count drives the scan, and the cycle lengths drive the answer.

Sample input:

```
6 5
1 2
2 3
3 4
4 1
3 5
3 3
1 2
2 1
2 3
```

Sample output:

```
4 4
-1 -1
```

## Idea

Numbering groups is like numbering seats around a circular table. Every sighting says the next person sits one seat along, so walking around a closed chain of sightings must bring you back to the same seat.

Give each killer an integer level with each sighting increasing the level by 1. A spanning walk over the sighting graph assigns those levels. For any sighting, the difference between the target level and the source level minus 1 measures how far that sighting misses a perfect step. The gcd of all those differences is the length that every cycle must divide.

A valid group count divides that gcd and is at least 3. With no cycle constraint, any count from 3 to N works, so the largest is N. Otherwise the gcd itself is the largest count, and the smallest is its smallest divisor of at least 3.

## Why It Works

1. A sighting A to B requires level(B) to be congruent to level(A) plus 1 modulo M.
2. Walking along sightings raises the level by 1; walking backward lowers it by 1.
3. A depth-first walk assigns integer levels to a whole weakly connected component with one arbitrary offset.
4. For a sighting from A to B, the shift level(B) minus level(A) minus 1 is independent of that offset.
5. Around any cycle, the shifts sum to minus the cycle length, so each legal M divides the gcd of all shifts.
6. Conversely, when M divides every shift, the levels taken modulo M give a valid group assignment.
7. A cycle on L distinct killers visits every residue modulo any divisor of L, so each chosen group is nonempty.
8. When `cycleGcd` is zero, no sighting closes a cycle, so the count can reach N.

Terms and formulas:

| term | meaning |
|---|---|
| `levels` | integer step number assigned to each killer |
| `cycleGcd` | gcd of all sighting shifts, hence of all cycle lengths |
| `minimumGroupCount` | lower bound 3 on the number of groups |
| `smallestGroups` | smallest divisor of `cycleGcd` that is at least 3 |

The gcd summarizes every cycle at once, without enumerating cycles.

The sample trace from gen.py:

```
levels [0, 1, 2, 3, 3, 0] shifts [0, 0, 0, -4, 0]
levels [0, 1, 2] shifts [0, -2, 0]
```

The first block has gcd 4, giving 4 4. The second has gcd 2, which has no divisor of at least 3, giving `-1 -1`.

## Code

**Input and graph storage.** The reader builds forward and backward edge lists for each block.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const minimumGroupCount = 3

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

proc gcdValues(leftValue, rightValue: int): int =
  var firstValue = leftValue
  var secondValue = rightValue
  while secondValue != 0:
    let remainder = firstValue mod secondValue
    firstValue = secondValue
    secondValue = remainder
  return firstValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One sentinel value marks the end of each adjacency chain.
Both directions use the same edge arrays, so memory stays linear in E.
The scanner reads all ten blocks without a block count.

**Level assignment.** A stack walk covers each weak component once and sets integer levels.

```nim
while scanPos < inputData.len:
  let killerCount = nextInt(inputData, scanPos)
  let sightingCount = nextInt(inputData, scanPos)
  if killerCount <= 0 or sightingCount <= 0:
    break
  var outgoingHead = newSeq[int](killerCount)
  var incomingHead = newSeq[int](killerCount)
  var edgeSource = newSeq[int](sightingCount)
  var edgeTarget = newSeq[int](sightingCount)
  var nextOutgoing = newSeq[int](sightingCount)
  var nextIncoming = newSeq[int](sightingCount)
  for headIndex in 0 .. killerCount - 1:
    outgoingHead[headIndex] = -1
    incomingHead[headIndex] = -1
  for edgeIndex in 0 .. sightingCount - 1:
    let sourceKiller = nextInt(inputData, scanPos) - 1
    let targetKiller = nextInt(inputData, scanPos) - 1
    edgeSource[edgeIndex] = sourceKiller
    edgeTarget[edgeIndex] = targetKiller
    nextOutgoing[edgeIndex] = outgoingHead[sourceKiller]
    outgoingHead[sourceKiller] = edgeIndex
    nextIncoming[edgeIndex] = incomingHead[targetKiller]
    incomingHead[targetKiller] = edgeIndex
  var levels = newSeq[int](killerCount)
  var visited = newSeq[bool](killerCount)
  var traversalStack = newSeq[int](killerCount)
  for startKiller in 0 .. killerCount - 1:
    if visited[startKiller]:
      continue
    levels[startKiller] = 0
    visited[startKiller] = true
    var stackTop = 0
    traversalStack[stackTop] = startKiller
    stackTop += 1
    while stackTop > 0:
      stackTop -= 1
      let currentKiller = traversalStack[stackTop]
      var edgeIndex = outgoingHead[currentKiller]
      while edgeIndex != -1:
        let neighborKiller = edgeTarget[edgeIndex]
        if not visited[neighborKiller]:
          levels[neighborKiller] = levels[currentKiller] + 1
          visited[neighborKiller] = true
          traversalStack[stackTop] = neighborKiller
          stackTop += 1
        edgeIndex = nextOutgoing[edgeIndex]
      edgeIndex = incomingHead[currentKiller]
      while edgeIndex != -1:
        let neighborKiller = edgeSource[edgeIndex]
        if not visited[neighborKiller]:
          levels[neighborKiller] = levels[currentKiller] - 1
          visited[neighborKiller] = true
          traversalStack[stackTop] = neighborKiller
          stackTop += 1
        edgeIndex = nextIncoming[edgeIndex]
```

Each killer enters the stack once, so the walk stays linear.
Following incoming edges adds one to a level when read backward.
The stack array holds at most one entry per killer.

**Gcd and verdict.** Every sighting contributes one shift, and the gcd settles the answer.

```nim
  var cycleGcd = 0
  for edgeIndex in 0 .. sightingCount - 1:
    let shift = levels[edgeTarget[edgeIndex]] - levels[edgeSource[edgeIndex]] - 1
    if shift < 0:
      cycleGcd = gcdValues(cycleGcd, -shift)
    else:
      cycleGcd = gcdValues(cycleGcd, shift)
  if cycleGcd == 0:
    appendOutput($killerCount & " " & $minimumGroupCount)
  elif cycleGcd < minimumGroupCount:
    appendOutput("-1 -1")
  else:
    var smallestGroups = cycleGcd
    for candidate in minimumGroupCount .. cycleGcd:
      if cycleGcd mod candidate == 0:
        smallestGroups = candidate
        break
    appendOutput($cycleGcd & " " & $smallestGroups)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The absolute shift keeps the gcd nonnegative.
A gcd below 3 rules out every legal group count.
The divisor scan stops at the first valid count of at least 3.

## Complexity

Graph storage, level assignment and the gcd pass each scale with edges.

| phase | time | space |
|---|---|---|
| input read | one pass over E sightings | one input string |
| graph build | one insert per sighting | six arrays sized N or E |
| level assignment | one visit per killer and edge | levels, visited and stack arrays |
| gcd and verdict | one gcd step per sighting | constant |

The stack visits each vertex once because `visited` blocks repeats.

| measure | Big O |
|---|---|
| time | O(N + E) per block |
| space | O(N + E) |

Testing each group count separately costs quadratic work, while one gcd pass settles all counts at once.
The fixed ten blocks keep total work proportional to total input size.
