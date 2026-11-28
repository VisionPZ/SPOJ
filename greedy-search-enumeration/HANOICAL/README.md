# HANOICAL — Hanoi Calls (SPOJ)

<https://www.spoj.com/problems/HANOICAL/>

## Problem

Given two legal arrangements of the same discs on three pegs, report the fewest moves that turn the first arrangement into the second. A move carries the top disc of one peg onto another peg or onto an empty peg.

The input holds about 100 cases. Each case starts with N, then N peg numbers for the start arrangement and N peg numbers for the target arrangement. A line holding 0 ends the input. Each case produces one integer on its own line.

| item | bound |
|---|---|
| discs N | 1 to 30 |
| peg numbers | 1, 2, or 3 |
| test cases | about 100 |
| judge limit | 1000 ms, 1536 MB |

The largest disc drives the answer, because it moves at most once.

Sample input:

```
4
1 1 1 1
2 2 2 2
3
1 3 3
2 1 1
5
1 3 2 2 2
2 3 2 1 2
0
```

Sample output:

```
15
6
14
```

## Idea

Find the largest disc on differing pegs, like clearing a table before sliding a heavy box. Clear its two pegs, then move it once. The algorithm walks discs from largest down and adds the cost of gathering each smaller stack onto one peg. Gathering one stack costs one pass over its discs. Searching the full state graph instead would explore 3^N arrangements. The walk down the disc list settles each case in linear time.

## Why It Works

1. Discs larger than the highest differing disc already sit on the same peg in both arrangements.
2. Those discs never move, so they can be ignored.
3. Before a disc moves, all smaller discs must be stacked on the third peg.
4. A one-jump route gathers them on the spare peg, moves the disc once, then gathers them from that peg.
5. A two-jump route parks the small stack on the target peg. It moves the disc to the spare peg, shifts the stack to the start peg, moves the disc again, then gathers the stack.
6. The shortest route is the smaller of those two counts.

| term | meaning |
|---|---|
| `startPegs` | peg number of each disc in the start arrangement |
| `finalPegs` | peg number of each disc in the target arrangement |
| `sparePeg` | peg that is neither the start peg nor the target peg |
| `oneJump` | cost of moving the highest differing disc once |
| `twoJumps` | cost of moving that disc twice |
| `movesToPeg` | moves needed to gather small discs onto one peg |

The two routes cover every shortest path for the highest differing disc.

A script trace of the third sample case gives these numbers:

```
highest differing disc 4 spare peg 3
one jump 7 + 1 + 6 = 14
two jumps 5 + 8 + 1 + 3 = 17
answer 14
```

The script value 14 matches the printed sample answer.

## Code

**Input and scanner.** The reader loads every case, and the hand scanner skips line breaks.

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
```

Peg numbers are positive, so the scanner needs no sign branch.
One string holds the whole input.
The position moves past one number per call.

**Output buffer.** One buffer collects answers and writes them in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 131072 bytes.
A final write clears any remainder.
No write happens per disc.

**Single peg gather.** The helper stacks small discs on one peg.

```nim
proc movesToPeg(startPegs: seq[int], discCount: int, targetPeg: int): int64 =
  var totalMoves: int64 = 0
  var wantedPeg = targetPeg
  var discIndex = discCount
  while discIndex >= 1:
    if startPegs[discIndex] != wantedPeg:
      totalMoves = totalMoves + (int64(1) shl (discIndex - 1))
      wantedPeg = 6 - startPegs[discIndex] - wantedPeg
    discIndex -= 1
  return totalMoves
```

The loop runs once per small disc.
A disc already on the wanted peg adds nothing.
The spare peg becomes the next wanted peg after a move.

**Case loop.** The driver finds the highest differing disc and compares both routes.

```nim
while true:
  let discCount = nextInt(inputData, scanPos)
  if discCount == 0:
    break
  var startPegs = newSeq[int](discCount + 1)
  var finalPegs = newSeq[int](discCount + 1)
  for discIndex in 1 .. discCount:
    startPegs[discIndex] = nextInt(inputData, scanPos)
  for discIndex in 1 .. discCount:
    finalPegs[discIndex] = nextInt(inputData, scanPos)
  var totalMoves: int64 = 0
  var discIndex = discCount
  while discIndex >= 1:
    if startPegs[discIndex] != finalPegs[discIndex]:
      let sourcePeg = startPegs[discIndex]
      let targetPeg = finalPegs[discIndex]
      let sparePeg = 6 - sourcePeg - targetPeg
      let smallerDiscs = discIndex - 1
      let oneJump: int64 = movesToPeg(startPegs, smallerDiscs, sparePeg) + 1 +
                           movesToPeg(finalPegs, smallerDiscs, sparePeg)
      let twoJumps: int64 = movesToPeg(startPegs, smallerDiscs, targetPeg) +
                            (int64(1) shl smallerDiscs) + 1 +
                            movesToPeg(finalPegs, smallerDiscs, sourcePeg)
      if oneJump < twoJumps:
        totalMoves = oneJump
      else:
        totalMoves = twoJumps
      break
    discIndex -= 1
  appendOutput($totalMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan stops at the highest differing disc.
The two counts fit in 64 bits for N up to 30.
The final write emits the buffered lines.

## Complexity

Each case scans the disc list once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| disc walk | up to N gathers of N discs | two arrays of N pegs |
| output | one buffered write per block | block buffer |

The disc walk dominates for large cases.

| measure | Big O |
|---|---|
| time | O(N^2) worst case, O(N) per gather |
| space | O(N) |

Searching all 3^N arrangements would be far slower than this walk.
The gather formula keeps each case short even at N = 30.
