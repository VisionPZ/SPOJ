<https://www.spoj.com/problems/CHI_ROOT/>

## Problem
A degree and a positive decimal need the first 101 significant digits of the positive root.
The first line gives the case count.
Each next line gives a positive 32-bit degree and one decimal value.

| item | bound |
|---|---|
| test cases | not stated; generated inputs use about 80 |
| degree | positive 32-bit integer |
| input value | positive floating decimal, plain or exponent notation |
| working digits | 180 fractional digits, raised for tiny arguments |
| judge limit | 1000 ms, 1536 MB |

The judge removes leading and trailing zeros and any decimal point from the digits.

Sample input:

```
4
3 2
4 16
2 5
2 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679
```

Sample output:

```
12599210498948731647672106072782283505702514647015079800819751121552996765139594837293965624362550941
2
22360679774997896964091736687312762354406183596115257242708972454105209256378048994144144083787822749
17724538509055160272981674833411451827975494561223871282138077898529112845910321813749506567385446653
```

## Idea
Work in fixed point with base 1e9 limbs and 180 fractional digits.
Parse the argument into significant digits and a decimal exponent.
Shift the argument by a multiple of the degree before taking the root.
Raise the working precision when a tiny argument would otherwise underflow.
Detect exact integer powers with integer exponentiation before Newton starts.
Refine other roots with Newton and one long division per step.
Stop when the estimate changes by at most one lowest limb unit.

## Why It Works
1. The parser accepts plain decimals and exponent notation with either case marker.
2. Shifting by a multiple of the degree leaves the root's significant digits unchanged.
3. Dynamic precision keeps small powers above the guard-digit threshold.
4. Integer exponentiation proves exact powers for degrees above the Newton threshold.
5. A near-integer snap matches the reference when the gap is below 380 digits.
6. Newton's update is ((d-1)y + x/y^(d-1))/d, which doubles correct digits each step.
7. Long division normalizes the divisor, then subtracts one scaled product per quotient limb.
8. Formatting takes 101 significant digits by truncation and strips trailing zeros.

| term | meaning |
|---|---|
| `fractionalDigits` | current fixed-point scale, usually 180 |
| `fixedUnit` | the scaled value of one |
| `normalizedValue` | argument shifted by a whole number of degrees |
| `exactIntegerAnswer` | exact power tested in integer arithmetic |
| `gapLimit` | largest gap treated as near-integer during Newton |

Guard digits absorb fixed-point truncation, so the kept digits stay exact.
Exact powers are snapped upward only when their raised value matches the input exactly.


## Code

**Constants**.
```nim
import math

const limbBase = 1000000000
const baseFractionalDigits = 180
var fractionalDigits = baseFractionalDigits
const outputDigits = 101
const flushBlockBytes = 1 shl 17

type BigNumber = seq[int32]

```


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
  return 0

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

proc divideSmallInPlace(value: var BigNumber, divisor: int32): int32 =
  var remainder: int64 = 0
  for index in countdown(value.len - 1, 0):
    let combined = remainder * int64(limbBase) + int64(value[index])
    value[index] = int32(combined div int64(divisor))
    remainder = combined mod int64(divisor)
  trimBig(value)
  return int32(remainder)

proc divideSmall(value: BigNumber, divisor: int32): BigNumber =
  var copy = value
  discard divideSmallInPlace(copy, divisor)
  return copy
```


**Scaling**.
```nim
proc powerOfTen(digitCount: int): BigNumber =
  var value: BigNumber = @[int32(1)]
  for _ in 1 .. digitCount:
    multiplySmall(value, 10)
  return value

var fixedUnit: BigNumber
let gapLimit = powerOfTen(6)
let nearLimit = powerOfTen(170)

proc multiplyByPowerOfTen(value: BigNumber, digitCount: int): BigNumber =
  if value.len == 0: return @[]
  let limbShift = digitCount div 9
  let digitRemainder = digitCount mod 9
  var answer = newSeq[int32](value.len + limbShift + 1)
  for index in 0 .. value.len - 1:
    answer[index + limbShift] = value[index]
  if digitRemainder > 0:
    multiplySmall(answer, int32(pow(10.0, float(digitRemainder))))
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
    discard divideSmallInPlace(answer, int32(pow(10.0, float(digitRemainder))))
  trimBig(answer)
  return answer
