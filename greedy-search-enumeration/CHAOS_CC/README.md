# CHAOS_CC — Chaos In Arkham (SPOJ)

<https://www.spoj.com/problems/CHAOS_CC/>

## Problem

Two villains alternate opening cells in a row. The first player who makes three opened cells consecutive wins, and Joker moves first. Report the winner for each row length.

The first input value is the test count. Each following value is one row length. Print one winner name per test.

| item | bound |
|---|---|
| test count T | 1 to 3333 |
| row length N | 2 to 3333 |
| judge limit | 1000 ms, 1536 MB |

A length of two cannot form a hole, so normal last-move play decides it.

Sample input:

```
3
3
5
6
```

Sample output:

```
Joker
Joker
Bane
```

## Idea

Treat a fresh strip like a heap in a take-and-break game: one move blocks a small window and leaves two shorter independent strips. This is Treblecross, an impartial game solved by Grundy numbers.

Each candidate opening costs three operations, so a strip of length n costs O(n) to evaluate. Searching the move tree would cost exponential time. Precompute every Grundy value once, then answer each test with one lookup.

## Why It Works

1. An opening at position p blocks positions p-2 through p+2 for the opponent.
2. The two remaining free stretches have lengths p-3 and n-p-2.
3. Their combined Grundy value is the bitwise xor of the two stretch values.
4. The Grundy value of length n is the smallest value absent from all openings.
5. A zero Grundy value means the player to move loses, except that length two has no winning move for anyone.

| term | meaning |
|---|---|
| `grundyValues` | Grundy number for each strip length |
| `seenValues` | marks values already produced by candidate openings |
| `forbiddenEachSide` | cells blocked on each side of the chosen opening |
| `minimumLosingCells` | length with no possible hole |

Script-generated trace for length six:

| opening | left stretch | right stretch | xor value |
|---|---|---|---|
| 1 | 0 | 3 | 1 |
| 2 | 0 | 2 | 2 |
| 3 | 0 | 1 | 1 |
| 4 | 1 | 0 | 1 |
| 5 | 2 | 0 | 2 |
| 6 | 3 | 0 | 1 |

The mex of 1 and 2 is 0, so Bane wins length six.

## Code

**Input and output setup.** One read loop fills the buffer and a hand scanner extracts lengths.

```nim
const flushBlockBytes = 1 shl 17
const forbiddenEachSide = 2
const minimumLosingCells = 2

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

The scan skips spaces and line breaks.
Output is buffered and written once.
Both loops cost one pass over their data.

**Grundy table and answers.** Each length takes one sweep over its openings.

```nim
let caseCount = nextInt(inputData, scanPos)
var cellCounts = newSeq[int](caseCount)
var largestCellCount = 0
for caseIndex in 0 .. caseCount - 1:
  let cellCount = nextInt(inputData, scanPos)
  cellCounts[caseIndex] = cellCount
  if cellCount > largestCellCount:
    largestCellCount = cellCount

var grundyValues = newSeq[int](largestCellCount + 1)
var seenValues = newSeq[bool](largestCellCount + 4)
for cellCount in 1 .. largestCellCount:
  for index in 0 .. seenValues.len - 1:
    seenValues[index] = false
  var position = 1
  while position <= cellCount:
    let leftCells = position - 1 - forbiddenEachSide
    let rightCells = cellCount - position - forbiddenEachSide
    var leftValue = 0
    var rightValue = 0
    if leftCells > 0:
      leftValue = grundyValues[leftCells]
    if rightCells > 0:
      rightValue = grundyValues[rightCells]
    let combined = leftValue xor rightValue
    if combined < seenValues.len:
      seenValues[combined] = true
    position += 1
  var candidate = 0
  while candidate < seenValues.len and seenValues[candidate]:
    candidate += 1
  grundyValues[cellCount] = candidate

for caseIndex in 0 .. caseCount - 1:
  let cellCount = cellCounts[caseIndex]
  if cellCount == minimumLosingCells or (cellCount > minimumLosingCells and grundyValues[cellCount] == 0):
    appendOutput("Bane\n")
  else:
    appendOutput("Joker\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Short stretches contribute a zero value.
The flag array is cleared before each length.
The final flush writes every winner line.

## Complexity

The table is built up to the largest requested length.

| phase | time | space |
|---|---|---|
| input scan | one pass over T lengths | one input string |
| Grundy table | O(N) work per length | two arrays of N entries |
| answer scan | one comparison per test | buffered output |

| measure | Big O |
|---|---|
| time | O(T + N^2) |
| space | O(N) |

A full game-tree search would branch on every opening instead of reusing two shorter results.

The precomputed table answers all tests after one sweep.
