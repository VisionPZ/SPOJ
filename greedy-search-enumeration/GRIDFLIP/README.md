# GRIDFLIP — Flipping Slipping of grids (SPOJ)

<https://www.spoj.com/problems/GRIDFLIP/>

## Problem

Recover the three parameters that turn grid A into grid B by reversing top rows, reversing two column ranges, and moving the left columns to the right end. Choose the lexicographically largest triple that works.

Input gives one integer n, then n lines for grid A, then n lines for grid B. All cells are lowercase letters. Output three space separated integers i, j, k.

| item | bound |
|---|---|
| grid size n | 5 to 1000 |
| letters | lowercase only |
| judge limit | 3000 ms, 1536 MB |

A valid triple is guaranteed to exist.

Sample input:

```
5
ooscz
hkaea
nnzth
khdlf
rejtf
fldhk
htznn
aeakh
zcsoo
ftjer
```

Sample output:

```
3 3 4
```

The sample reverses rows 0 through 3, then moves four columns to the end.

## Idea

Finding the parameters is like identifying a shuffled deck from the backs of the cards before checking each card face. Every step permutes positions, so row effects and column effects can be separated. Column letter counts stay unchanged when rows move, which gives a short list of column candidates. Hashing the three column blocks of the answer finds those candidates in quadratic time. Trying all triples and rebuilding each grid would cost cubic time.

## Why It Works

1. The four steps only move cells; they never change a letter.
2. The row cut controls only which rows are permuted, and the two column cuts control only the column order.
3. Reordering rows leaves each column's letter counts unchanged.
4. The final column order is the middle block in order, then the right block reversed, then the left block reversed.
5. Rolling hashes test those three blocks in constant time, and an exact cell check confirms the largest triple.

| term | meaning |
|---|---|
| `rowCandidates` | row cuts whose row counts match |
| `leftCandidates` | first column cut of a candidate pair |
| `rightCandidates` | second column cut of a candidate pair |
| `matchesTransform` | exact cell by cell comparison |

The candidate lists shrink the search before any full grid is rebuilt.

A script trace for the sample column order:

```
n = 5, leftCut = 3, rightCut = 4, middle length = 0
middle block: none
right block reversed: column 4
left block reversed: columns 3 2 1 0
final order: 4 3 2 1 0, which matches the sample grid B
```

The trace explains why the sample reads its columns in reverse.

## Code

**Input and scanner.** The reader loads the size and both grids as tokens.

```nim
const hashBase: uint64 = 257
const flushBlockBytes = 1 shl 17

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Grid rows contain only lowercase letters.
Tokens skip the line breaks between rows.
One token holds one entire row.

**Hash helpers.** Letter counts become hashes, and prefix hashes give range values.

```nim
proc signatureHash(counts: array[26, int]): uint64 =
  var hashValue: uint64 = 0
  for letterIndex in 0 .. 25:
    hashValue = hashValue * hashBase + uint64(counts[letterIndex])
  return hashValue

proc rowSignature(text: string): uint64 =
  var counts: array[26, int]
  for letterIndex in 0 .. 25:
    counts[letterIndex] = 0
  for textIndex in 0 .. text.len - 1:
    counts[int(text[textIndex]) - 97] += 1
  return signatureHash(counts)

proc buildPrefix(values: seq[uint64], count: int): seq[uint64] =
  result = newSeq[uint64](count + 1)
  result[0] = 0
  for indexValue in 0 .. count - 1:
    result[indexValue + 1] = result[indexValue] * hashBase + values[indexValue]
  return result

proc rangeHash(prefix: seq[uint64], powers: seq[uint64], leftIndex, rightIndex: int): uint64 =
  return prefix[rightIndex] - prefix[leftIndex] * powers[rightIndex - leftIndex]
