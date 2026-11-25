# PHIDIAS — Phidias (SPOJ)

<https://www.spoj.com/problems/PHIDIAS/>

## Problem

Cut a rectangular slab of size `W` × `H` into desired plates `W_i` × `H_i` with straight cuts across a whole piece. Waste is the slab area left over, and the task is to make that waste as small as possible.

Input: the test count `t`, then per case the slab width and height, the plate count, and one width/height pair per plate. Plates cannot rotate, so each pair keeps its order.

Output: one integer per case, the minimum wasted area.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | at most 20 |
| Slab width `W` | 1 to 600 |
| Slab height `H` | 1 to 600 |
| Desired plates `N` | 1 to 200 |
| Plate sizes | 1 ≤ `W_i` ≤ `W` and 1 ≤ `H_i` ≤ `H` |
| Judge limit | 21 s, 1536 MB |

The 600 by 600 grid drives the design, while the plate count only sizes the input.

The sample case:

```
1
21 11
4
10 4
6 2
7 5
15 10
```

```
10
```

The sample wastes 10 units of area.

## Idea

Score every possible sub-rectangle once, like filling a price list before shopping. Later cuts then read earlier scores instead of repeating work. The algorithm is dynamic programming over rectangle sizes. Each size tries every legal cut position and keeps the smallest waste. A size matching a desired plate scores zero.

A state costs one pass over candidate cut positions, at most 600 per direction. Exploring cut trees by recursion repeats the same sub-rectangles many times, so one table answers each size once. Only sums of plate widths or heights can end a useful cut, which shortens each pass.

Takeaway: one table of at most 360,000 sizes replaces an exponential search.

## Why It Works

1. A straight cut splits a rectangle into two smaller rectangles, so each subproblem shrinks in one dimension.
2. A size matching a desired plate needs no cuts, so its waste is zero.
3. Any other size wastes its whole area, or the sum of the two children's wastes at some cut.
4. A useful cut leaves plates on at least one side. Moving that side's boundary to the end of its plates never raises waste, so cut positions are sums of plate widths or heights.
5. A state whose waste equals its area saves nothing. If neither child can save area, no cut helps.

The terms in each candidate value:

| Term | Meaning |
|---|---|
| whole waste | area w × h when no cut helps |
| plate size | zero waste when the rectangle matches a desired plate |
| vertical cut at x | waste(x, h) + waste(w − x, h) |
| horizontal cut at y | waste(w, y) + waste(w, h − y) |
| reachable sum | any total built by adding desired widths or desired heights |

Every candidate is a sum of two earlier table entries, so one table pass settles every case.

A script traced a 10 by 10 slab with one 3 by 3 plate:

```
reachable width sums: 0 3 6 9
reachable height sums: 0 3 6 9
h= 1 w= 1:1 w= 3:3 w= 4:4 w= 6:6 w= 7:7 w= 9:9 w=10:10
h= 3 w= 1:3 w= 3:0 w= 4:3 w= 6:0 w= 7:3 w= 9:0 w=10:3
h= 4 w= 1:4 w= 3:3 w= 4:7 w= 6:6 w= 7:10 w= 9:9 w=10:13
h= 6 w= 1:6 w= 3:0 w= 4:6 w= 6:0 w= 7:6 w= 9:0 w=10:6
h= 7 w= 1:7 w= 3:3 w= 4:10 w= 6:6 w= 7:13 w= 9:9 w=10:16
h= 9 w= 1:9 w= 3:0 w= 4:9 w= 6:0 w= 7:9 w= 9:0 w=10:9
h=10 w= 1:10 w= 3:3 w= 4:13 w= 6:6 w= 7:16 w= 9:9 w=10:19
vertical cuts of 10x10: x=3 -> 19, x=6 -> 19, x=9 -> 19
horizontal cuts of 10x10: y=3 -> 19, y=6 -> 19, y=9 -> 19
answer 19
```

Nine plates fill 81 of the 100 cells, and the other 19 cells are waste.

## Code

**Input reader and constants.** Scans digits from one buffer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scanner skips separators, so blank lines cannot desync the reader. It builds each integer without substrings. Cost: one pass over input bytes.

**Bulk input and plate flags.** Reads the stream once, then records desired sizes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 1 .. caseCount:
  let slabWidth = nextInt(inputData, scanPos)
  let slabHeight = nextInt(inputData, scanPos)
  let plateCount = nextInt(inputData, scanPos)

  var desiredWidths = newSeq[int](plateCount)
  var desiredHeights = newSeq[int](plateCount)
  let widthStride = slabHeight + 1
  let heightStride = slabWidth + 1
  var plateFlags = newSeq[bool]((slabWidth + 1) * widthStride)

  for plateIndex in 0 ..< plateCount:
    let plateWidth = nextInt(inputData, scanPos)
    let plateHeight = nextInt(inputData, scanPos)
    desiredWidths[plateIndex] = plateWidth
    desiredHeights[plateIndex] = plateHeight
    plateFlags[plateWidth * widthStride + plateHeight] = true
