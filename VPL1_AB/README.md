# VPL1_AB — Summer Game (SPOJ)

<https://www.spoj.com/problems/VPL1_AB/>

## Problem

Count the ways to walk from position one to position N by throwing D six-sided dice each turn. Each turn advances by the sum of the dice, and a turn may not repeat the exact ordered dice tuple thrown on the previous turn. Report the count modulo one billion and seven.

Input starts with a test count. Each test gives two integers, the board size N and the dice count D. Output one line per test in the form `Scenario #i: answer`.

| item | bound |
|---|---|
| tests | up to 50 |
| board size N | 1 to 100 |
| dice per turn D | 1 to 3 |
| modulus | 1000000007 |
| judge limit | 4000 ms, 1536 MB |

Three dice give 216 ordered tuples, enough to keep the state small.

Sample input:

```
3
3 1
4 1
6 1
```

Sample output:

```
Scenario #1: 1
Scenario #2: 3
Scenario #3: 7
```

Four positions can be reached in three different ways with one die.

## Idea

Think of each turn as choosing a card from a fixed deck of 216 dice tuples, with the rule that you cannot draw the same card twice in a row. Keep a count for each position and last tuple. From one position, every tuple works except the last one, so the total minus the last tuple's own count gives all allowed additions. One pass per position updates every tuple. Listing whole play sequences would grow exponentially, while this pass grows with positions times tuples. Trade the sequence list for a last-tuple state.

## Why It Works

1. A turn's advance depends only on the sum of its ordered dice tuple.
2. Repeating a turn means repeating the whole tuple, not only its sum.
3. A state stores the count of walks ending at a position with a given last tuple.
4. From that state, all tuples except the last tuple are legal next turns.
5. The legal contribution equals the sum over all tuples at that position minus its own count.
6. No advance is zero, so positions are processed in increasing order without revisiting a source row.

| term | meaning |
|---|---|
| `sumTables` | advance of every ordered tuple for each dice count |
| `stepSums` | advances used by the current test |
| `ways` | counts indexed by position and last tuple |
| `totalWays` | sum of all tuple counts at one position |
| `addedWays` | legal contribution of one next tuple |
| `answerModulus` | modulus for all counts |

The aggregate update replaces a nested loop over pairs of tuples.

A trace for board size four with one die:

```
first roll 1 lands on 2, one way, last tuple 1
first roll 2 lands on 3, one way, last tuple 2
first roll 3 lands on 4, one way, last tuple 3
from position 2 last 1: roll 2 lands on 4
from position 3 last 2: roll 1 lands on 4
ways ending on 4: 1 + 1 + 1 = 3
```

The three walks are three, one plus two, and two plus one.

## Code

**Input and tuple sums.** The reader stores tests and encodes every ordered dice tuple by its sum.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const dieFaces = 6
const largestDiceCount = 3

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

The hand scanner reads every integer from one input string.
Six raised to the dice count gives the tuple total.
Base six digits decode each ordered tuple in turn.

```nim
let caseCount = nextInt(inputData, scanPos)
var boardSizes = newSeq[int](caseCount)
var diceCounts = newSeq[int](caseCount)
for caseIndex in 0 .. caseCount - 1:
  boardSizes[caseIndex] = nextInt(inputData, scanPos)
  diceCounts[caseIndex] = nextInt(inputData, scanPos)

var sumTables = newSeq[seq[int]](largestDiceCount + 1)
for diceCount in 1 .. largestDiceCount:
  var tupleTotal = 1
  for dieIndex in 1 .. diceCount:
    tupleTotal *= dieFaces
  var stepSums = newSeq[int](tupleTotal)
  for tupleIndex in 0 .. tupleTotal - 1:
    var encodedTuple = tupleIndex
    var diceSum = 0
    for dieIndex in 1 .. diceCount:
      diceSum += encodedTuple mod dieFaces + 1
      encodedTuple = encodedTuple div dieFaces
    stepSums[tupleIndex] = diceSum
  sumTables[diceCount] = stepSums
```

Each tuple gets its own index, including tuples with equal sums.
Different tuples with the same sum stay separate in the state.
Tables are shared across tests with the same dice count.

**Position sweep.** Each position contributes all tuples except its own last tuple.

```nim
for caseIndex in 0 .. caseCount - 1:
  let boardSize = boardSizes[caseIndex]
  let diceCount = diceCounts[caseIndex]
  if boardSize == 1:
    appendOutput("Scenario #" & $(caseIndex + 1) & ": 1")
    outputBuffer.add '\n'
    continue
  let stepSums = sumTables[diceCount]
  let tupleTotal = stepSums.len
  var ways = newSeq[seq[int64]](boardSize + 1)
  for position in 0 .. boardSize:
    ways[position] = newSeq[int64](tupleTotal)
  for tupleIndex in 0 .. tupleTotal - 1:
    let landing = 1 + stepSums[tupleIndex]
    if landing <= boardSize:
      ways[landing][tupleIndex] = 1
  for position in 1 .. boardSize - 1:
    var totalWays: int64 = 0
    for tupleIndex in 0 .. tupleTotal - 1:
      totalWays += ways[position][tupleIndex]
    totalWays = totalWays mod answerModulus
    for tupleIndex in 0 .. tupleTotal - 1:
      let addedWays = totalWays - ways[position][tupleIndex]
      if addedWays == 0:
        continue
      let landing = position + stepSums[tupleIndex]
      if landing <= boardSize:
        var updated = (ways[landing][tupleIndex] + addedWays) mod answerModulus
        if updated < 0:
          updated += answerModulus
        ways[landing][tupleIndex] = updated
  var answer: int64 = 0
  for tupleIndex in 0 .. tupleTotal - 1:
    answer = (answer + ways[boardSize][tupleIndex]) mod answerModulus
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first roll has no previous tuple, so every tuple starts one walk.
A negative difference is corrected after the modulus operation.
Landing beyond the board is skipped because it ends the game badly.

## Complexity

The sweep visits each position and tuple once per test.

| phase | time | space |
|---|---|---|
| input read | one pass over test pairs | two small arrays |
| tuple sums | up to 216 decodings | three sum tables |
| position sweep | positions times tuples | one row per position |
| output | one buffered write per block | one output string |

The aggregate update removes the quadratic factor in tuple pairs.

| measure | Big O |
|---|---|
| time | O(n × 6^d) per test |
| space | O(n × 6^d) per test |

Enumerating complete play sequences grows exponentially with the board size.
Store the last tuple instead of the full history and sweep positions once.
