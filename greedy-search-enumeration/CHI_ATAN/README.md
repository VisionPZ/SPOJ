# CHI_ATAN — The real arctangent (SPOJ)

<https://www.spoj.com/problems/CHI_ATAN/>

## Problem

Compute the first 101 significant decimal digits of arctan(x) for each decimal x in [0, 10].
Drop the decimal point and all trailing zero digits. Truncate; never round.
The first line gives the case count. Each later line holds one decimal number.

| item | bound |
|---|---|
| test cases | not stated; generated inputs use about 160 |
| input | 0 <= x <= 10, at most 101 decimal digits |
| output | 101 significant digits, point and trailing zeros removed |
| precision tiers | 304, 200, and 120 fractional digits |
| judge limit | 1000 ms, 1536 MB |

The 304-digit tier protects inputs near 1e-101. The 120-digit tier covers ordinary inputs.

Sample input:

```
3
0
1
2.718281828459045235360287
```

Sample output:

```
0
78539816339744830961566084581987572104929234984377645524373614807695410157155224965700870633552926699
12182829050172776217604617127291832691014807688333489455796019635447595534415986839011077205055833227
```

## Idea

One ordinary case costs about 13 divisions and 30 series terms on 14 limbs.
Fixed-point integers hold 120, 200, or 304 fractional digits.
Dyadic pivot angles and pi are computed once per tier and then reused.
Long division replaces repeated Newton reciprocals.
One output buffer flushes in blocks of 128 KiB.

## Why It Works

1. Values above one use atan(x) = pi/2 - atan(1/x).
2. Pivots use atan(t) - atan(p) = atan((t-p)/(1+tp)).
3. Thirteen dyadic pivots keep the residual below 1/256.
4. The series stops when its term reaches zero at the tier precision.
5. The smallest tier leaves at least 14 guard digits beyond the 101 printed digits.
6. Long division estimates one limb with floats, then corrects with exact comparisons.

| term | meaning |
|---|---|
| `pivot` | a dyadic angle removed from the argument |
| `reduced` | residual tangent after applied pivots |
| `circleConstant` | pi from the Machin formula |
| `activeData` | precomputed constants for the selected tier |

All shifts truncate toward zero. The formatter truncates to 101 digits, then strips zeros.

Script trace for the sample case 1:

```
input 1 selects the 120-digit tier
pivot 1/2 leaves residual 0.3333333333333333333333333333333
pivot 1/4 leaves residual 0.0769230769230769230769230769230
the residual series ends after about 25 terms
first 101 digits: 785398163397448309615660...
```

## Code

**Constants and representation**.
```nim
const limbBase = 1000000000
const highPrecision = 304
const midPrecision = 200
const lowPrecision = 120
const outputDigits = 101
const flushBlockBytes = 1 shl 17
const smallPowers = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000]

type BigNumber = seq[int32]

var fractionalDigits = highPrecision```

**Limb arithmetic**.
```nim
proc trimBig(value: var BigNumber) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc multiplySmall(value: var BigNumber, factor: int32) =
  if factor == 0:
    value.setLen 0
    return
  var carry: int64 = 0
  for index in 0 .. value.len - 1:
    let combined = int64(value[index]) * int64(factor) + carry
    value[index] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
  while carry > 0:
    value.add int32(carry mod int64(limbBase))
    carry = carry div int64(limbBase)

proc scaledSmall(value: BigNumber, factor: int32): BigNumber =
  var copy = value
  multiplySmall(copy, factor)
  return copy

proc addSmall(value: var BigNumber, digit: int32) =
  var carry: int64 = int64(digit)
  var position = 0
  while carry > 0 and position < value.len:
    let combined = int64(value[position]) + carry
    value[position] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
    position = position + 1
  while carry > 0:
    value.add int32(carry mod int64(limbBase))
    carry = carry div int64(limbBase)

proc compareBig(left: BigNumber, right: BigNumber): int =
  if left.len > right.len: return 1
  if left.len < right.len: return -1
  for index in countdown(left.len - 1, 0):
    if left[index] > right[index]: return 1
    if left[index] < right[index]: return -1
  return 0```

