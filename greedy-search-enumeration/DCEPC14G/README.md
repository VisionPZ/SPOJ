# DCEPC14G — God of Nim (SPOJ)

<https://www.spoj.com/problems/DCEPC14G/>

## Problem

Two players remove coins from piles in turn. From pile i a player takes between 1 and K_i coins; the player with no move loses. Decide whether the second player wins when the first player opens.

Input starts with a test count T. Each test gives a pile count N, a line of N pile sizes P_i, and a line of N limits K_i. Print `Mishra` when the second player wins and `Amit` when the first player wins.

| item | bound |
|---|---|
| tests T | 1 to 10 |
| piles N | 1 to 10000 |
| coins P_i | 0 to 1000000000 |
| limit K_i | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

A move removes coins from one pile only. An empty pile offers no move.

Sample input:

```
2
1
5
2
2
4 7
1 3
```

Sample output:

```
Amit
Amit
```

## Idea

A pile behaves like a clock that wraps every K+1 coins, so its Grundy value equals its size modulo K+1, like counting hours on a dial.

The algorithm combines the pile values with bitwise xor. A nonzero xor means the first player has a winning move, and zero means the second player wins. Computing each value takes O(1), so a test costs O(N). Enumerating reachable pile states would need P_i steps per pile and cannot handle billion-coin piles.

## Why It Works

1. From p coins the reachable sizes are p−1 down to p−K, or to 0.
2. The Grundy value is the smallest value missing from those reachable values.
3. That mex repeats every K+1 coins, so the value equals p mod (K+1).
4. Independent piles combine by xor, as in ordinary Nim.
5. Zero xor means every move leaves a nonzero xor, so the mover loses.

| term | meaning |
|---|---|
| `coinCounts` | sizes P_i stored for one test |
| `maxRemoval` | the limit K_i for one pile |
| `nimSum` | xor of all pile Grundy values |
| `Amit` | printed when `nimSum` is nonzero |
| `Mishra` | printed when `nimSum` is zero |

The worked example uses the second sample test, with piles 4 and 7 and limits 1 and 3.

| pile | coins | limit | coins mod (limit + 1) |
|---|---|---|---|
| first | 4 | 1 | 0 |
| second | 7 | 3 | 3 |

The xor is 0 xor 3 = 3, so the first player wins and the answer is `Amit`.

A pile with zero coins has Grundy value zero and adds nothing to the xor. The modulo keeps intermediate sizes small even for billion-coin piles.

## Code

**Input and helpers.** The reader loads stdin once, scans integers by hand, and buffers output in blocks.

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

Two input lines hold the piles and their limits, so pile sizes are stored first.
The scanner ignores line breaks and spacing.
Output names are appended once per test.

**Xor scan.** Each pile contributes its wrapped Grundy value.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pileCount = nextInt(inputData, scanPos)
  var coinCounts = newSeq[int64](pileCount)
  for pileIndex in 0 .. pileCount - 1:
    coinCounts[pileIndex] = int64(nextInt(inputData, scanPos))
  var nimSum: int64 = 0
  for pileIndex in 0 .. pileCount - 1:
    let maxRemoval = int64(nextInt(inputData, scanPos))
    nimSum = nimSum xor (coinCounts[pileIndex] mod (maxRemoval + 1))
  if nimSum != 0:
    appendOutput("Amit")
  else:
    appendOutput("Mishra")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The modulo gives the mex from fact 3.
The xor of all piles decides the winner.
The buffer flushes once after the loop.

## Complexity

Each test stores the piles once and scans the limits once.

| phase | time | space |
|---|---|---|
| input read | one pass over 2N numbers | one input string |
| grundy xor | one operation per pile | array of N sizes |
| output | one name per test | block buffer |

| measure | Big O |
|---|---|
| time per test | O(N) |
| space per test | O(N) |

Exploring the game tree would need O(P_i) states per pile and fail for large piles.
The closed form turns each pile into one modulo and one xor.

The xor rule depends on piles being independent; a shared move limit would break this decomposition.
