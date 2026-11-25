# MELE2 — ELEVATOR II (SPOJ)

<https://www.spoj.com/problems/MELE2/>

## Problem

Count the floors reachable from floor one by pressing three up buttons, where a press that would pass the top floor does nothing.

The input holds one case. The first line gives the building height h. The second line gives the three step sizes a, b, and c.

Output the number of distinct floors reachable from floor one.

| item | bound |
|---|---|
| height h | 1 to 1000000000000000000 |
| step sizes a, b, c | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

The reset button returns the elevator to floor one. Presses that overshoot the top floor leave the elevator in place.

Sample input:

```
15
4 7 9
```

Sample output:

```
9
```

A second sample input:

```
500000
160 96 111
```

Second sample output:

```
498167
```

A third sample input:

```
987654321987654321
99995 99997 99999
```

Third sample output:

```
987654319487854318
```

## Idea

Grouping floors by remainder is like counting seats by row: once one seat in a row is reachable, every later seat in that row is reachable too.

Let m be the smallest step. Adding m never changes the floor modulo m, so each reachable remainder forms an arithmetic progression.

Find the least offset reachable in every remainder class with a shortest-path search. Then count the terms of each progression up to h minus one.

A floor-by-floor sweep cannot finish when h reaches 1e18.

Take the smallest step as the modulus, search the remainders, and add the arithmetic counts.

## Why It Works

1. Every reachable floor is floor one plus a nonnegative sum of a, b, and c.
2. A reset returns to floor one and adds no new offset.
3. Only sums at most h minus one give real floors.
4. If offset d is reachable, so is d plus any multiple of m.
5. Shortest paths on residues modulo m find the least reachable d in each class.

| term | meaning |
|---|---|
| `shortestSteps` | the smallest button step, used as modulus |
| `buttonSteps` | the three step sizes |
| `residueDistances` | least reachable offset for each residue |
| `highestOffset` | h minus one, the largest allowed offset |
| `reachableFloors` | sum of the arithmetic counts |

Every term above appears in the driver below.

For the first sample, m = 4 and h minus one is 14. The least offsets by residue are 0, 9, 14, and 7.

The counts are 4, 2, 1, and 2 floors. Their sum is 9.

Distances above h minus one are harmless because the counting step skips them. The 64-bit types hold heights up to 1e18 and offsets well beyond that bound.

## Code

**Input and modulus choice.** The reader loads the height and picks the smallest step as modulus.

```nim
const flushBlockBytes = 1 shl 17
const largeDistance = int64(1000000000000000000)

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

let buildingHeight = int64(nextInt(inputData, scanPos))
var buttonSteps = newSeq[int](3)
for buttonIndex in 0 .. 2:
  buttonSteps[buttonIndex] = nextInt(inputData, scanPos)
var shortestSteps = buttonSteps[0]
for buttonIndex in 1 .. 2:
  if buttonSteps[buttonIndex] < shortestSteps:
    shortestSteps = buttonSteps[buttonIndex]

var residueDistances = newSeq[int64](shortestSteps)
for residue in 0 .. shortestSteps - 1:
  residueDistances[residue] = largeDistance
residueDistances[0] = 0
```

Offsets count floors above floor one.
The modulus is at most 100000, so the distance array stays small.
The sentinel exceeds every relevant offset.

**Binary heap.** Two parallel arrays back a min-heap of pending residues.

```nim
var heapPriorities = newSeq[int64]()
var heapNodes = newSeq[int]()

proc heapPush(priority: int64, node: int) =
  heapPriorities.add priority
  heapNodes.add node
  var childIndex = heapPriorities.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapPriorities[parentIndex] <= heapPriorities[childIndex]:
      break
    swap(heapPriorities[parentIndex], heapPriorities[childIndex])
    swap(heapNodes[parentIndex], heapNodes[childIndex])
    childIndex = parentIndex

proc heapPop(): tuple[priority: int64, node: int] =
  result.priority = heapPriorities[0]
  result.node = heapNodes[0]
  let lastPriority = heapPriorities[heapPriorities.len - 1]
  let lastNode = heapNodes[heapNodes.len - 1]
  heapPriorities.setLen(heapPriorities.len - 1)
  heapNodes.setLen(heapNodes.len - 1)
  if heapPriorities.len > 0:
    heapPriorities[0] = lastPriority
    heapNodes[0] = lastNode
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= heapPriorities.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapPriorities.len and heapPriorities[rightChild] < heapPriorities[leftChild]:
        smallerChild = rightChild
      if heapPriorities[parentIndex] <= heapPriorities[smallerChild]:
        break
      swap(heapPriorities[parentIndex], heapPriorities[smallerChild])
      swap(heapNodes[parentIndex], heapNodes[smallerChild])
      parentIndex = smallerChild
```

Push sifts a new entry upward.
Pop moves the last entry to the root and sifts downward.
Each heap operation touches one path in the tree.

**Search and count.** Dijkstra finds least offsets; arithmetic gives the floor totals.

```nim
heapPush(0, 0)
while heapNodes.len > 0:
  let entry = heapPop()
  if entry.priority > residueDistances[entry.node]:
    continue
  for buttonIndex in 0 .. 2:
    let buttonStep = buttonSteps[buttonIndex]
    if buttonStep == shortestSteps:
      continue
    let nextResidue = (entry.node + buttonStep) mod shortestSteps
    let nextDistance = entry.priority + int64(buttonStep)
    if nextDistance < residueDistances[nextResidue]:
      residueDistances[nextResidue] = nextDistance
      heapPush(nextDistance, nextResidue)

let highestOffset = buildingHeight - 1
var reachableFloors: int64 = 0
for residue in 0 .. shortestSteps - 1:
  if residueDistances[residue] <= highestOffset:
    reachableFloors += (highestOffset - residueDistances[residue]) div int64(shortestSteps) + 1
appendOutput($reachableFloors)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The modulus step needs no edge because it keeps the residue.
Stale heap entries are skipped by the distance check.
One pass over residues produces the answer.

## Complexity

The heap search visits each residue a small number of times.

| phase | time | space |
|---|---|---|
| input read | one pass over four integers | three step slots |
| shortest paths | O(m log m) heap work | two arrays of m entries |
| counting | one pass over m residues | no extra arrays |

Here m means the smallest step size, which is at most 100000.

| measure | Big O |
|---|---|
| time | O(m log m) |
| space | O(m) |

A sweep over h floors would need 1e18 iterations for the largest cases.
Residue search depends only on the step sizes and finishes with about 100000 nodes.
