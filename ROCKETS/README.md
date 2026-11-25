# ROCKETS — Rockets (SPOJ)

<https://www.spoj.com/problems/ROCKETS/>

## Problem

Ground-to-ground rockets must hit enemy targets with straight flight paths that never cross. Assign one target to each rocket so every pair of trajectories stays clear.

Input: `t` cases separated by blank lines. Each starts with `n`, then `n` rocket points followed by `n` target points. Output: `n` lines; line `i` gives the index of the target assigned to rocket `i`.

The bounds from the statement:

| Item | Bound |
|---|---|
| Points in each set `n` | 1 ≤ n ≤ 10000 |
| Coordinates | integers from −10000 to 10000 |
| General position | no three points are collinear |
| Judge limit | 1200 ms, 1536 MB |

Any non-crossing pairing is accepted, so the output need not match the sample exactly.

The sample input and output:

```
1
4
0 0
1 5
4 2
2 6
1 2
5 4
4 5
3 1
```

```
2
1
4
3
```

## Idea

Pair the leftmost point first, like untangling crossing strings by deciding the one strand that must reach across. Its partner splits the remaining points into two independent halves.

The program picks the leftmost point, sorts all others by angle around it, and scans that order. A target that balances rocket and target counts gives a valid split. The program chooses the balancing point closest to the angular median, then recurses on each half.

Each level sorts its slice by angle, giving O(n log² n) expected work overall. Small slices use insertion sort. Trying all n! pairings is impossible beyond a handful of points.

The leftmost point has a forced partner, and recursion settles the rest.

## Why It Works

Four facts carry the pairing.

1. In a non-crossing perfect matching, the leftmost point's segment splits the other points into two halves. A point on one side cannot pair across that segment without crossing it.
2. Each half must hold equal numbers of rockets and targets. In angular order, an opposite-type point that brings `balanceValue` to zero creates such a half.
3. Picking the balancing point nearest the angular median keeps both recursive slices small, limiting total work.
4. `slopeLess` compares angles with integer cross-products, so no floating point enters the sort. The general-position rule removes ties.

The values that drive the split:

| Term | Meaning |
|---|---|
| `pivotX`, `pivotY` | coordinates of the current leftmost point |
| `slopeLess` | angular order test using a cross-product |
| `balanceValue` | rockets minus targets in the angular scan |
| `matchPos` | chosen partner position inside the sorted slice |

The median choice bounds recursion depth and total work.

A script-traced example with two rockets and two targets:

```
R1 = (0,0), R2 = (0,2), W1 = (2,0), W2 = (2,2)
pivot R1; others by angle: W1 (0 deg), W2 (45 deg), R2 (90 deg)
scan: W1 -> balance 0 -> partner W1
remaining R2 and W2 pair together

output for rocket 1, rocket 2: 1 2
```

The four-point sample produces the pairing `2 1 4 3` by the same rule.

## Code

**Constants and scanner.** The scanner accepts negative coordinates and the input is read once.

```nim
{.push checks: off, optimization: speed, stackTrace: off, lineDir: off.}
{.emit: "#pragma GCC optimize(\"O3\")".}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxPoints = 20000
const maxCaseSize = 10000
const insertionLimit = 16

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value
```

`nextInt` checks for a leading minus sign before reading digits. `maxPoints = 20000` covers both sets at the largest case.

**Output helper and state.** Arrays hold coordinates, types, indices, and the recursion stack.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var xCoord: array[maxPoints, int]
var yCoord: array[maxPoints, int]
var isRocketPoint: array[maxPoints, bool]
var sourceIndex: array[maxPoints, int]
var pointIds: array[maxPoints, int]
var matchResult: array[maxCaseSize + 1, int]
var stackLo: array[maxPoints, int]
var stackHi: array[maxPoints, int]
var pivotX = 0
var pivotY = 0
var randomState: uint32 = 2463534242'u32
```

`sourceIndex` maps a point back to its input number. `matchResult` holds one target per rocket. `randomState` seeds the quicksort pivot choice.

**Random pivot and angular order.** `nextIndex` picks a pivot, and `slopeLess` orders points by angle.

```nim
proc nextIndex(rangeSize: int): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState xor (randomState shr 17)
  randomState = randomState xor (randomState shl 5)
  return int(randomState mod uint32(rangeSize))

proc slopeLess(leftId, rightId: int): bool =
  let leftDx = xCoord[leftId] - pivotX
  let rightDx = xCoord[rightId] - pivotX
  if leftDx == 0:
    if rightDx == 0:
      return yCoord[leftId] < yCoord[rightId]
    return false
  if rightDx == 0:
    return true
  return int64(yCoord[leftId] - pivotY) * int64(rightDx) < int64(yCoord[rightId] - pivotY) * int64(leftDx)
