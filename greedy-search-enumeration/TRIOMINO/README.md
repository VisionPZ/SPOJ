# TRIOMINO — Triomino Game (SPOJ)

<https://www.spoj.com/problems/TRIOMINO/>

## Problem

An empty board with two rows and N columns hosts a tiling game. Two players place L-shaped pieces covering three cells each, and the player with no legal placement loses.

Input starts with T, the number of test cases. Each of the next T lines holds one board length N. Output one line per case: `X` when the first player wins, or `Y` when the second player wins.

| item | bound |
|---|---|
| test cases T | 1 to 50 |
| board length N | 1 to 800 |
| judge limit | 1000 ms, 1536 MB |

The board length drives the design; each case needs its game value.

Sample input:

```
2
3
4
```

Sample output:

```
X
Y
```

## Idea

Treat each empty run as a heap whose size is its Grundy number, like counting leftover stones in Nim. Combine Grundy values with exclusive-or, then take the mex of reachable values. A full column splits a run, while a partial column leaves only one open side, so three run types describe every position.

Compute the values once for all lengths up to 800, then answer each case in constant time. A brute-force search over every board would enumerate exponentially many placements.

## Why It Works

1. An L-piece occupies three cells of a 2×2 block, so one of its columns gets both cells and becomes full.
2. A full column blocks every future piece, so it splits the board into independent runs.
3. A partial column has one empty cell and one full neighbor, so only its open side can be used.
4. An empty run, a run with one partial end, and a run with two partial ends cover every reachable shape.
5. The mex of the exclusive-or values of all replies gives each run its Grundy number.

| term | meaning |
|---|---|
| `emptyRun` | Grundy number of a run of empty columns |
| `oneEndRun` | Grundy number of a run with one partial end |
| `twoEndRun` | Grundy number of a run with two partial ends |
| `mexFrom` | smallest value missing from a set of reachable values |

Rows 0 through 7 of `emptyRun` come from the generator:

```
length:      0 1 2 3 4 5 6 7
emptyRun:    0 0 1 2 0 3 1 0
```

Length 3 has value 2, so the first player wins; length 4 has value 0, so the second player wins.

## Code

**Input and scanner.** The program reads every line once and parses integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const maxBoardLength = 800

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

proc mexFrom(candidates: seq[bool]): int =
  var value = 0
  while value < candidates.len and candidates[value]:
    value += 1
  return value
```

The board limit fixes the size of the three tables.
The mex helper scans from zero and stops at the first gap.
Parsing ignores line breaks and repeated spaces.

**Value tables.** Each length combines shorter run values into one mex.

```nim
var emptyRun = newSeq[int](maxBoardLength + 1)
var oneEndRun = newSeq[int](maxBoardLength + 1)
var twoEndRun = newSeq[int](maxBoardLength + 1)

for length in 1 .. maxBoardLength:
  var candidates = newSeq[bool](length + 8)
  if length >= 2:
    for leftLength in 0 .. length - 2:
      let rightLength = length - leftLength - 2
      candidates[emptyRun[leftLength] xor oneEndRun[rightLength]] = true
      candidates[oneEndRun[leftLength] xor emptyRun[rightLength]] = true
  emptyRun[length] = mexFrom(candidates)

  var oneCandidates = newSeq[bool](length + 8)
  oneCandidates[emptyRun[length - 1]] = true
  for leftLength in 0 .. length - 2:
    let rightLength = length - leftLength - 2
    oneCandidates[oneEndRun[leftLength] xor oneEndRun[rightLength]] = true
    oneCandidates[twoEndRun[leftLength] xor emptyRun[rightLength]] = true
  oneEndRun[length] = mexFrom(oneCandidates)

  var twoCandidates = newSeq[bool](length + 8)
  twoCandidates[oneEndRun[length - 1]] = true
  for leftLength in 0 .. length - 2:
    let rightLength = length - leftLength - 2
    twoCandidates[oneEndRun[leftLength] xor twoEndRun[rightLength]] = true
    twoCandidates[twoEndRun[leftLength] xor oneEndRun[rightLength]] = true
  twoEndRun[length] = mexFrom(twoCandidates)
```

Each loop tries every place for a piece that splits a run.
Exclusive-or joins the Grundy values of independent parts.
The tables are built once for all 800 lengths.

**Answer loop.** Each case reads a length and writes one winner.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let boardLength = nextInt(inputData, scanPos)
  if emptyRun[boardLength] == 0:
    appendOutput("Y\n")
  else:
    appendOutput("X\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero Grundy number means the second player wins.
The buffer flushes in blocks, then once at the end.
Output stays exact for the largest test case.

## Complexity

The tables are built once before any case is read.

| phase | time | space |
|---|---|---|
| input read | one pass over T lengths | one input string |
| table build | about 800 squared pairs | three arrays of 801 values |
| answer loop | one lookup per case | block buffer |

The table build dominates every other phase.

| measure | Big O |
|---|---|
| time | O(800² + T) |
| space | O(800) |

A brute-force search over board states would grow exponentially with N.

A single precomputed table answers every case in constant time.
