# BLACJACK — Blackjack (SPOJ)

<https://www.spoj.com/problems/BLACJACK/>

## Problem

Choose one cut of a card deck to maximize the number of rounds the player wins under a fixed hit strategy. Print the best count with a case number.

Input contains cases until end of file. Each case starts with n and k, followed by n card symbols. A cut moves one middle block to the front and keeps the order inside every block. Output is one line per case in the form `Case X: Y`.

| item | bound |
|---|---|
| cards n | 20 to 2000 |
| minimum cards k | 10 to n |
| test cases | about 15 |
| judge limit | 3000 ms, 1536 MB |

The quadratic number of cuts drives the need for fast round skipping.

Sample input:

```
20 10
8 4 7 8 8 K 5 A Q Q A Q 6 4 J 6 9 5
3 9
40 10
3 J 7 7 2 T J 6 A 4 4 8 J T 6 A 6 2 K 9
6 5 7 J T 3 5 5 3 7 7 J 5 3 A 5 9 Q 6 7
```

Sample output:

```
Case 1: 3
Case 2: 6
```

## Idea

A round consumes between four and ten cards, so think of it as a short train car on a long track. Doubling tables jump over whole trains of rounds inside one block, while only the few rounds crossing a cut need fresh cards. Try every cut but spend constant time on most rounds. Simulating every card for every cut would cost cubic time. Takeaway: skip whole rounds with doubling and simulate only the boundaries.

## Why It Works

1. A cut produces three blocks in order: the moved block, the old front block, and the tail.
2. Rounds start at the front and consume four to ten cards each, always in deck order.
3. Inside one block, the next round start depends only on the cards at that start.
4. Doubling tables store the end index and win count for 2^j consecutive rounds.
5. At most three rounds cross a block boundary, so those rounds are built from up to ten real cards.

| term | meaning |
|---|---|
| `keepLimit` | minimum cards needed to start a round |
| `endTable` | last card index of a doubling block of rounds |
| `winTable` | player wins inside a doubling block |
| `jumpTable` | index after a doubling block |
| `buildCrossWindow` | ten cards spanning a block boundary |

A script trace for one round:

```
player cards 7 and 8 : total 15, hit 5 gives 20, stand
dealer cards 4 and 8 : total 12, hit 8 gives 20, stand
20 ties 20, so neither side wins
```

All totals stay below 32, so plain integers are safe.

## Code

**Input and card parsing.** The reader stores symbols and converts them to values.

```nim
const flushBlockBytes = 1 shl 17
const maxCards = 2005
const maxLogLevels = 12
const maxWindow = 12

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc hasMoreData(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and data[scanIndex] <= ' ':
    scanIndex += 1
  return scanIndex < data.len

proc cardValue(cardToken: string): int =
  let symbol = cardToken[0]
  if symbol == 'A':
    return 1
  if symbol >= '2' and symbol <= '9':
    return int(symbol) - 48
  return 10
```

The word reader stops at spaces and line breaks.
Face cards map to ten and the ace maps to one.
The header parses with the integer scanner.

**Round simulation.** Both sides follow the same fixed hit strategy.

```nim
proc simulateRound(cards: array[maxWindow, int]): tuple[wins: int, used: int] =
  var playerTotal = cards[0] + cards[2]
  var dealerTotal = cards[1] + cards[3]
  var usedCards = 4
  var playerHits = 0
  while playerHits < 3 and playerTotal <= 15:
    playerTotal = playerTotal + cards[usedCards]
    usedCards += 1
    playerHits += 1
    if playerTotal > 21:
      result[0] = 0
      result[1] = usedCards
```

A player bust loses at once and a five-card hand wins at once.
The dealer then repeats the same rules with later cards.
Ties return no win without special handling.

**Doubling tables.** Precomputed blocks skip long runs of rounds.

```nim
var endTable: array[maxLogLevels, array[maxCards, int]]
var winTable: array[maxLogLevels, array[maxCards, int]]
var jumpTable: array[maxLogLevels, array[maxCards, int]]
var logCount = 0
var deckSize = 0
var keepLimit = 0
var cardValues: array[maxCards, int]

proc buildPrefixRound(startIndex: int): array[maxWindow, int] =
  for windowIndex in 0 .. maxWindow - 1:
    result[windowIndex] = 0
  for offsetIndex in 0 .. 9:
    result[offsetIndex] = cardValues[startIndex + offsetIndex]

proc buildTables() =
  logCount = 1
  while (1 shl logCount) <= deckSize:
    logCount += 1
  for levelIndex in 0 .. maxLogLevels - 1:
    for cardIndex in 0 .. deckSize + 1:
      endTable[levelIndex][cardIndex] = deckSize + 1
      winTable[levelIndex][cardIndex] = 0
      jumpTable[levelIndex][cardIndex] = cardIndex
  for startIndex in 0 .. deckSize - 10:
    let windowCards = buildPrefixRound(startIndex)
    let roundResult = simulateRound(windowCards)
    let nextIndex = startIndex + roundResult[1]
    endTable[0][startIndex] = nextIndex - 1
    winTable[0][startIndex] = roundResult[0]
    jumpTable[0][startIndex] = nextIndex
  var levelIndex = 1
  while levelIndex < logCount:
    for cardIndex in 0 .. deckSize + 1:
      let middleIndex = jumpTable[levelIndex - 1][cardIndex]
      endTable[levelIndex][cardIndex] = endTable[levelIndex - 1][middleIndex]
      winTable[levelIndex][cardIndex] = winTable[levelIndex - 1][cardIndex] + winTable[levelIndex - 1][middleIndex]
      jumpTable[levelIndex][cardIndex] = jumpTable[levelIndex - 1][middleIndex]
    levelIndex += 1

proc winsInRange(startIndex: int, stopIndex: int): tuple[wins: int, used: int] =
  var currentIndex = startIndex
  var totalWins = 0
  if currentIndex > stopIndex:
    result[0] = 0
    result[1] = currentIndex
```

