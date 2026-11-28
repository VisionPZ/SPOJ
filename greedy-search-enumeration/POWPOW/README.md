# POWPOW — Power with Combinatorics (SPOJ)

<https://www.spoj.com/problems/POWPOW/>

## Problem

Compute a raised to exp raised to b modulo 1000000007, where exp is the sum of squared binomial coefficients for n. Answer T independent cases.

The first input line gives T. Each following line gives a, b, and n in that order. Print one residue per line.

| item | bound |
|---|---|
| test count T | up to 1000 |
| base a | 0 to 100000 |
| outer exponent b | 0 to 100000 |
| binomial index n | 0 to 100000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
1
1 1 1
```

Sample output:

```
1
```

The explanation with the sample states that exp is 2 and 1 to the power 2 gives 1.

## Idea

The long sum of squared binomial coefficients collapses to one central binomial coefficient, like replacing a long hand count with a single known total. Fermat's rule then shrinks the huge exponent modulo 1000000006, and two modular exponentiations finish the job.

Vandermonde's identity gives exp = C(2n, n). Since n is at most 100000, that coefficient fits comfortably under the prime factor 500000003 of 1000000006. One factorial table and one CRT step recover exp modulo 1000000006. Summing all n squared terms per case would cost O(n) each time and repeat the same work.

## Why It Works

1. Vandermonde's identity gives the sum of C(n,k) squared over k as C(2n, n).
2. The modulus 1000000007 is prime, so a nonzero base satisfies a^(p−1) = 1.
3. The exponent exp^b may be reduced modulo p − 1 before the final power.
4. The number p − 1 equals 2 · 500000003, with 500000003 prime.
5. Since 2n < 500000003, factorials and inverse factorials give C(2n, n) modulo that prime directly.
6. Combining the value modulo 500000003 with the parity of C(2n, n) gives the residue modulo p − 1.

| term | meaning |
|---|---|
| `factorials` | factorials modulo 500000003 |
| `inverseFactorials` | inverse factorials by Fermat |
| `centralValue` | C(2n, n) modulo 500000003 |
| `exponentBase` | exp modulo 1000000006 |
| `reducedExponent` | exp^b modulo 1000000006 |

For the sample a = 1, b = 1, n = 1, the table shows the reduction.

| step | value |
|---|---|
| exp from squared binomials | 1² + 1² = 2 |
| central coefficient | C(2, 1) = 2 |
| parity adjustment | 0, so exp modulo 1000000006 is 2 |
| final power | 1^2 modulo 1000000007 = 1 |

`powerModulo` begins with powerResult equal to 1, so a zero exponent returns 1. Every product stays below 10^18 and fits in `int64`.

## Code

**Input and buffer.** All cases are parsed before the factorial table is built.

```nim
const flushBlockBytes = 1 shl 17
const resultModulus = 1000000007'i64
const exponentModulus = 1000000006'i64
const primeFactor = 500000003'i64

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

Inputs are nonnegative, so the scanner skips separators only.
`appendOutput` flushes after `flushBlockBytes` bytes.
The constants name the two moduli and the smaller prime factor.

**Modular power and tables.** One power routine serves both Fermat steps, and factorials are built once.

```nim
proc powerModulo(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var powerResult = 1'i64
  var currentBase = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) != 0:
      powerResult = (powerResult * currentBase) mod modulus
    currentBase = (currentBase * currentBase) mod modulus
    remaining = remaining shr 1
  return powerResult

let caseCount = nextInt(inputData, scanPos)
var baseValues = newSeq[int](caseCount)
var powerValues = newSeq[int](caseCount)
var combinationNs = newSeq[int](caseCount)
var largestN = 0
for caseIndex in 0 .. caseCount - 1:
  let baseValue = nextInt(inputData, scanPos)
  let powerValue = nextInt(inputData, scanPos)
  let combinationN = nextInt(inputData, scanPos)
  baseValues[caseIndex] = baseValue
  powerValues[caseIndex] = powerValue
  combinationNs[caseIndex] = combinationN
  if combinationN > largestN:
    largestN = combinationN

let factorialLimit = 2 * largestN
var factorials = newSeq[int64](factorialLimit + 1)
var inverseFactorials = newSeq[int64](factorialLimit + 1)
factorials[0] = 1'i64
for index in 1 .. factorialLimit:
  factorials[index] = (factorials[index - 1] * int64(index)) mod primeFactor
inverseFactorials[factorialLimit] = powerModulo(factorials[factorialLimit], primeFactor - 2, primeFactor)
var reverseIndex = factorialLimit
while reverseIndex > 0:
  inverseFactorials[reverseIndex - 1] = (inverseFactorials[reverseIndex] * int64(reverseIndex)) mod primeFactor
  reverseIndex -= 1
```

`powerModulo` uses binary exponentiation with 64-bit products.
Factorials stop at twice the largest n in the input.
One inverse power and a downward pass fill all inverse factorials.

**Case loop.** Each case rebuilds the exponent, reduces it, and writes one residue.

```nim
for caseIndex in 0 .. caseCount - 1:
  let combinationN = combinationNs[caseIndex]
  let doubledN = 2 * combinationN
  let centralModuloPrime = (factorials[doubledN] * inverseFactorials[combinationN]) mod primeFactor
  let centralValue = (centralModuloPrime * inverseFactorials[combinationN]) mod primeFactor
  var oddParity = 0
  if combinationN == 0:
    oddParity = 1
  else:
    oddParity = 0
  var adjust = oddParity - int(centralValue mod 2'i64)
  if adjust < 0:
    adjust += 2
  adjust = adjust mod 2
  let exponentBase = centralValue + primeFactor * int64(adjust)
  let reducedExponent = powerModulo(exponentBase, int64(powerValues[caseIndex]), exponentModulus)
  let answerValue = powerModulo(int64(baseValues[caseIndex]), reducedExponent, resultModulus)
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`centralValue` is C(2n, n) modulo the smaller prime.
The parity adjustment completes the Chinese remainder reconstruction.
Two powers turn that residue into the printed answer.

## Complexity

Factorials are shared, so each case only performs two short powers.

| phase | time | space |
|---|---|---|
| input read | one pass over 3T values | one input string |
| factorial tables | O(Nmax) up to 2Nmax entries | two arrays |
| each case | O(log b + log p) modular work | none extra |
| output | T lines | block buffer |

| measure | Big O |
|---|---|
| time | O(Nmax + T log Nmax) |
| space | O(Nmax) for factorial arrays |

Summing all squared binomials for every case would cost O(n) per case and grow large before reduction. The identity and CRT keep each case near logarithmic cost.