```

`nextIndex` uses xorshift and stays inside its range. `slopeLess` compares slopes with a cross-product, handling vertical rays first.

**Sorting.** Quicksort switches to insertion sort for small slices.

```nim
proc insertionSort(lo, hi: int) =
  for i in lo + 1..<hi:
    let value = pointIds[i]
    var j = i - 1
    while j >= lo and slopeLess(value, pointIds[j]):
      pointIds[j + 1] = pointIds[j]
      j -= 1
    pointIds[j + 1] = value

proc quickSort(lo, hi: int) =
  if hi - lo <= insertionLimit:
    insertionSort(lo, hi)
    return
  let last = hi - 1
  let chosen = lo + nextIndex(hi - lo)
  swap pointIds[chosen], pointIds[last]
  let pivotValue = pointIds[last]
  var store = lo
  for i in lo..<last:
    if slopeLess(pointIds[i], pivotValue):
      swap pointIds[i], pointIds[store]
      store += 1
  swap pointIds[store], pointIds[last]
  quickSort(lo, store)
  quickSort(store + 1, hi)
```

`insertionLimit = 16` bounds the small-slice work. The last point becomes the pivot, and points are partitioned by `slopeLess`. Recursion stops at the insertion threshold.

**Divide and conquer.** Each step picks a leftmost pivot, finds its balanced partner, and recurses on both sides.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  let totalPoints = 2 * pointCount
  for i in 0..<totalPoints:
    xCoord[i] = nextInt(inputData, scanPos)
    yCoord[i] = nextInt(inputData, scanPos)
    isRocketPoint[i] = i < pointCount
    sourceIndex[i] = if i < pointCount: i + 1 else: i - pointCount + 1
    pointIds[i] = i

  var stackSize = 1
  stackLo[0] = 0
  stackHi[0] = totalPoints
  while stackSize > 0:
    stackSize -= 1
    let lo = stackLo[stackSize]
    let hi = stackHi[stackSize]
    if hi - lo <= 0:
      continue
    var leftPos = lo
    for i in lo + 1..<hi:
      let candidate = pointIds[i]
      let best = pointIds[leftPos]
      if xCoord[candidate] < xCoord[best] or (xCoord[candidate] == xCoord[best] and yCoord[candidate] < yCoord[best]):
        leftPos = i
    swap pointIds[lo], pointIds[leftPos]
    let pivotId = pointIds[lo]
    pivotX = xCoord[pivotId]
    pivotY = yCoord[pivotId]
    quickSort(lo + 1, hi)
    var balanceValue = 0
    var matchPos = lo + 1
    var bestDistance = hi - lo
    let middlePos = (lo + hi) div 2
    for i in lo + 1..<hi:
      let otherId = pointIds[i]
      if isRocketPoint[otherId] == isRocketPoint[pivotId]:
        balanceValue += 1
      else:
        if balanceValue == 0:
          let distance = if i > middlePos: i - middlePos else: middlePos - i
          if distance < bestDistance:
            bestDistance = distance
            matchPos = i
        balanceValue -= 1
    if isRocketPoint[pivotId]:
      matchResult[sourceIndex[pivotId]] = sourceIndex[pointIds[matchPos]]
    else:
      matchResult[sourceIndex[pointIds[matchPos]]] = sourceIndex[pivotId]
    stackLo[stackSize] = lo + 1
    stackHi[stackSize] = matchPos
    stackSize += 1
    stackLo[stackSize] = matchPos + 1
    stackHi[stackSize] = hi
    stackSize += 1

  for i in 1..pointCount:
    appendOutput($(matchResult[i]))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

The stack avoids deep call recursion. Each scan counts same-type against opposite-type points and keeps the partner nearest the middle. `matchResult` records the pair for the rocket's output line.

## Complexity

Each level sorts one slice by angle, then splits it in two.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Angular sort | O(m log m) expected per level | O(m) |
| Divide and conquer | O(log n) levels | O(n) stack |
| Output | one write per 128 KiB block | 128 KiB |
| Total per case | O(n log² n) expected | O(n) |

The median partner keeps both halves small at every level.

| Measure | Big O |
|---|---|
| Time | O(n log² n) expected per case |
| Space | O(n) for point arrays and the recursion stack |

Trying all n! rocket-to-target assignments would be hopeless at `n = 10000`.

Enumerating every assignment costs n! steps. The balanced angular split builds a valid non-crossing matching in polynomial time.
