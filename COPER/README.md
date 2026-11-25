# COPER — Crane Operator (SPOJ)

<https://www.spoj.com/problems/COPER/>

## Problem

Each case hides a target arrangement of boxes over numbered locations. The answer is the fewest crane moves that turn the starting arrangement into that target.

Input starts with T, the number of cases. Each of the next T lines holds six integers: N, M, q, p, m, d. Output one line per case with the minimum move count.

The recurrence sets c0 = 0 and c(i+1) = (c(i) * q + p) mod m. Box i goes to (c(i) + d*x + y) mod N, with x and y non-negative, avoiding M and all earlier destinations. Choose the smallest y first, then the smallest x. The forbidden location is `M mod N`, as the note on the judge page says.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases T | at most 7 000 |
| Locations N | at most 1 000 000 |
| Forbidden location M | at most 1 000 000 |
| Step d | at most 1 000 000 |
| Recurrence values q, p, m | at most 10 000 |
| Judge limit | 40 s, 1 536 MB |

The million-location bound drives the design. The recurrence modulus stays below ten thousand, so values of c repeat quickly.

Write `g = gcd(d, N)`, `n' = N / g` and `d' = d / g` for the notes below. Here `d'` is the column step inside one class.

The sample case:

```
1
8 3 5 2 7 4
```

```
6
```

The sample answer is six moves.

## Idea

Picture locations as parking spaces and boxes as drivers who follow one fixed route. Each driver takes the first free space on that route, and the crane then untangles the cycles.

The algorithm is a disjoint-set next-free search on a grid, followed by permutation cycle counting. Split the locations into g residue classes of size n'. Inside a class, relabel columns with the inverse of d', so a jump of d becomes one step forward. Two parent arrays answer both searches: one for free columns, one for classes with space.

Each box costs two or three almost constant finds, and the final pass visits each location once. Scanning every (x, y) pair costs up to N squared steps per box, and a search over arrangements grows exponentially.

Flat parent arrays and one cycle pass give a near-linear answer for every case.

## Why It Works

Five facts carry the proof.

1. For fixed y, the term d*x mod N is always a multiple of g. The box then reaches only locations whose residue mod g matches (c(i) + y) mod g.
2. Values y from 0 through g - 1 cover all g residues. The smallest y comes from the first class that still has a free location.
3. Inside one class, d' permutes the n' columns. Multiplying by the inverse of d' turns a column jump into one step.
4. A parent array returns the first free column at or after the start. A second call wraps to the row start, and a second array skips full classes.
5. The destination map is a permutation of locations. A cycle through location 0 costs length minus one moves; each other nontrivial cycle costs length plus one.

These facts reduce the secret rule to two searches and one cycle sum.

The terms and formulas:

| Term | Meaning |
|---|---|
| `g` | count of residue classes, equal to gcd(d, N) |
| `n'` | locations in one class, equal to N / g |
| `d'` | column step in one class, equal to d / g |
| `stepInverse` | inverse of `d'` modulo `n'`, turns a jump into one step |
| `excludedLocation` | forbidden location, equal to M mod N |
| `cycleLength` | size of one cycle in the destination map |

Every size follows from the single division of N by g.

A script trace of the sample case:

```
N=8 M=3 d=4 g=4 n1=2 dp=1 inv=1 excluded=3
box c class col row y startCol startUnit slot
  1 2     2   0   2 0        0         0    2
  2 5     1   1   1 0        1         1    5
  3 6     2   1   2 0        1         1    6
  4 4     0   1   0 0        1         1    4
  5 1     1   0   1 0        0         0    1
  6 0     0   0   0 0        0         0    0
  7 2     2   0   3 1        0         0    7
successor 0->3 1->2 2->5 3->6 4->4 5->1 6->0 7->7
cycle 0 length 3 cost 2
cycle 1 length 3 cost 4
total 6
```

