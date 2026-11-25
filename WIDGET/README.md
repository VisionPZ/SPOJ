# WIDGET — Widget Factory (SPOJ)

<https://www.spoj.com/problems/WIDGET/>

## Problem

Each widget type takes between 3 and 9 days to build. Records give only the weekday a worker started, the weekday they left, and the multiset of widgets they built. Recover each build time when the records force one answer.

Working days include both the start day and the end day, so a record spanning Monday to Thursday lasts 4 days. Weekdays map to numbers 0 for MON through 6 for SUN. Each record gives one congruence modulo 7: the sum of the build times in its list equals the inclusive day span modulo 7.

Input contains blocks. Each block starts with n and m, the type count and record count. Each record then has a widget count k, a start weekday, an end weekday, and a line with k type numbers from 1 to n. A block with n = m = 0 ends the input.

Output has one line per block. Print n space-separated build times, `Multiple solutions.`, or `Inconsistent data.`. Here `Multiple solutions.` and `Inconsistent data.` are exact output strings defined by this contract.

The bounds size the linear system:

| item | bound |
|---|---|
| widget types n | 1 to 300 |
| records m | 1 to 300 |
| widgets per record k | 1 to 10000 |
| build time | 3 to 9 days |
| judge limit | 2000 ms, 1536 MB |

The product m times n drives elimination, and k drives input volume.

Sample input:

```
2 3
2 MON THU
1 2
3 MON FRI
1 1 2
3 MON SUN
1 2 2
10 2
1 MON TUE 
3
1 MON WED
3
0 0
```

Sample output:

```
8 3
Inconsistent data.
```

## Idea

Solving the records is like balancing scales that wrap around after seven days. Each record weighs a multiset of widget types against a residue, so the whole set forms a linear system modulo 7.

Gauss-Jordan elimination reduces the augmented matrix. A zero row with a nonzero right side proves contradiction, and a free column proves several solutions. Otherwise each pivot value is a residue, and residues 0, 1 and 2 map to 7, 8 and 9 days while residues 3 through 6 map to themselves.

Full elimination touches every row for every pivot. The cost is cubic in n and linear in m, far below trying all 7 to the n assignments.

## Why It Works

1. The inclusive span from weekday s to weekday e is e minus s plus 1, reduced modulo 7.
2. A record lists each built widget, so its coefficients count how many times each type appears.
3. The seven residues form a field, so division by any nonzero pivot uses the table in `inverseValues`.
4. Reducing all rows leaves one pivot per independent column and no coefficient above or below a pivot.
5. A row with zero coefficients and a nonzero right side cannot hold for any assignment.
6. A free column leaves one variable unpinned, so at least two assignments satisfy every record.
7. When no column is free, `appendDays` turns each residue into its unique day count from 3 to 9.

Terms and formulas:

| term | meaning |
|---|---|
| `equations` | augmented matrix of coefficients and day residues |
| `pivotRow` | index of the next pivot row during elimination |
| `freeColumns` | count of columns without a pivot |
| `duration` | inclusive weekday span reduced modulo 7 |
| `appendDays` | maps residue 0, 1, 2 to 7, 8, 9 and keeps 3 through 6 |

The residue field makes every nonzero pivot invertible.

The sample trace from gen.py:

```
1*x1 + 1*x2 = 4 (mod 7)
2*x1 + 1*x2 = 5 (mod 7)
1*x1 + 2*x2 = 0 (mod 7)
solution residues 1 3 -> days 8 3
```

Subtracting the first equation from the second gives x1 = 1, and the third equation then forces x2 = 3, matching the sample line 8 3.

## Code

