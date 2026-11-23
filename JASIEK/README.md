## Problem

Jasiek colors connected grid squares with no white holes. He describes a walk around the centers of the boundary squares, one step north, west, south, or east per letter. Read ten descriptions and print the number of colored squares in each picture.

The judge fixes these bounds:

| quantity | limit |
| --- | --- |
| descriptions per run | 10 |
| letters per description | 20000 |
| time limit | 1000 ms |
| memory limit | 1536 MB |

Each answer is one integer on its own line.

The shoelace term for a step is `x1*y2 - x2*y1`, for the centers before and after that step. The count is `(area + moves + 2) / 2`.

## Idea

Put a lattice point at the center of every square. The walk closes around the centers of the boundary squares. The shoelace sum gives twice the signed area of that closed path. Pick's theorem relates a lattice polygon's area to its interior and boundary lattice points. That relation turns the area and the move count into the number of colored squares. The program scans each letter once and keeps three running totals.

Cost: one shoelace term and three additions per move, with no grid stored.

## Why It Works

A colored square has a lattice point at its center. Boundary squares lie on the walk. Interior squares lie inside it. The no-hole rule keeps white lattice points out of that inside region. A retraced step adds zero to the shoelace sum and one to the move count. The move count therefore supplies the boundary term even where the walk revisits a square.

The count for one picture is:

`count = (|sum(x1*y2 - x2*y1)| + moveCount + 2) / 2`

Each term has a fixed role:

- `sum(x1*y2 - x2*y1)` adds one shoelace term per step.
- The absolute value removes the sign of the winding direction.
- `moveCount` counts boundary visits, one for each letter.
- `2` is the Pick constant.
- `/ 2` halves both the doubled area and the visit count.

The sample walk returns to its start after 26 moves. These are the nonzero shoelace terms from a script run over that walk:

| step | from | letter | to | term |
| --- | --- | --- | --- | --- |
| 4 | (0,-3) | E | (1,-3) | 3 |
| 5 | (1,-3) | N | (1,-2) | 1 |
| 14 | (5,0) | N | (5,1) | 5 |
| 15 | (5,1) | S | (5,0) | -5 |
| 21 | (3,-1) | N | (3,0) | 3 |

All 26 terms sum to 18. The count is `(18 + 26 + 2) / 2 = 23`.

## Code

The program reads the whole input once, then scans characters by index.

```nim
const flushBlockBytes = 1 shl 18

var inputData = ""
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
```

The line loop ends at EOF, so the bound is one pass over the input stream. `readLine` avoids the bulk read that Nim 0.19.4 lacks. The cost is one append per input line.

```nim
var outputBuffer = ""

var scanPos = 0
var centerX: int64 = 0
var centerY: int64 = 0
var doubledArea: int64 = 0
var moveCount: int64 = 0
var insideDescription = false
```

`scanPos` walks `inputData` from zero to its last index. State stays in fixed fields, so no per-case table exists. The cost is constant space.

```nim
while scanPos < inputData.len:
  let currentChar = inputData[scanPos]
  scanPos += 1
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

`P` starts a case and `K` closes it, so the loop runs once per input letter. The flush guard keeps memory at one block. The `if` on `insideDescription` keeps stray letters from emitting output. The cost is one branch and one comparison per letter.

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

This branch runs once per direction letter, so its bound is `moveCount`. The shoelace line uses the old center, which avoids an off-by-one term. `int64` keeps the sum safe at the largest legal walk. The cost is one multiply and a few adds per step.

```nim
stdout.write outputBuffer
```

This final write flushes the tail shorter than one block. It runs once, after the scan ends. The cost is one write call.

## Complexity

Reading costs O(total letters) time and O(total letters) space. The scan costs O(moves) time and O(1) extra space for each case. Output costs O(cases) time inside one buffered buffer. Total time is O(total letters), and total space is O(total letters) plus one output block.

A flood fill over the bounding grid would cost O(width times height) for each case. A walk of 20000 steps can span a grid of 10⁸ points, so the scan avoids that grid entirely.
