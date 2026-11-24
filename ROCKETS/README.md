## Problem

Read t test cases. Each case gives n points in set R and n points in set W, with integer coordinates in [-10000, 10000]. Print one target number per rocket, in input order. Each segment from a rocket to its target must avoid every other segment. No three input points lie on one line.

| Quantity | Bound |
| --- | --- |
| Points per set | n <= 10000 |
| Coordinate range | -10000 to 10000 |
| Memory limit | 1536 MB |
| Time limit | 1200 ms |

The point count drives the running time; the coordinate range only bounds the arithmetic.

## Idea

Split each point set with a balanced line and solve the two sides on their own. A balanced line passes through one rocket and one target. Each open half-plane then holds equal counts of both kinds. Match the two points on that line, then recurse on each side. Each point takes O(log n) sorting work per level and O(log^2 n) over the whole recursion.

## Why It Works

Choose the leftmost point v of a set. Every other point lies to its right, or directly above it. Direction angles from v therefore span less than a half turn. Sort the other points by slope around v.

Call a point same when it belongs to v's kind and opposite otherwise. Start a running count at zero. Add one for each same point and subtract one for each opposite point. The count ends at -1, so some opposite point has count zero before it. Take the one nearest the middle position. The points before it and after it then hold equal counts of both kinds.

The segment from v to that point separates the halves. Segments built inside a half stay inside that half. They never cross the separating segment or a segment from the other half.

The sample uses v = (0, 0), the leftmost rocket. The table lists the other points by slope around v. The count column shows the value before each point.

| Target | Kind | Angle | Count before |
| --- | --- | --- | --- |
| w4 | W | 0.322 | 0 |
| r3 | R | 0.464 | -1 |
| w2 | W | 0.675 | 0 |
| w3 | W | 0.896 | -1 |
| w1 | W | 1.107 | -2 |
| r4 | R | 1.249 | -3 |
| r2 | R | 1.373 | -2 |

w2 sits nearest the middle, so the first segment joins r1 to w2. The remaining points form two balanced sets and follow the same rule.

## Code

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop ends at end of input. The scanner handles a leading minus sign, so negative coordinates parse correctly. One scan of the input bytes covers every token.

```nim
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

The sort runs over the half-open range [lo, hi). A point directly above v has zero horizontal distance and sorts last. Cross products compare slopes without division. A random pivot keeps the sort fast on already ordered point lists. Sorting costs O(m log m) expected time for m points.

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

The stack holds ranges of still unsolved points. Each range picks its leftmost point and finds one balanced target. Choosing the target nearest the middle keeps the two new ranges close in size. The final loop prints n answers per case. This phase costs O(n log^2 n) time and O(n) working space per case.

## Complexity

Reading the input takes time linear in the number of input bytes. Sorting costs O(m log m) per node of expected time, with m points in that node. Balanced splits give O(n log^2 n) total time per case. The output pass takes O(n) time and the block buffer holds at most flushBlockBytes bytes. Working arrays hold O(n) points.

A naive search tries each rocket with each target and tests every pair of segments. That approach costs O(n^3) time and loses badly at n = 10000.
