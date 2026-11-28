# RPS — Finding the Top RPS Player (SPOJ)

<https://www.spoj.com/problems/RPS/>

## Problem

Given N players and a target streak M, find the fewest turns until some player holds M consecutive wins. Only players with equal win counts play each other, and every possible pair in a group plays each turn.

Each test case gives N and M on one line. Two zeroes end the input. Output the case number and the minimum turn count.

| item | bound |
|---|---|
| players N | 2 to 20 |
| target wins M | 1 to N-1 |
| largest answer | 102033 turns |
| judge limit | 2000 ms, 1536 MB |

A loser returns to zero wins. An unpaired player keeps the current win count.

Sample input:

```
2 1
10 5
15 10
0 0
```

Sample output:

```
Case 1: 1
Case 2: 11
Case 3: 210
```

## Idea

Raise opponents like seedlings in a nursery, then let the strongest plant keep winning: each level needs another player at the same win count, so the group sizes determine everything.

Every turn pairs players inside each win-count group. Half advance one level and half drop to zero. We replay those deterministic groups for every player count up to 20 and record the first turn that reaches each target.

A replay costs one pass over the level counts per turn. The slowest pair reaches its answer after 102033 turns, so a fresh replay per query would repeat large work. One precomputation pays that cost once. Takeaway: build the table once, then answer each case with a lookup.

## Why It Works

1. Players in one win-count group are interchangeable, so counts describe the whole state.
2. Each turn lets floor of half of each group win, and the same number fall back to zero.
3. Leftover players stay at their current level because no partner exists.
4. Winners from the level below join the next level on the following turn.
5. The first turn with a positive count at level M is the minimum required.

| term | meaning |
|---|---|
| `counts` | number of players at each win level |
| `gamesPlayed` | total pairs played in one turn |
| `turnTable` | recorded answer for each player and target pair |
| `missingTargets` | targets not yet reached during precomputation |

For N = 15 the counts start as 15 at level zero. Turn one gives 8 at level zero and 7 at level one. Turn two gives 7, 5, and 3 across levels zero, one, and two. Level ten first appears on turn 210.

Precomputation stops for a player count only after every target below it has a recorded turn.

## Code

**Input and output.** The driver reads all lines, then emits one formatted answer per case.

```nim
const flushBlockBytes = 1 shl 17
const maxPlayers = 20

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

The scanner ignores line breaks between pairs. The output buffer flushes in large blocks.

**Turn simulation.** Counts move between levels until every target has a recorded turn.

```nim
var turnTable = newSeq[seq[int]](maxPlayers + 1)
for playerIndex in 0 .. maxPlayers:
  turnTable[playerIndex] = newSeq[int](maxPlayers + 1)

for playerCount in 2 .. maxPlayers:
  var counts = newSeq[int](playerCount + 2)
  counts[0] = playerCount
  var turnNumber = 0
  var missingTargets = playerCount - 1
  while missingTargets > 0:
    turnNumber += 1
    var nextCounts = newSeq[int](counts.len)
    var gamesPlayed = 0
    for winLevel in 0 .. counts.len - 1:
      gamesPlayed += counts[winLevel] div 2
    nextCounts[0] = counts[0] mod 2 + gamesPlayed
    for winLevel in 1 .. counts.len - 1:
      nextCounts[winLevel] = counts[winLevel] mod 2 + counts[winLevel - 1] div 2
    counts = nextCounts
    for targetWins in 1 .. playerCount - 1:
      if turnTable[playerCount][targetWins] == 0 and counts[targetWins] > 0:
        turnTable[playerCount][targetWins] = turnNumber
        missingTargets -= 1
```

The zero level collects all losers plus its unpaired leftover. Higher levels collect their leftover plus winners from the level below. Each newly occupied level stores its first turn.

**Case loop.** Zeroes stop the loop, and each case reads its answer from the table.

```nim
var caseNumber = 0
while true:
  let playerCount = nextInt(inputData, scanPos)
  let targetWins = nextInt(inputData, scanPos)
  if playerCount == 0 and targetWins == 0:
    break
  caseNumber += 1
  appendOutput("Case " & $caseNumber & ": " & $turnTable[playerCount][targetWins])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Case numbering starts at one. The last flush writes the buffered answers.

## Complexity

Precomputation runs once before any query is read.

| phase | time | space |
|---|---|---|
| precompute | about 2.2 million level updates | 21 by 21 table |
| query loop | one lookup per case | one input string |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| precompute time | O(N^2 * T) |
| query time | O(1) |

A fresh simulation for every query would repeat up to 102033 turns per case. The shared table removes that repeated work.

Takeaway: reuse the precomputed table for every query.