Each table entry covers 2^j rounds from one start index.
A block fits when its end index stays inside the query range.
The high-to-low scan consumes the largest fitting blocks first.

**Cut evaluation.** Each pair of cut points is scored in one sweep.

```nim
proc buildCrossWindow(cutPosition: int, blockStart: int, blockStop: int): array[maxWindow, int] =
  for windowIndex in 0 .. maxWindow - 1:
    result[windowIndex] = 0
  let firstLength = blockStop - blockStart + 1
  let secondLength = blockStart
  var taken = 0
  if cutPosition < firstLength:
    var sourceIndex = blockStart + cutPosition
    while sourceIndex <= blockStop and taken < 10:
      result[taken] = cardValues[sourceIndex]
      taken += 1
      sourceIndex += 1
  if taken < 10 and cutPosition < firstLength + secondLength:
    var sourceIndex = cutPosition - firstLength
    if sourceIndex < 0:
      sourceIndex = 0
    while sourceIndex <= blockStart - 1 and taken < 10:
      result[taken] = cardValues[sourceIndex]
      taken += 1
      sourceIndex += 1
  if taken < 10:
    var sourceIndex = cutPosition - firstLength - secondLength
    if sourceIndex < 0:
      sourceIndex = 0
    sourceIndex = blockStop + 1 + sourceIndex
    while sourceIndex <= deckSize - 1 and taken < 10:
      result[taken] = cardValues[sourceIndex]
      taken += 1
      sourceIndex += 1

proc bestWins(): int =
  var bestTotal = 0
  var blockStart = 1
  while blockStart <= deckSize - 2:
    var blockStop = blockStart
    while blockStop <= deckSize - 2:
      let firstLength = blockStop - blockStart + 1
      let secondLength = blockStart
      var cutPosition = 0
      var roundWins = 0
      while cutPosition + keepLimit <= deckSize:
        var sourceIndex = 0
        var segmentStop = 0
        var segmentCutStop = 0
        var offsetValue = 0
        if cutPosition < firstLength:
          sourceIndex = blockStart + cutPosition
          segmentStop = blockStop
          segmentCutStop = firstLength - 1
          offsetValue = -blockStart
        elif cutPosition < firstLength + secondLength:
          sourceIndex = cutPosition - firstLength
          segmentStop = blockStart - 1
          segmentCutStop = firstLength + secondLength - 1
          offsetValue = firstLength
        else:
          sourceIndex = cutPosition
          segmentStop = deckSize - 1
          segmentCutStop = deckSize - 1
          offsetValue = 0
        var playStop = deckSize - keepLimit - offsetValue
        if playStop > segmentStop:
          playStop = segmentStop
        let rangeResult = winsInRange(sourceIndex, playStop)
        roundWins = roundWins + rangeResult[0]
        cutPosition = cutPosition + (rangeResult[1] - sourceIndex)
        if cutPosition + keepLimit > deckSize:
          break
        if rangeResult[1] <= segmentStop:
          let crossingCards = buildCrossWindow(cutPosition, blockStart, blockStop)
          let crossingResult = simulateRound(crossingCards)
          roundWins = roundWins + crossingResult[0]
          cutPosition = cutPosition + crossingResult[1]
        else:
          cutPosition = segmentCutStop + 1
      if roundWins > bestTotal:
        bestTotal = roundWins
      blockStop += 1
    blockStart += 1
  return bestTotal
```

The sweep moves through the three blocks in cut order.
Crossing rounds read ten cards from the correct blocks.
The best win count is kept across all cuts.

**Driver.** Cases are read until the input ends.

```nim
var caseIndex = 0
while hasMoreData(inputData, scanPos):
  deckSize = nextInt(inputData, scanPos)
  keepLimit = nextInt(inputData, scanPos)
  for cardIndex in 0 .. deckSize - 1:
    cardValues[cardIndex] = cardValue(nextWord(inputData, scanPos))
  buildTables()
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & $bestWins())
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Card arrays are rebuilt for every case.
Table construction happens once per case.
One labeled line is written per case.

## Complexity

Doubling tables replace long round simulations inside each block.

| phase | time | space |
|---|---|---|
| input read | one pass over card symbols | one input string |
| table build | O(n log n) entries | three doubling tables |
| cut sweep | O(n^2 log n) per case | a few integers |
| output | one line per case | block buffer |

Only boundary rounds use the full ten-card simulation.

| measure | Big O |
|---|---|
| time | O(n^2 log n) per case |
| space | O(n log n) |

Simulating every dealt card for every cut would take O(n^3) per case. Takeaway: doubling tables bring the full deck bound within the limit.
