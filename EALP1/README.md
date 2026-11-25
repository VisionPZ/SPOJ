# EALP1 — Enough of analyzing, let’s play (SPOJ)

<https://www.spoj.com/problems/EALP1/>

## Problem

Count the opening moves that leave a Nim position losing for the next player. A move changes one pile to any smaller size, so the count is the number of piles that can be reduced to make the pile sizes cancel in pairs.

Input starts with T, the number of cases, where T ≤ 1000. Each case gives N, with 1 ≤ N ≤ 1000, then N pile sizes, each below 1000. Print one labelled line per case with its case number and answer, where the answer is the number of winning opening moves.

| item | bound |
|---|---|
| cases T | up to 1000 |
| piles N | 1 to 1000 |
| stones per pile | below 1000 |
| judge limit | 1000 ms, 1536 MB |

The pile size bound keeps each xor within a small fixed range.

The sample case has two queries and two replies.

```
2
3
11 15 8
3
11 15 7
```

```
Case 1: 3
Case 2: 3
```

Each sample case has exactly three winning opening moves.

## Idea

The trick is to make the opponent face a board where every pile pairs off, like matching socks so that none is left over. A position with zero pile xor is exactly such a balanced board.

The algorithm computes the xor of all pile sizes, then tests one target size per pile. Each test costs one xor and one comparison, while trying every possible reduction would cost the total number of stones.

Compute one xor, then count qualifying piles.

## Why It Works

1. Nim positions with pile xor zero are losing for the player to move, and all other positions are winning.
2. Changing one pile from a to t changes the whole xor from X to X xor a xor t.
3. The new xor is zero exactly when t equals a xor X.
4. The move is legal exactly when t is smaller than a, so each pile contributes at most one winning move.
5. If X is zero, no move can leave xor zero, so the answer is zero.

| term | meaning |
|---|---|
| `pileSizes` | stone counts for the current case |
| `nimXor` | xor of every pile size in the case |
| `winningMoves` | number of piles that can be reduced to a xor X |

The terms give one count from one scan of the piles.

The generator derives Nim values by mex and compares them with brute-force move enumeration.

```
brute("1 2 3") = 0
brute("7 7") = 0
brute("11 15 8") = 3
```

Three legal reductions of the sample piles leave a balanced board.

## Code

**Input and pile scan.** The reader loads each case and computes one xor.

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

The scanner skips the whitespace that separates cases.

`appendOutput` buffers several case lines before one write.

The pile sizes fit in the scanner's `int` value.

**Winning move count.** Each pile yields at most one legal balancing reduction.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let pileCount = nextInt(inputData, scanPos)
  var pileSizes = newSeq[int](pileCount)
  var nimXor = 0
  for pileIndex in 0 .. pileCount - 1:
    pileSizes[pileIndex] = nextInt(inputData, scanPos)
    nimXor = nimXor xor pileSizes[pileIndex]
  var winningMoves = 0
  if nimXor != 0:
    for pileIndex in 0 .. pileCount - 1:
      if (pileSizes[pileIndex] xor nimXor) < pileSizes[pileIndex]:
        winningMoves += 1
  appendOutput("Case " & $caseIndex & ": " & $winningMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero-xor guard avoids counting moves from a balanced board.

The strict comparison rejects targets that would add stones.

The final write clears the buffered tail once.

## Complexity

Each case scans the piles twice and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over pile tokens | one input string |
| move count | two passes over N piles | one array of N sizes |
| output | one line per case | one output block |

Each case adds work proportional only to its pile count.

| measure | Big O |
|---|---|
| time | O(total piles) |
| space | O(N) |

Trying every reduction would cost the sum of all stone counts, so one xor per case is the decisive gain.
