# MPOLGRID — Polygon on the Grid (SPOJ)

<https://www.spoj.com/problems/MPOLGRID/>

## Problem

Use all given rods as the sides of one convex polygon with grid-point corners and report its largest possible area, or -1 when no such polygon exists. A rod of integer length must lie along an integer vector between two grid points.

Each dataset gives the rod count `n`, then one line with `n` rod lengths. A line containing a single zero ends the input. Output one integer per dataset.

| item | bound |
|---|---|
| rod count n | 3 to 6 |
| rod length | 1 to 300 |
| datasets | until the zero line |
| judge limit | 1000 ms, 1536 MB |

A lattice side of length r needs integer offsets dx and dy with dx² + dy² = r².

Sample input:

```
3
3 4 5
5
1 2 5 5 5
6
195 221 255 260 265 290
6
130 145 169 185 195 265
3
1 1 2
6
3 3 3 3 3 3
0
```

Sample output:

```
6
19
158253
-1
-1
18
```

## Idea

Split the rods into two small groups and match the groups by their net offset, like balancing two piles of vectors until they point opposite ways. A closed polygon needs the total offset to be zero, so matching sums find every candidate.

The algorithm lists every integer vector for each rod, generates all choices for each half, and joins pairs whose sums cancel. For each joined pair it sorts vectors by angle and computes the shoelace area. A full search over all rod choices would multiply up to 36 options six times.

The split turns a huge product into two small lists plus a hash lookup.

## Why It Works

1. A rod of length r can only use offsets with dx² + dy² = r², and there are at most 36 such vectors for r up to 300.
2. The polygon closes exactly when the sum of all chosen vectors is zero.
3. Sorting the side vectors by angle gives a convex polygon, and the order is fixed by the vector set.
4. Twice the shoelace area equals the sum of cross products over all vector pairs in angular order.
5. Splitting the rods into halves preserves every valid assignment, since the two half sums must be opposites.

| term | meaning |
|---|---|
| `WireVector` | one integer side offset |
| `rodOptions` | all possible vectors for one rod |
| `groupCombos` | first-half choices indexed by their offset sum |
| `bestAreaTwice` | largest doubled area found so far |

For rods 3, 4, 5 the vectors (3,0), (0,4), and (-3,-4) sum to zero. The cross products sum to 12, so the area is 6, matching the sample.

A positive doubled area always gives the integer answer after division by two.

## Code

**Vector listing and angular sort.** The helper builds every lattice side and orders vectors around the origin.

```nim
import math
import tables

const flushBlockBytes = 1 shl 17
const maxRodCount = 6
const sumKeyOffset = 2000
const sumKeyBase = 5000

type WireVector = tuple[dx: int, dy: int]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc buildOptions(length: int): seq[WireVector] =
  var candidates: seq[WireVector] = @[]
  for dxValue in -length .. length:
    let remainingSquare = length * length - dxValue * dxValue
    if remainingSquare < 0:
      continue
    let dyValue = int(sqrt(float(remainingSquare)))
    if dyValue * dyValue == remainingSquare:
      candidates.add((dxValue, dyValue))
      if dyValue != 0:
        candidates.add((dxValue, -dyValue))
  for candidateIndex in 0 .. candidates.high:
    let held = candidates[candidateIndex]
    let swapped = (held.dy, held.dx)
    var known = false
    for existing in candidates:
      if existing.dx == swapped[0] and existing.dy == swapped[1]:
        known = true
        break
    if not known:
      candidates.add(swapped)
  return candidates

proc halfPlane(value: WireVector): int =
  if value.dy > 0 or (value.dy == 0 and value.dx > 0):
    return 0
  return 1

proc vectorLess(first: WireVector, second: WireVector): bool =
  let firstHalf = halfPlane(first)
  let secondHalf = halfPlane(second)
  if firstHalf != secondHalf:
    return firstHalf < secondHalf
  return first.dx * second.dy - first.dy * second.dx > 0

proc sortVectors(values: var seq[WireVector]) =
  for rightIndex in 1 .. values.high:
    let held = values[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and vectorLess(held, values[leftIndex]):
      values[leftIndex + 1] = values[leftIndex]
      leftIndex -= 1
    values[leftIndex + 1] = held
```

Signs and swaps cover all rotations and reflections.
The half-plane test avoids floating-point comparisons.
Insertion sort handles at most six vectors.

**Half generation and matching.** The first half is indexed by sum, and the second half looks up its opposite.

