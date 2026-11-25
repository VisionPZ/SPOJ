# COMPLEX2 — HELP ABHISHEK(version-II) (SPOJ)

<https://www.spoj.com/problems/COMPLEX2/>

## Problem

The task asks for the product of x minus each nontrivial nth root of unity. Report the result as the unreduced fraction (x^n - 1)/(x - 1).

The first line holds the number of test cases. Each following line holds two integers x and n. Print one fraction per case, with the numerator and denominator separated by a slash.

| item | bound |
|---|---|
| base x | 2 to 1000 |
| exponent n | 2 to 1000 |
| test cases | up to 410 |
| judge limit | 1000 ms, 1536 MB |

The exponent drives the design because x^n can contain thousands of digits.

Sample input:

```
1
5 10
```

Sample output:

```
9765624/4
```

## Idea

The root product collapses into one geometric sum, like folding a long strip so every interior crease meets its neighbor. The algorithm uses the identity (x^n - 1)/(x - 1) and prints that fraction without reducing it.

The numerator needs big integer arithmetic. The program multiplies a base-1000000000 number by x, n times, then subtracts one. Each multiplication touches only a few hundred limbs.

Expanding the product with complex numbers would accumulate rounding error. Dividing a fully built big integer by x - 1 would also cost more work than the direct fraction. The takeaway is to keep the closed form and build only its numerator.

## Why It Works

1. The nth roots of unity are the roots of z^n - 1.
2. The polynomial z^n - 1 factors as the product of z - w^k for k from 0 to n - 1.
3. Removing the factor z - 1 leaves the product from k = 1 to n - 1.
4. That remaining product equals (z^n - 1)/(z - 1), the geometric sum of powers of z.
5. For integer x the sum is an integer, yet the judge wants the unreduced numerator and denominator.
6. Base 1000000000 limbs keep each intermediate product below 10^12, well inside a machine word.

| term | meaning |
|---|---|
| `limbBase` | radix of the big integer, 10^9 per limb |
| `limbs` | little-endian digits of the running power x^n |
| `powerText` | routine that raises x to n and subtracts one |
| `carry` | overflow passed to the next limb during multiplication |
| `borrowIndex` | limb receiving a borrow during subtraction |
| `limbText` | renders one limb with optional leading zeros |

The table names the values and routines used by the big integer code.

A script trace for x = 5 and n = 10 sums powers from 1 to 5^9. That sum is 2441406. Multiplying by x - 1 = 4 gives 9765624, and the printed fraction is 9765624/4.

| step | value |
|---|---|
| geometric sum | 2441406 |
| denominator | 4 |
| numerator | 9765624 |
| printed answer | 9765624/4 |

The trace matches the sample byte for byte.

A second trace for x = 1000 and n = 3 reaches exactly 1000000000. The limbs are [0, 1] before subtraction. Borrowing turns them into [999999999, 0], and trimming the top zero yields the numerator 999999999.

No rounding occurs because every operation is integer arithmetic. The borrow loop handles the case where the lowest limb is zero, and the trim loop removes limbs that vanish after subtraction.

## Code

**Input and scanner.** The reader loads all lines and extracts each pair of integers.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbWidth = 9

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

The scanner advances one index per number.
Nine-digit limbs match `limbBase`.
All test cases share one input string.

**Output buffer and big integer.** One buffer collects text, and limb arithmetic builds the numerator.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc limbText(value: int, padded: bool): string =
  let rawText = $value
  if not padded:
    return rawText
  result = ""
  var zeroCount = limbWidth - rawText.len
  while zeroCount > 0:
    result.add '0'
    zeroCount -= 1
  result.add rawText

proc powerText(baseValue: int, exponentValue: int): string =
  var limbs: seq[int] = @[1]
  for stepIndex in 1 .. exponentValue:
    var carry = 0
    for limbIndex in 0 .. limbs.len - 1:
      let productValue = limbs[limbIndex] * baseValue + carry
      limbs[limbIndex] = productValue mod limbBase
      carry = productValue div limbBase
    while carry > 0:
      limbs.add carry mod limbBase
      carry = carry div limbBase
  limbs[0] = limbs[0] - 1
  var borrowIndex = 0
  while limbs[borrowIndex] < 0:
    limbs[borrowIndex] = limbs[borrowIndex] + limbBase
    borrowIndex += 1
    limbs[borrowIndex] = limbs[borrowIndex] - 1
  while limbs.len > 1 and limbs[limbs.len - 1] == 0:
    limbs.setLen(limbs.len - 1)
  result = limbText(limbs[limbs.len - 1], false)
  var limbIndex = limbs.len - 2
  while limbIndex >= 0:
    result.add limbText(limbs[limbIndex], true)
    limbIndex -= 1
  return result
```

Each multiplication pass carries into higher limbs.
The borrow loop keeps the numerator positive.
Lower limbs receive zero padding on output.

**Case loop.** Each case prints the numerator, a slash, and the small denominator.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let baseValue = nextInt(inputData, scanPos)
  let exponentValue = nextInt(inputData, scanPos)
  appendOutput(powerText(baseValue, exponentValue))
  appendOutput("/")
  appendOutput($(baseValue - 1))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes when the buffer grows large.
One newline follows every fraction.
The final write emits any buffered tail.

## Complexity

Each case performs n small multiplications and then renders the limbs.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| power build | n passes over up to 334 limbs | limb array |
| rendering | one pass over limbs | output buffer |
| output | buffered writes | block buffer |

Power building dominates every other phase.

| measure | Big O |
|---|---|
| time | O(n^2 log x) digit work per case |
| space | O(n log x) per case |

Building and dividing a full decimal expansion would add extra long-division passes. The closed form avoids that work and keeps the printed fraction exact.
