# MOULDS — Moulds (SPOJ)

<https://www.spoj.com/problems/MOULDS/>

## Problem

A command block of lifts and shifts drives a small blade over a solid cuboid. For each block, print the volume of hollows the blade cuts.

The bounds set the size of the problem.

| item | bound |
|---|---|
| data sets `d` | at most 10 |
| command block length | at most 10000 characters |
| cuboid | 250 x 250 x 30 mm |
| blade cross-section | 1 x 1 mm |
| maximum blade offset | 1000 mm |
| judge limits | 5 s, 1536 MB |

The grid holds 62500 cells, so one depth array fits in memory. Sample input and output:

```
1
[^2;@S2;]
```

```
3
```

## Idea

Store the deepest cut at each 1 mm cell in a flat array. A plunge cuts the current cell, and a shift cuts every cell along its path. The sum of stored depths is the hollow volume.

A plunge costs O(1). A shift costs O(250), the clipped grid width.

## Why It Works

Four facts carry the proof.

1. The blade cross-section is one 1 mm cell, so each command touches one cell at a time.
2. Removed material never returns, so each cell keeps the deepest cut it ever received.
3. The blade bottom stops at the cuboid bottom, so depth never exceeds `maxPenetration`.
4. Brackets and semicolons only order the commands, so a left-to-right scan runs them in order.

The array index multiplies `cellRow` by 250 and adds `cellCol`, with `cellRow` growing south and `cellCol` growing east. The initial `bladeDepth` of -1 puts the blade 1 mm above the top surface, so a plunge of 2 reaches depth 1.

The sample runs as follows.

```
command  row  col  depth  cells cut on this command
start      0    0     -1  none
^2         0    0      1  (0,0)->1
@S2        2    0      1  (0,0)->1 (1,0)->1 (2,0)->1
final depths: (0, 0)=1 (1, 0)=1 (2, 0)=1
volume = 1 + 1 + 1 = 3
```

Three cells each reach depth 1, so the volume is 3.

## Code

`cuboidSize` fixes the grid, `maxPenetration` caps the depth, `firstDigitValue` decodes digits, and `flushBlockBytes` sets the output block. The clear loop ends at `cuboidSize * cuboidSize - 1`.

```nim
const cuboidSize = 250
const maxPenetration = 30
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
```

The digit loop stops at the first non-digit, so a trailing semicolon is safe. The sign branch handles negative lift and shift distances. Cost is O(number length).

```nim
proc scanSigned(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var sign = 1
  if i < inputData.len and inputData[i] == '-':
    sign = -1
    i = i + 1
  elif i < inputData.len and inputData[i] == '+':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
  return sign * value
```

The bounds test skips cells outside the cuboid. The write keeps the larger depth, which implements fact 2. Cost is O(1).

```nim
proc cutCell(hollowDepth: var seq[int], cellRow, cellCol, cutDepth: int) =
  if cutDepth > 0 and cellRow >= 0 and cellRow < cuboidSize and cellCol >= 0 and cellCol < cuboidSize:
    var cellIndex = cellRow * cuboidSize + cellCol
    if cutDepth > hollowDepth[cellIndex]:
      hollowDepth[cellIndex] = cutDepth
```

The `readLine` loop builds one input buffer. Token bounds come from whitespace, so any spacing works. `bladeDepth` starts at -1 for the 1 mm gap.

```nim
var hollowDepth = repeat(0, cuboidSize * cuboidSize)
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = scanSigned(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var tokenStart = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  var tokenEnd = i
  var k = tokenStart
  var bladeDepth = -1
  var bladeRow = 0
  var bladeCol = 0
  while k < tokenEnd:
    var commandChar = inputData[k]
```

The clamp at `maxPenetration` stops the blade at the bottom. `cutCell` updates the current cell only. Cost is O(1).

```nim
    if commandChar == '^':
      k = k + 1
      var liftDistance = scanSigned(inputData, k)
      bladeDepth = bladeDepth + liftDistance
      if bladeDepth > maxPenetration: bladeDepth = maxPenetration
      cutCell(hollowDepth, bladeRow, bladeCol, bladeDepth)
```

The clipped range `rowLow .. rowHigh` holds at most `cuboidSize` cells. A huge shift distance is the trap, and clipping keeps the loop short. `bladeRow` and `bladeCol` advance to the target even outside the grid.

```nim
    elif commandChar == '@':
      k = k + 1
      var shiftDirection = inputData[k]
      k = k + 1
      var shiftDistance = scanSigned(inputData, k)
      var rowFrom = bladeRow
      var colFrom = bladeCol
      var rowTo = bladeRow
      var colTo = bladeCol
      if shiftDirection == 'N': rowTo = bladeRow - shiftDistance
      elif shiftDirection == 'S': rowTo = bladeRow + shiftDistance
      elif shiftDirection == 'W': colTo = bladeCol - shiftDistance
      elif shiftDirection == 'E': colTo = bladeCol + shiftDistance
      if rowTo != rowFrom:
        var rowLow = max(0, min(rowFrom, rowTo))
        var rowHigh = min(cuboidSize - 1, max(rowFrom, rowTo))
        var penetration = bladeDepth
        if penetration > maxPenetration: penetration = maxPenetration
        for i in rowLow .. rowHigh:
          cutCell(hollowDepth, i, bladeCol, penetration)
      else:
        var colLow = max(0, min(colFrom, colTo))
        var colHigh = min(cuboidSize - 1, max(colFrom, colTo))
        var penetration = bladeDepth
        if penetration > maxPenetration: penetration = maxPenetration
        for i in colLow .. colHigh:
          cutCell(hollowDepth, bladeRow, i, penetration)
      bladeRow = rowTo
      bladeCol = colTo
```

Brackets and semicolons fall through this branch. They add no cutting work.

```nim
    else:
      k = k + 1
```

The sum visits all `cuboidSize * cuboidSize` cells. `setLen 0` reuses the buffer after each 256 KiB block. The final write covers the tail.

```nim
  var volume = 0
  for cellDepth in hollowDepth: volume = volume + cellDepth
  outputBuffer.add $volume
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for cellIndex in 0 .. (cuboidSize * cuboidSize - 1): hollowDepth[cellIndex] = 0
stdout.write outputBuffer
```

## Complexity

The phases and their costs are as follows.

| phase | time | space |
|---|---|---|
| input read | one pass per line, then one token scan | input bytes |
| one plunge | O(1) | none |
| one shift | at most O(250) | none |
| volume sum | 62500 additions | none |
| output | one write per 256 KiB block | 256 KiB |

The grid and output block are the only sizable stores. Let L be the total command length and S the number of shifts. Time is O(L + 250*S + 62500*d), and space is O(62500) plus the input buffer. A full voxel grid marks 250*250*30 = 1.875 million cells and sums them, about 30 times the work of summing one depth array.
