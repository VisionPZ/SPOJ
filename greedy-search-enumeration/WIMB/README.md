# WIMB — The Grandslam of Grandslams! (SPOJ)

<https://www.spoj.com/problems/WIMB/>

## Problem

A tennis match ends when a player wins three sets. Each set ends at six games with a two-game lead, or at a tie-break from six-all. Each game takes five minutes, and the server alternates after every game, so the task is the expected game count of the whole match.

Input starts with the case count T. Each case has two lines, one per player. Each line holds a first name, a last name and an integer. The integer runs from 0 to 100. It is the win chance, in percent, on that player's serve. Output the expected match length in minutes with six digits after the point.

| item | bound |
|---|---|
| cases T | small in practice |
| serve win percent | 0 to 100 |
| sets to win match | 3 |
| minutes per game | 5 |
| judge limit | 5000 ms, 1536 MB |

Sample input:

```
2
Pete Sampras 50
Rafael Nadal 50
Roger Federer 100
Arjit Srivastava 0
```

Sample output:

```
199.281006
90.000000
```

## Idea

Treat the score as a position in a board game. Count the expected remaining moves from each position. This is like counting steps to the end of a ladder. The algorithm is expectation over a finite Markov chain with memoisation.

The state stores the two game scores, the two set counts and the next server. One game moves to at most two successor states. Terminal states return zero. Alternating the server inside the transition keeps the global serving order across sets and tie-breaks. Recursion from the start visits each reachable state once.

## Why It Works

1. A game won on serve has probability A/100 for the first player, and 1 - B/100 when the second player serves.
2. After every game the server flips, so the next server is part of the state.
3. A set ends at six games with a lead of two, or at seven-six after a tie-break.
4. The expectation from a state is one game plus the weighted expectations of its successors.
5. Summing the game expectation over all paths gives the match length in minutes.

| term | meaning |
|---|---|
| `firstServeProbability` | chance the first player wins on their own serve |
| `secondServeProbability` | chance the second player wins on their own serve |
| `memoizedGames` | cached expected games for each state |
| `matchMinutes` | expected games times five |

Take the second sample. The first player wins every game, so each set ends six-nil. Three sets give eighteen games, and eighteen times five is ninety minutes.

The score index packs five small fields into one array slot. A score of seven appears only in a tie-break. No rounding is needed until the final print, where adding half a unit performs round-half-up.

## Code

**Input and scanner.** The reader loads stdin once, and the scanner extracts the two percentages per case.

```nim
const flushBlockBytes = 1 shl 17
const gamesInSetWin = 6
const setsInMatchWin = 3
const minutesPerGame = 5
const decimalScale = 1000000
const memoSize = 2048

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

Names contain no digits, so the scanner reads only the two percentages. One array slot holds each state.

**Buffered output and transition.** The transition applies one game and detects a finished set.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var firstServeProbability = 0.0
var secondServeProbability = 0.0
var memoizedGames: array[0 .. memoSize - 1, float64]

proc applyGame(firstGames, secondGames, firstSets, secondSets: int, firstWon: bool,
               nextFirstGames, nextSecondGames, nextFirstSets, nextSecondSets: var int) =
  if firstWon:
    nextFirstGames = firstGames + 1
    nextSecondGames = secondGames
  else:
    nextFirstGames = firstGames
    nextSecondGames = secondGames + 1
  var setFinished = false
  nextFirstSets = firstSets
  nextSecondSets = secondSets
  if nextFirstGames >= gamesInSetWin and nextFirstGames - nextSecondGames >= 2:
    nextFirstSets = firstSets + 1
    setFinished = true
  elif nextSecondGames >= gamesInSetWin and nextSecondGames - nextFirstGames >= 2:
    nextSecondSets = secondSets + 1
    setFinished = true
  elif nextFirstGames == gamesInSetWin + 1 and nextSecondGames == gamesInSetWin:
    nextFirstSets = firstSets + 1
    setFinished = true
  elif nextSecondGames == gamesInSetWin + 1 and nextFirstGames == gamesInSetWin:
    nextSecondSets = secondSets + 1
    setFinished = true
  if setFinished:
    nextFirstGames = 0
    nextSecondGames = 0
```

A finished set adds one set win and clears both game scores. The tie-break branches handle seven-six.

**Expectation.** Recursion computes and caches the expected games for each state.

```nim
proc expectedGames(firstGames, secondGames, firstSets, secondSets, server: int): float64 =
  if firstSets == setsInMatchWin or secondSets == setsInMatchWin:
    return 0.0
  let stateIndex = (((firstGames * 8 + secondGames) * 4 + firstSets) * 4 + secondSets) * 2 + server
  if memoizedGames[stateIndex] >= 0.0:
    return memoizedGames[stateIndex]
  var winProbability = firstServeProbability
  if server == 1:
    winProbability = 1.0 - secondServeProbability
  var winFirstGames, winSecondGames, winFirstSets, winSecondSets: int
  applyGame(firstGames, secondGames, firstSets, secondSets, true,
            winFirstGames, winSecondGames, winFirstSets, winSecondSets)
  var loseFirstGames, loseSecondGames, loseFirstSets, loseSecondSets: int
  applyGame(firstGames, secondGames, firstSets, secondSets, false,
            loseFirstGames, loseSecondGames, loseFirstSets, loseSecondSets)
  let nextServer = 1 - server
  let expected = 1.0 +
    winProbability * expectedGames(winFirstGames, winSecondGames, winFirstSets, winSecondSets, nextServer) +
    (1.0 - winProbability) * expectedGames(loseFirstGames, loseSecondGames, loseFirstSets, loseSecondSets, nextServer)
  memoizedGames[stateIndex] = expected
  return expected
```

Each state is evaluated once. The two successors carry the flipped server.

**Driver and formatting.** The cache resets per case, since probabilities differ between cases.

```nim
proc formatMinutes(minutes: float64): string =
  let scaled = int64(minutes * float64(decimalScale) + 0.5)
  var whole = scaled div decimalScale
  var fraction = scaled mod decimalScale
  if fraction == decimalScale:
    whole += 1
    fraction = 0
  result = $whole
  result.add '.'
  var divisor: int64 = decimalScale div 10
  while divisor > 0:
    result.add chr(48 + int(fraction div divisor))
    fraction = fraction mod divisor
    divisor = divisor div 10
  result.add '\n'

for stateIndex in 0 .. memoSize - 1:
  memoizedGames[stateIndex] = -1.0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstServePercent = nextInt(inputData, scanPos)
  let secondServePercent = nextInt(inputData, scanPos)
  firstServeProbability = float64(firstServePercent) / 100.0
  secondServeProbability = float64(secondServePercent) / 100.0
  for stateIndex in 0 .. memoSize - 1:
    memoizedGames[stateIndex] = -1.0
  let matchMinutes = expectedGames(0, 0, 0, 0, 0) * float64(minutesPerGame)
  appendOutput(formatMinutes(matchMinutes))
stdout.write outputBuffer
outputBuffer.setLen 0
```

Minus one marks an unvisited slot. The formatter pads each line to six digits.

## Complexity

The state space has at most eight score values per player, four set counts per player and two servers.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| expectation | one evaluation per state | 2048 cached doubles |
| output | one line per case | 128 KiB buffer |

| measure | Big O |
|---|---|
| time | O(states per case + input length) |
| space | O(states) |

Enumerating full match paths would grow exponentially with the number of games. Memoisation reduces that work to a fixed table.
