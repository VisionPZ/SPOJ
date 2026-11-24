## Problem

Read several tournaments. Each case gives the number of players and a square matrix of duel results. A duel pits a player against the neighbor on its right, and the loser leaves the circle. Print how many players can win some order of all duels, then print those numbers in ascending order.

The bounds are:

| Quantity | Bound |
| --- | --- |
| Players per case | 3 to 100 |
| Test cases | not stated in the statement |
| Time limit | 1169 ms |
| Memory limit | 1536 MB |

The player count is small, so interval dynamic programming fits. The number of duel orders does not.

## Idea

The surviving players keep their circle order after every duel. The last two survivors must therefore come from two neighboring arcs. Compute the possible winners of every arc from short arcs to long ones.

Double the player list so an arc that wraps past the last player becomes one straight interval. Each interval stores two sets: its possible winners, and the players that beat at least one of them. Merging two arcs uses only bit operations on these sets.

One split of an arc costs O(n / 64) word operations.

## Why It Works

Each duel removes one player and keeps the remaining order. The final duel joins two neighboring arcs, and each arc has already been reduced to one survivor.

For an arc, call its winner set win and its hit set. A hit set holds every player that beats at least one winner of that arc.

When two arcs join, a player wins the union if its own side produces a survivor and that survivor beats the other survivor.

merged winners = (left win ∩ right hit) ∪ (right win ∩ left hit)

- left win ∩ right hit: left survivors that beat some right survivor.
- right win ∩ left hit: right survivors that beat some left survivor.
- The union covers both cases, because either side may win the last duel.

Doubling the list puts every possible final arc of players at a start position from 1 to the player count. The program unions the winner sets of those arcs.

For the sample, the seven arcs of full length give these winner sets.

| Arc start | Possible winners |
| --- | --- |
| 1 | 1, 6 |
| 2 | 1, 3 |
| 3 | 1, 3 |
| 4 | 3, 6 |
| 5 | 3, 6 |
| 6 | 3, 6 |
| 7 | 1, 6 |

Their union is 1, 3, 6, which matches the sample output.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const bitsPerWord = 64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The scanner walks one buffer built from `readLine`. It converts digits with `firstDigitValue`, so no token objects are created. Reading the whole stream once costs one pass over the input.

```nim
proc addBit(lowWord: var uint64, highWord: var uint64, bitIndex: int) =
  if bitIndex < bitsPerWord:
    lowWord = lowWord or (1'u64 shl bitIndex)
  else:
    highWord = highWord or (1'u64 shl (bitIndex - bitsPerWord))

proc readRow(data: string, position: var int, beatsLow: var seq[uint64],
             beatsHigh: var seq[uint64], rowIndex: int, playerCount: int) =
  while position < data.len and (data[position] < '0' or data[position] > '1'):
    position += 1
  for j in 0..<playerCount:
    if data[position] == '1':
      addBit(beatsLow[rowIndex], beatsHigh[rowIndex], j)
    position += 1
```

`readRow` reads exactly `playerCount` digit characters, so a row such as 010 is not read as the number ten. The first 64 bits go into one word and the rest go into the second word. The cost is one pass over the matrix.

```nim
proc hasBit(lowWord: uint64, highWord: uint64, bitIndex: int): bool =
  if bitIndex < bitsPerWord:
    return (lowWord and (1'u64 shl bitIndex)) != 0'u64
  return (highWord and (1'u64 shl (bitIndex - bitsPerWord))) != 0'u64

proc countBits(lowWord: uint64, highWord: uint64): int =
  var value = lowWord
  while value != 0'u64:
    value = value and (value - 1'u64)
    result += 1
  value = highWord
  while value != 0'u64:
    value = value and (value - 1'u64)
    result += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`hasBit` and `countBits` work on two words. `appendOutput` flushes at `flushBlockBytes`, which caps memory and avoids one write per number. Each number costs constant work.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let playerCount = nextInt(inputData, scanPos)
  var beatsLow: seq[uint64]
  var beatsHigh: seq[uint64]
  beatsLow.setLen(playerCount)
  beatsHigh.setLen(playerCount)
  for i in 0..<playerCount:
    readRow(inputData, scanPos, beatsLow, beatsHigh, i, playerCount)
  let doubled = 2 * playerCount
  let cellCount = doubled * doubled
  var winLow: seq[uint64]
  var winHigh: seq[uint64]
  var hitLow: seq[uint64]
  var hitHigh: seq[uint64]
  winLow.setLen(cellCount)
  winHigh.setLen(cellCount)
  hitLow.setLen(cellCount)
  hitHigh.setLen(cellCount)
  for length in 1..playerCount:
    for leftIndex in 0..<doubled:
      let rightIndex = leftIndex + length - 1
      if rightIndex >= doubled:
        break
      let intervalIndex = leftIndex * doubled + rightIndex
      if length == 1:
        addBit(winLow[intervalIndex], winHigh[intervalIndex], leftIndex mod playerCount)
      else:
        for splitIndex in leftIndex..<rightIndex:
          let leftBase = leftIndex * doubled + splitIndex
          let rightBase = (splitIndex + 1) * doubled + rightIndex
          winLow[intervalIndex] = winLow[intervalIndex] or
            ((winLow[leftBase] and hitLow[rightBase]) or
             (winLow[rightBase] and hitLow[leftBase]))
          winHigh[intervalIndex] = winHigh[intervalIndex] or
            ((winHigh[leftBase] and hitHigh[rightBase]) or
             (winHigh[rightBase] and hitHigh[leftBase]))
      for player in 0..<playerCount:
        if (beatsLow[player] and winLow[intervalIndex]) != 0'u64 or
           (beatsHigh[player] and winHigh[intervalIndex]) != 0'u64:
          addBit(hitLow[intervalIndex], hitHigh[intervalIndex], player)
```

The loop over `length` stops at `playerCount`, and `leftIndex` scans the doubled list. The split merges winner sets with a few word operations. The program fills `hitLow` and `hitHigh` after each winner set, so longer arcs can use them. The cost per case is O(n^3 / 64) word operations.

```nim
  var answerLow = 0'u64
  var answerHigh = 0'u64
  for startIndex in 0..<playerCount:
    let answerIndex = startIndex * doubled + startIndex + playerCount - 1
    answerLow = answerLow or winLow[answerIndex]
    answerHigh = answerHigh or winHigh[answerIndex]
  let winnerCount = countBits(answerLow, answerHigh)
  appendOutput($(winnerCount))
  outputBuffer.add '\n'
  for player in 0..<playerCount:
    if hasBit(answerLow, answerHigh, player):
      appendOutput($(player + 1))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The answer unions the full-length arcs. `countBits` gives the first output line, and the scan prints winners in ascending order. The final `stdout.write` flushes the remaining buffer.

## Complexity

Reading and parsing cost O(total input bytes). The table stores four words for each of O(n^2) cells. Each case costs O(n^3 / 64) word operations, so the total is O(input bytes + t * n^3 / 64). Space is O(n^2) per case.

Trying every duel order takes exponential time in the player count.
