# IRECSQRT — Inverse of Recurrence Problem With a Square Root (SPOJ)
<https://www.spoj.com/problems/IRECSQRT/>

## Problem

The recurrence is written backwards: a0 = 1 and a_n equals (1 + 4 a_{n+1} + sqrt(1 + 24 a_{n+1})) / 16. For each pair n, m, report a_n modulo m.

Input starts with T. Each of the next T lines holds two unsigned integers n and m.

Output is one line per case with a_n modulo m.

The input bounds are:

| item | bound |
|---|---|
| test cases T | 1 to 50000 |
| index n | 0 to 2^64 - 1 |
| modulus m | 1 to 2^64 - 1 |
| judge limit | 13000 ms, 1536 MB |

The square root term always makes a_n an integer, so no rounding is involved.

Sample input:

```
10
0 10
1 10
2 10
3 10
10 10
100 100
1000 1000
10000 10000
100000 100000
9876543210123456789 1234567890987654321
```

Sample output:

```
1
2
5
5
5
51
251
6251
6251
657422418465782775
```

## Idea

Unfold the inverse formula to expose a plain power of two, like straightening a folded strip to read the marks in order. The square-root recurrence gives the closed form a_n = (2^n + 1)(2^{n-1} + 1) / 3.

That expression follows a linear recurrence of order three, so Kitamasa polynomial exponentiation computes the term in O(log n) modular steps. Stepping through n terms one by one is impossible once n reaches 2^64.

Kitamasa keeps only three coefficients per polynomial, and a hand-written product handles 64-bit moduli. One short exponentiation answers each case.

## Why It Works

1. Set s = sqrt(1 + 24 a_{n+1}), so a_{n+1} = (s^2 - 1) / 24.
2. Substitution into the given formula gives 16 a_n = (s + 1)(s + 5) / 6.
3. Solving that quadratic yields s = 2 sqrt(1 + 24 a_n) - 3.
4. Writing t = sqrt(1 + 24 a_n) gives a_{n+1} = (t - 1)(t - 2) / 6, and induction gives t = 3 + 2^{n+1}.
5. Hence a_n = (2^n + 1)(2^{n-1} + 1) / 3.
6. Powers 4, 2, and 1 satisfy x^3 - 7x^2 + 14x - 8 = 0, so a_{n+3} = 7a_{n+2} - 14a_{n+1} + 8a_n.
7. Kitamasa reduces x^n modulo that cubic and combines the three coefficients with a0, a1, and a2.

The main formulas are:

| item | meaning |
|---|---|
| a_n | (2^n + 1)(2^{n-1} + 1) / 3 |
| t | 3 + 2^{n+1}, the square root in the recurrence |
| characteristic polynomial | x^3 - 7x^2 + 14x - 8 |
| `resultPoly` | coefficients of x^n after reduction |
| `mulMod` | product of two residues modulo m |

A short script over small indices gives these values:

| n | 2^n | (2^n + 1)(2^{n-1} + 1) / 3 | a_n mod 100 |
|---|---|---|---|
| 0 | 1 | 1 | 1 |
| 1 | 2 | 2 | 2 |
| 2 | 4 | 5 | 5 |
| 3 | 8 | 15 | 15 |
| 4 | 16 | 51 | 51 |

The fourth row explains the sample answer 51 for n = 100 modulo 100.
Modular products use a 128-bit emulated product with exact correction, so even moduli divisible by high powers of three work without any division.

## Code

**Input and modular helpers.** The reader accepts unsigned 64-bit values.

```nim
const flushBlockBytes = 1 shl 17
const lowMask = 4294967295'u64
const twoPower64 = 18446744073709551616.0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextUInt(data: string, pos: var int): uint64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'u64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10'u64 + uint64(int(data[pos]) - 48)
    pos += 1
  return value
```

The scanner skips every non-digit separator.
Each unsigned value is built one digit at a time.
The constants support the wide modular product.

**Wide product.** One hundred twenty-eight product bits are kept in two 64-bit words.

```nim
proc addMod(left, right, modulus: uint64): uint64 =
  if left >= modulus - right:
    return left - (modulus - right)
  return left + right

proc subMod(left, right, modulus: uint64): uint64 =
  if left >= right:
    return left - right
  return modulus - (right - left)

proc product128(left, right: uint64): tuple[hi, lo: uint64] =
  let leftLow = left and lowMask
  let leftHigh = left shr 32
  let rightLow = right and lowMask
  let rightHigh = right shr 32
  let lowLow = leftLow * rightLow
  let lowHigh = leftLow * rightHigh
  let highLow = leftHigh * rightLow
  let highHigh = leftHigh * rightHigh
  let middle = (lowLow shr 32) + (lowHigh and lowMask) + (highLow and lowMask)
  result.lo = (lowLow and lowMask) or (middle shl 32)
  result.hi = highHigh + (lowHigh shr 32) + (highLow shr 32) + (middle shr 32)
```

The product splits both factors into 32-bit halves.
Four small products form the high and low words.
Additions and subtractions stay below the modulus.

**Reduction.** A floating estimate is corrected with exact integer comparisons.

