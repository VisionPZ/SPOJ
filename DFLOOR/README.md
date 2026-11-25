# DFLOOR — Dance Floor (SPOJ)
<https://www.spoj.com/problems/DFLOOR/>

## Problem

A singer steps on glowing tiles, flipping that tile and its four side neighbors.
The program finds a short routine that lights them all.

Read several dance floors as grids of `0` and `1`.
Stepping on a tile flips it and its four side neighbors, up, down, left, and right.
Print the number of steps and the tile coordinates, or `-1` when no routine exists.

Each case gives width `x` and height `y`, followed by `y` rows of `x` characters.
Input ends with `0 0`.
Print the step count first, then that many lines `i j`.
Here `i` is the column and `j` is the row, both starting at 1.
Any valid routine is accepted.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Width `x` | 3 to 15 |
| Height `y` | 3 to 15 |
| Time limit | 2400 ms |
| Memory limit | 1536 MB |

The small grid lets one integer hold a whole row.

The sample input and expected output follow verbatim.

```
4 3
0111
1010
1000

0 0
```

```
3
1 2
1 3
4 3
```

Three presses light the 4 by 3 floor in the sample.

## Idea

Light chasing (sweeping rows so each step fixes the row above) turns a search into a fixed sweep.
Once the upper rows are settled, only one choice per tile in the next row can fix the row above.

The program transposes the grid so the shorter side becomes the width.
Each row is a bit mask (an integer whose bits are tiles).
A `crossRow` operation applies a vertical press and its two horizontal neighbors.
Row images and offsets carry one first-row choice down the floor.
Gaussian elimination (solving equations by eliminating variables with xor) handles the final row.

Cost per case is O(w³) bit operations for width w at most 15.
Trying all 2^(x*y) press sets is impossible.
Chase the light down, then solve one small linear system.

## Why It Works

Four facts prove the method.

1. Pressing a tile is its own inverse, so each tile needs at most one press.
2. Once row `j - 1` is fixed, only a press in row `j` can change that row.
   The press pattern of row `j` is therefore forced by the rows above.
3. Row images follow `image[j + 1] = crossRow(image[j]) xor image[j - 1]`.
   Offsets carry the target rows through the same recurrence.
4. The last row gives `w` equations in the first-row presses.
   Elimination over xor arithmetic either solves them or proves no routine exists.

The main values and their roles follow.

| Term | Meaning |
| --- | --- |
| `crossRow` | value xor left neighbor xor right neighbor on a row mask |
| `rowImages[j][k]` | effect on row `j` from pressing tile `k` in row zero |
| `offsets[j]` | forced contribution from the target in row `j` |
| `equations[l]` | bit `l` of the final-row system |

A consistent system yields the first-row presses and the whole routine.

A script presses the three sample tiles and prints each intermediate floor.

```
start:
  0111
  1010
  1000
press (1,2):
  1111
  0110
  0000
press (1,3):
  1111
  1110
  1100
press (4,3):
  1111
  1111
  1111
all tiles alight after 3 steps
```

The last floor is all ones, so the three commands are valid.

## Code

**Bulk input and scanner.**

```nim
var inputData = stdin.readAll()
var i = 0

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and ord(data[i]) <= 32:
    inc i

proc nextInt(data: string, i: var int): int =
  skipWhitespace(data, i)
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + (ord(data[i]) - 48)
    inc i
  return value
```

The whole stream is read into one buffer before parsing. skipWhitespace advances over separators by index. nextInt builds a number digit by digit. nextRowMask turns one grid row into a bit mask.

**Cross operation and output buffer.**

```nim
proc nextRowMask(data: string, i: var int, width: int): int =
  skipWhitespace(data, i)
  var mask = 0
  var k = 0
  while k < width and i < data.len:
    if data[i] == '1':
      mask = mask or (1 shl k)
    inc i
    inc k
  return mask

proc crossRow(value: int, widthMask: int): int =
  return value xor ((value shl 1) and widthMask) xor (value shr 1)

const flushBlockBytes = 1 shl 18
var outputBuffer = ""

proc emit(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

crossRow applies a press and its two horizontal neighbors in one xor. The output buffer flushes at 256 KiB. emit never writes one line at a time.

**Build the propagation table.**

```nim
while true:
  let width = nextInt(inputData, i)
  let height = nextInt(inputData, i)
  if width == 0 and height == 0:
    break

  var transposed = false
  var workWidth = width
  var workHeight = height
  if height < width:
    transposed = true
    workWidth = height
    workHeight = width

  var sourceRows: array[16, int]
  for j in 0 .. height - 1:
    sourceRows[j] = nextRowMask(inputData, i, width)

  var workRows: array[16, int]
  if transposed:
    for k in 0 .. width - 1:
      var rowMask = 0
      for j in 0 .. height - 1:
        if (sourceRows[j] and (1 shl k)) != 0:
          rowMask = rowMask or (1 shl j)
      workRows[k] = rowMask
  else:
    for j in 0 .. height - 1:
      workRows[j] = sourceRows[j]

  let allOn = (1 shl workWidth) - 1

  var rowImages: array[16, array[16, int]]
  var offsets: array[16, int]
  for k in 0 .. workWidth - 1:
    rowImages[0][k] = 1 shl k
    rowImages[1][k] = crossRow(1 shl k, allOn)
  offsets[1] = workRows[0] xor allOn
  for j in 1 .. workHeight - 2:
    for k in 0 .. workWidth - 1:
      rowImages[j + 1][k] =
        crossRow(rowImages[j][k], allOn) xor rowImages[j - 1][k]
    offsets[j + 1] =
      crossRow(offsets[j], allOn) xor offsets[j - 1] xor
      workRows[j] xor allOn
