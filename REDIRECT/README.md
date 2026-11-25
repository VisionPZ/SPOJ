<https://www.spoj.com/problems/REDIRECT/>

## Problem

A player starts on tile 1 of a row of n tiles and has m turns to stay on the board. Each turn moves from tile i to tile i + a[i] or i + a[i] + 1, and the charged tile s also allows a move to i - a[i]. Print WINNER when some choice of moves keeps the player on the board for m turns, otherwise print LOSER.

| item | bound |
|---|---|
| tiles n | 1 to 100000 |
| turns m | 1 to 1000000000 |
| jump a[i] | 1 to 1000000000 |
| charged tile s | 1 to n |
| judge limit | 1000 ms, 1536 MB |

Forward moves always increase the tile index. Only the charged tile can send the player backward.

Sample input:

```
3 2
1 2 3
2
```

Sample output:

```
LOSER
```

## Idea

Think of the board as a one-way street with one allowed U-turn, like a bus route that can loop only at one terminal. If the player can reach the charged tile and travel from its backward landing spot back to it, the route repeats forever and every value of m wins. Otherwise the longest possible play is short, so a backward dynamic program gives the exact answer.

## Why It Works

1. Forward moves increase the tile index by at least one, so a forward-only play lasts at most n - 1 turns.
2. A play longer than n turns must use the backward move at least twice, which implies a cycle.
3. A cycle exists exactly when tile 1 reaches s and the landing tile s - a[s] reaches s by forward moves.
4. When a cycle exists, any number of turns wins: walk to s first, then repeat the loop.
5. Without a cycle, the backward move can be used once at most, so maximum play length is finite.

| term | meaning |
|---|---|
| `reachableFromStart` | tiles reachable from tile 1 by forward moves |
| `reachesCharged` | tiles that reach s by forward moves |
| `backTarget` | tile reached by the backward move at s |
| `forwardOnly` | longest forward play from a tile with no backward move left |
| `fullPlay` | longest play from a tile with the backward move still available |

For the sample, tile 1 reaches tile 2, but tile 2 has no safe move, so the play ends after one turn and two turns give LOSER.

In the third sample, tiles are 1 and 2 with jumps of 1. Tile 1 reaches tile 2 and the backward move returns to tile 1, so the loop runs forever and ten turns give WINNER.

The dynamic program scans tiles from high to low because every forward target has a larger index.

## Code

**Input and scanning.** The hand reader loads the board, the jumps and the charged tile.

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

let tileCount = nextInt(inputData, scanPos)
let turnCount = int64(nextInt(inputData, scanPos))
var jumpLengths = newSeq[int64](tileCount + 2)
for tileIndex in 1 .. tileCount:
  jumpLengths[tileIndex] = int64(nextInt(inputData, scanPos))
let chargedTile = nextInt(inputData, scanPos)
let boardEnd = int64(tileCount)
```

Jumps and turn counts use 64-bit values to hold bounds up to 1e9.
Targets outside the board are discarded by range checks.

**Reachability sweeps.** Two linear sweeps detect whether a repeating cycle is available.

```nim
var reachableFromStart = newSeq[bool](tileCount + 2)
reachableFromStart[1] = true
for tileIndex in 1 .. tileCount:
  if reachableFromStart[tileIndex]:
    let firstTarget = int64(tileIndex) + jumpLengths[tileIndex]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd:
      reachableFromStart[int(firstTarget)] = true
    if secondTarget >= 1 and secondTarget <= boardEnd:
      reachableFromStart[int(secondTarget)] = true

var reachesCharged = newSeq[bool](tileCount + 2)
var backwardTile = tileCount
while backwardTile >= 1:
  if backwardTile == chargedTile:
    reachesCharged[backwardTile] = true
  else:
    let firstTarget = int64(backwardTile) + jumpLengths[backwardTile]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd and reachesCharged[int(firstTarget)]:
      reachesCharged[backwardTile] = true
    if secondTarget >= 1 and secondTarget <= boardEnd and reachesCharged[int(secondTarget)]:
      reachesCharged[backwardTile] = true
  backwardTile -= 1

let backTarget = int64(chargedTile) - jumpLengths[chargedTile]
var repeatingCycle = false
if reachableFromStart[chargedTile] and backTarget >= 1 and reachesCharged[int(backTarget)]:
  repeatingCycle = true
```

The ascending sweep spreads reachability from tile 1.
The descending sweep collects tiles that can land on s.
Both sweeps touch each tile once.

**Length computation.** Two backward passes compute the longest finite play.

```nim
if repeatingCycle:
  appendOutput("WINNER\n")
else:
  var forwardOnly = newSeq[int](tileCount + 2)
  var scanTile = tileCount
  while scanTile >= 1:
    var bestSteps = 0
    let firstTarget = int64(scanTile) + jumpLengths[scanTile]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd:
      bestSteps = 1 + forwardOnly[int(firstTarget)]
    if secondTarget >= 1 and secondTarget <= boardEnd and 1 + forwardOnly[int(secondTarget)] > bestSteps:
      bestSteps = 1 + forwardOnly[int(secondTarget)]
    forwardOnly[scanTile] = bestSteps
    scanTile -= 1
  var fullPlay = newSeq[int](tileCount + 2)
  scanTile = tileCount
  while scanTile >= 1:
    var bestSteps = 0
    let firstTarget = int64(scanTile) + jumpLengths[scanTile]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd:
      bestSteps = 1 + fullPlay[int(firstTarget)]
    if secondTarget >= 1 and secondTarget <= boardEnd and 1 + fullPlay[int(secondTarget)] > bestSteps:
      bestSteps = 1 + fullPlay[int(secondTarget)]
    if scanTile == chargedTile and backTarget >= 1 and 1 + forwardOnly[int(backTarget)] > bestSteps:
      bestSteps = 1 + forwardOnly[int(backTarget)]
    fullPlay[scanTile] = bestSteps
    scanTile -= 1
  if int64(fullPlay[1]) >= turnCount:
    appendOutput("WINNER\n")
  else:
    appendOutput("LOSER\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first pass forbids every backward move and gives forward-only lengths.
The second pass allows one backward move at the charged tile.
The final comparison turns the longest play length into WINNER or LOSER.

## Complexity

Each sweep and each dynamic pass visits every tile once.

| phase | time | space |
|---|---|---|
| input read | one pass over n jumps | one input string |
| reachability | two sweeps over n tiles | two boolean arrays |
| length DP | two backward passes over n tiles | two integer arrays |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) |

Simulating every turn would cost O(m) time, which fails for m near 1e9.

The cycle test and backward passes give the exact result in linear time.
