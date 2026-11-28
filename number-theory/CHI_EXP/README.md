# CHI_EXP — The real exponential (SPOJ)

<https://www.spoj.com/problems/CHI_EXP/>

## Problem
A decimal input needs 101 correct significant digits of its exponential.
The first line is the case count. Each next line holds one real number between -100 and 100.
| item | bound |
|---|---|
| test cases | not stated; generated inputs use about 160 |
| input | -100 <= x <= 100, at most 101 decimal digits |
| output | 101 significant digits, zeros and point removed |
| working digits | 380 fractional digits |
| judge limit | 1000 ms, 1536 MB |

The 101-digit target fixes the working precision.

Sample input:

```
3
0
1
-3.14159265358979323846264338327950288
```

Sample output:

```
1
27182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274
43213918263772249774417737171728011457104245174434972327166908869626900798351779694542372009588635587
```

## Idea
Think of repeatedly halving a quantity before measuring it, then squaring back up. The solution uses fixed-point base 10^9 limbs, a halved Taylor series, and repeated squaring. One case costs a few hundred limb products.

## Why It Works
1. Fixed-point limbs store the value times 10^380, so 380 fractional digits survive.
2. Halving until the argument is below 1/32 makes the Taylor terms shrink quickly.
3. Each Taylor term multiplies by the reduced argument and divides by the next index.
4. Squaring undoes the halvings, and a Newton reciprocal handles negative inputs.

| term | meaning |
|---|---|
| `fractionalDigits` | decimal places kept in every fixed-point limb array |
| `reduced` | the argument after repeated halving |
| `term` | current Taylor summand |
| `doubleUnit` | two in fixed-point form, the Newton ceiling |

Halving trades many terms for a few squarings.

Script trace for a sample case:

```
reduce by 5 halvings: 1 -> 0.03125
term 1: 0.03125
term 2: 0.00048828125
term 3: 0.000005086263020833333333333333333333333333333
continue the Taylor sum, then square five times
first 101 digits: 271828182845904523536028...
```

The final formatter truncates, never rounds, to 101 significant digits. Guard digits absorb 280 digits of internal truncation, so the kept digits are stable.

## Code

**Representation and constants.**

```nim
const limbBase = 1000000000
const fractionalDigits = 380
const outputDigits = 101
const flushBlockBytes = 1 shl 17
```

The precision constants are fixed, not per case.

**Limb arithmetic.**

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

Every product carries in int64, then truncates to 380 places.

**Fixed-point formatting.**

```nim
proc multiplyFixed(left: BigNumber, right: BigNumber): BigNumber =
  return divideByPowerOfTen(multiplyBig(left, right), fractionalDigits)

proc reciprocalFixed(value: BigNumber): BigNumber =
  if value.len == 0: return @[]
  let unitValue = powerOfTen(fractionalDigits)
  let decimalExponent = decimalLength(value) - 1 - fractionalDigits
  var guess = powerOfTen(fractionalDigits - decimalExponent)
  discard divideSmallInPlace(guess, 8)
  let doubleUnit = scaledSmall(unitValue, 2)
  for iteration in 1 .. 18:
    let product = multiplyFixed(value, guess)
    if compareBig(product, doubleUnit) >= 0: break
    let complement = subtractBig(doubleUnit, product)
    guess = multiplyFixed(guess, complement)
  return guess

proc divideFixed(numerator: BigNumber, denominator: BigNumber): BigNumber =
  if numerator.len == 0 or denominator.len == 0: return @[]
  return multiplyFixed(numerator, reciprocalFixed(denominator))

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
```

Formatting shifts by the digit length minus 101, then strips zeros.

**Exponential evaluation.**

```nim
proc exponentialFixed(value: BigNumber, isNegative: bool): BigNumber =
  let unitValue = powerOfTen(fractionalDigits)
  let threshold = divideSmall(unitValue, 32)
  var reduced = value
  var halvingCount = 0
  while compareBig(reduced, threshold) > 0:
    reduced = divideSmall(reduced, 2)
    halvingCount = halvingCount + 1
  var term = unitValue
  var total = unitValue
  var denominator = 0
  while denominator <= 500:
    term = multiplyFixed(term, reduced)
    denominator = denominator + 1
    term = divideSmall(term, int32(denominator))
    if term.len == 0: break
    total = addBig(total, term)
  var answer = total
  for _ in 1 .. halvingCount:
    answer = multiplyFixed(answer, answer)
  if isNegative:
    answer = reciprocalFixed(answer)
  return answer
```

Halving, Taylor summation, squaring, and one reciprocal finish the case.

## Complexity
| phase | time | space |
|---|---|---|
| input read | one pass over lines, then one digit pass per token | input bytes |
| big-integer core | schoolbook limb products and shifts per call | limb arrays |
| series or Newton work | one fixed-point evaluation per test case | constant limb arrays |
| output write | one `stdout.write` per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(k * d^2) for d working limbs and k series or Newton steps |
| space | O(d) limbs plus the input buffer |

A naive float or builtin integer path loses the required digits. Fixed-point limbs
keep every digit, so the extra cost buys exact decimal output.

Series terms fall factorially, so a few dozen terms cover 380 places.
