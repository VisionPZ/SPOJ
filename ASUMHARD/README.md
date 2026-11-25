# ASUMHARD — A Summatory (HARD) (SPOJ)

<https://www.spoj.com/problems/ASUMHARD/>

## Problem

Compute the sum of `f(i)` for `i` from one to `n`, where `f(i)` adds the `k`-th powers of all integers up to `i`. Print each answer modulo 1234567891.

The first integer is `T`, the number of test cases. Each test case has two integers: `n` and `k` on one line. Write `S_k(n)` for the sum of the `k`-th powers from one to `n`.

The statement gives these bounds:

| item | bound |
|---|---|
| test cases T | 1 to 54321 |
| n | 1 to 123456789 |
| k | 0 to 321 |
| modulus | 1234567891 |
| judge limit | 2107 ms, 1536 MB |

The counts are too large for any loop over `n`.

Sample input:

```
5
2 3
10 3
3 3
100 0
100 1
```

Sample output:

```
10
7942
46
5050
171700
```

## Idea

Think of swapping the order of a double sum, like counting a wall of bricks by columns instead of rows.

Each power `j^k` appears once for every `i` from `j` to `n`, so it appears `n - j + 1` times. The answer becomes `(n + 1)` times the power sum up to `n`, minus the next power sum. Faulhaber's formula gives those power sums from Bernoulli numbers and precomputed coefficients.

Summing over `i` and then over `j` costs linear time in `n`. Reordering the sum and evaluating a polynomial costs linear time in `k`. The takeaway is to change the counting order, then evaluate a fixed-degree polynomial.

## Why It Works

1. The double sum counts each `j^k` once for every later or equal `i`.
2. That count equals `n - j + 1` for each `j` from one to `n`.
3. The total is `(n + 1) S_k(n) - S_(k+1)(n)`.
4. Faulhaber's formula writes `S_k(n)` as a polynomial of degree `k + 1` in `n`.
5. Bernoulli numbers and modular inverses fix every coefficient once.
6. The modulus is prime, so each inverse exists for every value used.

The main terms are listed here:

| term | meaning |
|---|---|
| `bernoulli` | Bernoulli numbers modulo the modulus |
| `coefficient` | Faulhaber coefficient for each power and term |
| `powers` | successive powers of `n` modulo the modulus |
| `answerValue` | final total modulo the modulus |

One coefficient table serves all test cases.

A script trace for `n = 100` and `k = 1` uses the first two power sums:

| quantity | value |
|---|---|
| `S_1(100)` | 5050 |
| `S_2(100)` | 338350 |
| `101 * 5050 - 338350` | 171700 |

The result matches the last sample line.

Guard: every multiplication stays in 64-bit integers because the modulus squared is below the limit.

## Code

**Input and modular inverses.** The reader stores the whole input, then builds inverses and factorials.

```nim
const flushBlockBytes = 1 shl 17
const modulus = 1234567891'i64
const maximumPower = 321
const tableLimit = maximumPower + 3

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

proc powerMod(baseValue: int64, exponent: int64): int64 =
  var powerResult = 1'i64
  var current = baseValue mod modulus
  var powerLeft = exponent
  while powerLeft > 0:
    if (powerLeft and 1'i64) == 1'i64:
      powerResult = powerResult * current mod modulus
    current = current * current mod modulus
    powerLeft = powerLeft shr 1
  return powerResult

var inverseValue = newSeq[int64](tableLimit + 2)
var factorialValue = newSeq[int64](tableLimit + 2)
var inverseFactorial = newSeq[int64](tableLimit + 2)
inverseValue[1] = 1'i64
factorialValue[0] = 1'i64
for index in 2 .. tableLimit + 1:
  inverseValue[index] = modulus - (modulus div int64(index)) * inverseValue[int(modulus mod int64(index))] mod modulus
for index in 1 .. tableLimit + 1:
  factorialValue[index] = factorialValue[index - 1] * int64(index) mod modulus
inverseFactorial[tableLimit + 1] = powerMod(factorialValue[tableLimit + 1], modulus - 2)
var reverseIndex = tableLimit + 1
while reverseIndex >= 1:
  inverseFactorial[reverseIndex - 1] = inverseFactorial[reverseIndex] * int64(reverseIndex) mod modulus
  reverseIndex -= 1```

Inverses up to 325 cover both required power sums.
Factorial inverses produce binomial coefficients in constant time.
The modular exponentiation uses repeated squaring.

**Bernoulli numbers and coefficient table.** The recurrence fixes each Bernoulli number from earlier ones.

```nim
proc binomial(topValue: int, bottomValue: int): int64 =
  if bottomValue < 0 or bottomValue > topValue:
    return 0'i64
  return factorialValue[topValue] * inverseFactorial[bottomValue] mod modulus * inverseFactorial[topValue - bottomValue] mod modulus

var bernoulli = newSeq[int64](tableLimit + 2)
bernoulli[0] = 1'i64
for order in 1 .. tableLimit:
  var runningSum = 0'i64
  for lower in 0 .. order - 1:
    runningSum = (runningSum + binomial(order + 1, lower) * bernoulli[lower]) mod modulus
  bernoulli[order] = (modulus - runningSum) * inverseValue[order + 1] mod modulus

var coefficient = newSeq[seq[int64]](tableLimit)
for powerIndex in 0 .. tableLimit - 1:
  coefficient[powerIndex] = newSeq[int64](powerIndex + 1)
  for lower in 0 .. powerIndex:
    var term = binomial(powerIndex + 1, lower) * bernoulli[lower] mod modulus
    if (lower and 1) == 1:
      term = modulus - term
    coefficient[powerIndex][lower] = term * inverseValue[powerIndex + 1] mod modulus```

The Bernoulli recurrence comes from the defining identity.
The sign flips on odd indices, matching Faulhaber's formula.
Each coefficient already includes its inverse factorial factor.

**Test case evaluation.** Each case computes powers of `n`, then two dot products.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let limitValue = int64(nextInt(inputData, scanPos))
  let power = nextInt(inputData, scanPos)
  var powers = newSeq[int64](power + 3)
  powers[0] = 1'i64
  for exponent in 1 .. power + 2:
    powers[exponent] = powers[exponent - 1] * (limitValue mod modulus) mod modulus
  var firstSum = 0'i64
  for lower in 0 .. power:
    firstSum = (firstSum + coefficient[power][lower] * powers[power + 1 - lower]) mod modulus
  var secondSum = 0'i64
  for lower in 0 .. power + 1:
    secondSum = (secondSum + coefficient[power + 1][lower] * powers[power + 2 - lower]) mod modulus
  let answerValue = ((limitValue + 1) mod modulus * firstSum - secondSum) mod modulus
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0```

Powers are built by repeated multiplication in linear time.
The two dot products evaluate `S_k(n)` and `S_(k+1)(n)`.
Buffered writes handle up to 54321 output lines.

## Complexity

A one-time table build is followed by short per-case work.

| phase | time | space |
|---|---|---|
| input read | one pass over the whole input | one input string |
| table build | O(K^2) modular operations | coefficient table |
| each test case | O(k) modular operations | power array |
| output | one line per case | block buffer |

The table is shared by every test case.

| measure | Big O |
|---|---|
| time | O(K^2 + sum of k over all cases) |
| space | O(K^2) |

Summing `i` from one to `n` for each case would cost O(n k). Polynomial evaluation removes that dependence on `n`, which is the takeaway.
