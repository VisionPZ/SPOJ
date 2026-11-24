## Problem

Read up to 20 test cases. Each case gives a bar with `columnCount` columns and `rowCount` rows. Then come the costs for every vertical line and every horizontal line. Print the smallest total cost to break the bar into single squares.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | at most 20 |
| Bar side | 2 to 1000 |
| Cut cost | 1 to 1000 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The bar size drives the design, since one case holds nearly 2000 cuts.

## Idea

Always cut along the most expensive remaining line. A cut crosses the whole bar, so its cost is paid once for every piece in the other direction. Counting costs by value replaces comparison sorting, and two downward scans merge the directions in one pass.

One cut costs constant time.

## Why It Works

A vertical cut crosses every horizontal piece that already exists. Its cost is multiplied by the horizontal piece count. A horizontal cut works the same way with the vertical piece count.

Doing a cheap cut before an expensive one only raises the total, since piece counts never shrink. So each direction uses its cuts from highest cost to lowest. Equal costs give the same total in either order.

The count array is indexed by cost. Scanning its index from 1000 down to 1 lists the cuts in descending order without a sort.

For each cut, the added cost is the cut cost times the perpendicular piece count. A vertical cut then raises `verticalPieces`, and a horizontal cut raises `horizontalPieces`.

The generator prints each step for the sample.

| Step | Cut | Multiplier | Added | Running total | Vertical / horizontal pieces |
| --- | --- | --- | --- | --- | --- |
| 1 | V 4 | 1 | 4 | 4 | 2 / 1 |
| 2 | H 4 | 2 | 8 | 12 | 2 / 2 |
| 3 | V 3 | 2 | 6 | 18 | 3 / 2 |
| 4 | V 2 | 2 | 4 | 22 | 4 / 2 |
| 5 | H 2 | 4 | 8 | 30 | 4 / 3 |
| 6 | V 1 | 3 | 3 | 33 | 5 / 3 |
| 7 | V 1 | 3 | 3 | 36 | 6 / 3 |
| 8 | H 1 | 6 | 6 | 42 | 6 / 4 |

The final total is 42, which matches the sample output.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumCutCost = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop runs once per input line. All input lives in one buffer, so the scanner never reads from the stream. Skipping non-digits absorbs the blank lines between cases. The scan costs one pass over the input bytes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 256 KiB and then reuses its storage. No write happens per answer. The cost is one write per full block.

```nim
var verticalCount: array[maximumCutCost + 1, int]
var horizontalCount: array[maximumCutCost + 1, int]

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  for k in 0..maximumCutCost:
    verticalCount[k] = 0
    horizontalCount[k] = 0
  var remainingVertical = columnCount - 1
  var remainingHorizontal = rowCount - 1
  for k in 0..<remainingVertical:
    let cutCost = nextInt(inputData, scanPos)
    verticalCount[cutCost] += 1
  for k in 0..<remainingHorizontal:
    let cutCost = nextInt(inputData, scanPos)
    horizontalCount[cutCost] += 1
  var verticalValue = maximumCutCost
  var horizontalValue = maximumCutCost
  var verticalPieces = 1
  var horizontalPieces = 1
  var totalCost: int64 = 0
  while remainingVertical > 0 or remainingHorizontal > 0:
    if remainingVertical > 0:
      while verticalCount[verticalValue] == 0:
        verticalValue -= 1
    if remainingHorizontal > 0:
      while horizontalCount[horizontalValue] == 0:
        horizontalValue -= 1
    if remainingVertical > 0 and (remainingHorizontal == 0 or verticalValue >= horizontalValue):
      totalCost += int64(verticalValue) * int64(horizontalPieces)
      verticalPieces += 1
      verticalCount[verticalValue] -= 1
      remainingVertical -= 1
    else:
      totalCost += int64(horizontalValue) * int64(verticalPieces)
      horizontalPieces += 1
      horizontalCount[horizontalValue] -= 1
      remainingHorizontal -= 1
  appendOutput($(totalCost))
  outputBuffer.add '\n'
```

The two count loops reset 1001 slots and then read exactly `columnCount - 1` and `rowCount - 1` costs. The variables `remainingVertical` and `remainingHorizontal` keep a case from reading the next case's data. The greedy loop stops when both counters reach zero. It scans at most 1000 values per direction and makes one cut per turn. The total uses `int64`, which covers the largest 1000 by 1000 case.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last write flushes a short tail. Emptying the buffer keeps a second flush silent.

## Complexity

Reading and scanning take time linear in the input size. Each case resets two arrays of 1001 slots and scans at most 1000 values per direction. The greedy loop runs in O(columns + rows) time. The total is O(T * (columns + rows + 1000)) time and O(1000) space. Trying every ordering of the cuts instead grows factorially with the number of cuts.
