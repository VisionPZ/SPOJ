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

Store every rectangle's waste twice, once in width order and once in height order, so each cut reads two neighbouring cells. Think of one address book sorted by street and the same book sorted by name.

The program fills a dynamic-programming table of rectangle sizes. For each size it tries cuts up to `currentWidth div 2` or `currentHeight div 2`. A reversed copy supplies the matching half, so both reads advance through adjacent memory. A size matching a desired plate scores zero.

Each size costs one pass over at most half of the widths and heights. Exploring cut trees by recursion repeats the same subrectangles many times, while one table answers each size once.

Takeaway: two views of one table turn every cut pair into a neighbouring read.

## Why It Works

1. A straight cut splits a rectangle into two smaller rectangles, so each subproblem shrinks in one dimension.
2. A size matching a desired plate needs no cuts, so its waste is zero.
3. Any other size wastes its whole area, or the sum of the two children's wastes at some cut.
4. A cut at `x` and a cut at `w − x` use the same pair of children, so testing `x ≤ w div 2` covers every vertical cut. The same holds for height cuts.
5. `wasteByHeight` stores width `w` in height row `h`. `reversedByHeight` stores that value at `W − w`, so the second child of a vertical cut sits next to the first in a forward scan.
6. For one width, `reversedColumn` holds height `h` at `H − h`. The two children of a horizontal cut then sit next to each other as well.

The terms in each candidate value:

| Term | Meaning |
|---|---|
| whole waste | area `w × h` when no cut helps |
| plate size | zero waste when the rectangle matches a desired plate |
| vertical cut at `x` | `wasteByHeight[x] + reversedByHeight[W − w + x]` in height row `h` |
| horizontal cut at `y` | `wasteByWidth[y] + reversedColumn[H − h + y]` in width row `w` |
| cut bound | `currentWidth div 2` or `currentHeight div 2`, one copy of each pair |

Every candidate adds two earlier table entries, so one sweep settles every case.

A script traced a 10 by 10 slab with one 3 by 3 plate:

```
  h   w=1  w=3  w=4  w=6  w=7  w=9  w=10
  1   1    3    4    6    7    9    10
  3   3    0    3    0    3    0    3
  4   4    3    7    6    10   9    13
  6   6    0    6    0    6    0    6
  7   7    3    10   6    13   9    16
  9   9    0    9    0    9    0    9
 10  10   3    13   6    16   9    19
vertical cut pairs for 10x10:
  x=1 -> waste(1,10)+waste(9,10) = 10+9 = 19
  x=2 -> waste(2,10)+waste(8,10) = 20+26 = 46
  x=3 -> waste(3,10)+waste(7,10) = 3+16 = 19
  x=4 -> waste(4,10)+waste(6,10) = 13+6 = 19
  x=5 -> waste(5,10)+waste(5,10) = 23+23 = 46
horizontal cut pairs for 10x10:
  y=1 -> waste(10,1)+waste(10,9) = 10+9 = 19
  y=2 -> waste(10,2)+waste(10,8) = 20+26 = 46
  y=3 -> waste(10,3)+waste(10,7) = 3+16 = 19
  y=4 -> waste(10,4)+waste(10,6) = 13+6 = 19
  y=5 -> waste(10,5)+waste(10,5) = 23+23 = 46
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

  let widthStride = slabHeight + 1
  let heightStride = slabWidth + 1
  var plateFlags = newSeq[bool]((slabWidth + 1) * widthStride)

  for plateIndex in 0 ..< plateCount:
    let plateWidth = nextInt(inputData, scanPos)
    let plateHeight = nextInt(inputData, scanPos)
    plateFlags[plateWidth * widthStride + plateHeight] = true
```

The read loop appends every line to one `inputData` string. `plateFlags` marks sizes that score zero. Cost: one input pass plus one byte per plate.

**Waste tables.** Allocates the forward and reversed views of the grid.

```nim
  var wasteByWidth = newSeq[int32]((slabWidth + 1) * widthStride)
  var wasteByHeight = newSeq[int32]((slabHeight + 1) * heightStride)
  var reversedByHeight = newSeq[int32]((slabHeight + 1) * heightStride)
  var reversedColumn = newSeq[int32](slabHeight + 1)
```

Two tables hold the same values in opposite orders. Cost: four allocations per case, with no work inside the sweep.

**Sweep.** Fills each waste cell from cuts up to the middle.

```nim
  for currentWidth in 1 .. slabWidth:
    let rowOffset = currentWidth * widthStride
    for reverseHeight in 0 .. slabHeight:
      reversedColumn[reverseHeight] = 0'i32
    for currentHeight in 1 .. slabHeight:
      let wholeWaste = currentWidth * currentHeight
      var bestWaste = int32(wholeWaste)
      if plateFlags[rowOffset + currentHeight]:
        bestWaste = 0'i32
      else:
        let transposedBase = currentHeight * heightStride
        let widthShift = slabWidth - currentWidth
        for cutWidth in 1 .. currentWidth div 2:
          let candidateWaste = wasteByHeight[transposedBase + cutWidth] +
                               reversedByHeight[transposedBase + widthShift + cutWidth]
          if candidateWaste < bestWaste: bestWaste = candidateWaste
        if bestWaste != 0'i32:
          let columnShift = slabHeight - currentHeight
          for cutHeight in 1 .. currentHeight div 2:
            let candidateWaste = wasteByWidth[rowOffset + cutHeight] +
                                 reversedColumn[columnShift + cutHeight]
            if candidateWaste < bestWaste: bestWaste = candidateWaste
      wasteByWidth[rowOffset + currentHeight] = bestWaste
      reversedColumn[slabHeight - currentHeight] = bestWaste
    for currentHeight in 1 .. slabHeight:
      let transposedBase = currentHeight * heightStride
      let storedWaste = wasteByWidth[rowOffset + currentHeight]
      wasteByHeight[transposedBase + currentWidth] = storedWaste
      reversedByHeight[transposedBase + slabWidth - currentWidth] = storedWaste
```

Vertical reads advance through `wasteByHeight` and `reversedByHeight` together. Horizontal reads do the same inside one width row. The final loop stores each new column in both height-order tables. Cost: half of the cut positions, all read from adjacent cells.

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
| Input scan | one pass over input bytes | input bytes |
| Plate flags | one byte per plate | (W + 1)(H + 1) bytes |
| Waste sweep | one pass over half the cuts per cell | four tables over (W + 1)(H + 1) |
| Output | one write per 128 KiB block | block buffer |

The sweep dominates, while input and output stay linear in their byte counts.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(W × H × (W + H)) worst case |
| Space | O(W × H) |

Enumerating cut trees grows exponentially, so filling each rectangle once is the practical win.
