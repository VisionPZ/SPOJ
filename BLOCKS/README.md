# BLOCKS — Arranging the Blocks (SPOJ)
<https://www.spoj.com/problems/BLOCKS/>

## Problem

An n by n color grid must become a target grid by permuting whole rows or columns, one per minute. Find the fewest minutes, or report that the target cannot be reached.

Input starts with a case count t. Each case gives n, then n rows of start colors, then n rows of target colors. Output one number from 0 to 3, or the word `no`.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | t at most 200 |
| Side length | 1 to 500 |
| Color copies | at most two per color |
| Time limit | 1754 ms |
| Memory limit | 1536 MB |

The answer is always 0, 1, 2, or 3, so each case is a short decision.

The sample input and output:

```
3
3
1
3
4
2
1
3
2
5
5
3
1
3
2
1
2
4
5
5
3
1
2
3
4
5
6
7
8
9
1
5
6
4
2
9
7
8
3
2
1
2
1
2
1
3
1
2
```

```
2
1
no
```

The first board needs two rounds; the third cannot be built.

## Idea

Treat one minute as one orientation: permute rows or permute columns. Three rounds of row, column, row always suffice, so the program only tests whether 0, 1, or 2 rounds work. A middle matrix captures the two-round case, and a 2-SAT solver (a satisfiability test for paired choices) decides whether that matrix exists.

Each check visits every cell a constant number of times, so the cost is O(n^2) per case. Trying every row and column permutation would be factorial and impossible at n = 500.

Takeaway: decide between four answers instead of searching permutations.

## Why It Works

1. A row round keeps each row's color multiset; a column round keeps each column's color multiset.
2. Three rounds always work, because row permutations can sort colors into final columns, column permutations fix rows, and a last row round fixes columns.
3. Counting tokens by start row and final row gives a doubly stochastic table, which splits into permutation matrices.
4. For two rounds, a middle matrix C1 must hold P's row colors in its rows and Q's column colors in its columns.
5. A color with two blocks may send them to either pair of target cells, which gives one binary choice per such color.
6. Each middle cell holds one block, so conflicting choices form a 2-SAT formula; a satisfying assignment fills C1.

The address formula uses two line numbers.

| Term | Meaning |
| --- | --- |
| src | the P line: p div side for rows, p mod side for columns |
| tgt | the Q line: q mod side for rows, q div side for columns |
| src times side plus tgt | the middle cell address |
| component[2i] vs component[2i+1] | equal SCC ids mean a contradictory assignment |

The formula reduces every choice to one graph test.

A script printed the forced choices for the first sample case:

| Color | P rows | Q columns |
| --- | --- | --- |
| 1 | 0, 1 | 1, 1 |
| 2 | 1, 2 | 0, 2 |
| 3 | 0, 1 | 0, 2 |
| 4 | 0 | 0 |
| 5 | 2, 2 | 1, 2 |

Those choices satisfy the formula, so two rounds are enough.

## Code

**Input, scanner, and output helper.**
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
The buffer gathers all lines, and `nextInt` walks the digits. `appendOutput` flushes after flushBlockBytes bytes, which keeps the large output in blocks.

**Color and line checks.**
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
`colorsMatch` cancels start against target counts per color. `linesMatch` compares multiset counts per row or per column. `touched` resets only the colors it sees.

**Two-round setup.**
```nim
proc twoRoundPossible(side: int, firstGrid, secondGrid: seq[int], byRowFirst: bool): bool =
  let cellTotal = side * side
  var startFirst = newSeq[int](cellTotal + 1)
  var startSecond = newSeq[int](cellTotal + 1)
  var goalFirst = newSeq[int](cellTotal + 1)
  var goalSecond = newSeq[int](cellTotal + 1)
  for i in 0..<cellTotal:
    let colorFirst = firstGrid[i]
    if startFirst[colorFirst] == 0: startFirst[colorFirst] = i + 1
    else: startSecond[colorFirst] = i + 1
    let colorSecond = secondGrid[i]
    if goalFirst[colorSecond] == 0: goalFirst[colorSecond] = i + 1
    else: goalSecond[colorSecond] = i + 1
  var variableOf = newSeq[int](cellTotal + 1)
  var variableCount = 0
  var cellHead = newSeq[int](cellTotal)
  var linkNext: seq[int] = @[0]
  var linkColor: seq[int] = @[0]
  var linkValue: seq[int] = @[0]
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
    let src1pos = startSecond[color] - 1
    let tgt1pos = goalSecond[color] - 1
    let src1 = if byRowFirst: src1pos div side else: src1pos mod side
    let tgt1 = if byRowFirst: tgt1pos mod side else: tgt1pos div side
    if tgt0 == tgt1:
      let claimCell0 = src0 * side + tgt0
      linkNext.add cellHead[claimCell0]
      linkColor.add 0
      linkValue.add 0
      cellHead[claimCell0] = linkColor.len - 1
      let claimCell1 = src1 * side + tgt1
      linkNext.add cellHead[claimCell1]
      linkColor.add 0
      linkValue.add 0
      cellHead[claimCell1] = linkColor.len - 1
      continue
    variableCount += 1
    variableOf[color] = variableCount
    let opt0a = src0 * side + tgt0
    linkNext.add cellHead[opt0a]
    linkColor.add color
    linkValue.add 0
    cellHead[opt0a] = linkColor.len - 1
    let opt0b = src1 * side + tgt1
    linkNext.add cellHead[opt0b]
    linkColor.add color
    linkValue.add 0
    cellHead[opt0b] = linkColor.len - 1
    let opt1a = src0 * side + tgt1
    linkNext.add cellHead[opt1a]
    linkColor.add color
    linkValue.add 1
    cellHead[opt1a] = linkColor.len - 1
    let opt1b = src1 * side + tgt0
    linkNext.add cellHead[opt1b]
    linkColor.add color
    linkValue.add 1
    cellHead[opt1b] = linkColor.len - 1
```
The code records the two start lines and two final lines of each color. A color with one block forces one cell; a color with two blocks creates one binary variable. Four candidate cells are linked to that variable.

