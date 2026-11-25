# MUSKET — Musketeers (SPOJ)

<https://www.spoj.com/problems/MUSKET/>

## Problem

Musketeers duel in a circle, and the loser leaves. Some fighters can win only under certain orders of duels.

Read several tournaments. Each case gives the player count and a square matrix of duel results. A duel pits a player against the neighbor on the right, and the loser leaves the circle.

Print how many players can win some order of all duels, then their numbers in ascending order.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Players per case | 3 to 100 |
| Test cases | not stated in the statement |
| Time limit | 1169 ms |
| Memory limit | 1536 MB |

The player count is small, so interval dynamic programming fits. The number of duel orders does not.

The sample case:

```
1
7
1111101
0101100
0111111
0001101
0000101
1101111
0100001
```

```
3
1
3
6
```

## Idea

Survivors keep their circle order after every duel, so the final duel joins two neighboring arcs.

Think of a necklace cut into two strands. Each strand is reduced to one bead, then the strands meet. The program doubles the player list so any wrapping arc becomes one straight interval.

Interval dynamic programming (solving short intervals first, then longer ones) fills a winner set and a hit set per interval. A merge uses bit operations on two 64-bit words.

One split of an arc costs O(n / 64) word operations. Trying every duel order takes exponential time.

## Why It Works

Five facts prove the merge rule.

1. Each duel removes one player and keeps the remaining order. The final duel therefore joins two neighboring arcs, each reduced to one survivor.
2. For an arc, the winner set holds its possible survivors. The hit set holds every player that beats at least one of those winners.
3. Merging two arcs gives `(left win AND right hit) OR (right win AND left hit)`. The first term covers a left survivor beating a right one, and the second covers the reverse.
4. Doubling the list puts every full-length arc at a start position from 1 through `n`. The union of their winner sets is the final answer.
5. `readRow` reads exactly `playerCount` digit characters, so a row such as `010` is not read as the number ten. Two words cover the 100 player bits.

The arrays and their roles:

| Term | Meaning |
| --- | --- |
| `beatsLow` | low word of players each player defeats |
| `winLow` | low word of possible winners of an interval |
| `hitLow` | low word of players beating some winner |
| `doubled` | twice the player count, for wrapping arcs |
| `intervalIndex` | flat index of an interval in the doubled list |
| `countBits` | counts set bits across both words |

The high-word arrays hold the same information for players 64 through 100.

A script prints the winner set of every full-length arc in the sample:

```
1 [1, 6]
2 [1, 3]
3 [1, 3]
4 [3, 6]
5 [3, 6]
6 [3, 6]
7 [1, 6]
```

The union is `{1, 3, 6}`, so the program prints count 3 and then players 1, 3, and 6.

## Code

**Setup and scanner.** One buffer holds the input, and a hand scanner reads integers.

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

**Bit helpers and matrix.** Two words hold all player bits, and one helper reads a row.

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

`readRow` reads exactly `playerCount` digit characters, so a row such as 010 stays three bits. The first 64 bits go into one word and the rest into the second. The cost is one pass over the matrix.

**Answer helpers and output.** Bit tests and one block buffer finish each case.

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

`hasBit` and `countBits` work on two words. `appendOutput` flushes at `flushBlockBytes`, which caps memory and avoids one write per number.

**Interval DP.** Arcs grow from one player to the full circle.

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

The loop over `length` stops at `playerCount`, and `leftIndex` scans the doubled list. The split merges winner sets with a few word operations. The program fills hit sets right after each winner set, so longer arcs can use them.

**Answer.** The full-length arcs union into the final winner set.

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

The answer unions the full-length arcs. `countBits` gives the first line, and the scan prints winners in increasing order. The final write flushes the remaining buffer.

## Complexity

The interval table dominates both time and space.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Matrix read | O(n^2) | O(n) bit rows |
| Interval DP | O(n^3 / 64) word operations | O(n^2) cells |
| Answer and output | O(n) | one output block |

Four words hold the sets of each interval cell.

| Measure | Big O |
| --- | --- |
| Time | O(input bytes + t * n^3 / 64) |
| Space | O(n^2) per case |

Trying every duel order takes exponential time in the player count.