```nim
proc addBig(left: BigNumber, right: BigNumber): BigNumber =
  var answer: BigNumber = @[]
  let longest = max(left.len, right.len)
  answer.setLen longest
  var carry: int64 = 0
  for index in 0 .. longest - 1:
    var combined = carry
    if index < left.len: combined = combined + int64(left[index])
    if index < right.len: combined = combined + int64(right[index])
    answer[index] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
  if carry > 0: answer.add int32(carry)
  trimBig(answer)
  return answer

proc subtractBig(left: BigNumber, right: BigNumber): BigNumber =
  var answer: BigNumber = @[]
  answer.setLen left.len
  var borrow: int64 = 0
  for index in 0 .. left.len - 1:
    var difference = int64(left[index]) - borrow
    if index < right.len: difference = difference - int64(right[index])
    if difference < 0:
      difference = difference + int64(limbBase)
      borrow = 1
    else:
      borrow = 0
    answer[index] = int32(difference)
  trimBig(answer)
  return answer

proc multiplyBig(left: BigNumber, right: BigNumber): BigNumber =
  if left.len == 0 or right.len == 0:
    return @[]
  var answer = newSeq[int32](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry: int64 = 0
    for rightIndex in 0 .. right.len - 1:
      let slot = leftIndex + rightIndex
      let combined = int64(answer[slot]) + int64(left[leftIndex]) * int64(right[rightIndex]) + carry
      answer[slot] = int32(combined mod int64(limbBase))
      carry = combined div int64(limbBase)
    var slot = leftIndex + right.len
    while carry > 0:
      let combined = int64(answer[slot]) + carry
      answer[slot] = int32(combined mod int64(limbBase))
      carry = combined div int64(limbBase)
      slot = slot + 1
  trimBig(answer)
  return answer

proc divideSmallInPlace(value: var BigNumber, divisor: int32) =
  var remainder: int64 = 0
  for index in countdown(value.len - 1, 0):
    let combined = remainder * int64(limbBase) + int64(value[index])
    value[index] = int32(combined div int64(divisor))
    remainder = combined mod int64(divisor)
  trimBig(value)

proc divideSmall(value: BigNumber, divisor: int32): BigNumber =
  var copy = value
  divideSmallInPlace(copy, divisor)
  return copy```

**Fixed-point shifts and division**.
```nim
proc powerOfTen(digitCount: int): BigNumber =
  var value: BigNumber = @[int32(1)]
  for _ in 1 .. digitCount:
    multiplySmall(value, 10)
  return value

proc multiplyByPowerOfTen(value: BigNumber, digitCount: int): BigNumber =
  if value.len == 0: return @[]
  let limbShift = digitCount div 9
  let digitRemainder = digitCount mod 9
  var answer = newSeq[int32](value.len + limbShift + 1)
  for index in 0 .. value.len - 1:
    answer[index + limbShift] = value[index]
  if digitRemainder > 0:
    multiplySmall(answer, int32(smallPowers[digitRemainder]))
  trimBig(answer)
  return answer

proc divideByPowerOfTen(value: BigNumber, digitCount: int): BigNumber =
  let limbShift = digitCount div 9
  if limbShift >= value.len: return @[]
  var answer = newSeq[int32](value.len - limbShift)
  for index in limbShift .. value.len - 1:
    answer[index - limbShift] = value[index]
  let digitRemainder = digitCount mod 9
  if digitRemainder > 0:
    divideSmallInPlace(answer, int32(smallPowers[digitRemainder]))
  trimBig(answer)
  return answer

proc decimalLength(value: BigNumber): int =
  if value.len == 0: return 1
  var topValue = int64(value[value.len - 1])```

```nim
proc multiplyFixed(left: BigNumber, right: BigNumber): BigNumber =
  return divideByPowerOfTen(multiplyBig(left, right), fractionalDigits)

proc quotientLongDivision(dividend: BigNumber, divisor: BigNumber): BigNumber =
  let divisorLen = divisor.len
  var quotient = newSeq[int32](dividend.len)
  var remainder: BigNumber = @[]
  let divisorHead = float(divisor[divisorLen - 1]) * float(limbBase) +
                    float(divisor[divisorLen - 2])
  for index in countdown(dividend.len - 1, 0):
    remainder.insert(int32(dividend[index]), 0)
    trimBig(remainder)
    if compareBig(remainder, divisor) < 0: continue
    let numeratorHead = float(remainder[remainder.len - 1]) * float(limbBase) +
                        float(remainder[remainder.len - 2])
    let scaleFactor = if remainder.len > divisorLen: float(limbBase) else: 1.0
    var estimate = int(numeratorHead / divisorHead * scaleFactor)
    if estimate >= int(limbBase): estimate = int(limbBase) - 1
    if estimate < 0: estimate = 0
    var product = scaledSmall(divisor, int32(estimate))
    while compareBig(remainder, product) < 0:
      estimate = estimate - 1
      product = scaledSmall(divisor, int32(estimate))
    while true:
      let nextProduct = scaledSmall(divisor, int32(estimate + 1))
      if compareBig(nextProduct, remainder) > 0: break
      estimate = estimate + 1
      product = nextProduct
    remainder = subtractBig(remainder, product)
    quotient[index] = int32(estimate)
  trimBig(quotient)
  return quotient

proc divideFixed(numerator: BigNumber, denominator: BigNumber): BigNumber =
  if numerator.len == 0 or denominator.len == 0: return @[]
  let dividend = multiplyByPowerOfTen(numerator, fractionalDigits)
  return quotientLongDivision(dividend, denominator)```

