# FACTMULP — Product of factorials (hard) (SPOJ)

<https://www.spoj.com/problems/FACTMULP/>

## Problem

Find the exponent of a prime p in the product of the first p^e factorials, modulo 1e9+7. The exponent is huge, so the problem asks for its residue.

Input starts with T, the number of test cases. Each later line holds a prime p and an exponent e. Print V(p, p^e) modulo 1000000007 on one line per case. The exponent i satisfies p^i dividing F(n) = 1! × 2! × … × n!, with n = p^e.

| item | bound |
|---|---|
| test cases T | 1 to 99999 |
| prime p | 1 < p < 10^18 |
| exponent e | 0 < e < 10^18 |
| judge limit | 4300 ms, 1536 MB |

Inputs include cases where p is congruent to 1 modulo the answer modulus.

Sample input:

```
1
2 2
```

Sample output:

```
5
```

## Idea

Collapse the many factorial contributions into one geometric sum, like adding a row of repeated payments with a single formula. For n = p^e, every relevant power p^j divides n exactly, so each term is a polynomial in p. The exponent becomes p^e times a shifted geometric sum, divided by two, plus that sum. Modular exponentiation handles the 10^18 exponent in about 60 steps. Adding each factorial term would need p^e steps and never finish. Use the closed form and Fermat inverses.

## Why It Works

1. The exponent of p in k! is the sum of floor(k / p^j) over j >= 1.
2. For n = p^e and d = p^j with j <= e, the quotient q equals p^(e-j) and the remainder is zero.
3. The floor sum S(n, d) becomes d × q × (q-1)/2 + q, which simplifies to p^e × (p^(e-j) - 1)/2 + p^(e-j).
4. Writing t = e-j gives V(p, p^e) = p^e × (G - e)/2 + G, where G = 1 + p + … + p^(e-1).
5. Modular division by two multiplies by 500000004, the inverse of two modulo 1000000007.
6. When p is 1 modulo 1000000007, every term of G is 1, so G equals e modulo the modulus.

| term | meaning |
|---|---|
| `primePower` | p^e modulo the answer modulus |
| `geometricSum` | G modulo the answer modulus |
| `exponentResidue` | e modulo the answer modulus |
| `difference` | G - e modulo the answer modulus |
| `doubledPart` | p^e × difference modulo the answer modulus |

For p = 2 and e = 2, G = 1 + 2 = 3 and p^e = 4. The difference is 3 - 2 = 1. Half of 4 × 1 is 2, and adding G gives 5. F(4) = 288 = 2^5 × 3^2, which confirms the result.

The inverse of p-1 is taken only when p is not 1 modulo the modulus. That branch covers the tricky cases without a division by zero.

## Code

**Input and modular power.** The reader buffers tokens, and binary exponentiation handles huge exponents.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007'i64
const inverseOfTwo = 500000004'i64

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var powerResult = 1'i64
  var baseCopy = baseValue mod answerModulus
  var exponentCopy = exponentValue
  while exponentCopy > 0:
    if (exponentCopy and 1'i64) != 0:
      powerResult = (powerResult * baseCopy) mod answerModulus
    baseCopy = (baseCopy * baseCopy) mod answerModulus
    exponentCopy = exponentCopy shr 1
  return powerResult
```

All products stay below 10^18, which fits an int64.
Each exponent bit either squares the base or advances the result.
Output goes to one buffer and flushes in large blocks.

**Closed form per case.** The program builds G, applies the modular division, and prints one residue.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let primeValue = int64(nextInt(inputData, scanPos))
  let exponentValue = int64(nextInt(inputData, scanPos))
  let primeResidue = primeValue mod answerModulus
  let primePower = powerMod(primeResidue, exponentValue)
  var geometricSum = 0'i64
  if primeResidue == 1:
    geometricSum = exponentValue mod answerModulus
  else:
    let denominatorResidue = (primeValue - 1) mod answerModulus
    let denominatorInverse = powerMod(denominatorResidue, answerModulus - 2)
    geometricSum = ((primePower - 1 + answerModulus) mod answerModulus) * denominatorInverse mod answerModulus
  let exponentResidue = exponentValue mod answerModulus
  let difference = (geometricSum - exponentResidue + answerModulus) mod answerModulus
  let doubledPart = primePower * difference mod answerModulus
  let answer = (doubledPart * inverseOfTwo + geometricSum) mod answerModulus
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The branch for residue one avoids an inverse of zero.
Adding the modulus before each subtraction keeps residues positive.
The final flush writes the buffered answers once.

## Complexity

Each case uses two modular powers with at most 60 bits.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| modular powers | about 60 squarings each | a few int64 values |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(log e + log p) |
| space | O(1) |

A direct sum over factorial terms needs p^e steps and cannot handle e near 10^18. Closed-form residues keep every case short.
