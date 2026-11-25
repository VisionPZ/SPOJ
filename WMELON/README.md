# WMELON — Johnny and the Watermelon Plantation (SPOJ)

<https://www.spoj.com/problems/WMELON/>

## Problem

The input gives plants at grid coordinates, each bearing some fruit. Find the smallest axis-aligned rectangle containing at least `k` fruit.

Input starts with `t ≤ 100`. Each case gives `n k`, where `n` counts plants and `k` is the fruit goal. The next `n` lines give `xi yi fi`: a plant's coordinates and its fruit count. Coordinates run from 1 to 1000. Output one integer, the minimum area.

The coordinate range fits in a million cells, but a full rectangle scan is still quadratic.

| Quantity | Bound |
| --- | --- |
| Test cases | t ≤ 100 |
| Plants per case | 1 to 1000 |
| Coordinates `xi`, `yi` | 1 to 1000 |
| Fruit goal | 1 to 10^6 |
| Time limit | 17 s |
| Memory limit | 1536 MB |

Several plants may share one coordinate cell, so counts are added together.

The sample input and output follow verbatim.

```
1
6 11
1 1 2
1 2 2
3 1 2
3 2 3
4 2 5
3 3 2
```

```
2
```

## Idea

Compress the used coordinates, then slide one window over columns and another over rows. Think of sliding a picture frame across a photo until it contains enough faces.

The program folds the 1000 by 1000 field into a compact grid of only the occupied columns and rows. For each pair of left and right columns, it accumulates fruit per row. A two-pointer window then finds the shortest row span reaching the goal. Each column pair costs linear time in the row count.

Checking every rectangle would take `O(Dx^2 · Dy^2)` time. The sliding window removes one quadratic factor.

Two sliding windows replace a full rectangle scan.

## Why It Works

Four facts justify the compression and the window.

1. A rectangle matters only at coordinates that hold plants. Mapping those coordinates to compact slots preserves every possible fruit total. The grid shrinks from a million cells to at most 1000 by 1000.
2. Fruit counts never go negative, so adding a column cannot lower a row sum. The two-pointer `bottom` index only moves forward.
3. The area uses real coordinates: width is the right column minus the left column, and height is the top row minus the bottom row. Adjacent coordinates differ by one, so a width or height of zero is legal.
4. A whole row or column with at least `k` fruit gives area zero at once. The width cutoff skips column pairs that cannot beat the best area.

The table names the area terms.

| Term | Meaning |
| --- | --- |
| `xCoords`, `yCoords` | occupied coordinates after compression |
| `field` | total fruit at each compact cell |
| `strip` | fruit per row for the current column pair |
| `bottom`, `top` | two-pointer row window |
| `best` | smallest area found so far |

The sample gives this trace for the strip `x = 3..4`.

```
x columns: 1 3 4
y rows: 1 2 3
strip x=3..4 fruit by row: 2 8 2
rows 1..3 hold 12 fruit; width=1 height=2 area=2
```

That area of 2 matches the sample output.

## Code

**Input setup.** Constants, bulk input, and the scanner set up parsing.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCoordinate = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The read loop ends at end of input, so one buffer holds every token. All values are positive, so the scanner skips signs. Scanning costs one pass over the input.

**Output buffer.** The output helper flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush check runs once per appended answer. Reusing the buffer avoids a fresh allocation per write.

**Coordinate compression.** Compression builds the compact grid and handles the zero-area cases.

```nim
proc solveCase(plantCount: int, fruitGoal: int, xValues: seq[int],
               yValues: seq[int], fruitCounts: seq[int]): int =
  var xSeen = newSeq[bool](maxCoordinate + 1)
  var ySeen = newSeq[bool](maxCoordinate + 1)
  for j in 0..<plantCount:
    xSeen[xValues[j]] = true
    ySeen[yValues[j]] = true
  var xCoords: seq[int] = @[]
  var yCoords: seq[int] = @[]
  var xSlot = newSeq[int](maxCoordinate + 1)
  var ySlot = newSeq[int](maxCoordinate + 1)
  for k in 1..maxCoordinate:
    if xSeen[k]:
      xSlot[k] = xCoords.len
      xCoords.add k
    if ySeen[k]:
      ySlot[k] = yCoords.len
      yCoords.add k
  let xCount = xCoords.len
  let yCount = yCoords.len
  var field = newSeq[int](xCount * yCount)
  for j in 0..<plantCount:
    field[xSlot[xValues[j]] * yCount + ySlot[yValues[j]]] += fruitCounts[j]
  for k in 0..<yCount:
    var rowTotal = 0
    for j in 0..<xCount:
      rowTotal += field[j * yCount + k]
    if rowTotal >= fruitGoal: return 0
  for j in 0..<xCount:
    var colTotal = 0
    for k in 0..<yCount:
      colTotal += field[j * yCount + k]
    if colTotal >= fruitGoal: return 0
```

The coordinate scan runs 1000 times and costs `O(1000)`. Slot arrays remove sorting from the hot path. The two early loops catch single row or column answers.

**Pair sweep.** The nested sweep finds the best area.

```nim
  var best = maxCoordinate * maxCoordinate
  var strip = newSeq[int](yCount)
  for leftX in 0..<xCount:
    for k in 0..<yCount:
      strip[k] = 0
    for rightX in leftX..<xCount:
      let width = xCoords[rightX] - xCoords[leftX]
      if width >= best: break
      let rowBase = rightX * yCount
      var stripTotal = 0
      for k in 0..<yCount:
        strip[k] += field[rowBase + k]
        stripTotal += strip[k]
      if stripTotal < fruitGoal: continue
      var bottom = 0
      var collected = 0
      for top in 0..<yCount:
        collected += strip[top]
        while collected - strip[bottom] >= fruitGoal:
          collected -= strip[bottom]
          bottom += 1
        if collected >= fruitGoal:
          let area = width * (yCoords[top] - yCoords[bottom])
          if area < best:
            best = area
            if best == 0: return 0
  return best
```

The outer sweep runs `xCount` times, and the inner sweep runs at most `xCount` times. `bottom` never decreases, so the row window stays linear. The width cutoff skips hopeless pairs.

**Case driver.** The driver reads plants and prints each answer.

```nim
let caseCount = nextInt(inputData, i)
for caseIndex in 0..<caseCount:
  let plantCount = nextInt(inputData, i)
  let fruitGoal = nextInt(inputData, i)
  var xValues = newSeq[int](plantCount)
  var yValues = newSeq[int](plantCount)
  var fruitCounts = newSeq[int](plantCount)
  for j in 0..<plantCount:
    xValues[j] = nextInt(inputData, i)
    yValues[j] = nextInt(inputData, i)
    fruitCounts[j] = nextInt(inputData, i)
  appendOutput($(solveCase(plantCount, fruitGoal, xValues, yValues, fruitCounts)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The driver runs `caseCount` times. Each plant adds three scanned integers. One final write flushes the remaining output.

## Complexity

Compression and the sweep have separate bounds.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(total tokens) | one input string |
| Grid compression | O(n + 1000) | O(Dx·Dy) cells |
| Column pair sweep | O(Dx^2·Dy) | O(Dy) strip |
| Output | one flush per block | one flush block |

`Dx` and `Dy` count distinct occupied columns and rows.

The totals use the plant count and the distinct counts.

| Measure | Big O |
| --- | --- |
| Time | O(n + 1000 + Dx^2·Dy) |
| Space | O(Dx·Dy) |

Checking every rectangle instead costs `O(Dx^2·Dy^2)` time.