```nim
proc sumKey(sumX: int, sumY: int): int =
  return (sumX + sumKeyOffset) * sumKeyBase + sumY + sumKeyOffset

var rodOptions: seq[seq[WireVector]] = @[]
var groupIndices: seq[int] = @[]
var groupCombos = initTable[int, seq[array[maxRodCount, int]]]()
var comboScratch: array[maxRodCount, int]
var bestAreaTwice = -1

proc storeCombo(sumX: int, sumY: int) =
  let key = sumKey(sumX, sumY)
  if not groupCombos.hasKey(key):
    groupCombos[key] = @[]
  groupCombos[key].add comboScratch

proc generateFirstGroup(position: int, sumX: int, sumY: int) =
  if position == groupIndices.len:
    storeCombo(sumX, sumY)
    return
  let rodIndex = groupIndices[position]
  for optionIndex in 0 .. rodOptions[rodIndex].high:
    let held = rodOptions[rodIndex][optionIndex]
    comboScratch[position] = optionIndex
    generateFirstGroup(position + 1, sumX + held.dx, sumY + held.dy)

proc evaluateCombo(firstCombo: array[maxRodCount, int], secondCombo: array[maxRodCount, int],
                   firstIndices: seq[int], secondIndices: seq[int]) =
  var vectors: seq[WireVector] = @[]
  for position in 0 .. firstIndices.high:
    vectors.add rodOptions[firstIndices[position]][firstCombo[position]]
  for position in 0 .. secondIndices.high:
    vectors.add rodOptions[secondIndices[position]][secondCombo[position]]
  sortVectors(vectors)
  var areaTwice = 0
  for firstIndex in 0 .. vectors.high:
    for secondIndex in firstIndex + 1 .. vectors.high:
      areaTwice = areaTwice + vectors[firstIndex].dx * vectors[secondIndex].dy -
                  vectors[firstIndex].dy * vectors[secondIndex].dx
  if areaTwice > bestAreaTwice:
    bestAreaTwice = areaTwice

var secondIndices: seq[int] = @[]
var secondScratch: array[maxRodCount, int]

proc generateSecondGroup(position: int, sumX: int, sumY: int) =
  if position == secondIndices.len:
    let key = sumKey(-sumX, -sumY)
    if groupCombos.hasKey(key):
      for firstCombo in groupCombos[key]:
        evaluateCombo(firstCombo, secondScratch, groupIndices, secondIndices)
    return
  let rodIndex = secondIndices[position]
  for optionIndex in 0 .. rodOptions[rodIndex].high:
    let held = rodOptions[rodIndex][optionIndex]
    secondScratch[position] = optionIndex
    generateSecondGroup(position + 1, sumX + held.dx, sumY + held.dy)

proc solveDataset(rodLengths: seq[int]): int =
  rodOptions = @[]
  for length in rodLengths:
    rodOptions.add buildOptions(length)
  let splitIndex = rodLengths.len div 2
  groupIndices = @[]
  secondIndices = @[]
  for rodIndex in 0 .. splitIndex - 1:
    groupIndices.add rodIndex
  for rodIndex in splitIndex .. rodLengths.high:
    secondIndices.add rodIndex
  groupCombos.clear()
  generateFirstGroup(0, 0, 0)
  bestAreaTwice = -1
  generateSecondGroup(0, 0, 0)
  if bestAreaTwice <= 0:
    return -1
  return bestAreaTwice div 2
```

The sum key packs two bounded offsets into one integer.
Each matched pair is scored with the vector-pair formula.
A missing match leaves the area at -1, which prints as -1.

**Driver.** The reader consumes datasets until the zero line.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let rodCount = nextInt(inputData, scanPos)
  if rodCount == 0 or scanPos > inputData.len:
    break
  var rodLengths = newSeq[int](rodCount)
  for rodIndex in 0 .. rodCount - 1:
    rodLengths[rodIndex] = nextInt(inputData, scanPos)
  appendOutput($(solveDataset(rodLengths)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

All input is read before any dataset is solved.
The zero terminator stops the loop.
One buffered write emits every answer.

## Complexity

Each rod has at most 36 lattice vectors, and the split keeps enumeration small.

| phase | time | space |
|---|---|---|
| vector listing | at most 600 offset checks per dataset | at most 36 vectors per rod |
| first half | at most 36³ choices | one table of sums |
| second half | at most 36³ lookups | one scratch combo |
| scoring | 15 cross products per matched pair | six sorted vectors |
| output | one buffered write | block buffer |

The matching step dominates for datasets with many Pythagorean lengths.

| measure | Big O |
|---|---|
| time | O(V^(n/2) + P · n²) with V ≤ 36 and P matched pairs |
| space | O(V^(n/2)) |

A full product search would visit V^n assignments. The sum index removes almost all of them before scoring.
