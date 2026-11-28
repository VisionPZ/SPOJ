# TAMADOM — PKP Knows Nothing 2 (SPOJ)

<https://www.spoj.com/problems/TAMADOM/>

## Problem

PKP owns `N` distinct knives and must count the ways to choose `R` of them. Print that count modulo `M`, one line per case.

The first input line holds the case count `T`. Each next line holds `N`, `R`, and `M`. A choice with `R > N` has zero ways.

| Item | Bound |
|---|---|
| Test count `T` | 1 to 100 |
| Knife count `N` | 1 to 100000 |
| Chosen count `R` | 0 to 100000 |
| Modulus `M` | 1 to 1000000000000 |
| Judge limit | 1 s |
| Memory limit | 1536 MB |

`M` need not be prime, so modular inverse tricks do not apply.

The sample as printed in the statement:

```
5
5 3 100
5 3 2
5 3 7
1 1 20
100 50 1000000009
```

```
10
0
3
1
933591892
```

## Idea

Treat the binomial as a crate built from prime bricks. Count each brick type first, then glue the stacks modulo `M`.

Legendre's formula counts prime powers in a factorial by repeated floor division. Subtracting the counts for `R` and `N - R` gives the exponent inside `C(N, R)`. Multiply each prime power modulo `M`.

A product of two residues below 10^12 can reach 10^24. Splitting each residue into 20-bit halves keeps every intermediate below 2^61. A Pascal triangle would need O(NR) big-integer work per case.

## Why It Works

1. Legendre's formula sums `floor(n / p^k)` over all powers `p^k <= n`.
2. `C(n, k)` equals `n! / (k! (n-k)!)`, so subtracting exponents gives each prime's power.
3. Multiplying those prime powers reconstructs the exact binomial before reduction.
4. Halves of 20 bits make the cross products fit in signed 64-bit integers.
5. Replacing `R` with `min(R, N-R)` halves the exponent work with no value change.

| Term | Meaning |
|---|---|
| `primeList` | primes up to 100000, built once |
| `exponent` | power of one prime inside the current binomial |
| `multiplyModulo` | product of two residues without 64-bit overflow |
| `powerModulo` | binary exponentiation under the modulus |
| `reducedChoice` | smaller of `R` and `N - R` |

`gen.py` prints this trace while building the files:

```
trace: C(5,3)=10; 10 mod 100 -> 10
```

The trace matches the first sample answer.

## Code

**Scanners and constants.** Reads small values as `int` and the modulus as `int64`.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxPrimeLimit = 100000
const splitShift = 20
const splitBase = 1 shl splitShift
const splitMask = splitBase - 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```

`maxPrimeLimit` matches the largest `N`. `splitBase` is 2^20, the radix for modular products. `nextInt64` holds moduli up to 10^12.

**Prime sieve.** Builds the ordered prime list once before any case runs.

```nim
var compositeFlags = newSeq[bool](maxPrimeLimit + 1)
var primeList: seq[int] = @[]
for candidate in 2..maxPrimeLimit:
  if not compositeFlags[candidate]:
    primeList.add candidate
    if int64(candidate) * int64(candidate) <= int64(maxPrimeLimit):
      var multiple = candidate * candidate
      while multiple <= maxPrimeLimit:
        compositeFlags[multiple] = true
        multiple += candidate
```

Each composite is marked from its smallest prime. Marking starts at `p^2`, so each pass begins at a fresh square. The list contains 9592 primes.

**Modular arithmetic.** Multiplies and exponentiates residues without overflow.

```nim
proc multiplyModulo(leftValue, rightValue, modulus: int64): int64 =
  let leftLow = leftValue and int64(splitMask)
  let leftHigh = leftValue shr splitShift
  let rightLow = rightValue and int64(splitMask)
  let rightHigh = rightValue shr splitShift
  let lowProduct = leftLow * rightLow
  let midProduct = leftLow * rightHigh + leftHigh * rightLow
  let highProduct = leftHigh * rightHigh
  var reducedValue = highProduct mod modulus
  reducedValue = (reducedValue * int64(splitBase) + midProduct) mod modulus
  reducedValue = (reducedValue * int64(splitBase) + lowProduct) mod modulus
  return reducedValue

proc powerModulo(baseValue, exponentValue, modulus: int64): int64 =
  var accumulated: int64 = 1 mod modulus
  var baseReduced = baseValue mod modulus
  var exponent = exponentValue
  while exponent > 0:
    if (exponent and 1) == 1:
      accumulated = multiplyModulo(accumulated, baseReduced, modulus)
    baseReduced = multiplyModulo(baseReduced, baseReduced, modulus)
    exponent = exponent shr 1
  return accumulated
```

`midProduct` stays below 2^41. Each Horner step multiplies by 2^20 and stays below 2^61. Binary exponentiation uses at most 17 squaring rounds.

**Binomial from exponents.** Applies Legendre's formula for each prime.

```nim
proc binomialModulo(nValue, kValue: int, modulus: int64): int64 =
  if modulus == 1:
    return 0
  if kValue < 0 or kValue > nValue:
    return 0
  if kValue == 0:
    return 1 mod modulus
  let complement = nValue - kValue
  var answerValue: int64 = 1
  for prime in primeList:
    if prime > nValue:
      break
    var primePower: int64 = int64(prime)
    var exponent: int64 = 0
    while primePower <= int64(nValue):
      exponent += int64(nValue) div primePower - int64(kValue) div primePower -
                  int64(complement) div primePower
      primePower *= int64(prime)
    if exponent > 0:
      let primeFactor = powerModulo(int64(prime), exponent, modulus)
      answerValue = multiplyModulo(answerValue, primeFactor, modulus)
  return answerValue
```

`primePower` is `int64`, so squaring a prime near 100000 stays safe. Zero exponents skip exponentiation. The loop stops at the first prime above `N`.

**Driver.** Reads all cases and writes one answer per line.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for _ in 0..<caseCount:
  let totalKnives = nextInt(inputData, scanPos)
  let chosenKnives = nextInt(inputData, scanPos)
  let modulus = nextInt64(inputData, scanPos)
  let reducedChoice = min(chosenKnives, totalKnives - chosenKnives)
  let answer = binomialModulo(totalKnives, reducedChoice, modulus)
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The input loop restores each newline. `reducedChoice` caps the exponent loop at `N / 2`. The final flush emits all 100 lines.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Prime sieve | O(N log log N), once | O(N) flags and primes |
| Exponents per case | O(pi(N) log N) | none |
| Modular powers | O(pi(N) log N) | none |
| Output | one final write | one buffer |

`N` is 100000 and `T` is at most 100.

| Measure | Big O |
|---|---|
| Time | O(N log log N + T pi(N) log N) |
| Space | O(N) |

A Pascal triangle would use O(NR) big-integer work per case. Prime exponents replace that with one bounded pass over the primes.
