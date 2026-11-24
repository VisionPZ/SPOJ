## Problem

The field holds n plants on a 1000 by 1000 grid. Each plant carries fi fruit at coordinates (xi, yi). Find the smallest rectangle area that covers at least k fruit. Print one integer per test case.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | t ≤ 100 |
| Plants per case | 1 ≤ n ≤ 1000 |
| Coordinates | 1 ≤ xi, yi ≤ 1000 |
| Fruit goal | 1 ≤ k ≤ 10^6 |
| Time limit | 17 s |
| Memory limit | 1536 MB |

The coordinate range fits in a million cells, so the grid stays small.

## Idea

Coordinates span 1 to 1000, so the program folds them into a compact grid. Let Dx count distinct columns and Dy count distinct rows. One pair of columns then needs a single row sweep.

A two-pointer window keeps the shortest row span that reaches `fruitGoal`. A full rectangle scan costs O(Dx²·Dy²) time.

Each column pair costs O(Dy) time.

## Why It Works

Fruit counts never go negative, so adding a column cannot lower a row sum. The two-pointer window moves `bottom` forward and finds the shortest span that reaches the goal.

The area uses the distance between coordinates:

| term | meaning |
| --- | --- |
| width | right column minus left column |
| height | top row minus bottom row |
| area | width times height |

Adjacent coordinates differ by one, so a width or height of zero is legal.

The sample gives this trace for the strip x = 3..4:

```
x columns: 1 3 4
y rows: 1 2 3
strip x=3..4 fruit by row: 2 8 2
rows 1..3 hold 12 fruit; width=1 height=2 area=2
```

That area of 2 matches the sample output.

## Code

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

The read loop ends at end of input, so one buffer holds every token. All values are positive, so the scanner skips signs. Scanning costs O(total tokens).

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush check runs once per appended answer. Reusing the buffer avoids a fresh allocation per write. Each append costs O(length of its text).

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

The coordinate scan runs maxCoordinate times, so it costs O(1000). Slot arrays remove sorting from the hot path. The grid holds at most a million cells.

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

The outer sweep runs xCount times, and the inner sweep runs at most xCount times. `bottom` never decreases, so the row window stays linear. The width cutoff skips pairs that cannot beat `best`.

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

The driver runs caseCount times. Each plant adds three scanned integers. One final write flushes the remaining output.

## Complexity

Input reading costs O(total tokens). Grid compression costs O(n + maxCoordinate) time and O(Dx·Dy) space. The sweep costs O(Dx²·Dy) time. The whole run costs O(n + maxCoordinate + Dx²·Dy) time and O(Dx·Dy) space. Checking every rectangle costs O(Dx²·Dy²) time.
