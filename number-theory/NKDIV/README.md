# NKDIV — N..K..Divide (SPOJ)

<https://www.spoj.com/problems/NKDIV/>

## Problem

Two players divide a number `n` by a divisor `m` on each turn, where `m` has at most `k` distinct prime factors. The player with no legal move loses, and the winner of a round starts the next round. Report each round winner, then the player who won more rounds, with ties favouring Mona.

| item | bound |
|---|---|
| rounds R | 1 to 10 |
| number n | 2 to 10^14 |
| limit k | 1 to 10 |
| judge limit | 1000 ms, 1536 MB |

Token order in each round is `n` then `k`, and a blank line separates the per-round answers from the final answer.

Sample input:

```
5
3 4
6 2
6 1
9 1
18 2
```

Sample output:

```
Mona
Mona
Alaa
Alaa
Alaa

Alaa
```

## Idea

Treat each prime exponent as a pile of stones. One move takes stones from at most `k` piles. This is like a shopper grabbing items from a few shelves at once. This is Moore's Nim, whose losing positions have every binary bit-sum divisible by `k + 1`. Factor `n` once per round, then check at most 52 bit positions. Brute-force game search over divisor chains explodes for `n` near 10^14. The takeaway is that exponent vectors turn a divisor game into a fixed-size parity test.

## Why It Works

1. Every divisor `m` of `n` subtracts exponents from at most `k` primes.
2. A move changes only those selected exponent piles, and never increases any pile.
3. Moore's Nim with at most `k` piles per move has losing states with all bit-sums divisible by `k + 1`.
4. A non-zero bit-sum gives a move back to a losing state, so the current player wins.
5. The winner of one round becomes the first player of the next round.

| term | meaning |
|---|---|
| `exponents` | prime exponents of the round's starting number |
| `modulus` | `k + 1`, the base for Moore's bit sums |
| `bitTotal` | count of exponents with a given bit set |
| `winningPosition` | true when some bit total is not divisible by `modulus` |
| `monaWins` | number of rounds Mona won |

The worked example comes from factoring two sample numbers with the generator's brute-force oracle.

| round | start | exponents | modulus | bit totals | winner |
|---|---|---|---|---|---|
| 3 | 6 | 1, 1 | 2 | bit0 = 2, divisible | Alaa |
| 4 | 9 | 2 | 2 | bit1 = 1, not divisible | Alaa |
| 5 | 18 | 1, 2 | 3 | bit0 = 1, bit1 = 1 | Alaa |

Round 3 has Alaa moving, and the position is losing, so Mona wins that round. The next round starts with Mona, but 9 is a winning position, so Alaa takes it. Round 5 also starts with Alaa and stays with Alaa.

Guards use 64-bit integers for `n` and for the squared prime test. The sieve stops at the integer square root of the largest input value.

## Code

**Input and sieve.** The reader collects all tokens, then a prime sieve covers the largest needed divisor.

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

The scanner skips blank lines and all separators.
The sieve bound comes from the largest round value.
The block buffer flushes once after all answers are appended.

```nim
let roundCount = nextInt(inputData, scanPos)
var roundValues = newSeq[int64](roundCount)
var allowedDistinctCounts = newSeq[int](roundCount)
var largestValue: int64 = 0
for roundIndex in 0 .. roundCount - 1:
  roundValues[roundIndex] = int64(nextInt(inputData, scanPos))
  allowedDistinctCounts[roundIndex] = nextInt(inputData, scanPos)
  if roundValues[roundIndex] > largestValue:
    largestValue = roundValues[roundIndex]

var divisorLimit = 1
while int64(divisorLimit) * int64(divisorLimit) <= largestValue:
  divisorLimit += 1

var compositeFlags = newSeq[bool](divisorLimit + 1)
var primeList = newSeq[int]()
var candidate = 2
while candidate <= divisorLimit:
  if not compositeFlags[candidate]:
    primeList.add candidate
    if int64(candidate) * int64(candidate) <= int64(divisorLimit):
      var multiple = candidate * candidate
      while multiple <= divisorLimit:
        compositeFlags[multiple] = true
        multiple += candidate
  candidate += 1
```

Trial division walks only the sieved primes.
Each prime contributes one exponent count to the round.

**Game decision.** The bit-sum test chooses the round winner and tracks the match winner.

```nim
var monaWins = 0
var currentPlayerIsMona = true
for roundIndex in 0 .. roundCount - 1:
  var remaining = roundValues[roundIndex]
  var exponents = newSeq[int]()
  var primeIndex = 0
  while primeIndex < primeList.len and int64(primeList[primeIndex]) * int64(primeList[primeIndex]) <= remaining:
    let primeValue = int64(primeList[primeIndex])
    if remaining mod primeValue == 0:
      var exponentCount = 0
      while remaining mod primeValue == 0:
        remaining = remaining div primeValue
        exponentCount += 1
      exponents.add exponentCount
    primeIndex += 1
  if remaining > 1:
    exponents.add 1
  let modulus = allowedDistinctCounts[roundIndex] + 1
  var winningPosition = false
  var bitPosition = 0
  while bitPosition < 52:
    var bitTotal = 0
    for exponentValue in exponents:
      bitTotal = bitTotal + ((exponentValue shr bitPosition) and 1)
    if bitTotal mod modulus != 0:
      winningPosition = true
      break
    bitPosition += 1
  var roundWinnerIsMona = false
  if winningPosition:
    roundWinnerIsMona = currentPlayerIsMona
  else:
    roundWinnerIsMona = not currentPlayerIsMona
  if roundWinnerIsMona:
    monaWins += 1
    appendOutput("Mona\n")
    currentPlayerIsMona = true
  else:
    appendOutput("Alaa\n")
    currentPlayerIsMona = false

appendOutput("\n")
if monaWins * 2 >= roundCount:
  appendOutput("Mona\n")
else:
  appendOutput("Alaa\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop lists exponents before testing any bits.
A losing position hands the round to the other player.
The final line compares Mona's wins with half the rounds.

## Complexity

Factoring and the bit scan run once per round.

| phase | time | space |
|---|---|---|
| sieve | one pass up to the square root | flags and primes |
| factor one round | one pass over relevant primes | exponent list |
| bit scan | 52 bit positions per round | constant |

| measure | Big O |
|---|---|
| time | O(R times sqrt(n) over log n) |
| space | O(sqrt(n) over log n) |

A brute-force game search enumerates every divisor chain and cannot handle 10^14. The takeaway is that prime exponents cap the search at a handful of bit columns.
