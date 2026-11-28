# CIRCLE_H — Three Circle Problem (HARD) (SPOJ)

<https://www.spoj.com/problems/CIRCLE_H/>

## Problem

Three circles touch each other pairwise. Compute the radius of the circle in the gap to 50 digits after the decimal point, truncated rather than rounded. Radii can have 30 digits, so fixed-width machine integers cannot hold the intermediate products.

| item | bound |
|---|---|
| test cases T | 1 to 100000 |
| radii R1, R2, R3 | 1 to 999999999999999999999999999999 |
| output | integer part, decimal point, exactly 50 digits |
| judge limit | 10000 ms, 1536 MB |

Curvature is the reciprocal of radius. Descartes' circle theorem gives the inner curvature from the three given curvatures. Multiplying through by the radii turns reciprocals into integer products and one square root.

Sample input:

```
3
1 1 1
10 10 10
23 46 69
```

Sample output:

```
0.15470053837925152901829756100391491129520350254025
1.54700538379251529018297561003914911295203502540253
6.00000000000000000000000000000000000000000000000000
```

## Idea

Scale the square root far beyond the printed precision, like measuring a room in millimetres before reporting meters. The answer equals P divided by S plus twice the square root of P times Q. P is the product of radii. S is the sum of pairwise products. Q is the sum of radii. Integer limbs hold P, S, and Q; Newton iteration extracts the square root with 60 fractional digits; one long division produces the 50 printed digits. Machine floating point would lose most of those digits, so integer arithmetic is required. Use the scaled integer formula.

## Why It Works

1. Curvature is the reciprocal of radius, and Descartes' theorem gives the inner curvature as k1 + k2 + k3 + 2*sqrt(k1*k2 + k2*k3 + k3*k1).
2. Let P = R1*R2*R3, S = R1*R2 + R2*R3 + R3*R1, and Q = R1 + R2 + R3.
3. The inner radius is P / (S + 2*sqrt(P*Q)).
4. Scaling P*Q by 10^120 makes its integer square root equal sqrt(P*Q) times 10^60.
5. Dividing P*10^110 by S*10^60 plus twice that root yields the radius times 10^50.
6. Splitting the quotient at its last 50 digits gives the truncated decimal answer.

| term | meaning |
|---|---|
| `LargeNumber` | unsigned integer stored in base 10^9 limbs |
| `precisionDigits` | 60 fractional digits kept for the square root |
| `fractionDigits` | 50 fractional digits printed |
| `scaledRoot` | integer square root of P*Q scaled by 10^60 |
| `scaledRadius` | radius multiplied by 10^50 |

For three equal radii of one, P = 1, S = 3, and Q = 3. The root term is sqrt(3), and the denominator is 3 + 2*sqrt(3). The printed value starts 0.1547005383, matching the first sample line.

| radii | P | S + 2*sqrt(P*Q) | printed start |
|---|---|---|---|
| 1 1 1 | 1 | 6.4641016151 | 0.1547005383 |
| 10 10 10 | 1000 | 646.410161513 | 1.5470053837 |
| 23 46 69 | 73002 | 12167 | 6.0000000000 |

The extra ten digits of root precision guard the final 50 digits against truncation error.

## Code

**Setup and input.** One integer buffer handles both the small test count and the large radii tokens.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const precisionDigits = 60
const fractionDigits = 50

