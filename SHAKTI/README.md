# SHAKTI — Shaktiman and Kilwish (SPOJ)

<https://www.spoj.com/problems/SHAKTI/>

## Problem

Two players take turns subtracting a proper divisor from a starting number. The player who cannot move loses, so decide whether the first player wins.

Input starts with the test count. Each following line holds one starting number. Print one win or loss message per number.

| item | bound |
|---|---|
| test count | below 100000 |
| starting number | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

The divisor must be smaller than the current number. Optimal play decides each answer.

Sample input:

```
2
212
424
```

Sample output:

```
Thankyou Shaktiman
Thankyou Shaktiman
```

## Idea

Think of a row of blocks: removing one block from an even row leaves an odd row, and an odd row offers only odd-sized removals. The game reduces to parity, which is decided by one `mod` per number. A full game search would explore every divisor chain, while parity settles each number in constant time.

## Why It Works

1. Every even number has divisor 1, so a player can subtract 1 and pass an odd number.
2. Every divisor of an odd number is odd, and odd minus odd is even.
3. The number 1 has no proper divisor, so the player facing it loses.
4. A player who receives an even number can always return an odd number.
5. A player who receives an odd number can only return an even number.
6. The player who receives 1 loses, so even positions win and odd positions lose.

| term | meaning |
|---|---|
| `gameNumber` | current starting number for one test |
| `winningMessage` | text printed when the number is even |
| `losingMessage` | text printed when the number is odd |

Each move flips parity, and the game ends at the odd number 1.

A worked trace from `gen.py`:

```
N = 212 -> even -> subtract 1 -> 211 -> opponent receives odd
N = 424 -> even -> subtract 1 -> 423 -> opponent receives odd
N = 3 -> odd -> divisors {1} -> move to 2 -> opponent receives even
```

Both sample numbers are even, so both lines report a win.

## Code

**Input and scanner.** The reader loads the whole input, and the hand parser walks its digits.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const winningMessage = "Thankyou Shaktiman"
const losingMessage = "Sorry Shaktiman"

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

Token scanning ignores line breaks and spacing.
The two message constants keep the output text in one place.
The parser handles up to one million without overflow.

**Buffered output.** Results accumulate in one string and flush in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One call appends a whole message.
Writing happens only after the buffer reaches the block size.
This keeps nearly 100000 lines fast.

**Parity decision.** One division decides each game and emits its message.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let gameNumber = nextInt(inputData, scanPos)
  if gameNumber mod 2 == 0:
    appendOutput(winningMessage)
  else:
    appendOutput(losingMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads exactly one number per test case.
Even numbers take the winning branch, and odd numbers take the other branch.
The final flush writes any remaining text.

## Complexity

Each test costs one parity check and one line of output.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parity check | one operation per number | constant |
| output | one line per number | block buffer |

The input string dominates memory, and each test adds only constant work.

| measure | Big O |
|---|---|
| time | O(t) |
| space | O(t) for buffered input |

A divisor search per number would cost far more than one parity check.
Parity gives the same answer with a single operation per case.
