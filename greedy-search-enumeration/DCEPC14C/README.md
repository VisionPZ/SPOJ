# DCEPC14C — The Long Pile Game (SPOJ)

<https://www.spoj.com/problems/DCEPC14C/>

## Problem

Decide who wins a coin-pile game where each move removes one, K, or L coins and the player taking the last coin wins. Print the winner for each case, assuming both players play well.

The first input line holds the case count. Each next line holds K, L, and the pile size N. Print `Alice` when the first player wins and `Bob` otherwise, one line per case. Equal values of K and L are allowed, and the move set then contains fewer than three sizes.

| Item | Bound |
|---|---|
| Move sizes K and L | 1 to 20 |
| Pile size N | 1 to 1000000000 |
| Case count | up to 100000 |
| Judge limit | 1000 ms, 1536 MB |

The huge pile size rules out a per-pile scan; the small move sizes make a repeated pattern possible.

Sample input:

```
5
5 4 8
1 3 9
4 3 10
1 1 5
1 5 6
```

The sample covers two move sizes, repeated move sizes, and several pile sizes.

Sample output:

```
Bob
Alice
Alice
Alice
Bob
```

Each line answers the case in the same position of the input.

## Idea

The win or loss of a pile repeats like a short drum loop: once the last few outcomes repeat, all later outcomes follow the same loop. Store one loop per move pair and fold a huge pile size back into it.

The algorithm builds a win table for every pair of move sizes up to twenty. It encodes the last max(K, L) outcomes as a bit pattern and records the first repeat of each pattern. That repeat gives a starting point and a period. A pile size beyond the start maps into the period and reads a stored win bit. A direct scan up to N would take a billion steps; the loop needs one lookup.

Takeaway: find the loop once per move pair, then answer each case by index arithmetic.

## Why It Works

1. A pile of zero coins loses, because the player to move has no move.
2. A pile wins when some legal removal leaves the opponent a losing pile.
3. The next outcome depends only on the outcomes of the previous max(K, L) piles.
4. Those previous outcomes have at most 2^20 patterns, so a repeat must occur.
5. Once a pattern repeats, the same transition rules repeat forever from its first occurrence.
6. The first repeat gives a start index and a period, so any N maps to a stored bit.

| Term | Meaning |
|---|---|
| `winArray` | win or loss values for consecutive pile sizes |
| `stateCode` | the last max(K, L) outcomes packed into one integer |
| `preperiod` | index where the repeating pattern starts |
| `period` | length of one repeating block |
| `patternTable` | stored win bits indexed by a move pair |

The table shows how a bit pattern becomes a reusable answer table.

A script-generated trace of the sample cases:

```
K=5 L=4 N=8: moves=[1, 4, 5] start=01011 pre=0 per=8 idx=0 winner=Bob
K=1 L=3 N=9: moves=[1, 3] start=010 pre=0 per=2 idx=1 winner=Alice
K=4 L=3 N=10: moves=[1, 3, 4] start=0101 pre=0 per=7 idx=3 winner=Alice
K=1 L=1 N=5: moves=[1] start=0 pre=0 per=2 idx=1 winner=Alice
K=1 L=5 N=6: moves=[1, 5] start=01010 pre=0 per=2 idx=0 winner=Bob
```

The trace reproduces all five sample winners.

The generated table stores bits from index zero through one full period. A pile smaller than the period reads its own bit. A larger pile reads the bit at the reduced index. Both paths return the same winner that a full scan would find.

## Code

**Input, scanner, and output helper.** One pass loads input and one buffer collects all winners.

```nim
const flushBlockBytes = 1 shl 17
const maxMoveValue = 20
const dpLimit = 2000
const pairWidth = 21

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

`dpLimit` covers enough piles to expose every loop for move sizes up to twenty. `pairWidth` indexes the pair tables. This block runs once.

**Loop discovery for every move pair.** Each pair gets a win table and a repeat check on packed states.

```nim
var preperiodTable = newSeq[int]((maxMoveValue + 1) * pairWidth)
var periodTable = newSeq[int]((maxMoveValue + 1) * pairWidth)
var patternTable = newSeq[string]((maxMoveValue + 1) * pairWidth)
var seenState = newSeq[int](1 shl maxMoveValue)
for stateCode in 0 .. seenState.len - 1:
  seenState[stateCode] = -1

for firstMove in 1 .. maxMoveValue:
  for secondMove in 1 .. maxMoveValue:
    var moveList = newSeq[int]()
    moveList.add 1
    if firstMove != 1:
      moveList.add firstMove
    if secondMove != 1 and secondMove != firstMove:
      moveList.add secondMove
    var maxMove = 1
    if firstMove > maxMove:
      maxMove = firstMove
    if secondMove > maxMove:
      maxMove = secondMove
    var winArray = newSeq[bool](dpLimit + 1)
    winArray[0] = false
    for position in 1 .. dpLimit:
      winArray[position] = false
      for moveValue in moveList:
        if moveValue <= position and not winArray[position - moveValue]:
          winArray[position] = true
          break
    var preperiod = 0
    var period = dpLimit - maxMove
    var usedStates = newSeq[int]()
    for startPos in 0 .. dpLimit - maxMove:
      var stateCode = 0
      for offset in 0 .. maxMove - 1:
        if winArray[startPos + offset]:
          stateCode = stateCode or (1 shl offset)
      let previousPos = seenState[stateCode]
      if previousPos >= 0:
        preperiod = previousPos
        period = startPos - previousPos
        break
      seenState[stateCode] = startPos
      usedStates.add stateCode
    for stateCode in usedStates:
      seenState[stateCode] = -1
    var pattern = ""
    for position in 0 .. preperiod + period - 1:
      if winArray[position]:
        pattern.add '1'
      else:
        pattern.add '0'
    let tableIndex = firstMove * pairWidth + secondMove
    preperiodTable[tableIndex] = preperiod
    periodTable[tableIndex] = period
    patternTable[tableIndex] = pattern
```

Repeated move sizes enter `moveList` once. `seenState` is cleared through the states touched by each pair. One block of bits is kept per pair.

**Case answers.** A huge pile size is reduced into its pair's stored block.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstMove = nextInt(inputData, scanPos)
  let secondMove = nextInt(inputData, scanPos)
  let pileSize = nextInt(inputData, scanPos)
  let tableIndex = firstMove * pairWidth + secondMove
  let preperiod = preperiodTable[tableIndex]
  let period = periodTable[tableIndex]
  var patternPos = pileSize
  if patternPos >= preperiod:
    patternPos = preperiod + (patternPos - preperiod) mod period
  if patternTable[tableIndex][patternPos] == '1':
    appendOutput("Alice\n")
  else:
    appendOutput("Bob\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads one triple per case. Reduction cost is constant and independent of N. The final flush writes all winners together.

## Complexity

Precomputation covers all 400 move pairs, and each case then costs one lookup.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all cases | one input string |
| Loop discovery | 400 tables of up to 2000 positions | pair tables and state array |
| Case answer | one reduced index per case | block buffer |

The phase table shows that the expensive work happens once before any case is read.

| Measure | Big O |
|---|---|
| Precomputation time | O(20 squared times dpLimit times 20) |
| Query time | O(number of cases) |
| Space | O(20 squared times block length plus 2^20) |

Scanning each pile up to a billion steps would be impossible here; the loop table answers each case in constant time.
