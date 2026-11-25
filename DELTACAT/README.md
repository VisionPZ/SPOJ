# DELTACAT — Delta catheti (hard) (SPOJ)

<https://www.spoj.com/problems/DELTACAT/>

## Problem

Find the nth right triangle whose two legs differ by a fixed number d. Output the three sides modulo m.

Input starts with T, then T lines holding n, d, and m. Print three reduced sides per line in the order a, b, c with b minus a equal to d.

| item | bound |
|---|---|
| test count T | 1 to 99999 |
| term index n | 1 to 9999999 |
| leg difference d | 1 to 99999999 |
| modulus m | 2 to 999999999 |
| judge limit | 30000 ms, 1536 MB |

The term index forces a jump formula, and the modulus keeps the printed sides small.

Sample input:

```
3
1 1 235813
3 21 1000
9 119 11
```

Sample output:

```
3 4 5
63 84 105
5 3 1
```

## Idea

Write the smaller leg as a, so the larger is a + d and the hypotenuse is c. Substituting into the Pythagorean equation gives a Pell equation, like turning a moving target into a fixed equation. All solutions split into a few families, and each family grows by the same factor. Sorting the families gives one shared recurrence, so a matrix power jumps straight to term n.

## Why It Works

1. Put X = 2a + d and Y = c.
2. Then X squared minus two times Y squared equals minus d squared.
3. Every solution with a greater than zero gives one such pair, and each pair gives one triangle.
4. Multiplying X + Y times the square root of two by 3 + 2 times the square root of two keeps the norm and enlarges both values.
5. That multiplication gives one family per factorization choice of d, with recurrence Y(k+2) = 6 times Y(k+1) minus Y(k).
6. All families grow by the same factor, so the sorted merge repeats every family count steps.
7. The merged sequence obeys C(i + 2F) = 6 times C(i + F) minus C(i), where F is the number of families.
8. A two by two matrix power applies that recurrence n divided by F times without walking through earlier terms.

| term | meaning |
|---|---|
| `differenceValue` | leg gap d in the current case |
| `orbitCount` | number of Pell families for d |
| `matrixAdvance` | applies the family recurrence with modular arithmetic |
| `doubleModulus` | twice m, used to halve X minus d safely |

For d equal to 21 there are three families with bases 39, 51, and 105.

```
merged: 39 51 105 219 291 609 1275
family count F = 3
C(6) = 6 times C(3) minus C(0) = 6 times 219 minus 39 = 1275
C(8) = 6 times C(5) minus C(2) = 6 times 609 minus 105 = 3549
```

The term at index two is 105, which gives the sample triangle 63 84 105.

## Code

**Input and shared helpers.** One read fills the input, and signed values are scanned by hand.

```nim
import algorithm
import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const sieveLimit = 10000
const stepLimit = 100

type Huge = tuple[negative: bool, exponent: int, mantissa: float64]
```

Large triangle sides overflow 64 bits, so the code stores them as a signed mantissa and a binary exponent.
The algorithm module supplies the term sort, and the math module supplies the square root.
The step limit guards family reduction for every factor pattern.

**Family recurrence jump.** A two by two matrix power applies the shared recurrence.

```nim
proc matrixAdvance(firstValue: int64, secondValue: int64, steps: int64, modulus: int64): int64 =
  var a00: int64 = 1 mod modulus
  var a01: int64 = 0
  var a10: int64 = 0
  var a11: int64 = 1 mod modulus
  var b00: int64 = 6 mod modulus
  var b01: int64 = (modulus - 1) mod modulus
  var b10: int64 = 1 mod modulus
  var b11: int64 = 0
  var exponentValue = steps
  while exponentValue > 0:
    if (exponentValue and 1) == 1:
      let c00 = (a00 * b00 + a01 * b10) mod modulus
      let c01 = (a00 * b01 + a01 * b11) mod modulus
      let c10 = (a10 * b00 + a11 * b10) mod modulus
      let c11 = (a10 * b01 + a11 * b11) mod modulus
      a00 = c00
      a01 = c01
      a10 = c10
      a11 = c11
    let d00 = (b00 * b00 + b01 * b10) mod modulus
    let d01 = (b00 * b01 + b01 * b11) mod modulus
    let d10 = (b10 * b00 + b11 * b10) mod modulus
    let d11 = (b10 * b01 + b11 * b11) mod modulus
    b00 = d00
    b01 = d01
    b10 = d10
    b11 = d11
    exponentValue = exponentValue shr 1
  return (a10 * firstValue + a11 * secondValue) mod modulus
```

The matrix encodes one step of the shared recurrence.
Exponentiation by squaring keeps the jump logarithmic in n.
Working modulo twice m makes the later halving exact.

**Case loop.** Each case builds its families, merges the first terms, then jumps or reads directly.

```nim
  if targetIndex <= directLimit:
    let chosenIndex = int(targetIndex - 1)
    firstLegMod = mergedRealMods[chosenIndex]
    hypotenuseMod = mergedImaginaryMods[chosenIndex] mod modulusValue
  else:
    let globalIndex = targetIndex - 1
    let quotient = globalIndex div int64(orbitCount)
    let remainder = globalIndex mod int64(orbitCount)
    let startIndex = int(remainder) + 3 * orbitCount
    let nextIndex = startIndex + orbitCount
    let steps = quotient - 3
    firstLegMod = matrixAdvance(mergedRealMods[nextIndex], mergedRealMods[startIndex], steps, doubleModulus)
    hypotenuseMod = matrixAdvance(mergedImaginaryMods[nextIndex], mergedImaginaryMods[startIndex], steps, doubleModulus) mod modulusValue
  secondLegMod = (positiveModulo(firstLegMod - int64(differenceValue), doubleModulus) div 2) mod modulusValue
  firstLegMod = positiveModulo(secondLegMod + int64(differenceValue), modulusValue)
  appendOutput($secondLegMod & " " & $firstLegMod & " " & $hypotenuseMod)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Small indices are read from the merged table without a jump.
The residue class of n picks the family and the starting pair.
X minus d is even, so division by two after reduction is exact.

## Complexity

Family construction is shared per case, and the jump costs one logarithm.

| phase | time | space |
|---|---|---|
| input read | one pass over T cases | one input string |
| factor trial division | primes up to the square root of d | one prime list |
| family build and merge | families times a few thousand terms | term arrays |
| jump | one matrix power per side | constant |
| output | one block flush | block buffer |

The matrix power replaces a walk of n steps with about sixty squarings.

| measure | Big O |
|---|---|
| time | O(sqrt d plus F squared plus log n) per case |
| space | O(F squared) per case |

Walking every triangle up to the nth would cost work proportional to n, while the merged recurrence jumps directly.
