# SCCCER — Soccer Ceremony (SPOJ)
<https://www.spoj.com/problems/SCCCER/>

## Problem

Rearrange the players in one row so no three neighbours wear the same team letter. Count the players who leave their original seat, or report `-1` when no rearrangement works.

The first integer gives the test count. Each test starts with `N` and a string of `N` letters from `C`, `P`, `N`, `S`. Print one integer per test.

| item | bound |
|---|---|
| tests | at least 1 |
| players N | 1 to 20 |
| team letters | C, P, N, S |
| judge limit | 10160 ms, 1536 MB |

A blank line separates two test cases in the input. Reordering keeps the team counts unchanged.

Sample input:

```
2
8
CCCCCCPN

3
CCC

```

Sample output:

```
4
-1
```

## Idea

Keep the row as it is wherever possible, like sliding books on a shelf only when a stack grows too tall. A dynamic program tracks the four used counts, the last letter, and its run length. It adds one player per seat and keeps the cheapest valid arrangement.

The state space is small because `N` never exceeds 20. Trying every permutation counts factorials, so the table avoids that cost. The answer is the minimum number of seats whose letter changes.

## Why It Works

1. A valid row never places the same letter in three consecutive seats.
2. The four team counts stay fixed during a rearrangement.
3. A state records how many players of each team are already seated.
4. The last letter and its run length decide whether the next letter may repeat.
5. Each transition adds one changed seat when the chosen letter differs from the original one.

| term | meaning |
|---|---|
| `totalCounts` | how many players wear each team letter |
| `runLength` | how many equal letters end the current prefix |
| `activeStates` | states reachable at the current seat |
| `bestCost` | fewest changed seats after all players are seated |

A worked run uses the sample row `CCCCCCPN`. The counts are six `C`, one `P`, one `N`. The cheapest valid row is `CCPCCNCC`. It differs at seats 2, 5, 6 and 7, so the answer is 4.

## Code

**Input and parsing.** The reader loads all stdin and pulls integers and team words by hand.

```nim
const flushBlockBytes = 1 shl 17
const teamKinds = 4
const lastKinds = 5
const runKinds = 3
const impossibleCost = 1000000000

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

proc nextTeamWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] notin {'C', 'P', 'N', 'S'}:
    pos += 1
  var word = ""
  while pos < data.len and data[pos] in {'C', 'P', 'N', 'S'}:
    word.add data[pos]
    pos += 1
  return word
```

Blank lines are skipped by both scanners.
Team words contain only the four allowed letters.
Each test consumes one integer and one word.

**State helpers.** The team number and the mixed-radix state index use small integers.

```nim
proc teamNumber(letter: char): int =
  case letter
  of 'C':
    return 0
  of 'P':
    return 1
  of 'N':
    return 2
  else:
    return 3

proc encodeState(countZero, countOne, countTwo, lastTeam, runLength, countBase: int): int =
  return (((countZero * countBase + countOne) * countBase + countTwo) * lastKinds + lastTeam) * runKinds + runLength

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The fourth count follows from the seat index.
The last letter value 4 means no letter yet.
Output waits in one buffer until the flush threshold.

**Seat-by-seat transitions.** Each active state extends by a team that still has players left.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let playerCount = nextInt(inputData, scanPos)
  let seatTeams = nextTeamWord(inputData, scanPos)
  var totalCounts = [0, 0, 0, 0]
  for seatIndex in 0 .. playerCount - 1:
    totalCounts[teamNumber(seatTeams[seatIndex])] += 1
  let countBase = playerCount + 1
  let countSquare = countBase * countBase
  let stateBase = countSquare * countBase
  let stateCount = stateBase * lastKinds * runKinds
  var currentCosts = newSeq[int](stateCount)
  var nextCosts = newSeq[int](stateCount)
  var activeStates: seq[int] = @[]
  var nextStates: seq[int] = @[]
  for stateIndex in 0 .. stateCount - 1:
    currentCosts[stateIndex] = impossibleCost
    nextCosts[stateIndex] = impossibleCost
  let initialState = encodeState(0, 0, 0, teamKinds, 0, countBase)
  currentCosts[initialState] = 0
  activeStates.add initialState
```

The two cost arrays hold the current and next seat layers.
Only reachable states enter the active list.
An impossible cost marks every unused state.

**Run guard and cost.** A run of three is rejected; a changed letter adds one.

```nim
  for seatIndex in 0 .. playerCount - 1:
    nextStates.setLen 0
    for stateIndex in activeStates:
      let stateCost = currentCosts[stateIndex]
      let runLength = stateIndex mod runKinds
      let afterRun = stateIndex div runKinds
      let lastTeam = afterRun mod lastKinds
      let afterLast = afterRun div lastKinds
      let countTwo = afterLast mod countBase
      let afterTwo = afterLast div countBase
      let countOne = afterTwo mod countBase
      let countZero = afterTwo div countBase
      let countThree = seatIndex - countZero - countOne - countTwo
      var usedCounts = [countZero, countOne, countTwo, countThree]
      let wantedTeam = teamNumber(seatTeams[seatIndex])
      for chosenTeam in 0 .. teamKinds - 1:
        if usedCounts[chosenTeam] >= totalCounts[chosenTeam]:
          continue
        var nextRun = 1
        if chosenTeam == lastTeam:
          nextRun = runLength + 1
        if nextRun > 2:
          continue
        var newZero = countZero
        var newOne = countOne
        var newTwo = countTwo
        case chosenTeam
        of 0:
          newZero += 1
        of 1:
          newOne += 1
        of 2:
          newTwo += 1
        else:
          discard
        let newState = encodeState(newZero, newOne, newTwo, chosenTeam, nextRun, countBase)
        var newCost = stateCost
        if chosenTeam != wantedTeam:
          newCost += 1
        if newCost < nextCosts[newState]:
          if nextCosts[newState] == impossibleCost:
            nextStates.add newState
          nextCosts[newState] = newCost
    for stateIndex in activeStates:
      currentCosts[stateIndex] = impossibleCost
    let swapCosts = currentCosts
    currentCosts = nextCosts
    nextCosts = swapCosts
    activeStates = nextStates
```

Decoding reverses the mixed-radix index.
A team with no remaining players cannot be chosen.
After each seat the two cost arrays swap roles.

**Final answer.** The last layer shows the cheapest full row, or no row at all.

```nim
  var bestCost = impossibleCost
  for stateIndex in activeStates:
    let afterRun = stateIndex div runKinds
    let afterLast = afterRun div lastKinds
    let countTwo = afterLast mod countBase
    let afterTwo = afterLast div countBase
    let countOne = afterTwo mod countBase
    let countZero = afterTwo div countBase
    if countZero == totalCounts[0] and countOne == totalCounts[1] and countTwo == totalCounts[2]:
      if currentCosts[stateIndex] < bestCost:
        bestCost = currentCosts[stateIndex]
  if bestCost == impossibleCost:
    appendOutput("-1")
  else:
    appendOutput($bestCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Matching three counts fixes the fourth count automatically.
An unreachable full row prints `-1`.
The buffer flushes once after the last test.

## Complexity

Each seat visits only states that are reachable so far.

| phase | time | space |
|---|---|---|
| parse one test | one pass over N letters | input string and team word |
| seat transitions | at most four extensions per active state | two cost arrays |
| answer scan | one pass over the final layer | one active list |

| measure | Big O |
|---|---|
| time per test | O(N^4) worst case |
| space per test | O(N^3) |

Enumerating every permutation costs O(N!) time per test.
The table keeps the work polynomial and handles N = 20 with ease.