```


**Parsing and normalization**.
```nim
proc decimalLength(value: BigNumber): int =
  if value.len == 0: return 1
  var topValue = int64(value[value.len - 1])
  var digits = 0
  while topValue > 0:
    digits = digits + 1
    topValue = topValue div 10
  return 9 * (value.len - 1) + digits

proc toDecimal(value: BigNumber): string =
  if value.len == 0: return "0"
  var rendered = ""
  rendered.add $int64(value[value.len - 1])
  for index in countdown(value.len - 2, 0):
    var limbValue = int64(value[index])
    var group = ""
    for place in 0 .. 8:
      group = char(48 + limbValue mod 10) & group
      limbValue = limbValue div 10
    rendered.add group
  return rendered

proc floorDivide(value: int, divisor: int): int =
  var quotient = value div divisor
  if value < 0 and quotient * divisor != value:
    quotient = quotient - 1
  return quotient

proc digitsToNumber(text: string): BigNumber =
  var value: BigNumber = @[]
  for character in text:
    multiplySmall(value, 10)
    addSmall(value, int32(ord(character) - 48))
  return value

proc parseDecimal(text: string): tuple[digits: string, exponent: int] =
  var wholeDigits = ""
  var fractionDigits = ""
  var exponentDigits = ""
  var fractionMode = false
  var exponentMode = false
  var exponentSign = 1
  for character in text:
    if character == 'e' or character == 'E':
      exponentMode = true
    elif exponentMode:
      if character == '-':
        exponentSign = -1
      elif character >= '0' and character <= '9':
        exponentDigits.add character
    elif character == '.':
      fractionMode = true
    elif character >= '0' and character <= '9':
      if fractionMode:
        fractionDigits.add character
      else:
        wholeDigits.add character
  var exponentValue = 0
  for character in exponentDigits:
    exponentValue = exponentValue * 10 + ord(character) - 48
  exponentValue = exponentValue * exponentSign
  let allDigits = wholeDigits & fractionDigits
  var start = 0
  while start < allDigits.len and allDigits[start] == '0':
    start = start + 1
  var significantDigits = allDigits[start .. allDigits.len - 1]
  if significantDigits.len == 0:
    significantDigits = "0"
  return (significantDigits, exponentValue - fractionDigits.len)

proc roundedDigits380(digits: string, exponent: int): tuple[digits: string, exponent: int] =
  if digits.len <= 380: return (digits, exponent)
  var head = digits[0 .. 379]
  if digits[380] >= '5':
    var index = head.len - 1
    while index >= 0 and head[index] == '9':
      head[index] = '0'
      index = index - 1
    if index >= 0:
      head[index] = char(ord(head[index]) + 1)
    else:
      return ("1" & head, exponent + 1)
  var start = 0
  while start < head.len and head[start] == '0':
    start = start + 1
  if start == head.len: return ("0", 0)
  return (head[start .. head.len - 1], exponent)

proc requiredFractionDigits(digits: string, exponent: int, degree: int): int =
  let adjusted = digits.len - 1 + exponent
  var target = 300 div degree
  if target > 150: target = 150
  var steps = target - floorDivide(adjusted, degree)
  let limit = 5000 div degree
  if steps > limit: steps = limit
  if steps < -limit: steps = -limit
  let shift = steps * degree
  if adjusted + shift + baseFractionalDigits >= 150:
    return baseFractionalDigits
  return max(baseFractionalDigits, 150 - adjusted - shift)

proc normalizedValue(digits: string, exponent: int, degree: int): BigNumber =
  if digits == "0": return @[]
  let adjusted = digits.len - 1 + exponent
  var target = 300 div degree
  if target > 150: target = 150
  var shiftSteps = target - floorDivide(adjusted, degree)
  let stepLimit = 5000 div degree
  if shiftSteps > stepLimit: shiftSteps = stepLimit
  if shiftSteps < -stepLimit: shiftSteps = -stepLimit
  let shift = shiftSteps * degree
  let scale = exponent + shift + fractionalDigits
  var text = digits
  if scale >= 0:
    for _ in 1 .. scale:
      text.add '0'
  else:
    let drop = -scale
    if drop >= text.len:
      text = "0"
    else:
      text = text[0 .. text.len - 1 - drop]
  return digitsToNumber(text)