```nim
proc mulMod(left, right, modulus: uint64): uint64 =
  if modulus <= 1'u64:
    return 0'u64
  let full = product128(left, right)
  var limbs = [full.hi shr 32, full.hi and lowMask, full.lo shr 32, full.lo and lowMask]
  var remHi = 0'u64
  var remLo = 0'u64
  for limb in limbs:
    remHi = (remHi shl 32) or (remLo shr 32)
    remLo = ((remLo and lowMask) shl 32) or limb
    if remHi == 0'u64 and remLo < modulus:
      continue
    let estimate = (float(remHi) * twoPower64 + float(remLo)) / float(modulus)
    var quotient = uint64(estimate)
    var quotProd = product128(quotient, modulus)
    while quotProd.hi > remHi or (quotProd.hi == remHi and quotProd.lo > remLo):
      quotient -= 1'u64
      quotProd = product128(quotient, modulus)
    while true:
      let nextQuotient = quotient + 1'u64
      let nextProd = product128(nextQuotient, modulus)
      if nextProd.hi < remHi or (nextProd.hi == remHi and nextProd.lo <= remLo):
        quotient = nextQuotient
        quotProd = nextProd
      else:
        break
    let borrow: uint64 = if remLo < quotProd.lo: 1'u64 else: 0'u64
    remLo = remLo - quotProd.lo
    remHi = remHi - quotProd.hi - borrow
  return remLo
```

The 128-bit product is consumed four limbs at a time.
Each quotient estimate is checked against the true remainder.
The final remainder fits in one unsigned word.

**Polynomial exponentiation.** Multiplication reduces powers above two with the cubic relation.

```nim
proc multiplyPoly(left, right: array[3, uint64], modulus: uint64): array[3, uint64] =
  let lowLow = mulMod(left[0], right[0], modulus)
  let lowMiddle = addMod(mulMod(left[0], right[1], modulus), mulMod(left[1], right[0], modulus), modulus)
  let middle = addMod(addMod(mulMod(left[0], right[2], modulus), mulMod(left[1], right[1], modulus), modulus), mulMod(left[2], right[0], modulus), modulus)
  let highMiddle = addMod(mulMod(left[1], right[2], modulus), mulMod(left[2], right[1], modulus), modulus)
  let high = mulMod(left[2], right[2], modulus)
  result[0] = addMod(addMod(lowLow, mulMod(highMiddle, 8'u64, modulus), modulus), mulMod(high, 56'u64, modulus), modulus)
  result[1] = subMod(subMod(lowMiddle, mulMod(highMiddle, 14'u64, modulus), modulus), mulMod(high, 90'u64, modulus), modulus)
  result[2] = addMod(addMod(middle, mulMod(highMiddle, 7'u64, modulus), modulus), mulMod(high, 35'u64, modulus), modulus)
```

Powers x^3 and x^4 use the constants 8, -14, 7 and 56, -90, 35.
All coefficients stay reduced modulo m.
Negative terms use subtraction modulo m.

**Term recovery.** Binary exponentiation builds x^n, then the three basis values are combined.

```nim
proc sequenceTerm(exponent, modulus: uint64): uint64 =
  if modulus <= 1'u64:
    return 0'u64
  var resultPoly = [1'u64, 0'u64, 0'u64]
  var basePoly = [0'u64, 1'u64, 0'u64]
  var remaining = exponent
  while remaining > 0'u64:
    if (remaining and 1'u64) == 1'u64:
      resultPoly = multiplyPoly(resultPoly, basePoly, modulus)
    remaining = remaining shr 1
    if remaining > 0'u64:
      basePoly = multiplyPoly(basePoly, basePoly, modulus)
  let firstTerm = mulMod(resultPoly[0], 1'u64, modulus)
  let secondTerm = mulMod(resultPoly[1], 2'u64, modulus)
  let thirdTerm = mulMod(resultPoly[2], 5'u64, modulus)
  return addMod(addMod(firstTerm, secondTerm, modulus), thirdTerm, modulus)
```

The result starts as x^0 and the base starts as x^1.
Set bits multiply the result by the current power.
The final dot product uses a0 = 1, a1 = 2, and a2 = 5.

**Final write.** Each case adds one answer line.

```nim
let caseCount = nextUInt(inputData, scanPos)
for caseIndex in 0 .. int(caseCount) - 1:
  let exponent = nextUInt(inputData, scanPos)
  let modulus = nextUInt(inputData, scanPos)
  appendOutput($sequenceTerm(exponent, modulus))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads one exponent and one modulus per case.
Every answer is appended to one buffer.
The buffer is flushed once at the end.

## Complexity

Exponentiation dominates each test case.

| phase | time | space |
|---|---|---|
| input read | one pass over T cases | one input string |
| binary exponentiation | about 96 polynomial products | three coefficients per polynomial |
| wide product | four limb reductions | two 64-bit words |
| output | one line per case | block buffer |

Each polynomial product costs a fixed nine wide products.

| measure | Big O |
|---|---|
| time | O(T log n) |
| space | O(1) besides input and output buffers |

Walking from a0 up to a_n would need exponentially many steps in the input size.
Closed-form reduction and Kitamasa answer every 64-bit index, which ends the work.
