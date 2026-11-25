# DELTACA2 — Delta catheti II (Hard) (SPOJ)

<https://www.spoj.com/problems/DELTACA2/>

## Problem

Find the nth right triangle whose legs differ by d, with d supplied in prime-factored form. Output the three sides modulo m.

Input starts with T. Each case uses two lines: n, d, m, then L followed by L pairs (p, e) whose product equals d. Print three reduced sides per case in the order a, b, c.

| item | bound |
|---|---|
| test count T | 1 to 9999 |
| term index n | 1 to 999999999999999999 |
| leg difference d | 1 to 99999999999999 |
| modulus m | 2 to 999999999 |
| judge limit | 10000 ms, 1536 MB |

The huge index rules out iteration, and the given factors remove trial division.

Sample input:

```
3
1 1 235813
0
3 21 1000
2 3 1 7 1
9 119 11
2 7 1 17 1
```

Sample output:

```
3 4 5
63 84 105
5 3 1
```

## Idea

Turn the leg gap into a Pell equation, like replacing a moving target with a fixed one. Put X equal to twice the small leg plus d, and Y equal to the hypotenuse. Then X squared minus twice Y squared equals minus d squared. The supplied factors of d build every solution family, and a shared recurrence plus one matrix power lands on term n.

## Why It Works

1. For a right triangle with legs a and a + d, set X = 2a + d and Y = c.
2. The Pythagorean equation becomes X squared minus two times Y squared equals minus d squared.
3. Multiplying a solution by 3 + 2 times the square root of two keeps the norm and enlarges both coordinates.
4. Split primes of d distribute their copies among conjugate factors, giving one family per distribution.
5. Inert primes and the prime two contribute only an overall scale, so they need no family choice.
6. Every family obeys Y(k+2) = 6 times Y(k+1) minus Y(k).
7. Sorting all families gives a merged sequence with C(i + 2F) = 6 times C(i + F) minus C(i), where F is the family count.
8. A matrix power applies that recurrence a quotient of n by F times, all modulo the given modulus.

| term | meaning |
|---|---|
| `differenceValue` | leg gap d in the current case |
| `orbitCount` | number of Pell families built from the factors |
| `matrixAdvance` | applies the family recurrence with modular arithmetic |
| `doubleModulus` | twice m, used to halve X minus d exactly |

For d equal to 119 the factors are 7 and 17, giving nine families.

```
first nine hypotenuses: 145 175 185 221 289 349 371 461 595
family count F = 9
step from index zero: C(18) = 6 times C(9) minus C(0)
```

The ninth hypotenuse is 595, which gives the sample triangle 357 476 595.

## Code

**Top-level helpers.** Tuples hold huge signed values as a mantissa and a binary exponent.

```nim
import algorithm
import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const stepLimit = 100

type Huge = tuple[negative: bool, exponent: int, mantissa: float64]
```

A mantissa stays between one and two, so comparison needs only exponent then mantissa.
Arithmetic on these tuples avoids any fixed-width overflow while families are built.
Only the final residues modulo m and twice m are kept for the jump.

**Family recurrence jump.** One matrix power advances a residue class of the merged sequence.

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

The matrix encodes one step of the shared second-order recurrence.
Binary exponentiation keeps the cost logarithmic in the term index.
All products stay below eight times ten to the eighteenth power, within signed 64 bits.

**Case parsing and jump.** Factors come from the second input line, and the term index selects a direct read or a jump.

```nim
  let factorCount = nextInt(inputData, scanPos)
  var factors: seq[Factor] = @[]
  var factorIndex = 0
  while factorIndex < factorCount:
    let primeValue = nextInt(inputData, scanPos)
    let exponentValue = nextInt(inputData, scanPos)
    factors.add((primeValue, exponentValue))
    factorIndex += 1
```

Reading both lines of every case keeps factor data paired with its difference.
The pair order follows the statement, prime then exponent.
No factorization work is needed inside the solver.

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

The residue of the index selects the family, and the quotient selects the jump count.
Working with twice the modulus preserves the parity needed for halving.
One output buffer collects every answer line.

## Complexity

Each case builds families from its given factors, then jumps in logarithmic time.

| phase | time | space |
|---|---|---|
| input read | one pass over all case lines | one input string |
| family build | factor count times family count | term arrays |
| merge | sort of a few thousand terms per family | term arrays |
| jump | one matrix power per side | constant |
| output | one block flush | block buffer |

The matrix power replaces a walk of n terms with about sixty squarings.

| measure | Big O |
|---|---|
| time | O(F terms built plus log n) per case |
| space | O(F squared) per case |

Enumerating triangles up to term n would need work proportional to n, while the merged recurrence handles the largest index directly.
