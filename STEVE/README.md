## Problem

Steve and Digit take turns taking 1 to m donuts from a box holding n donuts. Whoever empties the box eats every donut on their side. The other player returns their donuts to the box and starts the next round. Play ends when every donut has been eaten. Print the number of donuts Steve eats when both players play optimally.

The bounds are small:

| Quantity | Bound |
| --- | --- |
| Starting donuts n | 1..100 |
| Move limit m | 1..100 |
| Test cases t | no bound in the statement |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

Both bounds stop at 100, so one table answers every query.

## Idea

Solve the whole game once with backward induction and store each answer in a table. A state keeps the round's starting count fixed and records the box and the current player's side. The program tries at most m moves per state and answers each case with one lookup.

Cost per test case: one table lookup.

## Why It Works

Every donut is eaten eventually, so the two players' totals add up to the donut count at the start of a round. A player therefore maximizes their own total by minimizing the other player's total.

When a player empties the box, the loser returns their side to the box. That returned pile is smaller than the round's starting count, so the induction moves to a smaller problem.

Inside one round the starting count never changes. The state stores `boxCount` and `currentSide`, and subtraction gives the other player's pile.

For one state:

- `otherSide = donutCount - boxCount - currentSide` gives the other player's pile.
- `takeLimit = min(moveLimit, boxCount)` bounds the legal moves.
- If `donutsTaken == boxCount`, the other player starts the next round and eats `steveEatsTable[otherSide][moveLimit]`.
- Otherwise the other player eats `roundStateValue[boxCount - donutsTaken][otherSide]` inside this round.
- `roundStateValue[boxCount][currentSide]` is `donutCount` minus the smallest opponent total over all moves.

The generator prints this optimal play for n = 5 and m = 2:

```
box 5, sides 0/0, Steve takes 2
box 3, sides 2/0, Digit takes 2
box 1, sides 2/2, Steve takes 1 and eats 3
box 2, sides 0/0, Digit takes 2 and eats 2
Steve 3, Digit 2
```

Steve eats 3 donuts, and Digit eats the 2 donuts she rolls over.

## Code

```nim
{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxDonuts = 100
const largeValue = 1 shl 30

var steveEatsTable: array[0..maxDonuts, array[0..maxDonuts, int]]
var roundStateValue: array[0..maxDonuts, array[0..maxDonuts, int]]

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
```

The outer loops cover 100 move limits and 100 donut counts.
The box loop runs from small to large, so each continuation is already known.
`takeLimit` keeps a move inside the box.
Each state scans at most `moveLimit` moves.

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
```

The loop reads every line into one buffer.
The scanner skips non-digits and builds a value one digit at a time.
Parsing costs one pass over the buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let donutCount = nextInt(inputData, scanPos)
  let moveLimit = nextInt(inputData, scanPos)
  appendOutput($(steveEatsTable[donutCount][moveLimit]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per test case.
`appendOutput` flushes after 256 KiB, so a large case count stays cheap in memory.
The last write flushes the remainder.
Each case costs one table lookup and one string append.

## Complexity

Table build: O(N^5) time for N = maxDonuts = 100. The build visits N move limits, N donut counts, O(N²) states for each count, and up to N moves per state. Space is O(N²) for the two square tables. Each test case takes O(1) time. A fresh game-tree search per query would visit exponentially many states.