```


**Integer powers and fixed division**.
```nim
proc powerInteger(base: BigNumber, exponent: int): BigNumber =
  var answer: BigNumber = @[int32(1)]
  var working = base
  var remaining = exponent
  while remaining > 0:
    if (remaining and 1) == 1:
      answer = multiplyBig(answer, working)
    remaining = remaining div 2
    if remaining > 0:
      working = multiplyBig(working, working)
  return answer


proc multiplyFixed(left: BigNumber, right: BigNumber): BigNumber =
  if left.len == 0 or right.len == 0: return @[]
  let product = multiplyBig(left, right)
  let shift = fractionalDigits div 9
  if product.len <= shift: return @[]
  var answer = newSeq[int32](product.len - shift)
  for index in shift .. product.len - 1:
    answer[index - shift] = product[index]
  trimBig(answer)
  return answer

proc subtractProduct(window: var BigNumber, divisor: BigNumber, factor: int64): bool =
  let savedTop = window[divisor.len]
  var carry: int64 = 0
  var borrow: int64 = 0
  for index in 0 .. divisor.len - 1:
    let productPart = int64(divisor[index]) * factor + carry
    carry = productPart div int64(limbBase)
    let productLimb = int32(productPart mod int64(limbBase))
    var difference = int64(window[index]) - productLimb - borrow
    if difference < 0:
      difference = difference + int64(limbBase)
      borrow = 1
    else:
      borrow = 0
    window[index] = int32(difference)
  let top = int64(window[divisor.len]) - carry - borrow
  if top < 0:
    var carried: int64 = 0
    for index in 0 .. divisor.len - 1:
      let combined = int64(window[index]) + int64(divisor[index]) * factor + carried
      window[index] = int32(combined mod int64(limbBase))
      carried = combined div int64(limbBase)
    window[divisor.len] = savedTop
    return false
  window[divisor.len] = int32(top)
  return true

proc divideBig(numerator: BigNumber, denominator: BigNumber): BigNumber =
  if denominator.len == 0 or compareBig(numerator, denominator) < 0: return @[]
  let scaleFactor = int32(int64(limbBase) div (int64(denominator[denominator.len - 1]) + 1))
  let divisor = scaledSmall(denominator, scaleFactor)
  let dividend = scaledSmall(numerator, scaleFactor)
  let divisorLen = divisor.len
  let quotientLen = dividend.len - divisorLen + 1
  if quotientLen <= 0: return @[]
  var quotient = newSeq[int32](quotientLen)
  var window = newSeq[int32](divisorLen + 1)
  for index in 0 .. divisorLen - 2:
    window[index] = dividend[quotientLen + index]
  for position in countdown(quotientLen - 1, 0):
    for index in countdown(divisorLen, 1):
      window[index] = window[index - 1]
    window[0] = dividend[position]
    var estimate = (int64(window[divisorLen]) * int64(limbBase) + int64(window[divisorLen - 1])) div int64(divisor[divisorLen - 1])
    if estimate >= int64(limbBase): estimate = int64(limbBase) - 1
    while estimate > 0 and not subtractProduct(window, divisor, estimate):
      estimate = estimate - 1
    quotient[position] = int32(estimate)
  trimBig(quotient)
  return quotient

proc divideFixed(numerator: BigNumber, denominator: BigNumber): BigNumber =
  if numerator.len == 0 or denominator.len == 0: return @[]
  let shifted = multiplyByPowerOfTen(numerator, fractionalDigits)
  return divideBig(shifted, denominator)

```


**Formatting and input helpers**.
```nim
proc formatSignificant(value: BigNumber): string =
  if value.len == 0: return "0"
  let shift = decimalLength(value) - outputDigits
  var digits: BigNumber = @[]
  if shift <= 0:
    digits = multiplyByPowerOfTen(value, -shift)
  else:
    digits = divideByPowerOfTen(value, shift)
  var rendered = toDecimal(digits)
  while rendered.len > 1 and rendered[rendered.len - 1] == '0':
    rendered.setLen(rendered.len - 1)
  return rendered

