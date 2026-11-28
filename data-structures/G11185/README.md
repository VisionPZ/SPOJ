# G11185 — Ordenación Grado 11 (SPOJ)
<https://www.spoj.com/problems/G11185/>

## Problem

One integer N is given. Build a vector of N cells, print it, then print a reordered version.

For a position i from 1 to N, an even i gives cell i times i plus one. An odd i gives three times i plus one.
Even-valued cells go first in descending order. Odd-valued cells follow in ascending order.

| Item | Value |
|---|---|
| Input | one integer N |
| Output | label SIN ORDENAR, the vector, label ORDENADO, the sorted vector |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The statement prints an empty example output, so the contract text defines the format used here.

The statement sample input follows verbatim.

```
10
```

The corresponding output follows the written contract.

```
SIN ORDENAR
6 5 12 17 18 37 24 65 30 101
ORDENADO
30 24 18 12 6 5 17 37 65 101
```

## Idea

Imagine splitting a deck into red and blue cards, stacking reds high to low and blues low to high.
The program fills cells by position parity, then splits them by value parity.
Each group gets its own comparison sort, and the two groups are joined.
Sorting the whole vector at once would mix the required orders and fail.

The joined groups form the requested vector.

## Why It Works

1. Position parity decides the formula, so filling cells needs one pass.
2. Value parity decides the destination group, so splitting is exact.
3. Descending order on even values fills the leading cells.
4. Ascending order on odd values fills the trailing cells.
5. The two groups are disjoint, so joining them loses no cell.

| Term | Meaning |
|---|---|
| cell | one vector value at a position |
| even group | cells whose value is even |
| odd group | cells whose value is odd |
| joined vector | even group followed by odd group |

The table captures the two-part ordering rule.

A script trace of the sample lists both groups.

```
cells: [6, 5, 12, 17, 18, 37, 24, 65, 30, 101]
even values descending: [30, 24, 18, 12, 6]
odd values ascending: [5, 17, 37, 65, 101]
```

Joining those lists reproduces the sample output.

## Code

**Vector construction.**
```nim
proc buildVector(size: int): seq[int64] =
  result = newSeq[int64](size)
  for index in 0..<size:
    let position = index + 1
    if (position and 1) == 0:
      result[index] = int64(position) * int64(position) + 1'i64
    else:
      result[index] = 3'i64 * int64(position + 1)
```

Positions start at one. Even positions use the square formula. Odd positions use the linear formula.

**Group sorting.**
```nim
proc sortDescending(values: seq[int64]): seq[int64] =
  result = values
  result.sort(proc(left, right: int64): int =
    if left > right: -1
    elif left < right: 1
    else: 0)

proc sortAscending(values: seq[int64]): seq[int64] =
  result = values
  result.sort(proc(left, right: int64): int =
    if left < right: -1
    elif left > right: 1
    else: 0)
```

Each comparator fixes one direction. Comparison sort handles large vectors quickly.

**Vector writing.**
```nim
proc writeVector(values: seq[int64]) =
  for index in 0..<values.len:
    if index > 0:
      outputBuffer.add ' '
    appendOutput($(values[index]))
  outputBuffer.add '\n'
```

Elements are separated by single spaces. The buffer flushes at its block size.

**Driver.**
```nim
let vectorSize = nextInt(inputData, scanPos)
let originalVector = buildVector(vectorSize)
var evenValues: seq[int64] = @[]
var oddValues: seq[int64] = @[]
for value in originalVector:
  if (value and 1'i64) == 0'i64:
    evenValues.add value
  else:
    oddValues.add value

appendOutput("SIN ORDENAR")
outputBuffer.add '\n'
writeVector(originalVector)
appendOutput("ORDENADO")
outputBuffer.add '\n'
writeVector(sortDescending(evenValues) & sortAscending(oddValues))
```

The driver splits values by parity and joins the sorted groups. Labels match the statement wording.

## Complexity

Filling and sorting dominate the work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Vector fill | O(N) | N cells |
| Sorting | O(N log N) | two groups |
| Output | one write per block | buffer block |

Each cell is filled once and sorted once.

| Measure | Big O |
|---|---|
| Time | O(N log N) |
| Space | O(N) |

Checking every pair of cells would cost O(N squared), so comparison sorting wins.
