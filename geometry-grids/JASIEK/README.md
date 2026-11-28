# JASIEK — Jasiek (SPOJ)
<https://www.spoj.com/problems/JASIEK/>

## Problem

A six-year-old colors grid squares, then describes their outline as a walk between square centers. His mother wants the exact square count.

The input holds ten descriptions stacked one after another. Each starts with `P`, ends with `K`, and lists steps `N`, `S`, `E`, or `W`. Print one count per description.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Descriptions | 10 |
| Letters per description | at most 20000 |
| Judge time | 1000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

Ten short walks fit in one pass.

Sample input and output:

Input:

```
P
S
S
S
E
N
E
E
S
E
E
N
N
N
N
S
S
S
W
W
N
N
W
W
W
N
S
K
```

Output:

```
23
```

## Idea

Convert the walk into area, then let a lattice rule count the squares. Think of tracing the outline of colored cells and counting the tiles it encloses.

The program applies the shoelace formula (twice the signed area from vertex coordinates) while reading the steps. A lattice rule (a link between enclosed area, walk length, and cells) turns that area into a square count. Each step costs two products and three additions. Drawing the picture and flooding it would need a grid and repeated scans.

Takeaway: one pass over the letters replaces the whole drawing.

## Why It Works

The identity holds for every closed walk around a hole-free group of squares.

1. The walk starts and ends at the same square center.
2. The shoelace sum `doubledArea` equals `2A`, twice the signed area.
3. `moveCount` counts steps, even when a center is visited twice.
4. The lattice rule gives `squares = (|2A| + moveCount + 2) / 2`.
5. The absolute value also handles a clockwise walk.

The terms are:

| Term | Meaning |
| --- | --- |
| `doubledArea` | Twice the signed area of the center walk |
| `moveCount` | Number of walk steps |
| `A` | Enclosed area in grid squares |
| `squares` | Colored squares in the picture |

Each term has one role in the final division.

A script checked the sample walk:

| Quantity | Value |
| --- | --- |
| Steps | 26 |
| Twice area | 18 |
| Area | 9 |
| Result | (18 + 26 + 2) / 2 = 23 |

The walk revisits centers, so the step count matters.

## Code

**Input and totals.**

```nim
const flushBlockBytes = 1 shl 18

var inputData = ""
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer

var outputBuffer = ""

var i = 0
var centerX: int64 = 0
var centerY: int64 = 0
var doubledArea: int64 = 0
var moveCount: int64 = 0
var insideDescription = false
```

The program reads all lines into one buffer. Three totals track area, position, and steps. `insideDescription` tells whether the current walk is open.

**Walk framing and output.**

```nim
while i < inputData.len:
  let currentChar = inputData[i]
  i += 1
  if currentChar == 'P':
    insideDescription = true
    centerX = 0
    centerY = 0
    doubledArea = 0
    moveCount = 0
  elif currentChar == 'K':
    if insideDescription:
      let areaValue = if doubledArea < 0: -doubledArea else: doubledArea
      let squareCount = (areaValue + moveCount + 2) div 2
      outputBuffer.add $squareCount
      outputBuffer.add '\n'
      if outputBuffer.len >= flushBlockBytes:
        stdout.write outputBuffer
        outputBuffer.setLen 0
    insideDescription = false
```

`P` opens a walk and clears every total. `K` closes it and emits the formula. The output buffer flushes after `flushBlockBytes` bytes.

**Step accumulation.**

```nim
  elif insideDescription:
    var stepX = 0
    var stepY = 0
    case currentChar
    of 'N':
      stepY = 1
    of 'S':
      stepY = -1
    of 'E':
      stepX = 1
    of 'W':
      stepX = -1
    else:
      continue
    doubledArea += centerX * int64(stepY) - int64(stepX) * centerY
    centerX += int64(stepX)
    centerY += int64(stepY)
    moveCount += 1
```

Each direction adds one component to the area sum. The code uses `int64`, so a long walk cannot overflow. One step costs one shoelace term.

**Final flush.**

```nim
stdout.write outputBuffer
```

This write emits any answer left in the buffer. Without it the last count would stay in memory.

## Complexity

The program reads once and prints ten lines.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(L) | O(L) |
| Shoelace scan | O(L) | O(1) |
| Output | O(10) | O(1) |

L is the total number of letters.

| Measure | Bound |
| --- | --- |
| Time | O(L) |
| Space | O(L) for the input buffer |

The scan runs once and dominates the runtime.

A drawing-based approach would allocate a grid and scan it again for each square.