```

The case loop stops at the `0 0` sentinel. A transpose keeps the smaller dimension as the width. rowImages and offsets follow a two-row recurrence down the floor. The double loop touches at most 15 by 15 bits.

**Final-row equations.**

```nim
  var finalCoeff: array[16, int]
  for k in 0 .. workWidth - 1:
    finalCoeff[k] =
      crossRow(rowImages[workHeight - 1][k], allOn) xor rowImages[workHeight - 2][k]
  let finalTarget = workRows[workHeight - 1] xor allOn xor
                    crossRow(offsets[workHeight - 1], allOn) xor offsets[workHeight - 2]

  var equations: array[16, int]
  for l in 0 .. workWidth - 1:
    var equation = 0
    for k in 0 .. workWidth - 1:
      if ((finalCoeff[k] shr l) and 1) != 0:
        equation = equation or (1 shl k)
    if ((finalTarget shr l) and 1) != 0:
      equation = equation or (1 shl workWidth)
    equations[l] = equation
```

finalCoeff collects the effect of every first-row press on the last row. finalTarget adds the required final state. One row of the equation system is built per bit.

**Elimination.**

```nim
  var pivotCount = 0
  var pivotColumns: array[16, int]
  for k in 0 .. workWidth - 1:
    var selected = -1
    for j in pivotCount .. workWidth - 1:
      if ((equations[j] shr k) and 1) != 0:
        selected = j
        break
    if selected < 0:
      continue
    let held = equations[pivotCount]
    equations[pivotCount] = equations[selected]
    equations[selected] = held
    for j in 0 .. workWidth - 1:
      if j != pivotCount and ((equations[j] shr k) and 1) != 0:
        equations[j] = equations[j] xor equations[pivotCount]
    pivotColumns[pivotCount] = k
    inc pivotCount

  var inconsistent = false
  for j in pivotCount .. workWidth - 1:
    if ((equations[j] shr workWidth) and 1) != 0:
      inconsistent = true
```

The pivot loop chooses one equation per column. Xor elimination clears that column from all other rows. A remaining row with a set target bit proves the system inconsistent.

**Reconstruct the presses.**

```nim
  if inconsistent:
    emit("-1\n")
  else:
    var firstPattern = 0
    var i = pivotCount - 1
    while i >= 0:
      if ((equations[i] shr workWidth) and 1) != 0:
        firstPattern = firstPattern or (1 shl pivotColumns[i])
      dec i

    var pressRows: array[16, int]
    pressRows[0] = firstPattern
    pressRows[1] = crossRow(firstPattern, allOn) xor offsets[1]
    for j in 1 .. workHeight - 2:
      pressRows[j + 1] = workRows[j] xor allOn xor
                                crossRow(pressRows[j], allOn) xor pressRows[j - 1]

    var stepCount = 0
    for j in 0 .. workHeight - 1:
      for k in 0 .. workWidth - 1:
        if ((pressRows[j] shr k) and 1) != 0:
          inc stepCount
```

Back substitution recovers the first-row press pattern. The two-row recurrence then rebuilds every later row. Each press is stored as a single bit.

**Emit the routine.**

```nim
    emit($stepCount)
    emit("\n")
    for j in 0 .. workHeight - 1:
      for k in 0 .. workWidth - 1:
        if ((pressRows[j] shr k) and 1) != 0:
          if transposed:
            emit($(j + 1))
            emit(" ")
            emit($(k + 1))
            emit("\n")
          else:
            emit($(k + 1))
            emit(" ")
            emit($(j + 1))
            emit("\n")

stdout.write outputBuffer
```

The loops count set bits and print each pressed tile in 1-based coordinates. The transpose is undone when printing. The final write emits the remaining output bytes.

## Complexity

The phases and their costs for one case follow.

| Phase | Time | Space |
| --- | --- | --- |
| Read and transpose | O(x*y) | O(x*y) bits |
| Propagation table | O(w²*h) | O(w*h) |
| Elimination and back substitution | O(w³) | O(w²) |
| Output | O(number of presses) | one output block |

Here w is the smaller dimension and h is the larger one.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(w³) per case |
| Space | O(x*y) per case |

Trying all 2^(x*y) press sets grows past a trillion for a 15 by 15 floor.
