# ADADIG — Ada and Digits (SPOJ)

<https://www.spoj.com/problems/ADADIG/>

## Problem

Count the positive integers whose digit sum equals their digit product, for a given common value N. A zero digit would force the product to zero, so every digit of a counted number is 1 through 9. Report the count modulo 1e9+7.

Input starts with T test cases, then one N per line. Output one line per case with the count modulo 1e9+7.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| required value N | 1 to 300000 |
| modulus | 1000000007 |
| judge limit | 500 ms, 1536 MB |

The value bound drives the design: N reaches 3e5, so no enumeration of integers is possible.

Verbatim sample input:

```
8
1
2
3
7
8
12
16
144
```

Verbatim sample output:

```
1
1
1
1
23
240
1091
243368058
```

## Idea

Factor N into digits greater than one, then fill the remaining sum with ones, like choosing toppings and then adding plain crackers to reach a fixed total weight. Each multiset of digits has a product and a sum; ones add to the sum without changing the product. Count the distinct arrangements with a multinomial coefficient.

Each factorization is found by a short recursion over divisors two through nine, and each arrangement count costs O(9) multiplications. Checking every integer up to 1e9 per case is hopeless. Factorials precomputed once turn each arrangement count into constant work. Takeaway: split the problem into factorizations and arrangements.

## Why It Works

1. A counted number has digits only from 1 to 9, since a zero digit makes the product zero.
2. Write the non-one digits as a multiset with product N and sum S.
3. Ones contribute to the sum alone, so the number of ones must be N - S, which has to be nonnegative.
4. The number of distinct digit strings from a multiset of c non-one digits and r ones is (c + r)! / (r! * product of the digit factorials).
5. Summing that multinomial over all valid multisets counts each number once, because each number has one multiset of digits.
6. Factorials and inverse factorials reduce each multinomial to a fixed number of modular multiplications.

The main terms and formulas:

| term | meaning |
|---|---|
| `digitMultiplicity` | count of each digit from 2 to 9 in the current multiset |
| `usedSum` | sum of the non-one digits chosen so far |
| `usedCount` | number of non-one digits chosen so far |
| `onesCount` | N minus the used sum, the required number of ones |
| `inverseFactorials` | modular inverses of the factorial table |

The smallest digit never decreases along a recursion path, so each multiset appears once.

A script-generated trace for N = 8:

```
digits {8}:          sum 8, ones 0, arrangements  1! / (1! 0!)          = 1
digits {2, 4}:       sum 6, ones 2, arrangements  4! / (2! 1! 1!)       = 12
digits {2, 2, 2}:    sum 6, ones 2, arrangements  5! / (2! 3!)          = 10
total 1 + 12 + 10 = 23
```

The trace matches the sample answer 23 for N = 8.

Modular inverses come from Fermat's theorem, valid because the modulus is prime. The factorial table covers N + 40, so `usedCount + onesCount` is always in range.

## Code

**Input and scanner.** All input is loaded once, then parsed by digit scanning.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007
const maxTarget = 300000

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

The scanner accepts any whitespace layout between values.
All values in this problem are positive, so no sign branch is needed.

**Buffered output.** Answer lines accumulate in one string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The final write after the case loop flushes the remaining bytes.

**Factorial tables.** Modular inverses make division exact under the modulus.

```nim
var factorials = newSeq[int64](maxTarget + 40)
var inverseFactorials = newSeq[int64](maxTarget + 40)

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var basePart = baseValue
  var exponentPart = exponentValue
  var powerResult = 1'i64
  while exponentPart > 0:
    if (exponentPart and 1) == 1:
      powerResult = powerResult * basePart mod modulusValue
    basePart = basePart * basePart mod modulusValue
    exponentPart = exponentPart div 2
  return powerResult

factorials[0] = 1
for factIndex in 1 .. factorials.high:
  factorials[factIndex] = factorials[factIndex - 1] * int64(factIndex) mod modulusValue
inverseFactorials[factorials.high] = powerMod(factorials[factorials.high], modulusValue - 2)
var downIndex = factorials.high - 1
while downIndex >= 0:
  inverseFactorials[downIndex] = inverseFactorials[downIndex + 1] * int64(downIndex + 1) mod modulusValue
  downIndex -= 1
```

Fast exponentiation handles the prime modulus.
Working downward gives every inverse from the next one.

**Factorization recursion.** Non-decreasing digits enumerate each multiset exactly once.

```nim
var currentTarget = 0
var digitMultiplicity = newSeq[int](10)
var accumulatedAnswer: int64 = 0

proc collectFactorizations(remaining: int, smallestDigit: int,
                           usedSum: int, usedCount: int) =
  if remaining == 1:
    let onesCount = currentTarget - usedSum
    if onesCount >= 0:
      var ways = factorials[usedCount + onesCount] * inverseFactorials[onesCount] mod modulusValue
      for digit in 2 .. 9:
        ways = ways * inverseFactorials[digitMultiplicity[digit]] mod modulusValue
      accumulatedAnswer = (accumulatedAnswer + ways) mod modulusValue
    return
  var digit = smallestDigit
  while digit <= 9:
    if remaining mod digit == 0:
      digitMultiplicity[digit] += 1
      collectFactorizations(remaining div digit, digit, usedSum + digit, usedCount + 1)
      digitMultiplicity[digit] -= 1
    digit += 1
```

A negative `onesCount` rejects a multiset whose sum already exceeds N.
Multiplicity is restored after each recursive call, so branches stay independent.

**Driver.** Each case resets the multiset and emits one modular answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  currentTarget = nextInt(inputData, scanPos)
  accumulatedAnswer = 0
  for digit in 0 .. 9:
    digitMultiplicity[digit] = 0
  collectFactorizations(currentTarget, 2, 0, 0)
  appendOutput($accumulatedAnswer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The recursion starts with no digits and a smallest allowed digit of two.
All answers use int64 intermediates to avoid overflow before the modular reduction.

## Complexity

Precomputation happens once, and each case explores only short factorizations.

| phase | time | space |
|---|---|---|
| factorial tables | O(Nmax) | two tables of Nmax entries |
| factorization per case | O(number of multisets * 9) | one multiplicity array |
| output | one buffered line per case | block buffer |

The factorization recursion is short because each digit is at least two.

| measure | Big O |
|---|---|
| preprocessing | O(300000) |
| time per case | O(F * 9), where F is the number of factor multisets |
| space | O(300000) |

Enumerating all integers up to N would take O(N) per case and cannot reach 3e5 within the limit. Takeaway: factor first, then arrange.
