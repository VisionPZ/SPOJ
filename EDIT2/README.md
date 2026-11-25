# EDIT2 — Editor Inverse (SPOJ)
<https://www.spoj.com/problems/EDIT2/>

## Problem

A text editor can double the current line with one key.
The program finds the shortest key sequence that rebuilds a given line.

Read exactly ten lines of text.
Each line has at most 600 printable ASCII characters and never contains the doubling key `d`.
Print the fewest keystrokes that rebuild each line in the described editor, then print the keys themselves.

A newline key ends an output line, and two newline keys end the program.
Ties break by fewest lines, then fewest keystrokes before each newline, then fewest `d` keys inside a line.
The sample output includes a blank line after each test case.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Test cases | 10 |
| Line length | at most 600 characters |
| Alphabet | printable ASCII except `d` |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The small line length permits tables over every substring.

The sample input and expected output follow verbatim.

```
00001123444456789
000011234444446789
```

```
18
00d1123444456789

18
00d1123
444d6789

```

Each sample line needs 18 keystrokes in the chosen layout.

## Idea

Fill a substring cost table once, like completing a multiplication chart instead of recomputing each cell.
A longest common prefix table (matching prefix lengths at two positions) tests each doubling in constant time.

The last key either types one character or doubles a line that splits into two equal halves.
Fill costs from short substrings to long ones.
Then choose newline positions with dynamic programming (keeping the best answer for each prefix).
Tie breaks use total cost, line count, then a dictionary-order cost list.

Cost per line is O(n²).
Comparing both halves again for every substring would cost O(n³).
Precompute the matches, then fill two tables.

## Why It Works

Four facts prove the method.

1. The last key in a shortest production types a character or doubles an exact half.
2. `lcpTable[k][k + halfLength] >= halfLength` tests whether the two halves match.
3. Filling `lcpTable` from right to left reuses the cell one step down and right.
4. The dp tables compare total cost, then line count, then the cost list.
   Reconstruction prefers typing over `d` when the two costs tie.

The main tables and their roles follow.

| Term | Meaning |
| --- | --- |
| `lcpTable[i][j]` | matching prefix length of suffixes at `i` and `j` |
| `costTable[k][j]` | fewest keys for substring `k` through `j` |
| `dcountTable[k][j]` | fewest `d` keys at that cost |
| `dpCost[j]` | best total cost for the first `j` characters |

The tables make each substring test constant time.

A script fills the cost table for the text `ababab` and prints every prefix.

```
| length | substring | cost | d keys |
| --- | --- | --- | --- |
| 1 | a | 1 | 0 |
| 2 | ab | 2 | 0 |
| 3 | aba | 3 | 0 |
| 4 | abab | 3 | 1 |
| 5 | ababa | 4 | 0 |
| 6 | ababab | 5 | 1 |
the chosen keys rebuild ababab with five keystrokes
```

The chosen keys rebuild the full text with five keystrokes.

## Code

**Helpers.**

```nim
const flushBlockBytes = 1 shl 18
const unreachableCost = 1000000000

proc lessLex(leftSeq, rightSeq: seq[int]): bool =
  let commonLength = min(leftSeq.len, rightSeq.len)
  for i in 0 ..< commonLength:
    if leftSeq[i] < rightSeq[i]:
      return true
    if leftSeq[i] > rightSeq[i]:
      return false
  return leftSeq.len < rightSeq.len

proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add(text)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)
```

lessLex compares cost lists for the tie break. appendOutput flushes a full block. Both helpers are shared across cases.

**Key reconstruction.**

```nim
proc buildProgram(targetText: string, costTable, dcountTable: seq[seq[int]], startPos, endPos: int): string =
  var reversedKeys = newSeq[char]()
  var i = startPos
  var j = endPos
  while i < j:
    let appendKeepsCount = costTable[i][j] == costTable[i][j - 1] + 1
    let appendKeepsDCount = dcountTable[i][j] == dcountTable[i][j - 1]
    if appendKeepsCount and appendKeepsDCount:
      reversedKeys.add(targetText[j - 1])
      j -= 1
    else:
      reversedKeys.add('d')
      j = i + (j - i) div 2
  var programText = newString(reversedKeys.len)
  for i in 0 ..< reversedKeys.len:
    programText[i] = reversedKeys[reversedKeys.len - 1 - i]
  return programText
```

buildProgram walks the substring from the end. It types a character when that keeps both optima. Otherwise it emits `d` and halves the remaining span. The keys are reversed once at the end.

**Prefix and cost tables.**

