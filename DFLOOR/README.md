## Problem

Read dance-floor grids and print tile presses that switch every light on. One press toggles the chosen tile and its up-to-four neighbours. Print `-1` when no sequence works. Any valid sequence is accepted.

The judge bounds are fixed:

| Quantity | Limit |
| --- | --- |
| Width x and height y | 3 to 15 |
| Time | 2400 ms |
| Memory | 1536 MB |
| Source | 50000 B |

Both sides stay at 15 or below, so one integer holds a whole grid row.

## Idea

Model each press as a binary variable and each tile as a linear equation over GF(2). Light chasing fixes every later row once the first row's presses are known. Rather than trying all 2^15 first rows, propagate the first row symbolically and solve one small linear system. The naive chase costs O(2^W * H) per grid; this method costs O(W^2 * H + W^3).

Here W is the smaller side and H is the larger side.

## Why It Works

A press toggles its own tile and its four neighbours. Over GF(2) a toggle is XOR. A row of presses acts on its own row through H(v) = v xor (v shl 1) xor (v shr 1).

Each term has one job:

| Term | Meaning |
| --- | --- |
| v | press mask for one row, bit c for column c |
| v shl 1 | toggles applied to the column on the right |
| v shr 1 | toggles applied to the column on the left |
| mask | clears bits that fall outside the row |

The mask keeps the row inside W columns.

After rows 1 through r are pressed, row r holds workRows[r] xor H(press[r]) xor press[r-1] xor press[r+1]. Setting that to allOn gives press[r+1] = workRows[r] xor allOn xor H(press[r]) xor press[r-1]. Each press row therefore depends only on the two rows above it.

Write press[r] as A_r(p) xor b_r, where p is the first-row pattern. The images in rowImages and the shifts in offsets follow the same recurrence. The last row collapses to finalCoeff(p) = finalTarget, a system of W bit equations. Elimination solves it, and a zero row with a set right-hand side proves no solution exists.

The sample grid gives this sequence:

| Row | Initial tiles | Press columns |
| --- | --- | --- |
| 1 | 0111 | none |
| 2 | 1010 | 1 |
| 3 | 1000 | 1 and 4 |

The presses print as 1 2, 1 3 and 4 3, and every tile ends alight.

## Code

The input is read once into `inputData`. The scanner walks `scanPos` by digits, and `emit` flushes the output in blocks.

```
var inputData = stdin.readAll()
var scanPos = 0

proc skipWhitespace(data: string, pos: var int) =
  while pos < data.len and ord(data[pos]) <= 32:
    inc pos

proc nextInt(data: string, pos: var int): int =
  skipWhitespace(data, pos)
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + (ord(data[pos]) - 48)
    inc pos
  return value

proc nextRowMask(data: string, pos: var int, width: int): int =
  skipWhitespace(data, pos)
  var mask = 0
  var colIndex = 0
  while colIndex < width and pos < data.len:
    if data[pos] == '1':
      mask = mask or (1 shl colIndex)
    inc pos
    inc colIndex
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

The row reader stops after exactly width characters, so unspaced digits are correct. The block flush keeps memory bounded. These steps cost O(input size).

The case header stores the grid in fixed arrays. When height is below width, the grid is transposed so the chased dimension stays smallest.

```
while true:
  let width = nextInt(inputData, scanPos)
  let height = nextInt(inputData, scanPos)
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
  for rowIndex in 0 .. height - 1:
    sourceRows[rowIndex] = nextRowMask(inputData, scanPos, width)

  var workRows: array[16, int]
  if transposed:
    for columnIndex in 0 .. width - 1:
      var rowMask = 0
      for rowIndex in 0 .. height - 1:
        if (sourceRows[rowIndex] and (1 shl columnIndex)) != 0:
          rowMask = rowMask or (1 shl rowIndex)
      workRows[columnIndex] = rowMask
  else:
    for rowIndex in 0 .. height - 1:
      workRows[rowIndex] = sourceRows[rowIndex]

  let allOn = (1 shl workWidth) - 1