```

Rows with equal counts share a signature.
Column signatures use the same helper.
A range hash is one subtraction.

**Exact check.** The final check walks each target cell back to its source.

```nim
proc matchesTransform(sourceGrid: seq[string], targetGrid: seq[string], rowCut, leftCut, rightCut, size: int): bool =
  for targetRow in 0 .. size - 1:
    let sourceRow = if targetRow <= rowCut: rowCut - targetRow else: targetRow
    for targetColumn in 0 .. size - 1:
      let rotatedIndex = (targetColumn + leftCut + 1) mod size
      var suffixIndex = rotatedIndex
      if rotatedIndex >= rightCut:
        suffixIndex = size + rightCut - 1 - rotatedIndex
      let sourceColumn = if suffixIndex <= leftCut: leftCut - suffixIndex else: suffixIndex
      if sourceGrid[sourceRow][sourceColumn] != targetGrid[targetRow][targetColumn]:
        return false
  return true
```

The mapping inverts the four operations.
A mismatch exits on the first bad cell.
No temporary grid is allocated.

**Candidate search.** Row counts and column blocks narrow the triples.

```nim
var sourceRowSignatures = newSeq[uint64](gridSize)
var targetRowSignatures = newSeq[uint64](gridSize)
for rowIndex in 0 .. gridSize - 1:
  sourceRowSignatures[rowIndex] = rowSignature(sourceGrid[rowIndex])
  targetRowSignatures[rowIndex] = rowSignature(targetGrid[rowIndex])

var rowCandidates: seq[int] = @[]
for rowCut in countDown(gridSize - 2, 1):
  var agree = true
  for targetRow in 0 .. gridSize - 1:
    let sourceRow = if targetRow <= rowCut: rowCut - targetRow else: targetRow
    if sourceRowSignatures[sourceRow] != targetRowSignatures[targetRow]:
      agree = false
      break
  if agree:
    rowCandidates.add rowCut
```

Row cuts are visited from largest to smallest.
The loop compares only letter counts.
A full cell check comes later.

```nim
var leftCandidates: seq[int] = @[]
var rightCandidates: seq[int] = @[]
for leftCut in countDown(gridSize - 2, 0):
  if rangeHash(targetPrefix, powers, gridSize - leftCut - 1, gridSize) !=
      rangeHash(reversedPrefix, powers, gridSize - 1 - leftCut, gridSize):
    continue
  for rightCut in countDown(gridSize - 1, leftCut + 1):
    let middleLength = rightCut - leftCut - 1
    if rangeHash(targetPrefix, powers, 0, middleLength) !=
        rangeHash(sourcePrefix, powers, leftCut + 1, rightCut):
      continue
    if rangeHash(targetPrefix, powers, middleLength, gridSize - leftCut - 1) !=
        rangeHash(reversedPrefix, powers, 0, gridSize - rightCut):
      continue
    leftCandidates.add leftCut
    rightCandidates.add rightCut
```

The first hash test fixes the left cut.
The next two tests fix the right cut.
Candidates are stored in lexicographic order.

```nim
var answerFound = false
for rowIndex in 0 .. rowCandidates.len - 1:
  if answerFound:
    break
  let rowCut = rowCandidates[rowIndex]
  for pairIndex in 0 .. leftCandidates.len - 1:
    let leftCut = leftCandidates[pairIndex]
    let rightCut = rightCandidates[pairIndex]
    if matchesTransform(sourceGrid, targetGrid, rowCut, leftCut, rightCut, gridSize):
      appendOutput($rowCut & " " & $leftCut & " " & $rightCut)
      outputBuffer.add '\n'
      answerFound = true
      break
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first exact match is the largest triple.
Output is one line with three integers.
The buffer flushes once at the end.

## Complexity

Work splits into signatures, candidate search, and one exact check.

| phase | time | space |
|---|---|---|
| signatures | two passes over all cells | four sequences |
| candidate search | one pair per column cut pair | two candidate lists |
| exact check | one pass over all cells | no extra grid |
| output | one line | block buffer |

The phase table shows one quadratic pass for each major step.

| measure | Big O |
|---|---|
| time | O(n^2) |
| space | O(n^2) for the grids |

Rebuilding the grid for every triple would cost O(n^5).
The block hashes cut that to a single quadratic pass.