Box 7 skips the full class 2 and lands on 7. The two nontrivial cycles then cost 2 and 4 moves, giving 6.

## Code

Constants and scanner. One read of stdin feeds a digit scanner.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxLocationCount = 1000000

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scanner skips separators and builds each value from digit bytes. `firstDigitValue` converts a byte to its digit. This block costs one pass over the input bytes.

Arithmetic helpers. Division and inversion set up the column relabeling.

```nim
proc gcdValues(firstValue, secondValue: int): int =
  var dividend = firstValue
  var divisor = secondValue
  while divisor != 0:
    let remainder = dividend mod divisor
    dividend = divisor
    divisor = remainder
  return dividend

proc modInverse(value, modulus: int): int =
  if modulus == 1: return 0
  var oldCoeff = 0
  var coeff = 1
  var oldRem = modulus
  var rem = value mod modulus
  while rem != 0:
    let quotient = oldRem div rem
    let nextOldCoeff = coeff
    coeff = oldCoeff - quotient * coeff
    oldCoeff = nextOldCoeff
    let nextOldRem = rem
    rem = oldRem - quotient * rem
    oldRem = nextOldRem
  return (oldCoeff mod modulus + modulus) mod modulus
```

`gcdValues` yields the class count. `modInverse` handles a single-column class as a special case. Both run once per case.

Next-free searches. Each parent chain skips occupied cells.

```nim
proc findSlot(slotParent: var seq[int], index: int): int =
  var root = index
  while slotParent[root] != root:
    root = slotParent[root]
  var cursor = index
  while slotParent[cursor] != cursor:
    let nextIndex = slotParent[cursor]
    slotParent[cursor] = root
    cursor = nextIndex
  return root

proc findRow(rowParent: var seq[int], row: int): int =
  var root = row
  while rowParent[root] != root:
    root = rowParent[root]
  var cursor = row
  while rowParent[cursor] != cursor:
    let nextRow = rowParent[cursor]
    rowParent[cursor] = root
    cursor = nextRow
  return root
```

`findSlot` compresses its path while returning the first free column. `findRow` does the same for full classes. Both run in almost constant time.

Per-case setup. The grid, the forbidden cell and the counters start here.

```nim
proc countMoves(locationCount, emptyLocation, recurrenceMultiplier, recurrenceAdd,
                recurrenceModulus, step: int, slotParent, rowParent, freeCount,
                boxDestination: var seq[int]): int =
  let excludedLocation = emptyLocation mod locationCount
  let classCount = gcdValues(step, locationCount)
  let slotsPerClass = locationCount div classCount
  let stepPerClass = step div classCount
  let stepInverse = modInverse(stepPerClass, slotsPerClass)
  for index in 0 .. locationCount:
    slotParent[index] = index
  for index in 0 .. classCount:
    rowParent[index] = index
  for index in 0 .. classCount - 1:
    freeCount[index] = slotsPerClass
  let excludedRow = excludedLocation mod classCount
  let excludedColumn = excludedLocation div classCount
  let excludedUnit = (stepInverse * excludedColumn) mod slotsPerClass
  let excludedIndex = excludedRow * slotsPerClass + excludedUnit
  slotParent[excludedIndex] = excludedIndex + 1
  freeCount[excludedRow] -= 1
  if freeCount[excludedRow] == 0:
    rowParent[excludedRow] = excludedRow + 1
```

`excludedLocation` uses `M mod N`, so a large M still works. The arrays come from tables allocated once. Setup costs one write per location and per class.

Configuration build. Each box takes its first free cell in probe order.

