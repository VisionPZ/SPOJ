# VPL1_AA — Spring Primality (SPOJ)

<https://www.spoj.com/problems/VPL1_AA/>

## Problem

Find the longest run of consecutive prime cards, then find the longest run that survives a penalty rule. The penalty rule gives each prime a score: one point for each prime card with that value, minus the number of times that prime divides any composite card.

Input starts with a test count. Each test gives a card count, then that many card values. Output one line per test in the form `Scenario #i: a > b`, where `a` is the plain run and `b` is the penalised run.

| item | bound |
|---|---|
| tests | 1 to 100 in the easiest group |
| cards per test | up to 100000 |
| card value | 2 to 10000000 |
| judge limit | 1000 ms, 1536 MB |

Large card values make factoring the main cost.

Sample input:

```
3
7
7 9 11 2 5 7 6
3
2 3 4
5
8 16 32 64 7
```

Sample output:

```
Scenario #1: 4 > 2
Scenario #2: 2 > 1
Scenario #3: 1 > 1
```

The first case keeps the run of five, seven and seven after penalties.

## Idea

Think of each prime as a battery that gains a charge for its own card and loses a charge every time a composite card uses it as a factor. A smallest-prime-factor sieve gives every factor in a few divisions, so one pass over the cards builds all scores and another pass measures runs. Factoring each card by trial division over all candidates would repeat work for every test. Build the sieve once, then score and scan.

## Why It Works

1. A card is prime exactly when its smallest stored factor is zero.
2. A prime card adds one to the score of its own value.
3. A composite card subtracts the multiplicity of each prime factor from that factor's score.
4. A prime card counts in the penalised run exactly when its score is positive.
5. A run ends at any card that fails the chosen condition.
6. Resetting only touched scores makes each test independent without clearing the whole table.

| term | meaning |
|---|---|
| `smallestFactor` | least prime factor of each value, or zero for primes |
| `primeBalance` | score of a prime after all penalties in the current test |
| `touchedPrimes` | primes whose scores must be cleared after a test |
| `caseBoundaries` | start and end positions of each test in the card list |
| `longestPrimeRun` | longest plain run of prime cards |
| `longestValidRun` | longest run of positively scored prime cards |

The sieve pays for itself once and serves every test.

A trace of the example cards two, five, eight, fourteen, eleven, fifteen:

```
card 2 prime score[2] = 1
card 5 prime score[5] = 1
card 8 factor 2 x3 score[2] = -2
card 14 factor 2 x1 score[2] = -3
card 14 factor 7 x1 score[7] = -1
card 11 prime score[11] = 1
card 15 factor 3 x1 score[3] = -1
card 15 factor 5 x1 score[5] = 0
plain run 2, penalised run 1
```

Only eleven keeps a positive score, so the penalised run has length one.

## Code

**Input and sieve.** The reader stores all tests, then builds one smallest-factor table.

```nim
const flushBlockBytes = 1 shl 17
const primeDigitBase = 48

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
    value = value * 10 + int(data[pos]) - primeDigitBase
    pos += 1
  return value
```

The scanner skips all whitespace, including blank lines.
Card values are kept flat with boundaries for each test.
The sieve upper bound comes from the largest card seen.

```nim
let caseCount = nextInt(inputData, scanPos)
var cardValues = newSeq[int]()
var caseBoundaries = newSeq[int]()
caseBoundaries.add 0
var largestCard = 2
for caseIndex in 0 .. caseCount - 1:
  let cardCount = nextInt(inputData, scanPos)
  for cardIndex in 0 .. cardCount - 1:
    let cardValue = nextInt(inputData, scanPos)
    cardValues.add cardValue
    if cardValue > largestCard:
      largestCard = cardValue
  caseBoundaries.add cardValues.len

var smallestFactor = newSeq[int32](largestCard + 1)
var candidatePrime = 2
while candidatePrime * candidatePrime <= largestCard:
  if smallestFactor[candidatePrime] == 0:
    var multipleValue = candidatePrime * candidatePrime
    while multipleValue <= largestCard:
      if smallestFactor[multipleValue] == 0:
        smallestFactor[multipleValue] = int32(candidatePrime)
      multipleValue += candidatePrime
  candidatePrime += 1
```

Each composite receives its least factor once.
Primes keep a zero entry, which also marks primality.
The sieve stops at the square root of the largest card.

**Scoring and runs.** One pass factors every card, and a second pass measures the penalised runs.

```nim
var primeBalance = newSeq[int32](largestCard + 1)
var touchedPrimes = newSeq[int]()
for caseIndex in 0 .. caseCount - 1:
  let lowerBound = caseBoundaries[caseIndex]
  let upperBound = caseBoundaries[caseIndex + 1]
  touchedPrimes.setLen 0
  var longestPrimeRun = 0
  var currentPrimeRun = 0
  for cardPosition in lowerBound .. upperBound - 1:
    let cardValue = cardValues[cardPosition]
    let cardIsPrime = cardValue >= 2 and smallestFactor[cardValue] == 0
    if cardIsPrime:
      currentPrimeRun += 1
      if currentPrimeRun > longestPrimeRun:
        longestPrimeRun = currentPrimeRun
    else:
      currentPrimeRun = 0
    var remainingValue = cardValue
    while remainingValue > 1:
      var factorValue = int(smallestFactor[remainingValue])
      if factorValue == 0:
        factorValue = remainingValue
      var factorCount = 0
      while remainingValue mod factorValue == 0:
        remainingValue = remainingValue div factorValue
        factorCount += 1
      if primeBalance[factorValue] == 0:
        touchedPrimes.add factorValue
      if cardIsPrime:
        primeBalance[factorValue] += 1
      else:
        primeBalance[factorValue] -= int32(factorCount)
  var longestValidRun = 0
  var currentValidRun = 0
  for cardPosition in lowerBound .. upperBound - 1:
    let cardValue = cardValues[cardPosition]
    if cardValue >= 2 and smallestFactor[cardValue] == 0 and primeBalance[cardValue] > 0:
      currentValidRun += 1
      if currentValidRun > longestValidRun:
        longestValidRun = currentValidRun
    else:
      currentValidRun = 0
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $longestPrimeRun & " > " & $longestValidRun)
  outputBuffer.add '\n'
  for primeIndex in 0 .. touchedPrimes.len - 1:
    primeBalance[touchedPrimes[primeIndex]] = 0
stdout.write outputBuffer
outputBuffer.setLen 0
```

Factor multiplicities are subtracted one by one.
The plain run is recorded during the scoring pass.
Only touched prime scores are reset for the next test.

## Complexity

The sieve runs once; each test factors its cards in a few steps each.

| phase | time | space |
|---|---|---|
| input read | one pass over all cards | flat card array |
| sieve | one pass over multiples of primes | factor table |
| scoring | one factor walk per card | score table |
| run scan | one pass per test | touched prime list |
| output | one buffered write per block | one output string |

The sieve dominates setup, while factoring dominates each test.

| measure | Big O |
|---|---|
| time | O(max value log log max value + total factors) |
| space | O(max value) |

Trial division for every card would multiply the work by thousands of candidates.
Sieve once, score with least factors, then scan runs twice per test.