**Two-round solver.**
```nim
  let nodeTotal = 2 * variableCount
  var arcHead = newSeq[int](nodeTotal)
  var reverseHead = newSeq[int](nodeTotal)
  var arcTo: seq[int] = @[0]
  var arcNext: seq[int] = @[0]
  var reverseTo: seq[int] = @[0]
  var reverseNext: seq[int] = @[0]
  var cellLits: seq[int] = @[]
  for cellIndex in 0..<cellTotal:
    cellLits.setLen 0
    var constantCount = 0
    var linkIndex = cellHead[cellIndex]
    while linkIndex != 0:
      if linkColor[linkIndex] == 0:
        constantCount += 1
        if constantCount >= 2: return false
      else:
        let varIndex = variableOf[linkColor[linkIndex]] - 1
        cellLits.add 2 * varIndex + linkValue[linkIndex]
      linkIndex = linkNext[linkIndex]
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
  var visited = newSeq[bool](nodeTotal)
  var finishOrder: seq[int] = @[]
  for startNode in 0..<nodeTotal:
    if visited[startNode]: continue
    visited[startNode] = true
    var stackNodes: seq[int] = @[startNode]
    var stackArcs: seq[int] = @[arcHead[startNode]]
    while stackNodes.len > 0:
      let currentNode = stackNodes[stackNodes.len - 1]
      var currentArc = stackArcs[stackArcs.len - 1]
      var pushed = false
      while currentArc != 0:
        let nextNode = arcTo[currentArc]
        if not visited[nextNode]:
          visited[nextNode] = true
          stackArcs[stackArcs.len - 1] = arcNext[currentArc]
          stackNodes.add nextNode
          stackArcs.add arcHead[nextNode]
          pushed = true
          break
        currentArc = arcNext[currentArc]
      if not pushed:
        stackArcs.setLen(stackArcs.len - 1)
        finishOrder.add currentNode
        stackNodes.setLen(stackNodes.len - 1)
  var component = newSeq[int](nodeTotal)
  var componentCount = 0
  for k in 0..<finishOrder.len:
    let startNode = finishOrder[finishOrder.len - 1 - k]
    if component[startNode] != 0: continue
    componentCount += 1
    component[startNode] = componentCount
    var stackNodes: seq[int] = @[startNode]
    while stackNodes.len > 0:
      let currentNode = stackNodes[stackNodes.len - 1]
      stackNodes.setLen(stackNodes.len - 1)
      var currentArc = reverseHead[currentNode]
      while currentArc != 0:
        let nextNode = reverseTo[currentArc]
        if component[nextNode] == 0:
          component[nextNode] = componentCount
          stackNodes.add nextNode
        currentArc = reverseNext[currentArc]
  for i in 0..<variableCount:
    if component[2 * i] == component[2 * i + 1]: return false
  return true
```
Each middle cell becomes a clause: a constant forces a literal, and two literals force implications. Two depth-first passes find strongly connected components, which are checked for contradictions.

**Driver.**
```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let side = nextInt(inputData, scanPos)
  let cellTotal = side * side
  var initialGrid = newSeq[int](cellTotal)
  var targetGrid = newSeq[int](cellTotal)
  for i in 0..<cellTotal:
    initialGrid[i] = nextInt(inputData, scanPos)
  for i in 0..<cellTotal:
    targetGrid[i] = nextInt(inputData, scanPos)
  var work = newSeq[int](cellTotal + 1)
  var touched: seq[int] = @[]
  var answer = 3
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
stdout.write outputBuffer
outputBuffer.setLen 0
```
The program tries equality, then one-round checks, then the two-round solver. `answer` holds 0, 1, 2, or -1, and the output prints `no` for -1.

## Complexity

Each test is a constant number of passes over the board.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Color and line checks | O(n^2) | O(n^2) grids |
| Two-round setup | O(n^2) | O(n^2) link arrays |
| 2-SAT graph and SCC | O(n^2) | O(n^2) |
| Output | one write per block | flushBlockBytes |

The board size drives every phase, not the color count.

| Measure | Big O |
| --- | --- |
| Time per case | O(n^2) |
| Space per case | O(n^2) |

Searching all row and column permutations would be factorial, while these four checks settle each case in quadratic time.
