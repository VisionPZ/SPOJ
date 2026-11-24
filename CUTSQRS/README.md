## Problem

Two players cut squares from a rectangle with sides a and b, where a is at most b.
Each turn removes one or more squares of side a that touch three sides of the current rectangle.
The player who removes the last piece wins.
Michael records the number of possible game sequences, the number where the first player wins, and the word first or second.
Print the character count of those three records, without spaces.

The input bounds and judge limits are:

| Item | Bound |
| --- | --- |
| Test cases | t ≤ 10000 |
| Rectangle sides | 1 ≤ a ≤ b ≤ 10^9 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Large quotients make the sequence count far too big to print.

## Idea

Every turn removes a whole number of squares, so the side lengths follow the Euclidean algorithm.
One step with quotient q, meaning b div a, adds q − 1 to an exponent.
The sequence count is 2 raised to that exponent, and exactly half of the sequences have odd length.
We compute only the decimal digit counts of those powers with high-precision logarithms.
The winner depends on the starting run of quotients equal to one.

Each case costs one Euclidean chain and two digit counts, so the time is O(log b).

## Why It Works

A turn that removes k squares leaves sides a and b − k*a.
Let q be b div a and r be b mod a.
Removing q squares ends the game when r is zero, and otherwise it leaves the smaller state (r, a).
The q − 1 smaller choices each lead to a state with half the parent count.
The exponent grows by q − 1.

The answer has three terms:

answer = digits(2^sum) + digits(2^(sum - 1)) + wordLength

- The first term counts characters of the total sequence count.
- The second term counts characters of the winning count.
- The third term adds five for first or six for second.

The winner flips once per leading quotient equal to one, then stops flipping at the first larger quotient.

A script-generated example for the starting sides 43 and 100:

- start (43, 100)
- quotients 2, 3, 14
- sum (2-1) + (3-1) + (14-1) = 16
- sequences 2^16 = 65536, 5 digits
- winning 2^15 = 32768, 5 digits
- word first, 5 characters
- answer 5 + 5 + 5 = 15

## Code

The constants fix the scanner radix, the flush size, and the logarithm words:

```nim
import math

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  splitFactor = 134217729.0
  logTenTwoHigh = 0.30102999566398119521373889472449302677
  logTenTwoLow = -2.8037281277851704e-18
```

The scanner walks the whole input buffer.
Its loops end at `dataLength`, the buffer length.
It never allocates a token and costs O(input bytes).

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

The split keeps the exact product and its error apart.
The split factor comes from Dekker's 53-bit split.
This step costs constant time.

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

The digit count adds the error term before taking the floor.
A plain float product loses the fractional part near large exponents.
This step costs constant time.

```nim
proc powerOfTwoDigitCount(exponent: int): int =
  let productParts = highPrecisionProduct(float(exponent), logTenTwoHigh)
  let correction = productParts.error + float(exponent) * logTenTwoLow
  let wholePart = floor(productParts.product)
  let fractionalPart = productParts.product - wholePart
  result = int(wholePart) + int(floor(fractionalPart + correction)) + 1
```

The Euclidean loop ends when `shorterSide` reaches zero.
That chain has O(log b) steps.
The code never builds the enormous power of two.

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

The driver loops `caseCount` times, once per test case.
It accumulates answers and writes one block at a time.
The final flush handles a short tail and costs O(output bytes).

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

## Complexity

Input scanning takes O(input bytes).
Each case walks one Euclidean chain and computes two digit counts.
Output flushing takes O(output bytes).

Total time is O(input bytes + output bytes + t log b).
Total space is O(input bytes + block bytes).
A naive method that builds the count as a big integer would need 2^sum bits and cannot fit.

The cost splits into three phases.

| Phase | Time | Extra space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Per case | O(log b) | constant |
| Output flush | O(output bytes) | one output block |

The program never materializes the enormous count.
