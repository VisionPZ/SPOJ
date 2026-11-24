## Problem

Read two n by n grids of colors, the start P and the target Q. Each color occurs at most twice. In one minute, permute the blocks inside any set of whole rows or any set of whole columns. Print the fewest minutes, or `no` when the color multisets differ.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | t ≤ 200 |
| Side length | 1 ≤ n ≤ 500 |
| Time limit | 1754 ms |
| Memory limit | 1536 MB |

The answer is always 0, 1, 2 or 3, so each case is a short decision.

## Idea

Treat a minute as one orientation: permute whole rows or whole columns. Three rounds of row, column, row always suffice, so the program only decides whether 0, 1 or 2 rounds suffice. A middle matrix captures the two-round case, and a 2-SAT solver decides whether that matrix exists.

Cost per cell: each check visits every cell a constant number of times, so the work is O(n^2) per case.

## Why It Works

A row round keeps every row's color multiset. A column round keeps every column's color multiset. Three rounds always work. Count tokens by their start row and final row. The counts form a doubly stochastic table, which splits into n permutation matrices. The first round puts one token per final row in every column, the second fixes rows, and the third fixes columns.

Two rounds of row then column need a middle matrix C1. Its rows hold P's row colors and its columns hold Q's column colors. A color with two blocks may send them to either pair of target cells. Each middle cell holds one block. The choices form a 2-SAT formula, and a satisfying choice fills C1.

The address formula uses two line numbers:

- `src` is the P line: `p div side` for rows, `p mod side` for columns.
- `tgt` is the Q line: `q mod side` for rows, `q div side` for columns.
- `src * side + tgt` is the middle cell address.

The generator prints the choices for the first sample case:

```text
color : P rows -> Q columns
1 : [0, 1] -> [1, 1]
2 : [1, 2] -> [0, 2]
3 : [0, 1] -> [0, 2]
4 : [0] -> [0]
5 : [2, 2] -> [1, 2]
answer: 2
```

The listed choices fill every row with distinct columns, so two rounds suffice.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The loop reads the whole stream once, so the scanner never touches the input stream again. The guard on `pos` skips whitespace and stops at the end. The buffer flushes in large blocks, which keeps writes rare. Cost: O(input size) for reading and parsing.

```nim
proc colorsMatch(side: int, firstGrid, secondGrid: seq[int], work: var seq[int]): bool =
  let cellTotal = side * side
  for i in 0..<cellTotal:
    work[firstGrid[i]] += 1
    work[secondGrid[i]] -= 1
  var ok = true
  for i in 1..cellTotal:
    if work[i] != 0: ok = false
    work[i] = 0
  return ok

proc linesMatch(side: int, firstGrid, secondGrid: seq[int], work: var seq[int], touched: var seq[int], byRow: bool): bool =
  for i in 0..<side:
    var bad = false
    for j in 0..<side:
      let cellIndex = if byRow: i * side + j else: j * side + i
      let colorFirst = firstGrid[cellIndex]
      if work[colorFirst] == 0: touched.add colorFirst
      work[colorFirst] += 1
      let colorSecond = secondGrid[cellIndex]
      if work[colorSecond] == 0: touched.add colorSecond
      work[colorSecond] -= 1
    for k in 0..<touched.len:
      if work[touched[k]] != 0: bad = true
      work[touched[k]] = 0
    touched.setLen 0
    if bad: return false
  return true
```

The loop bounds are the cell count and the side length. `work` returns to zero before the next line, so no color counter leaks between lines. Each line check costs O(n) cells, hence O(n^2) per case.

```nim
  for color in 1..cellTotal:
    if startFirst[color] == 0: continue
    let src0pos = startFirst[color] - 1
    let tgt0pos = goalFirst[color] - 1
    let src0 = if byRowFirst: src0pos div side else: src0pos mod side
    let tgt0 = if byRowFirst: tgt0pos mod side else: tgt0pos div side
    if startSecond[color] == 0:
      let claimCell = src0 * side + tgt0
      linkNext.add cellHead[claimCell]
      linkColor.add 0
      linkValue.add 0
      cellHead[claimCell] = linkColor.len - 1
      continue
```

The loop runs once per color, from 1 to the cell count. A single block gives one fixed claim, with no variable. A shared target column also needs no variable, which avoids a false choice. Cost: O(n^2) links at most.

```nim
    if constantCount == 1:
      for i in 0..<cellLits.len:
        let lit = cellLits[i]
        let negLit = lit xor 1
        arcTo.add lit
        arcNext.add arcHead[negLit]
        arcHead[negLit] = arcTo.len - 1
        reverseTo.add negLit
        reverseNext.add reverseHead[lit]
        reverseHead[lit] = reverseTo.len - 1
    else:
      for i in 0..<cellLits.len:
        for j in i + 1..<cellLits.len:
          let leftLit = cellLits[i]
          let rightLit = cellLits[j]
          let leftNeg = leftLit xor 1
          let rightNeg = rightLit xor 1
          arcTo.add rightLit
          arcNext.add arcHead[leftNeg]
          arcHead[leftNeg] = arcTo.len - 1
          reverseTo.add leftNeg
          reverseNext.add reverseHead[rightLit]
          reverseHead[rightLit] = reverseTo.len - 1
          arcTo.add leftLit
          arcNext.add arcHead[rightNeg]
          arcHead[rightNeg] = arcTo.len - 1
          reverseTo.add rightNeg
          reverseNext.add reverseHead[leftLit]
          reverseHead[leftLit] = reverseTo.len - 1
```

The outer loop scans every middle cell. Two fixed claims on one cell fail at once. Otherwise the code forbids each pair of choices that would claim the same cell. Cost: O(n^2) clauses on typical data.

```nim
  if not colorsMatch(side, initialGrid, targetGrid, work):
    answer = -1
  elif initialGrid == targetGrid:
    answer = 0
  elif linesMatch(side, initialGrid, targetGrid, work, touched, true) or linesMatch(side, initialGrid, targetGrid, work, touched, false):
    answer = 1
  elif twoRoundPossible(side, initialGrid, targetGrid, true) or twoRoundPossible(side, initialGrid, targetGrid, false):
    answer = 2
  if answer == -1:
    appendOutput("no\n")
  else:
    appendOutput($(answer) & "\n")
```

The checks run from cheapest to strongest, so a simple case skips the 2-SAT work. `answer = -1` marks a color mismatch and prints `no`. The middle matrix test runs in both orientations, rows then columns and columns then rows. Cost: O(n^2) per case.

## Complexity

Reading and parsing take O(total input) time and memory. The color and line checks take O(n^2) time each and O(n^2) counters. The 2-SAT build and the two component passes take O(n^2) time and O(n^2) memory.

The total is O(t * n^2) time and O(n^2) memory per case. A naive search over color arrangements is factorial, so it cannot handle n above 3.