```nim
  var currentC = 0
  for boxNumber in 1 .. locationCount - 1:
    currentC = (currentC * recurrenceMultiplier + recurrenceAdd) mod recurrenceModulus
    let classOfC = currentC mod classCount
    let columnOfC = currentC div classCount
    var freeRow = findRow(rowParent, classOfC)
    if freeRow == classCount:
      freeRow = findRow(rowParent, 0)
    let shiftY = (freeRow - classOfC + classCount) mod classCount
    let carry = (classOfC + shiftY) div classCount
    let startColumn = (columnOfC + carry) mod slotsPerClass
    let startUnit = (stepInverse * startColumn) mod slotsPerClass
    let rowStart = freeRow * slotsPerClass
    let rowEnd = rowStart + slotsPerClass
    var foundIndex = findSlot(slotParent, rowStart + startUnit)
    if foundIndex >= rowEnd:
      foundIndex = findSlot(slotParent, rowStart)
    let unitIndex = foundIndex - rowStart
    let columnIndex = (stepPerClass * unitIndex) mod slotsPerClass
    let assignedSlot = freeRow + classCount * columnIndex
    boxDestination[boxNumber] = assignedSlot
    slotParent[foundIndex] = foundIndex + 1
    freeCount[freeRow] -= 1
    if freeCount[freeRow] == 0:
      rowParent[freeRow] = freeRow + 1
```

`findRow` gives the smallest y, with one wrap when needed. `startUnit` converts the column start into inverse-step coordinates. `boxDestination` stores the target for the later cycle pass.

Move count. One visit per location sums the cycle costs.

```nim
  boxDestination[0] = excludedLocation
  for boxNumber in 0 .. locationCount - 1:
    slotParent[boxNumber] = boxDestination[boxNumber]
  var totalMoves = 0
  for startSlot in 0 .. locationCount - 1:
    if slotParent[startSlot] < 0: continue
    var currentSlot = startSlot
    var cycleLength = 0
    var holdsInitialEmpty = false
    while slotParent[currentSlot] >= 0:
      let nextSlot = slotParent[currentSlot]
      slotParent[currentSlot] = -1
      if currentSlot == 0: holdsInitialEmpty = true
      cycleLength += 1
      currentSlot = nextSlot
    if cycleLength > 1:
      if holdsInitialEmpty:
        totalMoves += cycleLength - 1
      else:
        totalMoves += cycleLength + 1
  return totalMoves
```

The `-1` marker replaces a visited array. A cycle through location 0 costs `cycleLength - 1`; others cost `cycleLength + 1`. Fixed points add nothing.

Driver. One input buffer, one output buffer, and block writes.

```nim
var slotParent = newSeq[int](maxLocationCount + 1)
var rowParent = newSeq[int](maxLocationCount + 1)
var freeCount = newSeq[int](maxLocationCount + 1)
var boxDestination = newSeq[int](maxLocationCount + 1)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 0 .. caseCount - 1:
  let locationCount = nextInt(inputData, scanPos)
  let emptyLocation = nextInt(inputData, scanPos)
  let recurrenceMultiplier = nextInt(inputData, scanPos)
  let recurrenceAdd = nextInt(inputData, scanPos)
  let recurrenceModulus = nextInt(inputData, scanPos)
  let step = nextInt(inputData, scanPos)
  let answer = countMoves(locationCount, emptyLocation, recurrenceMultiplier,
                          recurrenceAdd, recurrenceModulus, step, slotParent,
                          rowParent, freeCount, boxDestination)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

All six values come from `nextInt` with no token objects. `outputBuffer` flushes at `flushBlockBytes` and once at the end. The four tables are allocated once, outside the case loop.

## Complexity

The work splits into input, setup, configuration build, cycle count and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Per-case setup | one write per location and class | three reused tables |
| Configuration build | two or three finds per box | two parent arrays |
| Move count | one visit per location | reused destination array |
| Output | one write per block | block buffer |

Setup and counting both scale with N, and no case allocates a new table.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(N α(N)) per case, plus output bytes |
| Space | O(N) for the reused tables |

The function α grows so slowly that it stays below five for any legal N. A naive scan costs O(N squared) per case, so the near-linear pass is the decisive gain.
