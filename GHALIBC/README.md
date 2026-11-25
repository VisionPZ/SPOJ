# GHALIBC — Ghalib's Challenge (SPOJ)

<https://www.spoj.com/problems/GHALIBC/>

## Problem

For each query, sum the Catalan counts of all bag sizes from 1 to p^a-1 that leave residue r modulo p-1, then report the sum modulo p squared. A bag of size i admits Catalan(i) arrangements when no three marbles form an increasing length subsequence.

The first line holds the test count. Each following line holds three integers: residue r, prime p, and exponent a. Print one answer per line.

| item | bound |
|---|---|
| test count | 1 to 10 |
| prime p | 5 to 1000 |
| exponent a | 1 to 100000000 |
| residue r | (p+1)/2 to p-1 |
| judge limit | 1000 ms, 1536 MB |

The exponent drives the design because p^a can be enormous.

Sample input:

```
2
5 7 2
5 7 1
```

Sample output:

```
42
42
```

Both queries return 42.

## Idea

The sum stops depending on the exponent after one parity check, like a light bulb toggled once and then left on the same circuit. Sun and Tauraso's congruence gives the closed forms: odd exponents keep Catalan(r), even exponents use 4^r times (2 minus 2^p), all modulo p squared. Modular exponentiation handles the powers, and p-adic factorials handle Catalan(r) when r approaches p. The naive sum would iterate up to p^a bags, which is impossible for large a. Two formulas replace that walk with a handful of modular operations.

## Why It Works

1. Arrangements without an increasing triple of lengths are 123-avoiding permutations, counted by Catalan(r).
2. Sun and Tauraso proved the residue-class sum equals Catalan(r) modulo p^2 for odd a.
3. For even a and r at least (p+1)/2, the same sum equals 4^r(2-2^p) modulo p^2.
4. Catalan(r) = binomial(2r, r) divided by (r+1), with p factors stripped before inversion.
5. Euler's theorem inverts units modulo p^2 because each stripped unit stays coprime to p.

| term | meaning |
|---|---|
| `residue` | the required residue r |
| `primeValue` | the prime p |
| `exponentValue` | the exponent a |
| `factorialUnit` | factorial with p factors removed, kept modulo p^2 |
| `netExponent` | remaining power of p in the Catalan quotient |

The table names the only inputs and the one nontrivial helper.

A script trace for r=5, p=7 follows:

```
p^2 = 49
odd branch: Catalan(5) = 42, so answer = 42
even branch: 4^5 mod 49 = 44
2^7 mod 49 = 30, 2 - 30 = -28 = 21 mod 49
44 * 21 mod 49 = 42
```

The trace reproduces both sample answers.

The unit inversion needs Euler's exponent p(p-1)-1, and a negative residue is shifted by one modulus.

## Code

**Input and buffered output.** The reader loads all tokens and flushes results in blocks.

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

Each case uses three tokens.
The buffer flushes after 131072 bytes.
No output is written per answer.

**Odd exponent formula.** The Catalan quotient is rebuilt from p-free factorials.

```nim
proc powerMod(baseValue, exponentValue, modulusValue: int64): int64 =
  var powerResult = 1.int64
  var currentBase = baseValue mod modulusValue
  var currentExponent = exponentValue
  while currentExponent > 0:
    if (currentExponent and 1) == 1:
      powerResult = powerResult * currentBase mod modulusValue
    currentBase = currentBase * currentBase mod modulusValue
    currentExponent = currentExponent div 2
  return powerResult

proc stripPrime(value, primeValue: int): tuple[exponentCount: int, unitPart: int64] =
  var remaining = value
  var exponentCount = 0
  while remaining mod primeValue == 0:
    remaining = remaining div primeValue
    exponentCount += 1
  return (exponentCount, int64(remaining))

proc factorialUnit(limitValue, primeValue: int, modulusValue: int64): tuple[exponentCount: int, unitPart: int64] =
  var exponentCount = 0
  var unitPart = 1.int64
  for numberValue in 1 .. limitValue:
    var reduced = numberValue
    while reduced mod primeValue == 0:
      reduced = reduced div primeValue
      exponentCount += 1
    unitPart = unitPart * int64(reduced) mod modulusValue
  return (exponentCount, unitPart)

proc catalanModulo(residue, primeValue: int, modulusValue: int64): int64 =
  let doubled = factorialUnit(2 * residue, primeValue, modulusValue)
  let single = factorialUnit(residue, primeValue, modulusValue)
  let divisor = stripPrime(residue + 1, primeValue)
  let eulerExponent = int64(primeValue * (primeValue - 1) - 1)
  let denominatorUnit = powerMod(int64(divisor.unitPart), eulerExponent, modulusValue)
  let squaredUnit = single.unitPart * single.unitPart mod modulusValue
  let denominatorSquare = powerMod(squaredUnit, eulerExponent, modulusValue)
  let netExponent = doubled.exponentCount - 2 * single.exponentCount - divisor.exponentCount
  var answer = powerMod(int64(primeValue), netExponent, modulusValue)
  answer = answer * doubled.unitPart mod modulusValue
  answer = answer * denominatorSquare mod modulusValue
  answer = answer * denominatorUnit mod modulusValue
  return answer
```

Factorials stop at 2r, below 2000.
Stripped factors keep their exponent separately.
Slow modular inverse would fail on p multiples.

**Case dispatch.** Parity selects the formula for each query.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let residue = nextInt(inputData, scanPos)
  let primeValue = nextInt(inputData, scanPos)
  let exponentValue = nextInt(inputData, scanPos)
  let modulusValue = int64(primeValue) * int64(primeValue)
  var answer: int64
  if (exponentValue and 1) == 1:
    answer = catalanModulo(residue, primeValue, modulusValue)
  else:
    let eulerExponent = int64(primeValue * (primeValue - 1) - 1)
    let fourPower = powerMod(4, int64(residue), modulusValue)
    let twoPower = powerMod(2, int64(primeValue), modulusValue)
    var difference = 2 - twoPower
    difference = difference mod modulusValue
    if difference < 0:
      difference += modulusValue
    answer = fourPower * difference mod modulusValue
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Two powerMod calls cover the even branch.
The branch depends on one bit of a.
The final flush emits the buffer once.

## Complexity

Each query runs a short fixed-size calculation.

| phase | time | space |
|---|---|---|
| input read | one pass over the token string | one input string |
| odd branch | factorials up to 2r | three small tuples |
| even branch | two modular powers | constant extra |
| output | one buffered write | block buffer |

The phase table shows bounded work per case.

| measure | Big O |
|---|---|
| time | O(p + log p) per odd case, O(log p) per even case |
| space | O(p) transient for odd cases |

Summing r Catalan values per query would take O(p^a) time. The congruences remove that factor entirely.