**Series, pivots, and pi**.
```nim
proc arctanSeries(argument: BigNumber): BigNumber =
  let squared = multiplyFixed(argument, argument)
  var term = argument
  var total = argument
  var sign = -1
  var denominator = 1
  while denominator <= 1400:
    term = multiplyFixed(term, squared)
    denominator = denominator + 2
    if sign > 0:
      total = addBig(total, divideSmall(term, int32(denominator)))
    else:
      let quotient = divideSmall(term, int32(denominator))
      if compareBig(total, quotient) < 0: break
      total = subtractBig(total, quotient)
    sign = -sign
    if term.len == 0: break
  return total

type PrecisionData = object
  unitValue: BigNumber
  pivots: seq[BigNumber]
  angles: seq[BigNumber]
  circle: BigNumber
  halfCircle: BigNumber

const pivotDenominators = [2, 8, 4, 16, 8, 32, 16, 64, 32, 128, 64, 256, 128]
const pivotNumerators = [1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1]
var unitConstant = powerOfTen(fractionalDigits)
var pivotValues: seq[BigNumber] = @[]
var pivotAngles: seq[BigNumber] = @[]
var halfCircleConstant: BigNumber = @[]

proc pivotValue(index: int): BigNumber =
  let base = divideSmall(unitConstant, int32(pivotDenominators[index]))
  if pivotNumerators[index] == 1: return base
  return scaledSmall(base, int32(pivotNumerators[index]))

proc arctangentFixed(value: BigNumber, circleConstant: BigNumber): BigNumber =
  let unitValue = unitConstant
  let halfCircle = halfCircleConstant
  if compareBig(value, unitValue) > 0:
    return subtractBig(halfCircle, arctangentFixed(divideFixed(unitValue, value), circleConstant))
  var answer: BigNumber = @[]
  var reduced = value
  for pivotIndex in 0 .. pivotValues.len - 1:
    let pivot = pivotValues[pivotIndex]
    if compareBig(reduced, pivot) >= 0:
      let pivotAngle = pivotAngles[pivotIndex]
      answer = addBig(answer, pivotAngle)
      let numerator = subtractBig(reduced, pivot)
      let denominator = addBig(unitValue, multiplyFixed(pivot, reduced))
      reduced = divideFixed(numerator, denominator)
  return addBig(answer, arctanSeries(reduced))

proc machinPi(): BigNumber =
  let unitValue = unitConstant
  let fifth = divideSmall(unitValue, 5)
  let twoThirtyNinth = divideSmall(unitValue, 239)
  let first = scaledSmall(arctanSeries(fifth), 16)
  let second = scaledSmall(arctanSeries(twoThirtyNinth), 4)
  return subtractBig(first, second)

proc buildData(digits: int): PrecisionData =
  fractionalDigits = digits```

```nim
proc machinPi(): BigNumber =
  let unitValue = unitConstant
  let fifth = divideSmall(unitValue, 5)
  let twoThirtyNinth = divideSmall(unitValue, 239)
  let first = scaledSmall(arctanSeries(fifth), 16)
  let second = scaledSmall(arctanSeries(twoThirtyNinth), 4)
  return subtractBig(first, second)

proc buildData(digits: int): PrecisionData =
  fractionalDigits = digits
  result.unitValue = powerOfTen(digits)
  unitConstant = result.unitValue
  result.pivots = newSeq[BigNumber](pivotDenominators.len)
  for index in 0 .. pivotDenominators.len - 1:
    result.pivots[index] = pivotValue(index)
  pivotValues = result.pivots
  result.angles = newSeq[BigNumber](pivotDenominators.len)
  for index in 0 .. pivotDenominators.len - 1:
    result.angles[index] = arctanSeries(result.pivots[index])
  pivotAngles = result.angles
  result.circle = machinPi()
  result.halfCircle = divideSmall(result.circle, 2)

proc activate(data: PrecisionData, digits: int) =
  fractionalDigits = digits
  unitConstant = data.unitValue
  pivotValues = data.pivots```

**Precision tiers and the output loop**.
```nim
proc leadingZeroCount(token: string): int =
  var integerPart = 0
  var position = 0
  while position < token.len and token[position] >= '0' and token[position] <= '9':
    integerPart = integerPart * 10 + ord(token[position]) - 48
    position = position + 1
  if integerPart > 0: return -1
  if position < token.len and token[position] == '.': position = position + 1
  var index = 1
  while position < token.len:
    if token[position] >= '1' and token[position] <= '9': return index - 1
    index = index + 1
    position = position + 1
  return -2

let highData = buildData(highPrecision)
let midData = buildData(midPrecision)
let lowData = buildData(lowPrecision)

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var position = 0
let caseCount = nextIndex(inputData, position)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let argumentToken = nextToken(inputData, position)
  let zeros = leadingZeroCount(argumentToken)
  var activeData: PrecisionData
  if zeros > 30:
    activate(highData, highPrecision)
    activeData = highData
  elif zeros > 6:
    activate(midData, midPrecision)
    activeData = midData
  else:
    activate(lowData, lowPrecision)
    activeData = lowData
  let argumentValue = parseFixed(argumentToken)
  let answer = arctangentFixed(argumentValue, activeData.circle)
  outputBuffer.add formatSignificant(answer)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer```

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over lines, then one digit pass per token | input bytes |
| limb core | schoolbook products and limb shifts per call | limb arrays |
| division | one long division per applied pivot | limb arrays |
| output write | one `stdout.write` per 128 KiB block | block buffer |

Time is O((k+c)*d^2) for k series terms, c divisions, and d working limbs.
Space is O(d) limbs plus the input buffer.
Machine integers cannot hold 101 required digits, so fixed-point limbs keep every digit.