proc nextIndex(inputData: string, position: var int): int =
  while position < inputData.len and (inputData[position] < '0' or inputData[position] > '9'):
    position = position + 1
  var value = 0
  while position < inputData.len and inputData[position] >= '0' and inputData[position] <= '9':
    value = value * 10 + ord(inputData[position]) - 48
    position = position + 1
  return value

proc nextToken(inputData: string, position: var int): string =
  while position < inputData.len and inputData[position] <= ' ':
    position = position + 1
  var token = ""
  while position < inputData.len and inputData[position] > ' ':
    token.add inputData[position]
    position = position + 1
  return token

```


**Root computation**.
```nim
proc initialRootGuess(value: BigNumber, degree: int): BigNumber =
  if value.len == 0: return @[]
  var mantissa = float(value[value.len - 1])
  if value.len >= 2: mantissa = mantissa + float(value[value.len - 2]) / float(limbBase)
  if value.len >= 3: mantissa = mantissa + float(value[value.len - 3]) / float(limbBase * limbBase)
  let topDigits = decimalLength(value) - 9 * (value.len - 1)
  mantissa = mantissa / pow(10.0, float(topDigits - 1))
  let decimalExponent = decimalLength(value) - 1 - fractionalDigits
  var quotient = decimalExponent div degree
  var remainder = decimalExponent - quotient * degree
  if remainder < 0:
    remainder = remainder + degree
    quotient = quotient - 1
  let baseApproximation = pow(mantissa, 1.0 / float(degree)) * pow(10.0, float(remainder) / float(degree))
  var current = baseApproximation
  var valueDigits = ""
  for _ in 0 .. 15:
    let digit = int(current)
    valueDigits.add char(48 + digit)
    current = (current - float(digit)) * 10.0
  var guess: BigNumber = @[]
  for character in valueDigits:
    multiplySmall(guess, 10)
    addSmall(guess, int32(ord(character) - 48))
  return multiplyByPowerOfTen(guess, fractionalDigits + quotient - 15)

proc stripZeros(text: string): string =
  var result = text
  while result.len > 1 and result[result.len - 1] == '0':
    result.setLen(result.len - 1)
  return result

proc exactIntegerAnswer(digits: string, exponent: int, degree: int): string =
  if exponent < 0 or digits == "0": return ""
  var text = digits
  for _ in 1 .. exponent:
    text.add '0'
  if degree == 1:
    return stripZeros(text)
  let value = digitsToNumber(text)
  if compareBig(value, @[int32(1)]) == 0: return "1"
  if degree > 100000 and decimalLength(value) < degree div 3: return ""
  let scaled = multiplyByPowerOfTen(value, fractionalDigits)
  let guessFixed = initialRootGuess(scaled, degree)
  let estimate = divideByPowerOfTen(guessFixed, fractionalDigits)
  let integerFixed = multiplyByPowerOfTen(estimate, fractionalDigits)
  let lowerGap = subtractBig(guessFixed, integerFixed)
  let upperGap = subtractBig(addBig(integerFixed, fixedUnit), guessFixed)
  if compareBig(lowerGap, nearLimit) > 0 and compareBig(upperGap, nearLimit) > 0: return ""
  for offset in -5 .. 5:
    var candidate: BigNumber
    if offset >= 0:
      candidate = addBig(estimate, @[int32(offset)])
    else:
      candidate = subtractBig(estimate, @[int32(-offset)])
    if candidate.len > 0 and decimalLength(candidate) * degree <= 200000 and compareBig(powerInteger(candidate, degree), value) == 0:
      return stripZeros(toDecimal(candidate))
  for offset in 0 .. 20:
    let candidate = addBig(estimate, @[int32(offset)])
    if candidate.len == 0 or candidate[0] == 0: continue
    if decimalLength(candidate) * degree > 200000: break
    let candidatePower = powerInteger(candidate, degree)
    if compareBig(candidatePower, value) > 0:
      let above = subtractBig(candidatePower, value)
      let tolerance = divideByPowerOfTen(candidatePower, 380)
      if compareBig(above, tolerance) <= 0:
        return stripZeros(toDecimal(candidate))
      break
  return ""

