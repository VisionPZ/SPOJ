# STEVE — Voracious Steve (SPOJ)

<https://www.spoj.com/problems/STEVE/>

## Problem

Two players alternately take donuts from a box, up to m per turn. Whoever empties it keeps that pile while the other pile returns; compute the first player's best total.

Input: `t` test cases, then one line `n m` per case. Here `n` is the starting donut count and `m` is the largest take in one move. Output: one integer per case, the number of donuts Steve eats under optimal play.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Starting donuts `n` | 1 to 100 |
| Move limit `m` | 1 to `n` |
| Test cases `t` | no bound in the statement |
| Judge limit | 7000 ms, 1536 MB |

Both parameters stay below 101, so one precomputed table answers every case.

The sample input and output:

```
1
5 2 
```

```
3
```

## Idea

Solve every small game once and store the answer, like a chess player who memorizes all endgames. A state remembers the round size, the donuts still boxed, and the current player's pile.

The program fills the table with backward induction (solving small states before larger ones). A state tries at most `m` moves and keeps the one that minimizes the opponent's total. The table is filled once; each test case then costs one lookup.

Searching the game tree afresh per case revisits the same states again and again. The table pays that cost once and reuses it.

Precomputation converts a repeated game-tree search into a single array read per case.

## Why It Works

Four facts justify the recurrence.

1. A round starts with `donutCount` donuts. The two piles inside that round always add up to `donutCount`.
2. A player maximizes their own pile by minimizing the opponent's pile, since the two totals sum to a fixed number.
3. Emptying the box starts a new round with the loser's pile. That pile is smaller than `donutCount`, so induction moves to a smaller problem.
4. For a state, `roundStateValue` is `donutCount` minus the smallest opponent total over all legal takes.

The two tables and their indices:

| Term | Meaning |
| --- | --- |
| `steveEatsTable[donutCount][moveLimit]` | Steve's total from a fresh round |
| `roundStateValue[boxCount][currentSide]` | current player's total inside one round |
| `otherSide` | opponent's pile, from `donutCount - boxCount - currentSide` |
| `takeLimit` | smaller of `moveLimit` and `boxCount` |
| `largeValue` | sentinel used while minimizing opponent totals |

The sentinel keeps the minimum well defined for the first legal move.

A generator trace for `n = 5` and `m = 2`:

```
box 5, sides 0/0, Steve takes 2
box 3, sides 2/0, Digit takes 2
box 1, sides 2/2, Steve takes 1 and eats 3
box 2, sides 0/0, Digit takes 2 and eats 2
Steve 3, Digit 2
```

Steve eats 3 donuts, and Digit eats the 2 donuts she rolls over.

## Code

**Tables and constants.** Two fixed arrays hold every game answer.

```nim
{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxDonuts = 100
const largeValue = 1 shl 30

var steveEatsTable: array[0..maxDonuts, array[0..maxDonuts, int]]
var roundStateValue: array[0..maxDonuts, array[0..maxDonuts, int]]
```

`maxDonuts = 100` matches the largest input.
Each table has 101 by 101 entries.
No case allocates memory during the run.

**Backward induction.** The nested loops fill values from smaller rounds upward.

```nim
proc computeGameValues() =
  for moveLimit in 1..maxDonuts:
    for donutCount in 1..maxDonuts:
      for boxCount in 0..donutCount:
        for currentSide in 0..donutCount:
          roundStateValue[boxCount][currentSide] = 0
      for boxCount in 1..donutCount:
        for currentSide in 0..(donutCount - boxCount):
          let otherSide = donutCount - boxCount - currentSide
          var fewestOpponentDonuts = largeValue
          var takeLimit = moveLimit
          if takeLimit > boxCount:
            takeLimit = boxCount
          for donutsTaken in 1..takeLimit:
            var opponentDonuts: int
            if donutsTaken == boxCount:
              opponentDonuts = steveEatsTable[otherSide][moveLimit]
            else:
              opponentDonuts = roundStateValue[boxCount - donutsTaken][otherSide]
            if opponentDonuts < fewestOpponentDonuts:
              fewestOpponentDonuts = opponentDonuts
          roundStateValue[boxCount][currentSide] = donutCount - fewestOpponentDonuts
      steveEatsTable[donutCount][moveLimit] = roundStateValue[donutCount][0]

computeGameValues()
```

The reset loop clears `roundStateValue` before each round size.
`otherSide` gives the opponent's pile inside the round.

A take that empties the box reads `steveEatsTable` for the smaller rollover round. The final assignment stores the round's starting value.

**Input and parsing.** The program reads all input and scans it by digit.

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips non-digits, so the trailing space in the sample line is harmless.
`appendOutput` flushes at 256 KiB.
Parsing one integer visits each digit once.

**Driver.** Each case reads two numbers and prints one lookup.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let donutCount = nextInt(inputData, scanPos)
  let moveLimit = nextInt(inputData, scanPos)
  appendOutput($(steveEatsTable[donutCount][moveLimit]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`donutCount` and `moveLimit` index the precomputed table directly.
The loop runs once per test case.
The final write covers the output tail.

## Complexity

The program pays for the table once, then answers cases with constant work.

| Phase | Time | Space |
| --- | --- | --- |
| Table fill | O(M × N⁴) worst case | O(M × N²) for two arrays |
| Input read | one pass over input bytes | input bytes |
| One query | O(1) lookup | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total | O(M × N⁴ + t) | O(M × N²) plus buffers |

With `M = N = 100` the fill dominates, and no test case adds meaningful work.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(M × N⁴ + t), with M, N ≤ 100 |
| Space | O(M × N²), plus input and output buffers |

A fresh game-tree search per case revisits the same states and costs far more under repeated queries.
