# BORING2 — Boring Factorials (Extended) (SPOJ)

<https://www.spoj.com/problems/BORING2/>

## Problem

Compute N! modulo a prime P where N and P can have 100 digits and differ by less than 10^6. Wilson's theorem reduces the factorial to a short tail product and one inverse.

Input starts with T, the number of test cases. Each later line holds two integers N and P, where P is prime. Print N! mod P on one line per case. The answer has at most 100 digits.

| item | bound |
|---|---|
| test cases T | 1 to 999 |
| integer N | 0 < N < 10^100 |
| prime P | 1 < P < 10^100 |
| distance | \|N - P\| < 10^6 |
| judge limit | 15000 ms, 1536 MB |

When N reaches P or exceeds it, the factorial contains P and the answer is zero.

Sample input:

```
3
2 5
5 11
21 71
```

Sample output:

```
2
10
6
```

## Idea

Replace a huge factorial with its missing tail, like balancing a scale by weighing only the few weights that were left off. Wilson's theorem gives (P-1)! ≡ -1 modulo P. The numbers from N+1 to P-1 are the negatives of 1 through d, where d = P-1-N. Their product is (-1)^d × d!, so N! is minus the inverse of that short factorial. Base-10^9 limbs carry the large values. Multiplying from 1 to N is impossible at 100 digits. Use Wilson's tail, a binary inverse, and a small limb library.

## Why It Works

1. Wilson's theorem gives (P-1)! ≡ -1 (mod P) for prime P.
2. When N < P, the identity (P-1)! = N! × (N+1) × … × (P-1) holds.
3. Each missing factor P-j equals -j, for j from 1 to d = P-1-N.
4. The missing product equals (-1)^d × d!, and d < 10^6 because N stays positive.
5. Small factors are grouped into int64 chunks before each modular reduction.
6. Binary extended Euclid inverts d! with halvings and subtractions, and needs no power of P-2.
7. An odd d keeps the inverse; an even d negates it modulo P.

| term | meaning |
|---|---|
| `parseBig` | converts a decimal token into base-10^9 limbs |
| `moduloBig` | reduces a limb array modulo the prime using normalized long division |
| `inverseMod` | binary extended Euclid returning a modular inverse |
| `chunkProduct` | product of small factors that still fits an int64 |
| `missingCount` | d = P - 1 - N, read from the low limb of the difference |

For N = 5 and P = 11, d = 5. The tail factors read 1, 2, 3, 4, 5, and 120 mod 11 = 10. The inverse of 10 modulo 11 is 10. Since d is odd, the answer stays 10. For N = 2 and P = 5, d = 2 and the inverse of 2 is 3, so the answer is 5 - 3 = 2.

Normalization in `moduloBig` scales the divisor so its top limb is at least half the base. Without that step, the quotient estimate can be far too large and the correction loop becomes slow.

## Code

**Input and limb basics.** The reader loads tokens, and the first limb helpers handle decimal values.

```nim
const flushBlockBytes = 1 shl 17
const decimalBase = 1000000000

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc trimBig(value: var seq[int]) =
  while value.len > 1 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc parseBig(text: string): seq[int] =
  result = @[0]
  for characterIndex in 0 .. text.len - 1:
    let digitValue = int(text[characterIndex]) - 48
    var carry = digitValue
    for limbIndex in 0 .. result.len - 1:
      let limbValue = result[limbIndex] * 10 + carry
      result[limbIndex] = limbValue mod decimalBase
      carry = limbValue div decimalBase
    if carry > 0:
      result.add carry
  trimBig(result)

proc compareBig(left: seq[int], right: seq[int]): int =
  if left.len != right.len:
    return if left.len < right.len: -1 else: 1
  for limbIndex in countdown(left.len - 1, 0):
    if left[limbIndex] != right[limbIndex]:
      return if left[limbIndex] < right[limbIndex]: -1 else: 1
  return 0

proc subtractBig(left: seq[int], right: seq[int]): seq[int] =
  result = newSeq[int](left.len)
  var borrow = 0
  for limbIndex in 0 .. left.len - 1:
    var difference = left[limbIndex] - borrow
    if limbIndex < right.len:
      difference -= right[limbIndex]
    if difference < 0:
      difference += decimalBase
      borrow = 1
    else:
      borrow = 0
    result[limbIndex] = difference
  trimBig(result)

proc addBig(left: seq[int], right: seq[int]): seq[int] =
  result = @[]
  var carry = 0
  for limbIndex in 0 .. max(left.len, right.len) - 1:
    var limbValue = carry
    if limbIndex < left.len:
      limbValue += left[limbIndex]
    if limbIndex < right.len:
      limbValue += right[limbIndex]
    result.add(limbValue mod decimalBase)
    carry = limbValue div decimalBase
  if carry > 0:
    result.add carry
  return result
```