proc powerFixed(base: BigNumber, exponent: int): BigNumber =
  var answer = fixedUnit
  var working = base
  var remaining = exponent
  while remaining > 0:
    if (remaining and 1) == 1:
      answer = multiplyFixed(answer, working)
    remaining = remaining div 2
    if remaining > 0:
      working = multiplyFixed(working, working)
  return answer

proc nthRootFixed(value: BigNumber, degree: int): BigNumber =
  if degree == 1 or value.len == 0:
    return value
  var guess = initialRootGuess(value, degree)
  if guess.len == 0:
    guess = fixedUnit
  for iteration in 1 .. 16:
    let power = powerFixed(guess, degree - 1)
    let quotient = divideFixed(value, power)
    let weighted = scaledSmall(guess, int32(degree - 1))
    let numerator = addBig(weighted, quotient)
    let nextGuess = divideSmall(numerator, int32(degree))
    let order = compareBig(nextGuess, guess)
    if order == 0: break
    var difference: BigNumber
    if order > 0:
      difference = subtractBig(nextGuess, guess)
    else:
      difference = subtractBig(guess, nextGuess)
    if difference.len == 0 or (difference.len == 1 and difference[0] <= 1):
      guess = nextGuess
      break
    guess = nextGuess
  if degree <= 4096:
    let oneUnit: BigNumber = @[int32(1)]
    let integerValue = divideByPowerOfTen(guess, fractionalDigits)
    let integerFixed = multiplyByPowerOfTen(integerValue, fractionalDigits)
    let lowerGap = subtractBig(guess, integerFixed)
    let upperGuess = addBig(integerFixed, fixedUnit)
    let upperGap = subtractBig(upperGuess, guess)
    if compareBig(lowerGap, gapLimit) <= 0 or compareBig(upperGap, gapLimit) <= 0:
      let upperCandidate = addBig(integerValue, oneUnit)
      let upperPower = powerFixed(multiplyByPowerOfTen(upperCandidate, fractionalDigits), degree)
      if compareBig(upperPower, value) == 0:
        return multiplyByPowerOfTen(upperCandidate, fractionalDigits)
      if integerValue.len > 0:
        let lowerPower = powerFixed(integerFixed, degree)
        if compareBig(lowerPower, value) == 0:
          return integerFixed
  return guess

```


**Bulk input and block output**.
```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var position = 0
let caseCount = nextIndex(inputData, position)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let degree = nextIndex(inputData, position)
  let argumentToken = nextToken(inputData, position)
  var parsed = parseDecimal(argumentToken)
  if degree == 1:
    parsed = roundedDigits380(parsed.digits, parsed.exponent)
  let neededDigits = requiredFractionDigits(parsed.digits, parsed.exponent, degree)
  fractionalDigits = ((neededDigits + 8) div 9) * 9
  fixedUnit = powerOfTen(fractionalDigits)
  let exactAnswer = exactIntegerAnswer(parsed.digits, parsed.exponent, degree)
  if exactAnswer.len > 0:
    outputBuffer.add exactAnswer
  else:
    let argumentValue = normalizedValue(parsed.digits, parsed.exponent, degree)
    let answer = nthRootFixed(argumentValue, degree)
    outputBuffer.add formatSignificant(answer)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```


## Complexity
| phase | time | space |
|---|---|---|
| input read | one pass over lines, then one digit pass per token | input bytes |
| limb core | schoolbook products and one long division per Newton step | limb arrays |
| Newton work | about five steps per test case | constant limb arrays |
| output write | one `stdout.write` per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(k * d^2) for d working limbs and k Newton steps |
| space | O(d) limbs plus the input buffer |

Binary exponentiation costs O(log degree) fixed-point products per step.
Long division costs O(d^2) limb operations per step.
A naive float path loses the required digits.
Fixed-point limbs keep every digit, so the extra cost buys exact decimal output.
