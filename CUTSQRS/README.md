# CUTSQRS — Cutting off Squares (SPOJ)
<https://www.spoj.com/problems/CUTSQRS/>

## Problem

Two players trim squares from a rectangle, and a bored spectator counts the characters in the game log.
The program must predict that count without playing the game.

Two players cut squares from a rectangle with sides `a` and `b`, where `a` is at most `b`.
Each turn removes at least one square of side `a` touching three sides of the current rectangle.
The player removing the last piece wins.
Michael records the number of possible move sequences, the number of winning sequences for the first player, and the word `first` or `second`.
Print the total character count of those three records, with spaces excluded.

Read `t` test cases, then `t` lines each holding `a` and `b`.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Test cases `t` | up to 10000 |
| Rectangle sides | 1 ≤ a ≤ b ≤ 10^9 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Large quotients make the sequence count far too big to print.

The sample input and expected output follow verbatim.

```
2
1 1
2 3
```

```
7
8
```

A square prints 7 characters and the 2 by 3 case prints 8.

## Idea

Every turn follows the Euclidean algorithm (repeated division by remainders), like trading a rectangle for a smaller one.
Let `q` be `b div a`.
Each chain step with quotient `q` adds `q - 1` to an exponent.
The sequence count is 2^sum and the winning count is 2^(sum - 1).

The program computes only decimal digit counts of those powers.
It uses a high-precision product of the exponent and log10(2).
The winner depends on the starting run of quotients equal to one.

Cost per case is one Euclidean chain of O(log b) steps plus two digit counts.
Counting digits of the powers replaces building the powers themselves.

## Why It Works

Four facts prove the method.

1. A turn removing `k` squares leaves sides `a` and `b - k*a`.
   Removing `q` squares ends the game when the remainder is zero.
2. The `q - 1` smaller choices each halve the sequences reaching the smaller state.
   The exponent therefore grows by `q - 1`.
3. Half of the sequences have odd length, so the winning count is 2^(sum - 1).
4. The winner flips once per leading quotient equal to one.
   It stops flipping at the first larger quotient.

The answer combines three character counts.

| Term | Meaning |
| --- | --- |
| `quotientSum` | sum of `q - 1` over the Euclidean chain |
| `powerOfTwoDigitCount` | decimal digits of 2^exponent from log10(2) |
| `leadingOnes` | count of leading quotients equal to one |
| `wordLength` | 5 for `first` and 6 for `second` |

The answer adds those three counts.

A script walks the chain for starting sides 43 and 100 and prints each value.

```
start (43, 100)
quotients 2 3 14
sum (2-1) + (3-1) + (14-1) = 16
sequences 2^16 = 65536 -> 5 digits
winning  2^15 = 32768 -> 5 digits
word first -> 5 characters
answer 5 + 5 + 5 = 15
```

The script never materializes the enormous power of two.

## Code

**Constants.**

```nim
import math

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  splitFactor = 134217729.0
  logTenTwoHigh = 0.30102999566398119521373889472449302677
  logTenTwoLow = -2.8037281277851704e-18
```

The split factor comes from the Dekker 53-bit split. The two logarithm constants store log10(2) with an error term. The output block holds 256 KiB.

**Integer scanner.**

```nim
proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] < '0':
    inc i
  result = 0
  while i < dataLength and inputData[i] >= '0':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i
```

The first loop stops at the next digit. The second loop consumes the remaining digits. The scanner touches each input byte once and allocates nothing.

**High-precision product.**

```nim
proc splitDouble(value: float): tuple[highPart, lowPart: float] =
  let scaled = splitFactor * value
  result.highPart = scaled - (scaled - value)
  result.lowPart = value - result.highPart

proc highPrecisionProduct(factorLeft, factorRight: float): tuple[product, error: float] =
  let product = factorLeft * factorRight
  let leftParts = splitDouble(factorLeft)
  let rightParts = splitDouble(factorRight)
  result.product = product
  result.error = ((leftParts.highPart * rightParts.highPart - product) +
                   leftParts.highPart * rightParts.lowPart +
                   leftParts.lowPart * rightParts.highPart) +
                   leftParts.lowPart * rightParts.lowPart
```

splitDouble separates a float into a high part and a low part. highPrecisionProduct recovers the rounding error of the product. Both procedures cost constant time.

**Digit count.**

```nim
proc powerOfTwoDigitCount(exponent: int): int =
  let productParts = highPrecisionProduct(float(exponent), logTenTwoHigh)
  let correction = productParts.error + float(exponent) * logTenTwoLow
  let wholePart = floor(productParts.product)
  let fractionalPart = productParts.product - wholePart
  result = int(wholePart) + int(floor(fractionalPart + correction)) + 1
```

The exponent is multiplied by log10(2) in high precision. The error term corrects the fractional part before the floor. The result is the decimal digit count of a power of two.

**Euclidean chain.**

```nim
proc solveCase(sideLeft, sideRight: int): int =
  if sideLeft == sideRight:
    return 7
  var shorterSide = sideLeft
  var longerSide = sideRight
  var quotientSum = 0
  var leadingOnes = 0
  var countingLeadingOnes = true
  while shorterSide != 0:
    let quotient = longerSide div shorterSide
    if countingLeadingOnes:
      if quotient == 1:
        inc leadingOnes
      else:
        countingLeadingOnes = false
    quotientSum += quotient - 1
    let remainder = longerSide mod shorterSide
    longerSide = shorterSide
    shorterSide = remainder
  let sequenceDigits = powerOfTwoDigitCount(quotientSum)
  let winningDigits = powerOfTwoDigitCount(quotientSum - 1)
  let wordLength = if leadingOnes mod 2 == 0: 5 else: 6
  result = sequenceDigits + winningDigits + wordLength
```

The loop ends when shorterSide reaches zero. It accumulates the exponent and counts leading quotients equal to one. The chain has O(log b) steps. A square returns 7 directly.

**Driver.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""
var j = 0
while j < caseCount:
  let sideLeft = nextInt(inputData, i)
  let sideRight = nextInt(inputData, i)
  outputBuffer.add $solveCase(sideLeft, sideRight)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  inc j
if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The driver loops once per test case. Each answer is appended to one output buffer. The final write handles a short tail.

## Complexity

The phases and their costs follow.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Per case | O(log b) | constant |
| Output flush | O(output bytes) | one output block |

The exponent never grows beyond a few billion, so each digit count stays cheap.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(input bytes + output bytes + t log b) |
| Space | O(input bytes + block bytes) |

A naive method that builds 2^sum as a big integer needs 2^sum bits and cannot fit.
