# BYTESM1 — Mystical River (SPOJ)

<https://www.spoj.com/problems/BYTESM1/>

## Problem

Find where the stone-number sequence of a remembered number first meets one of three stone rivers, and print which river it meets. A stone river starts at 1, 3, or 9, and each next stone adds the digit sum of the current stone.

The input starts with the test count `T`, then one remembered number per line. Output the river start and the meeting stone, separated by a space, for each test.

| item | bound |
|---|---|
| test cases T | 1 to 50 |
| remembered number N | 1 to 99999999 |
| judge limit | 1399 ms, 1536 MB |

When several rivers meet the remembered sequence, report the meeting stone with the smallest value.

Sample input:

```
2
29
42
```

Sample output:

```
1 107
3 111
```

## Idea

Use the digit-sum rule to sort numbers into lanes, like trains that can only meet on the same track. The residue of a stone modulo 9 never leaves its lane, so each remembered number can meet only one river.

The algorithm precomputes the three river tracks as bit sets, then walks the remembered sequence until it lands on the matching bit. A bit lookup costs constant time. Simulating all three rivers for every test would repeat millions of steps.

The lane rule plus one bit set per lane answers every test quickly.

## Why It Works

1. The digit sum of a number has the same remainder modulo 9 as the number itself.
2. The next stone is the current stone plus its digit sum, so the next remainder is twice the current remainder modulo 9.
3. Remainders 1, 2, 4, 8, 7, 5 cycle among themselves and belong to the river starting at 1.
4. Remainders 3 and 6 cycle among themselves and belong to the river starting at 3.
5. Remainder 0 stays at 0 and belongs to the river starting at 9.
6. Each river sequence is strictly increasing, so the first shared stone is the first meeting point.

| term | meaning |
|---|---|
| `trunkLimit` | largest stone value stored in the bit sets |
| `riverBits` | one bit set per river, marking its stones |
| `stoneValue` | current stone on the remembered sequence |
| `riverIndexFor` | maps a remainder modulo 9 to a river |

For the sample value 29, the sequence is 29, 40, 44, 52, 59, 73, 83, 94, 107. The river from 1 reaches 107, so the answer is `1 107`.

The bit for the meeting stone is set in exactly one river's bit set.

## Code

**Digit sum and river bits.** The precompute marks each river stone in a packed bit set.

```nim
const flushBlockBytes = 1 shl 17
const trunkLimit = 100002000
const riverSeeds: array[3, int] = [1, 3, 9]
const residueBits = 3

proc digitSum(value: int): int =
  var remaining = value
  var total = 0
  while remaining > 0:
    total += remaining mod 10
    remaining = remaining div 10
  return total

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var riverBits: array[3, seq[byte]]
for riverIndex in 0 .. 2:
  riverBits[riverIndex] = newSeq[byte]((trunkLimit shr residueBits) + 1)
  var stoneValue = riverSeeds[riverIndex]
  while stoneValue <= trunkLimit:
    let byteIndex = stoneValue shr residueBits
    riverBits[riverIndex][byteIndex] = riverBits[riverIndex][byteIndex] or byte(1 shl (stoneValue and 7))
    stoneValue += digitSum(stoneValue)
```

A byte holds eight stone marks.
The three rivers are generated once at startup.
The limit covers every meeting stone allowed by the input bound.

**Lane choice and meeting search.** The solver picks one river and walks until its bit is set.

```nim
proc isOnRiver(riverIndex: int, stoneValue: int): bool =
  let byteIndex = stoneValue shr residueBits
  if byteIndex >= riverBits[riverIndex].len:
    return false
  return (riverBits[riverIndex][byteIndex] and byte(1 shl (stoneValue and 7))) != 0

proc riverIndexFor(value: int): int =
  let remainder = value mod 9
  if remainder == 1 or remainder == 2 or remainder == 4 or remainder == 5 or remainder == 7 or remainder == 8:
    return 0
  if remainder == 3 or remainder == 6:
    return 1
  return 2

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rememberedNumber = nextInt(inputData, scanPos)
  let chosenRiver = riverIndexFor(rememberedNumber)
  var stoneValue = rememberedNumber
  while not isOnRiver(chosenRiver, stoneValue):
    stoneValue += digitSum(stoneValue)
  appendOutput($riverSeeds[chosenRiver])
  outputBuffer.add ' '
  appendOutput($stoneValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The remainder chooses the only possible river.
Each step adds one digit sum and one bit test.
All answers are written in one buffered pass.

## Complexity

The precompute touches every stone of all three rivers up to the fixed limit.

| phase | time | space |
|---|---|---|
| bit-set precompute | one step per stored stone | three packed bit sets |
| input read | one pass over T numbers | one input string |
| meeting search | one digit sum per step until the bit is set | constant |
| output | one buffered write | block buffer |

The fixed precompute cost is paid once for all tests.

| measure | Big O |
|---|---|
| time | O(L + K) where L is the precompute length and K is total search steps |
| space | O(L/8) |

Rebuilding a river for every test would repeat the long precompute many times. One shared bit set per river keeps each test short.
