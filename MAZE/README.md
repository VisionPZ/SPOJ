## Problem

A maze has three rows and n columns of square blocks. Each block is empty, straight or bent, and the program may rotate any block by a multiple of 90 degrees. Decide whether those rotations form one passage from the left edge to the right edge. Print yes when a passage exists and no otherwise.

The bounds and judge limits are:

| Quantity | Bound |
| --- | --- |
| Test cases | no bound in the statement |
| Columns per case | 1 to 200000 |
| Blocks per column | 3, each of type 0, 1 or 2 |
| Time limit | 10000 ms |
| Memory limit | 1536 MB |

The column count sets the scale, so one column must cost a small fixed amount.

## Idea

State-compression dynamic programming keeps a three-bit mask of the rows whose right side is reachable from the left edge. A table built once maps one column's three block types and the current mask to the next mask. Trying every rotation of the whole maze grows exponentially with n.

One column costs one table lookup after its three integers are read.

## Why It Works

A straight block opens either the left and right sides or the top and bottom sides. A bent block opens one adjacent pair of sides, and its four rotations cover all four pairs. An empty block opens no side. Two cells in one column join only when the upper cell opens its bottom side and the lower cell opens its top side.

The component of joined rows acts as one unit. A passage entering any row of that component can leave through any row that opens its right side. Columns choose rotations independently, so no earlier choice limits the next column. The reachable-row mask is therefore a complete state.

The table uses these three rules:

- typeCode = topType * 9 + midType * 3 + botType packs the three block types into one key from 0 to 26.
- reachRows[l] holds the exit rows reachable from entry row l inside one column.
- nextMaskTable[typeCode][stateMask] gives the reachable rows after that column.

For the sample, the generator prints the mask trace 7 -> 3 -> 4 -> 4 -> 4 -> 4 -> 2. The last mask is nonzero, so the answer is yes.

## Code

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const bitLeft = 1
const bitRight = 2
const bitTop = 4
const bitBottom = 8
const orientCount = [1, 2, 4]
const orientSides = [[0, 0, 0, 0], [3, 12, 0, 0], [5, 6, 10, 9]]

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The orientation table stores side bits for each block type: 3 for left and right, 12 for top and bottom, and four corner masks. The scanner skips separators and stops at the buffer end. It reads each integer in one pass and allocates nothing.

```nim
proc buildReach(topType, midType, botType: int): array[3, int] =
  var reachRows = [0, 0, 0]
  for i in 0..<orientCount[topType]:
    for j in 0..<orientCount[midType]:
      for k in 0..<orientCount[botType]:
        var sides = [orientSides[topType][i], orientSides[midType][j], orientSides[botType][k]]
        let upperLink = (sides[0] and bitBottom) != 0 and (sides[1] and bitTop) != 0
        let lowerLink = (sides[1] and bitBottom) != 0 and (sides[2] and bitTop) != 0
        var leftRows = 0
        var rightRows = 0
        var compRows = [1, 2, 4]
        for l in 0..2:
          if (sides[l] and bitLeft) != 0: leftRows = leftRows or (1 shl l)
          if (sides[l] and bitRight) != 0: rightRows = rightRows or (1 shl l)
        if upperLink:
          compRows[0] = compRows[0] or 2
          compRows[1] = compRows[1] or 1
        if lowerLink:
          compRows[1] = compRows[1] or 4
          compRows[2] = compRows[2] or 2
        if upperLink and lowerLink:
          compRows[0] = compRows[0] or 4
          compRows[2] = compRows[2] or 1
        for l in 0..2:
          if (leftRows and (1 shl l)) != 0:
            reachRows[l] = reachRows[l] or (rightRows and compRows[l])
  return reachRows
```

The loops cover all rotations of the three blocks, at most four per block. compRows marks rows joined by open vertical sides, and the last branch adds the link across both joins. Each combination updates reachRows once, and there are at most 64 combinations.

```nim
var nextMaskTable: array[27, array[8, int]]
for i in 0..2:
  for j in 0..2:
    for k in 0..2:
      let reachRows = buildReach(i, j, k)
      let typeCode = i * 9 + j * 3 + k
      for l in 0..7:
        var nextMask = 0
        if (l and 1) != 0: nextMask = nextMask or reachRows[0]
        if (l and 2) != 0: nextMask = nextMask or reachRows[1]
        if (l and 4) != 0: nextMask = nextMask or reachRows[2]
        nextMaskTable[typeCode][l] = nextMask
```

The loops cover 27 type triples and eight incoming masks. typeCode packs a triple into one array index. The table is built once before input starts, at a cost of 216 cells.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let columnCount = nextInt(inputData, scanPos)
  var stateMask = 7
  for j in 0..<columnCount:
    let topType = nextInt(inputData, scanPos)
    let midType = nextInt(inputData, scanPos)
    let botType = nextInt(inputData, scanPos)
    let typeCode = topType * 9 + midType * 3 + botType
    stateMask = nextMaskTable[typeCode][stateMask]
  if stateMask != 0:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop reads the entire input into one buffer before parsing starts. appendOutput flushes after flushBlockBytes bytes, which caps memory on large test sets. The outer loop runs once per case and the inner loop once per column. The last write flushes the partial block.

## Complexity

Building the orientation table visits at most 64 combinations for each of 27 type triples. Scanning reads one integer per block and costs O(n) time and O(1) extra space per case. The output buffer uses one block of memory.

Total time is O(n) per case with a constant below ten operations per column. Total space is O(1) besides the input buffer and the output block. A naive search over all rotations takes exponential time in n.
