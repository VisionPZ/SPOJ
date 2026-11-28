# RDRUG — Rage Drug (SPOJ)

<https://www.spoj.com/problems/RDRUG/>

## Problem

Several atoms already form separate compounds. Spend one new bond per atom at most and join every compound into one, with the lowest total of bonded atomic masses. Print the minimum energy, or -1 when the join cannot be made.

Input starts with the test count. Each case gives atom count and bond count, then the existing bonds, then one atomic mass per atom. Print one answer per case.

| item | bound |
|---|---|
| tests T | 1 to 12 |
| atoms N | 1 to 100000 |
| existing bonds M | 0 to 1000000 |
| atomic mass | 1 to 10000 |
| judge limit | 2000 ms, 1536 MB |

An already connected set needs no new bond.

Sample input:

```
2
6 6
1 2
2 3
1 3
4 5
5 6
4 6
1
3
5
2
4
6
4 0
1
2
3
4
```

Sample output:

```
3
-1
```

## Idea

Think of each compound as a suitcase that must carry at least one new strap, like tying boxes into one pile. A spanning tree of compounds uses exactly one bond per join and two atom slots per bond.

Take the cheapest atom from every compound, then add the cheapest remaining atoms until enough slots exist. A union-find pass finds the compounds, and one sort orders the atoms by mass.

## Why It Works

1. New bonds join different compounds, so the compounds form a tree.
2. A tree on k compounds uses k-1 bonds and 2(k-1) atom slots.
3. Every compound needs at least one slot, so its cheapest atom is mandatory.
4. Extra slots come from the remaining atoms in increasing mass order.
5. Any positive degree sequence summing to 2(k-1) forms a tree, so the chosen slots always connect.

| term | meaning |
|---|---|
| `parentSeq` | union-find parent for each atom |
| `componentCount` | number of existing compounds |
| `extraSlotsNeeded` | additional atoms beyond one per compound |
| `rootMultiplier` | packing factor for mass and root in one integer |

Script-generated trace for the first sample case:

| compound | masses | mandatory | extra |
|---|---|---|---|
| one | 1, 3, 5 | 1 | none |
| two | 2, 4, 6 | 2 | none |

Two compounds need k-2 = 0 extra slots, so the total is 1 + 2 = 3.

## Code

**Input, output, and union-find helpers.** Bonds are merged as they are read.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const rootShiftBits = 17
const rootMultiplier = 1 shl rootShiftBits
const impossibleAnswer = -1

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

proc findRoot(parentSeq: var seq[int], atom: int): int =
  var current = atom
  while parentSeq[current] != current:
    parentSeq[current] = parentSeq[parentSeq[current]]
    current = parentSeq[current]
  return current

proc unionAtoms(parentSeq: var seq[int], sizeSeq: var seq[int], leftAtom: int, rightAtom: int) =
  var leftRoot = findRoot(parentSeq, leftAtom)
  var rightRoot = findRoot(parentSeq, rightAtom)
  if leftRoot == rightRoot:
    return
  if sizeSeq[leftRoot] < sizeSeq[rightRoot]:
    let swapRoot = leftRoot
    leftRoot = rightRoot
    rightRoot = swapRoot
  parentSeq[rightRoot] = leftRoot
  sizeSeq[leftRoot] = sizeSeq[leftRoot] + sizeSeq[rightRoot]

proc compareEncoded(leftValue: int, rightValue: int): int =
  return leftValue - rightValue
```

Path compression keeps merges nearly constant time.
The comparator works on packed mass-and-root integers.
Output stays buffered until the end of the run.

**Compound counting and slot choice.** One sort determines the whole answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let atomCount = nextInt(inputData, scanPos)
  let bondCount = nextInt(inputData, scanPos)
  var parentSeq = newSeq[int](atomCount)
  var sizeSeq = newSeq[int](atomCount)
  for atomIndex in 0 .. atomCount - 1:
    parentSeq[atomIndex] = atomIndex
    sizeSeq[atomIndex] = 1
  for bondIndex in 0 .. bondCount - 1:
    let leftAtom = nextInt(inputData, scanPos) - 1
    let rightAtom = nextInt(inputData, scanPos) - 1
    unionAtoms(parentSeq, sizeSeq, leftAtom, rightAtom)
  var atomicMasses = newSeq[int](atomCount)
  for atomIndex in 0 .. atomCount - 1:
    atomicMasses[atomIndex] = nextInt(inputData, scanPos)
  var componentSeen = newSeq[bool](atomCount)
  var componentCount = 0
  for atomIndex in 0 .. atomCount - 1:
    let rootIndex = findRoot(parentSeq, atomIndex)
    if not componentSeen[rootIndex]:
      componentSeen[rootIndex] = true
      componentCount += 1
  if componentCount == 1:
    appendOutput("0\n")
    continue
  var encodedMasses = newSeq[int](atomCount)
  for atomIndex in 0 .. atomCount - 1:
    let rootIndex = findRoot(parentSeq, atomIndex)
    encodedMasses[atomIndex] = atomicMasses[atomIndex] * rootMultiplier + rootIndex
  encodedMasses.sort(compareEncoded)
  var componentChosen = newSeq[bool](atomCount)
  var extraSlotsNeeded = componentCount - 2
  var totalEnergy: int64 = 0
  for atomIndex in 0 .. atomCount - 1:
    let encoded = encodedMasses[atomIndex]
    let mass = encoded div rootMultiplier
    let rootIndex = encoded mod rootMultiplier
    if not componentChosen[rootIndex]:
      componentChosen[rootIndex] = true
      totalEnergy = totalEnergy + int64(mass)
    elif extraSlotsNeeded > 0:
      totalEnergy = totalEnergy + int64(mass)
      extraSlotsNeeded -= 1
  if extraSlotsNeeded > 0:
    appendOutput($impossibleAnswer)
    outputBuffer.add '\n'
  else:
    appendOutput($totalEnergy)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A single compound needs zero energy.
Missing slots produce the -1 answer.
The energy sum uses int64 for large masses.

## Complexity

Union-find handles every bond once, and one sort handles every atom.

| phase | time | space |
|---|---|---|
| bond merges | nearly O(M) | two arrays of N entries |
| compound scan | O(N) | one flag per atom |
| atom sort | O(N log N) | one packed array |

| measure | Big O |
|---|---|
| time | O(M + N log N) |
| space | O(N) |

Trying every set of bonds would explode with the bond count.

The tree view reduces the choice to one sorted atom list.