Each limb stores nine decimal digits.
Parsing multiplies the growing value by ten per digit.
Compare, add, and subtract walk limbs from low to high.

**Small multiplication and division.** Normalized long division reduces a limb array to a residue.

```nim
proc multiplyBySmall(value: seq[int], factor: int64): seq[int] =
  var factorDigits: array[0 .. 2, int64]
  var factorLength = 0
  var remaining = factor
  while remaining > 0:
    factorDigits[factorLength] = remaining mod decimalBase
    remaining = remaining div decimalBase
    factorLength += 1
  result = newSeq[int](value.len + factorLength)
  for indexValue in 0 .. value.len - 1:
    var innerCarry = 0'i64
    for indexFactor in 0 .. factorLength - 1:
      let limbPosition = indexValue + indexFactor
      let limbValue = int64(result[limbPosition]) + int64(value[indexValue]) * factorDigits[indexFactor] + innerCarry
      result[limbPosition] = int(limbValue mod decimalBase)
      innerCarry = limbValue div decimalBase
    var carryPosition = indexValue + factorLength
    while innerCarry > 0:
      let carryValue = int64(result[carryPosition]) + innerCarry
      result[carryPosition] = int(carryValue mod decimalBase)
      innerCarry = carryValue div decimalBase
      carryPosition += 1
  trimBig(result)

proc compareWindow(remainder: seq[int], shift: int, productValue: seq[int], windowLength: int): int =
  for index in countdown(windowLength - 1, 0):
    let leftLimb = remainder[shift + index]
    let rightLimb = if index < productValue.len: productValue[index] else: 0
    if leftLimb != rightLimb:
      return if leftLimb < rightLimb: -1 else: 1
  return 0

proc divideBySmall(value: seq[int], divisorValue: int): seq[int] =
  result = newSeq[int](value.len)
  var carry = 0'i64
  for index in countdown(value.len - 1, 0):
    let limbValue = carry * decimalBase + int64(value[index])
    result[index] = int(limbValue div int64(divisorValue))
    carry = limbValue mod int64(divisorValue)
  trimBig(result)

proc moduloBig(dividend: seq[int], divisor: seq[int]): seq[int] =
  let scale = decimalBase div (divisor[divisor.len - 1] + 1)
  let scaledDividend = multiplyBySmall(dividend, int64(scale))
  let scaledDivisor = multiplyBySmall(divisor, int64(scale))
  var remainder = newSeq[int](scaledDividend.len + 1)
  for index in 0 .. scaledDividend.len - 1:
    remainder[index] = scaledDividend[index]
  let divisorLength = scaledDivisor.len
  if scaledDividend.len < divisorLength:
    return divideBySmall(remainder, scale)
  for shift in countdown(scaledDividend.len - divisorLength, 0):
    let topPair = int64(remainder[shift + divisorLength]) * decimalBase + int64(remainder[shift + divisorLength - 1])
    var estimate = topPair div int64(scaledDivisor[divisorLength - 1])
    if estimate >= decimalBase:
      estimate = decimalBase - 1
    var productValue = multiplyBySmall(scaledDivisor, estimate)
    while compareWindow(remainder, shift, productValue, divisorLength + 1) < 0:
      estimate -= 1
      productValue = multiplyBySmall(scaledDivisor, estimate)
    var borrow = 0
    for index in 0 .. divisorLength:
      let subLimb = if index < productValue.len: productValue[index] else: 0
      var difference = remainder[shift + index] - subLimb - borrow
      if difference < 0:
        difference += decimalBase
        borrow = 1
      else:
        borrow = 0
      remainder[shift + index] = difference
  return divideBySmall(remainder, scale)
```

The factor splits into at most three base-10^9 digits.
The divisor is scaled up before each long-division step.
The final division by that scale restores the true residue.

**Binary inverse.** Halvings and subtractions build the inverse without exponentiation.

