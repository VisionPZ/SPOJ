# SUFFIX — Suffixes (SPOJ)

<https://www.spoj.com/problems/SUFFIX/>

## Problem

Find the smallest natural number whose representation in each of several bases ends with a given suffix. The answer is a decimal integer, and no bound larger than the product of the base powers appears.

Input starts with the constraint count. Each later line gives one base and one suffix, using digits and capital letters for digit values up to 35. Bases are distinct, and the product of all base powers is below 10 to the 18.

Output the smallest matching number in base ten.

| item | bound |
|---|---|
| constraints | 1 to 10 |
| base | 2 to 36, pairwise distinct |
| digit values | 0 to 35 |
| product of base powers | below 10^18 |
| judge limit | 100 ms, 1536 MB |

Distinct bases give coprime prime factors only when the bases share no factor, so the general Chinese remainder theorem handles all cases.

First sample input:

```
3
5 22
11 A2
18 4
```

First sample output:

```
112
```

Second sample input:

```
5
2 110
32 E
25 M3
28 2
7 2
```

Second sample output:

```
53678
```

## Idea

A suffix fixes the last digits, and those digits are the remainder modulo a power of the base, like reading only the last digits of a receipt. Convert each suffix to its remainder and modulus, then merge the congruences with the Chinese remainder theorem. Each merge takes a few big multiplications. Scanning candidate numbers one by one would take up to 10 to the 18 steps. One algebraic merge per base replaces that scan.

## Why It Works

1. A number ends with the suffix d when the number equals that suffix value modulo base to the suffix length.
2. Horner evaluation turns the suffix characters into that value, while one multiply per character builds the modulus.
3. Merging two congruences keeps every number satisfying both, with a modulus equal to their least common multiple.
4. An extended gcd supplies the inverse needed for a non-coprime merge.
5. Repeated merging ends with one residue below the final modulus, which is the smallest valid number.

| term | meaning |
|---|---|
| `suffixValue` | numeric value of the suffix in its base |
| `modulusPower` | base raised to the suffix length |
| `commonDivisor` | gcd of the current modulus and the new modulus |
| `resultResidue` | smallest solution modulo the modulus built so far |

The table tracks one partial solution through all constraints.

A worked example from the generator:

```
base 5, suffix 22 -> value 12, modulus 25
base 11, suffix A2 -> value 112, modulus 121
base 18, suffix 4 -> value 4, modulus 18
112 mod 25 = 12, 112 mod 121 = 112, 112 mod 18 = 4
smallest combined solution = 112
```

The three remainders meet at 112, matching the first sample output.

## Code

**Reading the constraints.** The scanner reads bases and mixed character suffixes.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitCode = 48
const firstUpperCode = 55

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitCode)
    pos += 1
  return value

proc isSuffixCharacter(character: char): bool =
  return (character >= '0' and character <= '9') or (character >= 'A' and character <= 'Z')

proc nextSuffixToken(data: string, pos: var int): string =
  while pos < data.len and not isSuffixCharacter(data[pos]):
    pos += 1
  var token = ""
  while pos < data.len and isSuffixCharacter(data[pos]):
    token.add data[pos]
    pos += 1
  return token

proc digitValue(character: char): int64 =
  if character >= '0' and character <= '9':
    return int64(int(character) - firstDigitCode)
  return int64(int(character) - firstUpperCode)
```

The token reader keeps letters and digits together.
Each suffix costs one pass over its characters.
The base powers stay below 10 to the 18, so int64 holds them.

**Gcd and modular arithmetic.** The helpers build inverses without overflow.

```nim
proc extendedGcd(firstValue: int64, secondValue: int64, coefficient: var int64,
                 otherCoefficient: var int64): int64 =
  if secondValue == 0:
    coefficient = 1
    otherCoefficient = 0
    return firstValue
  var innerCoefficient: int64 = 0
  var innerOther: int64 = 0
  let common = extendedGcd(secondValue, firstValue mod secondValue,
                           innerCoefficient, innerOther)
  coefficient = innerOther
  otherCoefficient = innerCoefficient - (firstValue div secondValue) * innerOther
  return common

proc multiplyModulo(leftFactor: int64, rightFactor: int64, modulus: int64): int64 =
  var product: int64 = 0
  var doubledFactor = leftFactor mod modulus
  var multiplier = rightFactor mod modulus
  while multiplier > 0:
    if (multiplier and 1) == 1:
      product = (product + doubledFactor) mod modulus
    doubledFactor = (doubledFactor * 2) mod modulus
    multiplier = multiplier shr 1
  return product
```

Extended gcd returns the gcd and one inverse coefficient.
Doubling keeps each intermediate below twice the modulus.
Recursive depth stays below the number of base powers.

**Merging congruences.** Each constraint folds into the running residue.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let constraintCount = int(nextInt(inputData, scanPos))
var resultResidue: int64 = 0
var resultModulus: int64 = 1

for constraintIndex in 0 .. constraintCount - 1:
  let baseValue = nextInt(inputData, scanPos)
  let suffixText = nextSuffixToken(inputData, scanPos)
  var suffixValue: int64 = 0
  var modulusPower: int64 = 1
  for letter in suffixText:
    suffixValue = suffixValue * baseValue + digitValue(letter)
    modulusPower = modulusPower * baseValue

  var unusedCoefficient: int64 = 0
  var unusedOther: int64 = 0
  let commonDivisor = extendedGcd(resultModulus, modulusPower,
                                  unusedCoefficient, unusedOther)
  let reducedModulus = modulusPower div commonDivisor
  var stepValue: int64 = 0
  if reducedModulus > 1:
    let difference = (suffixValue - resultResidue) div commonDivisor
    var differenceModulo = difference mod reducedModulus
    if differenceModulo < 0:
      differenceModulo += reducedModulus
    var inverseCoefficient: int64 = 0
    var inverseOther: int64 = 0
    discard extendedGcd(resultModulus div commonDivisor, reducedModulus,
                        inverseCoefficient, inverseOther)
    var inverseValue = inverseCoefficient mod reducedModulus
    if inverseValue < 0:
      inverseValue += reducedModulus
    stepValue = multiplyModulo(differenceModulo, inverseValue, reducedModulus)

  let combinedModulus = resultModulus * reducedModulus
  var candidate = (resultResidue + resultModulus * stepValue) mod combinedModulus
  if candidate < 0:
    candidate += combinedModulus
  resultResidue = candidate
  resultModulus = combinedModulus

appendOutput($resultResidue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Horner evaluation builds the suffix value and its modulus together.
The step jumps to the residue that satisfies the new constraint.
The final residue is printed as one decimal line.

## Complexity

Each constraint costs one suffix pass and one merge.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | one input string |
| suffix evaluation | one pass per suffix character | constant |
| congruence merge | logarithmic gcd per constraint | constant |
| output | one line | block buffer |

Ten constraints stay far below the time limit.

| measure | Big O |
|---|---|
| time | O(total suffix length times log of the modulus) |
| space | O(total input bytes) |

Trying every candidate number would take up to 10 to the 18 steps, so the theorem removes the search.
The residue after all merges is the smallest answer by construction.
