# GAME — Game schedule required (SPOJ)

<https://www.spoj.com/problems/GAME/>

## Problem

Assign a winner and a round to each listed game so the games form a legal single-elimination schedule. Print the rounds, the champion, and any teams that advance with a wildcard.

Input holds several cases. Each case starts with `n`, then `n` team names, then `n - 1` games. A game line holds two team names. A line with `0` ends the input. Output gives `Round #X` first in each round, then one `A defeats B` line per game, then an optional `A advances with wildcard` line. After the last round, print `Winner: A` and a blank line.

The bounds from the statement:

| Item | Bound |
|---|---|
| Teams per case `n` | 2 ≤ n ≤ 1000 |
| Team name | at most 25 English letters |
| Games per case | exactly n - 1 |
| End marker | a line with 0 |
| Judge limits | 2517 ms, 1536 MB |

The largest case drives the design, since each case scans all teams once per round.

The sample case:

```
3
A
B
C
A B
B C
5
A
B
C
D
E
A B
C D
A E
C E
0
```

```
Round #1
B defeats A
C advances with wildcard
Round #2
C defeats B
Winner: C

Round #1
A defeats B
C defeats D
E advances with wildcard
Round #2
E defeats A
C advances with wildcard
Round #3
E defeats C
Winner: E

```

The sample has two cases, six games, and three wildcards.

## Idea

Peel the outer layer first, like taking layers off an onion. The games form a tree, and each loser sits at the edge of the surviving tree. The program strips leaves with distinct neighbors, lowest team index first, until one team stays. One strip costs one scan of the teams, so a case costs O(n log n). Trying every bracket builds far more orderings and cannot serve n = 1000. Takeaway: strip legal leaves and print each strip as a round.

## Why It Works

The rules force the shape of every round.

1. With n teams and n - 1 games, the games connect every team into a tree. The statement guarantees that a valid schedule exists.
2. A loser has already beaten its earlier opponents. Those teams have left, so only its conqueror still touches it. The loser is a leaf.
3. Two teams with the same neighbor cannot lose in the same round. That neighbor would play two games at once. Chosen leaves need distinct conquerors.
4. A round removes half the survivors, rounded down. The survivor count falls from R to ceil(R / 2). At most ten rounds occur when n ≤ 1000.
5. Any legal strip leaves a tree that still admits a schedule. Scanning by team index turns that freedom into one fixed answer.

The round arithmetic:

| Term | Meaning |
|---|---|
| `R` | teams alive at the start of a round |
| `remainingCount div 2` | games scheduled in that round |
| `ceil(R / 2)` | teams alive after the round |
| `remainingCount mod 2` | one wildcard when the value is 1 |
| `roundNumber` | the round printed in the header |

Half the teams leave each round, and an odd count adds one wildcard.

A script traces the second sample case:

```
teams: A B C D E
games: A-B C-D A-E C-E
round 1: remaining=5 need=2 leaves=B(1),D(3) pairs=A-over-B,C-over-D wildcard=E
round 2: remaining=3 need=1 leaves=A(0),C(2) pairs=E-over-A wildcard=C
round 3: remaining=2 need=1 leaves=C(2),E(4) pairs=E-over-C wildcard=-
winner: E
```

The trace yields defeat pairs and ends with champion E.

## Code

**Input and output plumbing.** One bulk read feeds two hand scanners; one buffer collects the schedule.