```

The read loop appends every line to one `inputData` string. `plateFlags` marks sizes that score zero. Cost: one pass plus one byte per plate.

**Cut positions.** Builds reachable sums and flat cut lists.

```nim
  var reachableWidth = newSeq[bool](slabWidth + 1)
  var reachableHeight = newSeq[bool](slabHeight + 1)
  reachableWidth[0] = true
  reachableHeight[0] = true
  for sumValue in 0 .. slabWidth:
    if reachableWidth[sumValue]:
      for plateIndex in 0 ..< plateCount:
        let reached = sumValue + desiredWidths[plateIndex]
        if reached <= slabWidth: reachableWidth[reached] = true
  for sumValue in 0 .. slabHeight:
    if reachableHeight[sumValue]:
      for plateIndex in 0 ..< plateCount:
        let reached = sumValue + desiredHeights[plateIndex]
        if reached <= slabHeight: reachableHeight[reached] = true

  var widthCutValues: seq[int] = @[]
  var heightCutValues: seq[int] = @[]
  var widthCutStart = newSeq[int](slabWidth + 2)
  var widthCutCount = newSeq[int](slabWidth + 1)
  var heightCutStart = newSeq[int](slabHeight + 2)
  var heightCutCount = newSeq[int](slabHeight + 1)
  for currentWidth in 1 .. slabWidth:
    widthCutStart[currentWidth] = widthCutValues.len
    for cutWidth in 1 ..< currentWidth:
      if reachableWidth[cutWidth]: widthCutValues.add cutWidth
    widthCutCount[currentWidth] = widthCutValues.len - widthCutStart[currentWidth]
  for currentHeight in 1 .. slabHeight:
    heightCutStart[currentHeight] = heightCutValues.len
    for cutHeight in 1 ..< currentHeight:
      if reachableHeight[cutHeight]: heightCutValues.add cutHeight
    heightCutCount[currentHeight] = heightCutValues.len - heightCutStart[currentHeight]
```

Reachable sums come from repeated addition of desired widths and heights. Flat lists avoid a new sequence per rectangle. Cost: at most (W + H) × N steps.

**Waste table.** Fills two layouts of the same values.

```nim
  var wasteByWidth = newSeq[int32]((slabWidth + 1) * widthStride)
  var wasteByHeight = newSeq[int32]((slabHeight + 1) * heightStride)
  var usefulWidthByHeight = newSeq[int](slabHeight + 1)

  for currentWidth in 1 .. slabWidth:
    let rowOffset = currentWidth * widthStride
    var usefulHeightForRow = 0
    for currentHeight in 1 .. slabHeight:
      let wholeWaste = currentWidth * currentHeight
      var bestWaste = int32(wholeWaste)
      if plateFlags[rowOffset + currentHeight]:
        bestWaste = 0'i32
      else:
        if usefulWidthByHeight[currentHeight] > 0:
          let verticalStart = widthCutStart[currentWidth]
          for cutIndex in verticalStart ..< verticalStart + widthCutCount[currentWidth]:
            let cutWidth = widthCutValues[cutIndex]
            let leftOffset = currentHeight * heightStride + cutWidth
            let rightOffset = currentHeight * heightStride + (currentWidth - cutWidth)
            let candidateWaste = wasteByHeight[leftOffset] + wasteByHeight[rightOffset]
            if candidateWaste < bestWaste: bestWaste = candidateWaste
            if bestWaste == 0'i32: break
        if bestWaste != 0'i32 and usefulHeightForRow > 0:
          let horizontalStart = heightCutStart[currentHeight]
          for cutIndex in horizontalStart ..< horizontalStart + heightCutCount[currentHeight]:
            let cutHeight = heightCutValues[cutIndex]
            let lowerOffset = rowOffset + cutHeight
            let upperOffset = rowOffset + (currentHeight - cutHeight)
            let candidateWaste = wasteByWidth[lowerOffset] + wasteByWidth[upperOffset]
            if candidateWaste < bestWaste: bestWaste = candidateWaste
            if bestWaste == 0'i32: break
      if bestWaste < int32(wholeWaste):
        usefulWidthByHeight[currentHeight] += 1
        usefulHeightForRow += 1
      wasteByWidth[rowOffset + currentHeight] = bestWaste
    for currentHeight in 1 .. slabHeight:
      wasteByHeight[currentHeight * heightStride + currentWidth] = wasteByWidth[rowOffset + currentHeight]
```

Vertical reads stay contiguous in `wasteByHeight`, horizontal reads in `wasteByWidth`. `usefulWidthByHeight` skips scans that cannot improve the answer. One transposed copy per width costs O(W × H) writes.

**Answer and output.** Appends one line per case and flushes in blocks.

```nim
  let answer = wasteByWidth[slabWidth * widthStride + slabHeight]
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The last cell holds the slab answer. `outputBuffer` flushes every 128 KiB, then once more for the tail. Cost: one write per block.

## Complexity

The program pays for the grid, not for the number of desired plates.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Reachable sums and cut lists | at most (W + H) × N additions | W + H booleans plus cut lists |
| Waste table | one pass over candidate cuts per cell | two tables of (W + 1)(H + 1) values |
| Output | one write per 128 KiB block | block buffer |

The table dominates, while input and output stay linear in their byte counts.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(W × H × (W + H)) worst case |
| Space | O(W × H) |

Enumerating cut trees grows exponentially, so filling each rectangle once is the practical win.
