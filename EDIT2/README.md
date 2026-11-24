## Problem

Read up to ten lines of text, each at most 600 printable characters. Print the fewest keystrokes that rebuild each line in the given editor. Then print the keys, one editor line per output line. Ties break by fewest lines, then fewest keystrokes before each early newline, then fewest `d` keys.

The judge fixes these bounds.

| Item | Bound |
| --- | --- |
| Test cases | 10 |
| Line length | at most 600 characters |
| Alphabet | printable ASCII except `d` |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The small line length permits tables over every substring.

## Idea

The program fills one table of substring costs and one table of newline choices. A longest common prefix table tests each doubling in constant time. Each substring costs constant time, so a line of length n costs O(n²) instead of the naive O(n³).

## Why It Works

The last key in any production sequence has one of two forms. A typed character shortens the target by one character. A `d` key ends the target only when the target splits into two equal halves.

For a substring starting at `k` with even length 2 × `halfLength`:

- the first half ends at `k + halfLength`;
- the second half ends at `k + 2 × halfLength`;
- the halves match when `lcpTable[k][k + halfLength] >= halfLength`.

The program fills `lcpTable` from right to left, so each cell reuses the cell one step down and right.

This generated example lists the cost of every prefix of the text ababab.

| length | substring | cost | `d` keys |
| --- | --- | --- | --- |
| 1 | a | 1 | 0 |
| 2 | ab | 2 | 0 |
| 3 | aba | 3 | 0 |
| 4 | abab | 3 | 1 |
| 5 | ababa | 4 | 1 |
| 6 | ababab | 5 | 1 |

The chosen keys rebuild the full text with five keystrokes.

## Code

The first block builds the prefix table and the per-substring cost tables.

```
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

The length loop has `textLength` iterations, and the start loop covers every substring of that length. The prefix table replaces a scan over both halves, which would cost O(n³). This block visits O(n²) substrings in constant time each.

The second block chooses the newline positions.

```
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
```

The outer loop runs once per prefix j, and the inner loop tries every k before it. The comparison tests total cost first, line count second, and the cost list last. The block costs O(n²) time and O(n²) space for the cost lists.

The third block rebuilds the keys for one line.

```
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

The loop walks j down to startPos and emits one key per step. The append branch runs first, so a tied choice never adds a `d` key. The block costs O(n) time per line and O(n) time across all lines.

The last blocks read the whole stream once and flush one output buffer.

```
proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add(text)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)
```

```
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
```

The reader stops at ten cases or at end of stream. A case keeps its spaces, because the editor treats them as text. The writer flushes after `flushBlockBytes` bytes, so it never holds the whole answer.

## Complexity

Building the prefix table costs O(n²) time and O(n²) space. Filling the substring cost tables costs O(n²) time. Choosing newlines costs O(n²) time and O(n²) space for the cost lists. Reconstruction costs O(n) time and O(n) space. One case costs O(n²) time and O(n²) space overall. Ten cases of length 600 finish in milliseconds.

A naive method compares both halves again for every substring. That method costs O(n³) time per case, which is slower without changing the answer.