```nim
proc solveCase(targetText: string, outputBuffer: var string) =
  let textLength = targetText.len
  var costTable = newSeq[seq[int]](textLength + 1)
  var dcountTable = newSeq[seq[int]](textLength + 1)
  var lcpTable = newSeq[seq[int]](textLength + 1)
  for i in 0 .. textLength:
    costTable[i] = newSeq[int](textLength + 1)
    dcountTable[i] = newSeq[int](textLength + 1)
    lcpTable[i] = newSeq[int](textLength + 1)
  var i = textLength - 1
  while i >= 0:
    var j = textLength - 1
    while j >= 0:
      if targetText[i] == targetText[j]:
        lcpTable[i][j] = lcpTable[i + 1][j + 1] + 1
      j -= 1
    i -= 1
  for segmentLength in 1 .. textLength:
    for k in 0 .. (textLength - segmentLength):
      let j = k + segmentLength
      var bestCost = costTable[k][j - 1] + 1
      var bestDCount = dcountTable[k][j - 1]
      if segmentLength mod 2 == 0:
        let halfLength = segmentLength div 2
        if lcpTable[k][k + halfLength] >= halfLength:
          let doubleCost = costTable[k][k + halfLength] + 1
          let doubleDCount = dcountTable[k][k + halfLength] + 1
          if doubleCost < bestCost or (doubleCost == bestCost and doubleDCount < bestDCount):
            bestCost = doubleCost
            bestDCount = doubleDCount
      costTable[k][j] = bestCost
      dcountTable[k][j] = bestDCount
```

Three square tables hold prefix matches, key costs, and `d` counts. The lcp loop runs from right to left. The length loop then visits every substring. A matching even half offers the doubling option.

**Prefix choices and output.**

```nim
  var dpCost = newSeq[int](textLength + 1)
  var dpLines = newSeq[int](textLength + 1)
  var dpPrevious = newSeq[int](textLength + 1)
  var dpCostSeqs = newSeq[seq[int]](textLength + 1)
  for i in 0 .. textLength:
    dpCost[i] = unreachableCost
  dpCost[0] = 0
  for j in 1 .. textLength:
    for k in 0 ..< j:
      let lineCost = costTable[k][j]
      let candidateCost = dpCost[k] + lineCost + 1
      let candidateLines = dpLines[k] + 1
      var candidateSeq = newSeq[int](dpCostSeqs[k].len + 1)
      for i in 0 ..< dpCostSeqs[k].len:
        candidateSeq[i] = dpCostSeqs[k][i]
      candidateSeq[candidateSeq.len - 1] = lineCost
      var isBetter = false
      if candidateCost < dpCost[j]:
        isBetter = true
      elif candidateCost == dpCost[j]:
        if candidateLines < dpLines[j]:
          isBetter = true
        elif candidateLines == dpLines[j]:
          if lessLex(candidateSeq, dpCostSeqs[j]):
            isBetter = true
      if isBetter:
        dpCost[j] = candidateCost
        dpLines[j] = candidateLines
        dpPrevious[j] = k
        dpCostSeqs[j] = candidateSeq
  let totalKeystrokes = dpCost[textLength] + 1
  var boundaryList = newSeq[int]()
  var l = textLength
  while l > 0:
    boundaryList.add(l)
    l = dpPrevious[l]
  boundaryList.add(0)
  var forwardBoundaries = newSeq[int]()
  for i in 0 ..< boundaryList.len:
    forwardBoundaries.add(boundaryList[boundaryList.len - 1 - i])
  appendOutput(outputBuffer, $totalKeystrokes)
  appendOutput(outputBuffer, "\n")
  for j in 0 ..< (forwardBoundaries.len - 1):
    let programText = buildProgram(targetText, costTable, dcountTable, forwardBoundaries[j], forwardBoundaries[j + 1])
    appendOutput(outputBuffer, programText)
    appendOutput(outputBuffer, "\n")
  appendOutput(outputBuffer, "\n")
```

The dp loop tries every cut point for each prefix. It compares cost, line count, and cost list in that order. Backward pointers recover the newline boundaries. One blank line closes each test case.

**Reader and driver.**

```nim
proc main() =
  var inputData = ""
  var inputLine = ""
  while stdin.readLine(inputLine):
    inputData.add(inputLine)
    inputData.add('\n')
  var outputBuffer = ""
  var i = 0
  var j = 0
  while i < inputData.len and j < 10:
    var k = i
    while k < inputData.len and inputData[k] != '\n':
      k += 1
    var targetText = inputData[i ..< k]
    if targetText.len > 0 and targetText[targetText.len - 1] == '\r':
      targetText.setLen(targetText.len - 1)
    i = k + 1
    j += 1
    solveCase(targetText, outputBuffer)
  if outputBuffer.len > 0:
    stdout.write(outputBuffer)

main()
```

The reader stops at ten cases or at end of stream. A case keeps spaces because the editor treats them as text. A trailing carriage return is removed. One final write emits the remaining bytes.

## Complexity

The phases and their costs for one line of length n follow.

| Phase | Time | Space |
| --- | --- | --- |
| Prefix table | O(n²) | O(n²) |
| Substring costs | O(n²) | O(n²) |
| Prefix choices | O(n²) | O(n²) |
| Reconstruction and output | O(n) | O(n) |

Ten lines of 600 characters finish quickly.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(n²) per line |
| Space | O(n²) per line |

Recomparing both halves for every substring would cost O(n³) per line.
