# PANANDDA — Pan-da (SPOJ)

<https://www.spoj.com/problems/PANANDDA/>

## Problem

Insert the fewest letters so the string can be cut into pieces equal to `DA` or `PAN`. Only insertions are allowed, and every original letter keeps its order.

Input is one line containing a string of the letters `P`, `A`, `N`, and `D`. Its length lies between 1 and 10^5.

Output is one integer: the minimum number of inserted letters.

| item | bound |
|---|---|
| string length | 1 to 10^5 |
| alphabet | P, A, N, D |
| token shapes | DA and PAN |
| judge limit | 1000 ms, 1536 MB |

The length keeps a linear scan necessary, while the token shapes keep the state set tiny.

Sample input 1:

```
PANDA
```

Sample output 1:

```
0
```

Sample input 2:

```
DPANA
```

Sample output 2:

```
2
```

## Idea

Treat the target as a tiny machine with four positions, like a board game with four squares. Inserting a letter moves a token forward one square for one cost. Reading a real letter moves forward for free only when it matches the expected letter.

Precompute the cheapest insertion-only path between every pair of positions. Then each input letter costs one table lookup to relax those paths and one free transition. Four states make the whole scan linear.

Precompute insert costs, then match letters in one pass.

## Why It Works

1. A target string is a chain of tokens, each equal to `DA` or `PAN`.
2. Four positions describe progress: start, after P, after PA, and after D.
3. Five insertion edges link the five states. They connect start to after P with P, start to after D with D, and after P to after PA with A. Two more edges connect after PA to start with N and after D to start with A.
4. Every insertion costs one, so all-pairs shortest paths give the cost of any run of insertions.
5. Matching an input letter costs zero and is possible only from a position that expects that letter.
6. Ending at the start position means every token is complete.

| term | meaning |
|---|---|
| `insertDist` | cheapest insertion-only cost between two positions |
| `stateCost` | cheapest cost at each position after the letters read so far |
| `relaxed` | costs after any number of insertions before the next letter |
| `nextCost` | costs after matching the next letter for free |
| `answer` | cheapest cost ending at a token boundary |

For `DPANA`, inserting `A` and `N` after the first `D` gives `DANPANA`, which cuts as `DA` and `PAN`. Two insertions match the sample.

Any letter is matchable after enough insertions, so a finite answer always exists.

## Code

**Insertion distance table.** The matrix is built once with three nested relaxations.

```nim
const flushBlockBytes = 1 shl 17
const stateCount = 4
const impossibleCost = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var insertDist = newSeq[seq[int]](stateCount)
var distanceCursor = 0
while distanceCursor < stateCount:
  insertDist[distanceCursor] = newSeq[int](stateCount)
  var targetCursor = 0
  while targetCursor < stateCount:
    if distanceCursor == targetCursor:
      insertDist[distanceCursor][targetCursor] = 0
    else:
      insertDist[distanceCursor][targetCursor] = impossibleCost
    targetCursor += 1
  distanceCursor += 1
insertDist[0][1] = 1
insertDist[0][3] = 1
insertDist[1][2] = 1
insertDist[2][0] = 1
insertDist[3][0] = 1
var middleCursor = 0
while middleCursor < stateCount:
  var fromCursor = 0
  while fromCursor < stateCount:
    var toCursor = 0
    while toCursor < stateCount:
      let candidate = insertDist[fromCursor][middleCursor] + insertDist[middleCursor][toCursor]
      if candidate < insertDist[fromCursor][toCursor]:
        insertDist[fromCursor][toCursor] = candidate
      toCursor += 1
    fromCursor += 1
  middleCursor += 1

```

Five unit edges describe all legal insertions.
Floyd-Warshall fills the rest of the matrix.
The table never changes during the scan.

**Letter scan and answer.** Each letter relaxes insertions, then moves for free when it matches.

```nim
var patternText = ""
var charCursor = 0
while charCursor < inputData.len:
  let currentChar = inputData[charCursor]
  if currentChar == 'P' or currentChar == 'A' or currentChar == 'N' or currentChar == 'D':
    patternText.add currentChar
  charCursor += 1

var stateCost: array[stateCount, int] = [0, impossibleCost, impossibleCost, impossibleCost]
for patternChar in patternText:
  var relaxed: array[stateCount, int]
  var targetCursor = 0
  while targetCursor < stateCount:
    relaxed[targetCursor] = impossibleCost
    var fromCursor = 0
    while fromCursor < stateCount:
      let candidate = stateCost[fromCursor] + insertDist[fromCursor][targetCursor]
      if candidate < relaxed[targetCursor]:
        relaxed[targetCursor] = candidate
      fromCursor += 1
    targetCursor += 1
  var nextCost: array[stateCount, int] = [impossibleCost, impossibleCost, impossibleCost, impossibleCost]
  case patternChar
  of 'P':
    nextCost[1] = relaxed[0]
  of 'A':
    nextCost[2] = relaxed[1]
    if relaxed[3] < nextCost[0]:
      nextCost[0] = relaxed[3]
  of 'N':
    nextCost[0] = relaxed[2]
  of 'D':
    nextCost[3] = relaxed[0]
  else:
    discard
  stateCost = nextCost

var answer = impossibleCost
var finalCursor = 0
while finalCursor < stateCount:
  let candidate = stateCost[finalCursor] + insertDist[finalCursor][0]
  if candidate < answer:
    answer = candidate
  finalCursor += 1
appendOutput($answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The reader keeps only the four allowed letters.
Each input letter needs sixteen table lookups.
The last relaxation completes any unfinished token.

## Complexity

The distance table is constant, and the letter scan is linear in the string length.

| phase | time | space |
|---|---|---|
| distance table | 4 cubed relaxations | 16 integers |
| input read | one pass over the input | one input string |
| letter scan | 16 lookups per letter | four costs |
| output | one line | block buffer |

The four-state machine makes each letter cheap.

| measure | Big O |
|---|---|
| time | O(N) after a constant setup |
| space | O(N) for the input string |

Enumerating legal target strings would grow exponentially with the string length.

Precompute insertion costs, then read the string once and finish at a token boundary.