```

The transpose loop visits every cell once, so it costs O(width * height). The sentinel 0 0 ends the input.

The row images and offsets are propagated once. The last row then yields the small system.

```
  var rowImages: array[16, array[16, int]]
  var offsets: array[16, int]
  for colIndex in 0 .. workWidth - 1:
    rowImages[0][colIndex] = 1 shl colIndex
    rowImages[1][colIndex] = crossRow(1 shl colIndex, allOn)
  offsets[1] = workRows[0] xor allOn
  for rowIndex in 1 .. workHeight - 2:
    for colIndex in 0 .. workWidth - 1:
      rowImages[rowIndex + 1][colIndex] =
        crossRow(rowImages[rowIndex][colIndex], allOn) xor rowImages[rowIndex - 1][colIndex]
    offsets[rowIndex + 1] =
      crossRow(offsets[rowIndex], allOn) xor offsets[rowIndex - 1] xor
      workRows[rowIndex] xor allOn

  var finalCoeff: array[16, int]
  for colIndex in 0 .. workWidth - 1:
    finalCoeff[colIndex] =
      crossRow(rowImages[workHeight - 1][colIndex], allOn) xor rowImages[workHeight - 2][colIndex]
  let finalTarget = workRows[workHeight - 1] xor allOn xor
                    crossRow(offsets[workHeight - 1], allOn) xor offsets[workHeight - 2]

  var equations: array[16, int]
  for bitIndex in 0 .. workWidth - 1:
    var equation = 0
    for colIndex in 0 .. workWidth - 1:
      if ((finalCoeff[colIndex] shr bitIndex) and 1) != 0:
        equation = equation or (1 shl colIndex)
    if ((finalTarget shr bitIndex) and 1) != 0:
      equation = equation or (1 shl workWidth)
    equations[bitIndex] = equation
```

The propagation loop stops at workHeight - 2, since the final row has no row beneath it. Each equation stores its right-hand side in bit workWidth. This phase costs O(W^2 * H).

Elimination marks one pivot column at a time. A zero row with a set right-hand side means the grid cannot be solved.

```
  var pivotCount = 0
  var pivotColumns: array[16, int]
  for colIndex in 0 .. workWidth - 1:
    var selected = -1
    for rowIndex in pivotCount .. workWidth - 1:
      if ((equations[rowIndex] shr colIndex) and 1) != 0:
        selected = rowIndex
        break
    if selected < 0:
      continue
    let held = equations[pivotCount]
    equations[pivotCount] = equations[selected]
    equations[selected] = held
    for rowIndex in 0 .. workWidth - 1:
      if rowIndex != pivotCount and ((equations[rowIndex] shr colIndex) and 1) != 0:
        equations[rowIndex] = equations[rowIndex] xor equations[pivotCount]
    pivotColumns[pivotCount] = colIndex
    inc pivotCount

  var inconsistent = false
  for rowIndex in pivotCount .. workWidth - 1:
    if ((equations[rowIndex] shr workWidth) and 1) != 0:
      inconsistent = true
```

The outer loop runs at most workWidth times, so elimination costs O(W^3). Free columns stay zero, which gives one valid solution.

The solver rebuilds the press rows and prints them in the original orientation.

```
  if inconsistent:
    emit("-1\n")
  else:
    var firstPattern = 0
    var pivotIndex = pivotCount - 1
    while pivotIndex >= 0:
      if ((equations[pivotIndex] shr workWidth) and 1) != 0:
        firstPattern = firstPattern or (1 shl pivotColumns[pivotIndex])
      dec pivotIndex

    var pressRows: array[16, int]
    pressRows[0] = firstPattern
    pressRows[1] = crossRow(firstPattern, allOn) xor offsets[1]
    for rowIndex in 1 .. workHeight - 2:
      pressRows[rowIndex + 1] = workRows[rowIndex] xor allOn xor
                                crossRow(pressRows[rowIndex], allOn) xor pressRows[rowIndex - 1]

    var stepCount = 0
    for rowIndex in 0 .. workHeight - 1:
      for colIndex in 0 .. workWidth - 1:
        if ((pressRows[rowIndex] shr colIndex) and 1) != 0:
          inc stepCount

    emit($stepCount)
    emit("\n")
    for rowIndex in 0 .. workHeight - 1:
      for colIndex in 0 .. workWidth - 1:
        if ((pressRows[rowIndex] shr colIndex) and 1) != 0:
          if transposed:
            emit($(rowIndex + 1))
            emit(" ")
            emit($(colIndex + 1))
            emit("\n")
          else:
            emit($(colIndex + 1))
            emit(" ")
            emit($(rowIndex + 1))
            emit("\n")

stdout.write outputBuffer
```

The back-substitution walks pivots in reverse order. The print loop swaps row and column indices when `transposed` is set, which restores the requested coordinates. Printing costs O(number of presses).

## Complexity

Input parsing reads one buffer and costs O(input size). Each grid costs O(W^2 * H) to propagate the rows and O(W^3) to eliminate, with W and H both at most 15. Space is O(W * H) in fixed arrays, well under a kilobyte per grid. A brute-force chase costs O(2^W * H), roughly half a million row steps for a 15 by 15 grid.