type LargeNumber = seq[int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

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

Radii arrive as digit strings, so token parsing keeps every digit.
All output lines pass through one buffer.

**Big integer primitives.** Limbs of base 10^9 support parsing, addition, and multiplication.

```nim
proc normalizeNumber(value: var LargeNumber) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen value.len - 1

proc fromDigits(text: string, startPos: int, digitCount: int): LargeNumber =
  result = newSeq[int](0)
  var endPos = startPos + digitCount
  while endPos > startPos:
    var groupStart = endPos - 9
    if groupStart < startPos:
      groupStart = startPos
    var limb = 0
    for digitPos in groupStart .. endPos - 1:
      limb = limb * 10 + int(text[digitPos]) - 48
    result.add limb
    endPos = groupStart
  normalizeNumber(result)

proc decimalDigits(value: int): int =
  result = 1
  var remaining = value
  while remaining >= 10:
    remaining = remaining div 10
    result += 1

proc addNumbers(left: LargeNumber, right: LargeNumber): LargeNumber =
  result = newSeq[int](max(left.len, right.len))
  var carry = 0
  for index in 0 .. result.len - 1:
    var total = carry
    if index < left.len:
      total = total + left[index]
    if index < right.len:
      total = total + right[index]
    result[index] = total mod limbBase
    carry = total div limbBase
  if carry > 0:
    result.add carry
  normalizeNumber(result)

proc multiplySmall(value: LargeNumber, factor: int64): LargeNumber =
  if value.len == 0 or factor == 0:
    return newSeq[int](0)
  result = newSeq[int](value.len)
  var carry: int64 = 0
  for index in 0 .. value.len - 1:
    let product = int64(value[index]) * factor + carry
    result[index] = int(product mod int64(limbBase))
    carry = product div int64(limbBase)
  while carry > 0:
    result.add int(carry mod int64(limbBase))
    carry = carry div int64(limbBase)
  normalizeNumber(result)

proc multiplyNumbers(left: LargeNumber, right: LargeNumber): LargeNumber =
  if left.len == 0 or right.len == 0:
    return newSeq[int](0)
  result = newSeq[int](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry: int64 = 0
    for rightIndex in 0 .. right.len - 1:
      let position = leftIndex + rightIndex
      let product = int64(result[position]) + int64(left[leftIndex]) * int64(right[rightIndex]) + carry
      result[position] = int(product mod int64(limbBase))
      carry = product div int64(limbBase)
    var position = leftIndex + right.len
    while carry > 0:
      let product = int64(result[position]) + carry
      result[position] = int(product mod int64(limbBase))
      carry = product div int64(limbBase)
      position += 1
  normalizeNumber(result)
```

Products use 64-bit intermediates before splitting into limbs.
Normalization removes leading zero limbs after every operation.

**Division and square root.** Long division and Newton iteration work on the same limb format.

```nim
proc compareNumbers(left: LargeNumber, right: LargeNumber): int =
  if left.len != right.len:
    if left.len < right.len:
      return -1
    return 1
  var index = left.len - 1
  while index >= 0:
    if left[index] != right[index]:
      if left[index] < right[index]:
        return -1
      return 1
    index -= 1
  return 0

proc subtractNumbers(left: LargeNumber, right: LargeNumber): LargeNumber =
  result = newSeq[int](left.len)
  var borrow = 0
  var index = 0
  while index < left.len:
    var difference = left[index] - borrow
    if index < right.len:
      difference = difference - right[index]
    if difference < 0:
      difference = difference + limbBase
      borrow = 1
    else:
      borrow = 0
    result[index] = difference
    index += 1
  normalizeNumber(result)

proc shiftDecimal(value: LargeNumber, digits: int): LargeNumber =
  if value.len == 0:
    return newSeq[int](0)
  let wholeLimbs = digits div 9
  let extraDigits = digits mod 9
  result = newSeq[int](value.len + wholeLimbs)
  for index in 0 .. value.len - 1:
    result[index + wholeLimbs] = value[index]
  if extraDigits > 0:
    var multiplier = 1
    for _ in 1 .. extraDigits:
      multiplier = multiplier * 10
    return multiplySmall(result, int64(multiplier))
  return result

proc divideNumbers(dividend: LargeNumber, divisor: LargeNumber): tuple[quotient: LargeNumber, remainder: LargeNumber] =
  if compareNumbers(dividend, divisor) < 0:
    return (newSeq[int](0), dividend)
  var quotient = newSeq[int](dividend.len)
  var remainder = newSeq[int](0)
  var index = dividend.len - 1
  while index >= 0:
    remainder = multiplySmall(remainder, int64(limbBase))
    if dividend[index] > 0:
      remainder = addNumbers(remainder, @[dividend[index]])
    var low = 0
    var high = limbBase - 1
    while low < high:
      let middle = (low + high + 1) div 2
      if compareNumbers(multiplySmall(divisor, int64(middle)), remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[index] = low
    if low > 0:
      remainder = subtractNumbers(remainder, multiplySmall(divisor, int64(low)))
    index -= 1
  normalizeNumber(quotient)
  return (quotient, remainder)

proc halfNumber(value: LargeNumber): LargeNumber =
  result = newSeq[int](value.len)
  var carry = 0
  var index = value.len - 1
  while index >= 0:
    let current = value[index] + carry * limbBase
    result[index] = current div 2
    carry = current mod 2
    index -= 1
  normalizeNumber(result)

proc isqrtNumber(value: LargeNumber): LargeNumber =
  if value.len == 0:
    return newSeq[int](0)
  let digitCount = (value.len - 1) * 9 + decimalDigits(value[value.len - 1])
  var guess = shiftDecimal(@[1], (digitCount + 1) div 2)
  while true:
    let division = divideNumbers(value, guess)
    let nextGuess = halfNumber(addNumbers(guess, division.quotient))
    if compareNumbers(nextGuess, guess) >= 0:
      return guess
    guess = nextGuess

proc numberToString(value: LargeNumber): string =
  if value.len == 0:
    return "0"
  result = $value[value.len - 1]
  var index = value.len - 2
  while index >= 0:
    let limbText = $value[index]
    for _ in 1 .. 9 - limbText.len:
      result.add '0'
    result.add limbText
    index -= 1
```

Borrows move from the low limb upward during subtraction.
Newton iteration stops once the next estimate no longer decreases.

**Driver.** Each case builds P, S, and Q, then divides the scaled numerator by the scaled denominator.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let radiusOneToken = nextToken(inputData, scanPos)
  let radiusTwoToken = nextToken(inputData, scanPos)
  let radiusThreeToken = nextToken(inputData, scanPos)
  let radiusOne = fromDigits(radiusOneToken, 0, radiusOneToken.len)
  let radiusTwo = fromDigits(radiusTwoToken, 0, radiusTwoToken.len)
  let radiusThree = fromDigits(radiusThreeToken, 0, radiusThreeToken.len)
  let productRadii = multiplyNumbers(multiplyNumbers(radiusOne, radiusTwo), radiusThree)
  let sumPairwise = addNumbers(addNumbers(multiplyNumbers(radiusOne, radiusTwo), multiplyNumbers(radiusTwo, radiusThree)), multiplyNumbers(radiusThree, radiusOne))
  let sumRadii = addNumbers(addNumbers(radiusOne, radiusTwo), radiusThree)
  let rootInput = shiftDecimal(multiplyNumbers(productRadii, sumRadii), 2 * precisionDigits)
  let scaledRoot = isqrtNumber(rootInput)
  let denominator = addNumbers(shiftDecimal(sumPairwise, precisionDigits), multiplySmall(scaledRoot, 2))
  let numerator = shiftDecimal(productRadii, fractionDigits + precisionDigits)
  let scaledRadius = divideNumbers(numerator, denominator).quotient
  let digitText = numberToString(scaledRadius)
  var integerPart = "0"
  var fractionPart = ""
  if digitText.len > fractionDigits:
    integerPart = digitText[0 .. digitText.len - fractionDigits - 1]
    fractionPart = digitText[digitText.len - fractionDigits .. digitText.len - 1]
  else:
    for _ in 1 .. fractionDigits - digitText.len:
      fractionPart.add '0'
    fractionPart.add digitText
  appendOutput(integerPart)
  appendOutput(".")
  appendOutput(fractionPart)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The denominator and numerator share the same 10^60 scale.
Splitting the quotient at 50 digits performs the required truncation.

## Complexity

Each case performs a fixed number of big integer operations on numbers of at most a few hundred digits.

| phase | time | space |
|---|---|---|
| input read | one pass over radius tokens | one input string |
| products and sums | constant limb multiplications | a few big integers |
| square root | Newton steps on the scaled product | one big quotient |
| division and output | one long division per case | one block buffer |

| measure | Big O |
|---|---|
| time per case | O(D squared) limb work for D about 250 digits |
| space per case | O(D) limbs |

Floating point with a fixed mantissa would lose the tail digits that this limb arithmetic preserves.

The 60-digit root scale keeps the printed 50 digits stable across the full radius range.