**Input and day parsing.** The reader loads all bytes and decodes weekdays from their first two letters.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusDays = 7
const inverseValues = [0'u8, 1'u8, 4'u8, 5'u8, 2'u8, 3'u8, 6'u8]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextDayIndex(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let firstChar = data[pos]
  let secondChar = data[pos + 1]
  pos += 3
  case firstChar
  of 'M': return 0
  of 'T':
    if secondChar == 'U': return 1
    return 3
  of 'W': return 2
  of 'F': return 4
  of 'S':
    if secondChar == 'A': return 5
    return 6
  else: return 0
```

The second letter separates TUE from THU and SAT from SUN.
Adding 7 before taking the residue keeps negative day spans positive.
The scanner walks past spaces and newlines without copying tokens.

**Record assembly.** Each record contributes one row of counts and one day residue.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendDays(residue: int) =
  var dayCount = residue
  if dayCount <= 2:
    dayCount += modulusDays
  appendOutput($dayCount)

while true:
  let typeCount = nextInt(inputData, scanPos)
  let recordCount = nextInt(inputData, scanPos)
  if typeCount == 0 and recordCount == 0:
    break
  let rowWidth = typeCount + 1
  var equations = newSeq[uint8](recordCount * rowWidth)
  for recordIndex in 0 .. recordCount - 1:
    let widgetCount = nextInt(inputData, scanPos)
    let startDay = nextDayIndex(inputData, scanPos)
    let endDay = nextDayIndex(inputData, scanPos)
    let duration = (endDay - startDay + 1 + modulusDays) mod modulusDays
    let rowStart = recordIndex * rowWidth
    equations[rowStart + typeCount] = uint8(duration)
    for widgetIndex in 0 .. widgetCount - 1:
      let widgetType = nextInt(inputData, scanPos) - 1
      let columnIndex = rowStart + widgetType
      equations[columnIndex] = uint8((int(equations[columnIndex]) + 1) mod modulusDays)
```

One flat array holds all rows, so no nested sequence allocation occurs.
Repeated widget types increment the same coefficient cell.
The rightmost cell of each row stores that record's `duration`.

**Elimination and verdict.** Pivots reduce every row, then the matrix decides the answer.

```nim
  var pivotRow = 0
  var freeColumns = 0
  for columnIndex in 0 .. typeCount - 1:
    var selectedRow = -1
    for rowIndex in pivotRow .. recordCount - 1:
      if equations[rowIndex * rowWidth + columnIndex] != 0'u8:
        selectedRow = rowIndex
        break
    if selectedRow == -1:
      freeColumns += 1
      continue
    if selectedRow != pivotRow:
      for columnScan in columnIndex .. typeCount:
        let pivotValue = equations[pivotRow * rowWidth + columnScan]
        equations[pivotRow * rowWidth + columnScan] = equations[selectedRow * rowWidth + columnScan]
        equations[selectedRow * rowWidth + columnScan] = pivotValue
    let pivotValue = int(equations[pivotRow * rowWidth + columnIndex])
    let scale = int(inverseValues[pivotValue])
    if scale != 1:
      for columnScan in columnIndex .. typeCount:
        let position = pivotRow * rowWidth + columnScan
        equations[position] = uint8((int(equations[position]) * scale) mod modulusDays)
    for rowIndex in 0 .. recordCount - 1:
      if rowIndex == pivotRow:
        continue
      let factor = int(equations[rowIndex * rowWidth + columnIndex])
      if factor == 0:
        continue
      let pivotStart = pivotRow * rowWidth
      let rowStart = rowIndex * rowWidth
      for columnScan in columnIndex .. typeCount:
        let subtraction = (factor * int(equations[pivotStart + columnScan])) mod modulusDays
        equations[rowStart + columnScan] = uint8(
          (int(equations[rowStart + columnScan]) + modulusDays - subtraction) mod modulusDays)
    pivotRow += 1
  var inconsistent = false
  for rowIndex in pivotRow .. recordCount - 1:
    let rowStart = rowIndex * rowWidth
    var zeroCoefficients = true
    for columnIndex in 0 .. typeCount - 1:
      if equations[rowStart + columnIndex] != 0'u8:
        zeroCoefficients = false
        break
    if zeroCoefficients and equations[rowStart + typeCount] != 0'u8:
      inconsistent = true
      break
  if inconsistent:
    appendOutput("Inconsistent data.")
  elif freeColumns > 0:
    appendOutput("Multiple solutions.")
  else:
    for typeIndex in 0 .. typeCount - 1:
      if typeIndex > 0:
        appendOutput(" ")
      appendDays(int(equations[typeIndex * rowWidth + typeCount]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Elimination scans columns in order and skips those without a pivot.
Subtraction adds 7 before reducing so no negative byte appears.
The verdict checks contradiction first, freedom second, and a unique answer last.

## Complexity

The three phases of each block have the following costs.

| phase | time | space |
|---|---|---|
| input read | one pass over k widget numbers per record | one input string |
| record assembly | one increment per widget | m rows of n + 1 bytes |
| elimination | one pivot sweep per column over all rows | the same matrix |
| output | one line per block | block buffer |

Elimination dominates because it sweeps m rows for each of n columns.

| measure | Big O |
|---|---|
| time | O(m * n^2) per block |
| space | O(m * n) |

Trying all assignments costs 7 to the n, while elimination stays polynomial.
The residue field keeps every intermediate value inside one byte.
