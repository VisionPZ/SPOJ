# VIP — VIP (SPOJ)

<https://www.spoj.com/problems/VIP/>

## Problem

At a party of `n` people, everyone knows themselves. A VIP is a person known by everybody who knows nobody except themselves. The matrix of who knows whom is given: entry `i j` is 1 when person `i` knows person `j`. A VIP is guaranteed to exist. Print that person's number (1-based) for each data set.

| item | bound |
|---|---|
| data sets `d` | 1 to 100 |
| people `n` | 1 to 500 |
| judge limit | 1000 ms, 1536 MB |

Sample input (first data set):

```
2
3
1 0 1
1 1 1
0 0 1
5
1 0 0 1 1
1 1 0 1 0
0 0 1 1 1
0 0 0 1 0
1 1 0 1 1
```

Sample output:

```
3
4
```

## Idea

Walk the people once, keeping one suspect. Whenever the current suspect knows somebody, replace the suspect with that person. One pass leaves a single suspect, and a second pass checks the two VIP rules against everyone. If the check fails, a plain scan of all people finishes the job.

## Why It Works

1. A VIP's column is all 1s (everyone knows them) and their row is all 0s except the diagonal 1 (they know nobody but themselves). These two rules are exactly what the program tests.
2. If the suspect `c` knows person `p`, then `c` cannot be the VIP, because a VIP knows nobody other than themselves and `p` is not `c`. So discarding `c` for `p` never throws away the real VIP.
3. The real VIP `v` is never skipped either: everyone knows `v`, so when the scan reaches `v` the current suspect knows `v` and the suspect becomes `v`. And `v` can never be discarded later, because `v` knows nobody. The one pass therefore always ends on the VIP.
4. There can be at most one VIP: two such people would have to know each other, yet a VIP knows nobody but themselves. So the fallback scan that stops at the first match cannot pick a wrong one.
5. In the first sample data set, person 1 (index 0) knows person 3, so the suspect moves to 3; nobody else displaces 3. Person 3's column is `1 1 1` and their row is `0 0 1`, so the answer is 3. The second data set ends with suspect 4, whose column is all 1s and whose row is `0 0 0 1 0`, giving 4.

| term | meaning |
|---|---|
| `knowsMatrix` | flattened n-by-n 0/1 grid |
| `candidate` | index of the current suspect |
| `isVip` | candidate passes both VIP rules |
| `knowsOnlySelf` | fallback test for one person's row |
| `knownByAll` | fallback test for one person's column |

## Code

**Input, scanner and output buffer.** This block loads stdin and prepares the writer.

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips every non-digit, so the grid's spaces and newlines need no special handling.

**Reading the grid and picking the suspect.** This block stores the matrix, runs the one-pass elimination and verifies the survivor.

```nim
let dataSetCount = nextInt(inputData, scanPos)
for dataSetIndex in 0 .. dataSetCount - 1:
  let peopleCount = nextInt(inputData, scanPos)
  var knowsMatrix = newSeq[int](peopleCount * peopleCount)
  for rowIndex in 0 .. peopleCount - 1:
    for columnIndex in 0 .. peopleCount - 1:
      knowsMatrix[rowIndex * peopleCount + columnIndex] = nextInt(inputData, scanPos)
  var candidate = 0
  for personIndex in 1 .. peopleCount - 1:
    if knowsMatrix[candidate * peopleCount + personIndex] == 1:
      candidate = personIndex
  var isVip = true
  for personIndex in 0 .. peopleCount - 1:
    if personIndex != candidate:
      if knowsMatrix[personIndex * peopleCount + candidate] != 1:
        isVip = false
      if knowsMatrix[candidate * peopleCount + personIndex] != 0:
        isVip = false
```

The matrix is kept in one flat list, indexed by `row * n + column`, which is faster than a list of lists. The elimination loop only reads from the current suspect's row, so it is a single pass of at most `n` lookups.

**Answering.** This block prints the suspect, or scans everyone if the check failed.

```nim
  if isVip:
    appendOutput($(candidate + 1))
  else:
    for personIndex in 0 .. peopleCount - 1:
      var knowsOnlySelf = true
      var knownByAll = true
      for otherIndex in 0 .. peopleCount - 1:
        if otherIndex != personIndex:
          if knowsMatrix[personIndex * peopleCount + otherIndex] != 0:
            knowsOnlySelf = false
          if knowsMatrix[otherIndex * peopleCount + personIndex] != 1:
            knownByAll = false
      if knowsOnlySelf and knownByAll:
        appendOutput($(personIndex + 1))
        break
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The fallback is the textbook double loop over rows and columns. It runs only when the suspect check fails, which the guarantee says never happens, but it keeps the program correct even on shaky input.

## Complexity

| phase | time | space |
|---|---|---|
| grid read | O(n^2) per data set | O(n^2) |
| elimination | O(n) | O(1) |
| suspect check | O(n) | O(1) |
| fallback scan | O(n^2), normally unused | O(1) |
| output | one line per data set | block buffer |

| measure | big O |
|---|---|
| time | O(d x n^2) |
| space | O(n^2) |

The grid itself is n^2 numbers, so reading it already costs O(n^2); the smart part adds only two linear passes on top.
