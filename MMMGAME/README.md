# MMMGAME — M&M Game (SPOJ)

<https://www.spoj.com/problems/MMMGAME/>

## Problem

Two players take candies from color piles, and the player who takes the last candy loses. Decide whether the first player wins under optimal play.

The input starts with the test count. Each test gives the pile count N and then N pile sizes. Print `John` when the first player wins and `Brother` otherwise.

| item | bound |
|---|---|
| tests T | 1 to 474 |
| piles N | 1 to 47 |
| candies per pile A_i | 1 to 4747 |
| judge limit | 1000 ms, 1536 MB |

Each move removes at least one candy from one pile. A player who removes the final candy from the box loses the game.

Sample input:

```
2
3
3 5 1
1
1
```

Sample output:

```
John
Brother
```

## Idea

Leaving the last candy is like leaving the last move in a board game: you want your opponent holding it.

This is misère Nim. When any pile holds more than one candy, the winning rule matches normal Nim: a nonzero pile XOR wins.

When every pile holds exactly one candy, the move count is fixed. An even number of piles wins for the first player.

Both tests cost one pass over the piles. Searching all move sequences is exponential.

Compute the XOR and note whether every pile is a single candy, then apply one rule.

## Why It Works

1. Each color acts as one Nim pile with A_i candies.
2. Removing the final candy loses, which defines misère play.
3. With a pile above one, a player can steer to a normal Nim end state.
4. There the XOR of pile sizes decides the winner: nonzero wins.
5. With all piles equal to one, exactly N moves happen, so even N wins.

| term | meaning |
|---|---|
| `pileCount` | number of colors in the box |
| `candyCount` | candies in one color pile |
| `nimSum` | bitwise XOR of all pile sizes |
| `allPilesSingle` | true when every pile holds one candy |
| `caseCount` | number of tests in the input |

The terms above name the values that the driver reads and tests.

In the first sample, 3 xor 5 xor 1 is 7, which is nonzero, so John wins. In the second sample there is one single-candy pile, the count is odd, and Brother wins.

The two rules cover every state because either a pile exceeds one or none does. XOR stays small because pile sizes fit in ordinary integers.

## Code

**Input and scanning.** The reader loads every test and both decision values.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All input values are positive, so the scanner needs no minus branch.
The scanner skips spaces and line breaks.
The buffer flushes in large blocks.

**Decision and output.** XOR and the single-pile flag select the winner.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pileCount = nextInt(inputData, scanPos)
  var nimSum = 0
  var allPilesSingle = true
  for pileIndex in 0 .. pileCount - 1:
    let candyCount = nextInt(inputData, scanPos)
    nimSum = nimSum xor candyCount
    if candyCount > 1:
      allPilesSingle = false
  if allPilesSingle:
    if pileCount mod 2 == 0:
      appendOutput("John\n")
    else:
      appendOutput("Brother\n")
  else:
    if nimSum != 0:
      appendOutput("John\n")
    else:
      appendOutput("Brother\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Any pile above one switches the test to XOR.
All single piles use the parity of the pile count.
One buffered write emits every answer.

## Complexity

The scan touches each pile once per test.

| phase | time | space |
|---|---|---|
| input read | one pass over all piles | one input string |
| winner test | one XOR and one flag per pile | two scalar values |
| output | one line per test | block buffer |

The table shows that no game tree is stored.

| measure | Big O |
|---|---|
| time per test | O(N) |
| space per test | O(1) |

At N = 47 the scan performs a few dozen operations.
Enumerating move sequences would grow with the total number of candies.
The XOR rule settles the game with one short loop.