```nim
proc isEven(value: seq[int]): bool =
  return (value[0] and 1) == 0

proc shiftRightOne(value: seq[int]): seq[int] =
  result = newSeq[int](value.len)
  var carryDown = 0
  for index in countdown(value.len - 1, 0):
    result[index] = value[index] div 2 + carryDown
    if (value[index] and 1) == 1:
      carryDown = decimalBase div 2
    else:
      carryDown = 0
  trimBig(result)

proc subtractMod(left: seq[int], right: seq[int], modulus: seq[int]): seq[int] =
  if compareBig(left, right) >= 0:
    return subtractBig(left, right)
  return subtractBig(addBig(modulus, left), right)

proc inverseMod(value: seq[int], modulus: seq[int]): seq[int] =
  let oneValue = @[1]
  var upper = value
  var lower = modulus
  var upperCoefficient: seq[int] = @[1]
  var lowerCoefficient: seq[int] = @[0]
  while compareBig(upper, oneValue) != 0 and compareBig(lower, oneValue) != 0:
    while isEven(upper):
      upper = shiftRightOne(upper)
      if isEven(upperCoefficient):
        upperCoefficient = shiftRightOne(upperCoefficient)
      else:
        upperCoefficient = shiftRightOne(addBig(upperCoefficient, modulus))
    while isEven(lower):
      lower = shiftRightOne(lower)
      if isEven(lowerCoefficient):
        lowerCoefficient = shiftRightOne(lowerCoefficient)
      else:
        lowerCoefficient = shiftRightOne(addBig(lowerCoefficient, modulus))
    if compareBig(upper, lower) >= 0:
      upper = subtractBig(upper, lower)
      upperCoefficient = subtractMod(upperCoefficient, lowerCoefficient, modulus)
    else:
      lower = subtractBig(lower, upper)
      lowerCoefficient = subtractMod(lowerCoefficient, upperCoefficient, modulus)
  var resultValue = upperCoefficient
  if compareBig(upper, oneValue) != 0:
    resultValue = lowerCoefficient
  while compareBig(resultValue, modulus) >= 0:
    resultValue = subtractBig(resultValue, modulus)
  return resultValue
```

An odd limb passes half a base to the limb below it.
Each coefficient stays reduced modulo the prime.
The loop ends when one side reaches one.

**Tail product and report.** The program builds d! in chunks, inverts it, and writes the answer.

```nim
proc appendBigDecimal(value: seq[int]) =
  var highest = value.len - 1
  appendOutput($value[highest])
  var position = highest - 1
  while position >= 0:
    var limbText = $value[position]
    while limbText.len < 9:
      limbText = "0" & limbText
    appendOutput(limbText)
    position -= 1

let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  let limitText = nextToken(inputData, scanPos)
  let primeText = nextToken(inputData, scanPos)
  let factorialIndex = parseBig(limitText)
  let primeModulus = parseBig(primeText)
  if compareBig(factorialIndex, primeModulus) >= 0:
    appendOutput("0\n")
    continue
  let missingValue = subtractBig(subtractBig(primeModulus, factorialIndex), @[1])
  let missingCount = int64(missingValue[0])
  var chunkProduct = 1'i64
  var factorialResidue: seq[int] = @[1]
  var factorValue = 1'i64
  while factorValue <= missingCount:
    if chunkProduct <= high(int64) div factorValue:
      chunkProduct = chunkProduct * factorValue
    else:
      factorialResidue = moduloBig(multiplyBySmall(factorialResidue, chunkProduct), primeModulus)
      chunkProduct = factorValue
    factorValue += 1
  factorialResidue = moduloBig(multiplyBySmall(factorialResidue, chunkProduct), primeModulus)
  if compareBig(factorialResidue, @[0]) == 0:
    appendOutput("0\n")
    continue
  let inverseValue = inverseMod(factorialResidue, primeModulus)
  if (missingCount and 1'i64) == 0:
    appendBigDecimal(subtractBig(primeModulus, inverseValue))
  else:
    appendBigDecimal(inverseValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Cases with N at least P write zero at once.
The guard flushes a chunk before an int64 multiply overflows.
The parity of missingCount selects the final sign.

## Complexity

Each case multiplies at most 10^6 small factors and inverts one 100-digit residue.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| tail product | d small factor steps | one limb array |
| inversion | about 330 halving rounds | a few limb arrays |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(d + L^2) |
| space | O(L) |

Here L is the limb count of P, about 12 for 100 digits. Multiplying from 1 to N needs about 10^100 steps. Wilson's tail reduces that to at most 10^6 steps.
