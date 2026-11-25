# VECTAR10 — Card Game (SPOJ)

<https://www.spoj.com/problems/VECTAR10/>

## Problem

A deck holds cards 1 to n from top to bottom. In each move the top card is discarded and the next top card moves to the bottom. Report the last remaining card.

Each line except the last holds one positive n up to 1000000. The last line holds 0 and produces no output. Print one answer line per input number.

The bounds from the statement:

| item | bound |
|---|---|
| card count n | 1 to 1000000 |
| input lines | at most 500000 |
| judge limit | 100 ms, 1536 MB |

Large output volume drives the design, not the size of any single deck.

Sample input:

```
2
3
4
0
```

Sample output:

```
2
2
4
```

## Idea

The deck sheds every other card each pass, like players counting off in a circle. One closed form replaces the whole simulation.

The survivors of the first pass are the even cards in order. After that pass the same game runs on half as many cards, so the answer doubles with each halving. Let the largest power of two at most n be `highestPower`. Write n as `highestPower` plus `remainder`; the answer is twice the remainder, or `highestPower` when the remainder is zero. Each query costs one logarithm-time loop. Simulating n cards costs n steps per query, which is far slower. The formula makes 500000 queries cheap.

## Why It Works

1. One full pass removes cards at odd positions and keeps even positions in order.
2. The kept cards are 2, 4, 6, and so on, which form the same game on n/2 cards.
3. The invariant repeats until the number of cards is a power of two.
4. At a power of two the last card is that power; otherwise the leftover cards restart the count and give twice the remainder.

The main terms:

| term | meaning |
|---|---|
| `cardCount` | number of cards n in the current query |
| `highestPower` | largest power of two not exceeding n |
| `remainder` | n minus `highestPower` |
| `lastCard` | answer for the current query |

The terms give a direct answer without moving a single real card.

A worked trace for n = 10, produced by the oracle simulation:

```
start      [1,2,3,4,5,6,7,8,9,10]
drop 1, move 2   [3,4,5,6,7,8,9,10,2]
drop 3, move 4   [5,6,7,8,9,10,2,4]
drop 5, move 6   [7,8,9,10,2,4,6]
drop 7, move 8   [9,10,2,4,6,8]
drop 9, move 10  [2,4,6,8,10]
drop 2, move 4   [6,8,10,4]
drop 6, move 8   [10,4,8]
drop 10, move 4  [8,4]
drop 8            [4]
```

The trace ends at card 4. The formula agrees: 10 minus 8 is 2, and twice 2 is 4.

## Code

**Input and scanning.** One read loads all lines, and the hand parser walks numbers.

```nim
const flushBlockBytes = 1 shl 17

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

The loop appends one newline per input line.
Digits are read one at a time into an int value.
The sentinel 0 needs no minus branch here.

**Output buffer.** Text is collected and written in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush threshold is 131072 bytes.
One `stdout.write` handles roughly a thousand answers.
The buffer is cleared after each flush.

**Main loop.** Each query gets its answer from the power-of-two formula.

```nim
while true:
  let cardCount = nextInt(inputData, scanPos)
  if cardCount == 0:
    break
  var highestPower = 1
  while highestPower * 2 <= cardCount:
    highestPower = highestPower * 2
  let remainder = cardCount - highestPower
  var lastCard = highestPower
  if remainder > 0:
    lastCard = 2 * remainder
  appendOutput($lastCard)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops at the sentinel 0.
Doubling stops once the next power exceeds n.
A final flush emits any remaining text.

## Complexity

Each query scans only its own number and a short chain of doublings.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| answer loop | one loop over powers of two | constant |
| output | one write per block | block buffer |

The input string dominates memory; answers use no table.

The asymptotic bounds:

| measure | Big O |
|---|---|
| time per query | O(log n) |
| total time | O(total input bytes) |
| space | O(input bytes) |

A deck simulation spends O(n) steps per query, while the formula spends O(log n). The closed form keeps even a huge batch of queries fast.