```nim
import tables

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ': pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ': pos += 1
  return data[startPos ..< pos]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'): pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`flushBlockBytes` is 256 KiB. `nextToken` slices a name from the single input string. `nextInt` skips letters and reads the case counts. `appendOutput` writes whole blocks, never one line at a time.

**Case setup.** Names become indices, and every game becomes two adjacency entries.

```nim
while true:
  var teamCount = nextInt(inputData, scanPos)
  if teamCount == 0: break
  var teamNames: seq[string]
  teamNames.setLen(teamCount)
  var nameToIndex = initTable[string, int]()
  for teamIndex in 0 ..< teamCount:
    let teamName = nextToken(inputData, scanPos)
    teamNames[teamIndex] = teamName
    nameToIndex[teamName] = teamIndex
  var adjacency: seq[seq[int]]
  adjacency.setLen(teamCount)
  for teamIndex in 0 ..< teamCount:
    adjacency[teamIndex] = @[]
  for gameIndex in 0 ..< (teamCount - 1):
    let firstName = nextToken(inputData, scanPos)
    let secondName = nextToken(inputData, scanPos)
    let firstIndex = nameToIndex[firstName]
    let secondIndex = nameToIndex[secondName]
    adjacency[firstIndex].add secondIndex
    adjacency[secondIndex].add firstIndex
  var aliveTeams: seq[bool]
  aliveTeams.setLen(teamCount)
  for teamIndex in 0 ..< teamCount:
    aliveTeams[teamIndex] = true
```

The game loop runs exactly n - 1 times. `nameToIndex` avoids a linear name search per game. Each adjacency list holds the alive neighbors of one team.

**Round choice.** One scan picks every loser for the round.

```nim
  var remainingCount = teamCount
  var roundNumber = 1
  while remainingCount > 1:
    let neededGames = remainingCount div 2
    let hadWildcard = (remainingCount mod 2) == 1
    var usedWinner: seq[bool]
    usedWinner.setLen(teamCount)
    for teamIndex in 0 ..< teamCount:
      usedWinner[teamIndex] = false
    var chosenLosers: seq[int]
    var chosenWinners: seq[int]
    for teamIndex in 0 ..< teamCount:
      if chosenLosers.len == neededGames: break
      if not aliveTeams[teamIndex]: continue
      var aliveNeighborCount = 0
      var neighborWinner = -1
      for neighborIndex in adjacency[teamIndex]:
        if aliveTeams[neighborIndex]:
          aliveNeighborCount += 1
          neighborWinner = neighborIndex
      if aliveNeighborCount == 1 and not usedWinner[neighborWinner]:
        chosenLosers.add teamIndex
        chosenWinners.add neighborWinner
        usedWinner[neighborWinner] = true
```

The loop scans all n teams, so a round costs O(n). `aliveNeighborCount == 1` finds a leaf. `usedWinner` stops one team from winning twice in one round.

**Round output.** Games print before the survivors shrink.

```nim
    appendOutput("Round #")
    appendOutput($roundNumber)
    appendOutput("\n")
    for choiceIndex in 0 ..< chosenLosers.len:
      appendOutput(teamNames[chosenWinners[choiceIndex]])
      appendOutput(" defeats ")
      appendOutput(teamNames[chosenLosers[choiceIndex]])
      appendOutput("\n")
    for loserIndex in chosenLosers:
      aliveTeams[loserIndex] = false
    remainingCount = remainingCount - chosenLosers.len
    if hadWildcard:
      for teamIndex in 0 ..< teamCount:
        if aliveTeams[teamIndex] and not usedWinner[teamIndex]:
          appendOutput(teamNames[teamIndex])
          appendOutput(" advances with wildcard\n")
          break
    roundNumber += 1
  for teamIndex in 0 ..< teamCount:
    if aliveTeams[teamIndex]:
      appendOutput("Winner: ")
      appendOutput(teamNames[teamIndex])
      appendOutput("\n")
      break
  appendOutput("\n")
```

Printing happens before removal, so the wildcard check still sees old winners. The blank line closes the case. One scan finds the champion after the last round.

**Final flush.** The tail of the buffer goes out in one write.

```nim
stdout.write outputBuffer
```

The empty-buffer case writes nothing, so the output never gains an extra line.

## Complexity

The work splits into a parse phase, a short stripping phase, and one output phase.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines | input bytes |
| Name mapping | one hash insert per team | n names |
| Leaf stripping | n scans in at most ten rounds | n flags |
| Output write | one write per 256 KiB block | block buffer |

The stripping phase dominates the arithmetic, while output dominates the bytes.

The overall bounds:

| Measure | Big O |
|---|---|
| Time per case | O(n log n) |
| Space per case | O(n) |

Checking every possible bracket grows factorially with n. Leaf stripping keeps each case inside the judge limit.
