# SDF4A — Vertical Garden Pipes (SPOJ)

<https://www.spoj.com/problems/SDF4A/>

## Problem

Connect every plant with pipes so water reaches the whole garden. Each pipe joins two plants and costs M per metre, and the bill rounds up.

The first line is T. Each case gives N and M, then N lines holding x and y. Print one line per case: `Rp ` followed by the bill with dots every three digits.

| item | bound |
|---|---|
| test cases T | not bounded by the statement |
| plants N | 1 to 1000 |
| price M | 1000 to 5000 per metre |
| x coordinate | 1 to 1000 |
| y coordinate | 1 to 200 |
| judge limit | 300 ms, 1536 MB |

The pair count grows as N squared, so the design must avoid enumerating pipe subsets.

The sample input:

```
2
2 1250
5 3
8 7
3 1375
5 3
8 3
6 7
```

It holds two separate cases.

The sample output:

```
Rp 6.250
Rp 9.795
```

Each line is the rounded bill for one case.

## Idea

Treat plants as dots and pipes as roads, like linking towns with the shortest road network. Prim's algorithm grows one connected tree, adding the nearest outside plant each round. Each round scans all plants once, so a round costs O(N). Enumerating all pipe subsets costs O(2^N) and is far slower. Takeaway: grow the tree, then multiply and round once.

## Why It Works

1. A tree with N plants uses exactly N minus one pipes.
2. The cheapest connected network is a minimum spanning tree over all pairs.
3. `closestEdges` stores the shortest link from the current tree to each outside plant.
4. Adding the smallest stored link is safe, since it crosses the lightest cut.
5. `totalLength` sums those links, and `roundedCost` rounds the bill up.

| term | meaning |
|---|---|
| `closestEdges` | nearest distance from the tree to one plant |
| `linkedPlants` | marks plants already inside the tree |
| `chosenPlant` | nearest outside plant in this round |
| `totalLength` | sum of chosen pipe lengths |
| `roundedCost` | bill after multiplying by M and rounding |
| `formatRupiah` | inserts a dot every three digits |

The table follows one round of the tree from distances to the printed bill.

A script trace of the second sample case uses distances 3, 4.1231 and 4.4721. The tree takes 3 and 4.1231, so the total is 7.1231 metres. Multiplying by 1375 gives 9794.27, and rounding gives 9795.

```
3 + 4.1231 = 7.1231
7.1231 * 1375 = 9794.27
ceil = 9795 -> Rp 9.795
```

The trace reproduces the second output line exactly.

A tiny epsilon precedes `ceil` so floating-point noise cannot add one rupiah.

## Code

**Input and currency format.** The reader loads every integer, and the formatter groups digits.

```nim
import math

const flushBlockBytes = 1 shl 17
const infinityLength = 1e100
const digitsPerGroup = 3

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

proc formatRupiah(value: int64): string =
  let digitText = $value
  let groupCount = (digitText.len - 1) div digitsPerGroup
  result = newStringOfCap(digitText.len + groupCount)
  for digitIndex in 0 .. digitText.len - 1:
    if digitIndex > 0 and (digitText.len - digitIndex) mod digitsPerGroup == 0:
      result.add '.'
    result.add digitText[digitIndex]
```

The scanner skips spaces and newlines between coordinates.
Grouping runs from the right, so 9795 becomes 9.795.
One buffer holds all case lines until it reaches the block size.

**Tree growth and billing.** Each round adds one pipe and updates the nearest links.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let plantCount = nextInt(inputData, scanPos)
  let pricePerMeter = nextInt(inputData, scanPos)
  var plantXs = newSeq[int](plantCount)
  var plantYs = newSeq[int](plantCount)
  for plantIndex in 0 .. plantCount - 1:
    plantXs[plantIndex] = nextInt(inputData, scanPos)
    plantYs[plantIndex] = nextInt(inputData, scanPos)
  var closestEdges = newSeq[float](plantCount)
  var linkedPlants = newSeq[bool](plantCount)
  for plantIndex in 0 .. plantCount - 1:
    closestEdges[plantIndex] = infinityLength
  closestEdges[0] = 0.0
  var totalLength = 0.0
  for stepIndex in 0 .. plantCount - 1:
    var chosenPlant = -1
    var chosenLength = infinityLength
    for plantIndex in 0 .. plantCount - 1:
      if not linkedPlants[plantIndex] and closestEdges[plantIndex] < chosenLength:
        chosenLength = closestEdges[plantIndex]
        chosenPlant = plantIndex
    linkedPlants[chosenPlant] = true
    totalLength = totalLength + chosenLength
    for plantIndex in 0 .. plantCount - 1:
      if not linkedPlants[plantIndex]:
        let horizontalGap = float(plantXs[chosenPlant] - plantXs[plantIndex])
        let verticalGap = float(plantYs[chosenPlant] - plantYs[plantIndex])
        let edgeLength = sqrt(horizontalGap * horizontalGap + verticalGap * verticalGap)
        if edgeLength < closestEdges[plantIndex]:
          closestEdges[plantIndex] = edgeLength
  let rawCost = totalLength * float(pricePerMeter)
  let roundedCost = int64(ceil(rawCost - 1e-9))
  appendOutput("Rp " & formatRupiah(roundedCost))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first plant starts the tree at zero length.
Distances use doubles, while the bill uses int64.
The final write flushes the remaining buffered text.

## Complexity

One pass reads the input, and the tree grows over N rounds.

| phase | time | space |
|---|---|---|
| input read | one pass over all coordinates | one input string |
| tree growth | N scans of N plants | two arrays of N values |
| billing | one rounding and one format per case | block buffer |

Each case adds one pipe per plant, so tree growth dominates.

| measure | Big O |
|---|---|
| time per case | O(N^2) |
| space per case | O(N) |

Enumerating pipe subsets would cost O(2^N) per case.

Takeaway: squared growth stays cheap at N equal to 1000.
