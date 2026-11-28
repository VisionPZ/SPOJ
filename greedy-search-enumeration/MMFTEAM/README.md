# MMFTEAM — Team formation (SPOJ)

<https://www.spoj.com/problems/MMFTEAM/>

## Problem

A coach owns n players and must form one team.
A team is a subset with at least two players.
One player is captain, a different player is keeper, and roles are distinct.
Count the possible teams modulo 1 000 000 007.
Each input line holds one n, and a line containing 0 ends the input.

| Item | Bound |
|---|---|
| Players | 2 ≤ n ≤ 10⁶ |
| Modulus | 1 000 000 007 |
| Terminator | n = 0 |
| Judge limit | 4000 ms, 1536 MB |

Many input lines make per-line work the main cost.

The sample case:

```
2
3
0
```

```
2
12
```

## Idea

Choose the captain first, then the keeper, then any subset of the rest.
Think of forming a band: pick a lead singer and a drummer, then invite anyone else.
There are n choices for captain and n − 1 for keeper.
The remaining n − 2 players each join or stay out, giving 2ⁿ⁻² teams.
A table of powers of two answers each line in constant time.

## Why It Works

1. Captain and keeper are distinct players, so role order yields n(n − 1) pairs.
2. After those choices, n − 2 players remain undecided.
3. Each remaining player has two states, in or out, giving 2ⁿ⁻² subsets.
4. Multiplying the counts gives n(n − 1)2ⁿ⁻², matching the sum over team sizes.
5. Taking each factor modulo the prime keeps every product inside int64.

| Term | Meaning |
|---|---|
| `answerModulus` | the prime 1 000 000 007 |
| `maxPlayers` | largest n from the statement |
| `powersOfTwo` | precomputed values of 2ᵏ modulo the prime |
| `orderedPairs` | captain and keeper choices modulo the prime |
| `answer` | team count for one line |

The table replaces repeated exponentiation with one array lookup.

A script-traced example from `gen.py`:

```
2 2
3 12
4 48
```

Brute-force subset counts match the closed form.

## Code

**Input, constants, and hand scanner.** This block loads stdin and reads one integer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxPlayers = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

The constants fix the modulus and the largest n.
The scanner skips whitespace and builds one decimal value.
Reading once avoids repeated system calls.

**Buffered output.** This block collects finished answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Power table and answer loop.** This block precomputes powers and answers every line.

```nim
var powersOfTwo: seq[int64]
powersOfTwo.setLen(maxPlayers + 1)
powersOfTwo[0] = 1
for exponent in 1..maxPlayers:
  powersOfTwo[exponent] = powersOfTwo[exponent - 1] * 2 mod int64(answerModulus)

while true:
  let playerCount = nextInt(inputData, scanPos)
  if playerCount == 0:
    break
  if scanPos > inputData.len:
    break
  let firstFactor = int64(playerCount) mod int64(answerModulus)
  let secondFactor = int64(playerCount - 1) mod int64(answerModulus)
  let orderedPairs = firstFactor * secondFactor mod int64(answerModulus)
  let answer = orderedPairs * powersOfTwo[playerCount - 2] mod int64(answerModulus)
  appendOutput($(answer) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The precompute loop runs at most one million times.
Each input line costs four modular operations.
A zero value stops the loop before any table access.

## Complexity

The cost splits into precomputation, input lines, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Power precompute | O(10⁶) doublings | 10⁶ + 1 int64 values |
| Answer lines | O(1) per line | output buffer |
| Output | one write per 128 KiB block | block buffer |

The fixed precompute cost is small next to the time limit.

| Measure | Big O |
|---|---|
| Time | O(10⁶ + T) for T input lines |
| Space | O(10⁶) |

Summing binomials per line costs O(n), so the closed form wins.
