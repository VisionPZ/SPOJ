# CHI_NATURAL — Natural numbers (SPOJ)

<https://www.spoj.com/problems/CHI_NATURAL/>

## Problem
Big nonnegative integers need the usual arithmetic plus one unusual product.
Each line gives an operation character, two integer operands, and a count only for the sharp operation.
| item | bound |
|---|---|
| test cases | not stated; generated inputs use a few hundred |
| operands | nonnegative decimal integers, well beyond 64 bits |
| sharp count | moderate integer inside 32-bit range |
| base for sharp | 100 |
| judge limit | 1000 ms, 1536 MB |

Operand length, not count, drives the limb loops.

Sample input:

```
15
< 1000 1999
< 9898 9898
< 1234 123
< 0 0
+ 1791593436984766559642626609333245051871 307634751338542477034677711517175
- 1000000000000000000000000000000000000000000000 1
- 9851454318615645743724544440468029862 40153566442954896526103872421591156
* 333333333 0
* 1 3333333335555
* 9999999999999999999999999999999999999999 999999999999999999999999999999999999999
/ 1 999999999999999999999999999999999999999999999
/ 999999999999999999999999999999999999999999999 2
/ 861564574372454444046802986230763475133854247703 6442954896526103872421591156
# 1010 2020 1
# 619665458372652911688999608 5642672187122910629212227277 6
```

Sample output:

```
1
0
-1
0
1791593744619517898185103644010956569046
999999999999999999999999999999999999999999999
9811300752172690847198440568046438706
0
3333333335555
9999999999999999999999999999999999999989000000000000000000000000000000000000001
0 1
499999999999999999999999999999999999999999999 1
133721962703322764598 5829723863328422309867552415
20400
3496569047280138337581751280571264068913704
```

## Idea
Imagine multiplying on paper in blocks of nine digits, then discarding the low blocks. The solution uses base 10^9 limbs, schoolbook multiplication, and digit-by-digit long division. Each operation costs O(d^2) limb steps for d limbs.

## Why It Works
1. A limb holds at most 999999999, so each limb product fits in a signed 64-bit value.
2. Carry propagation after every inner product keeps each slot below the base.
3. Long division finds one quotient limb by binary search, then subtracts the scaled divisor.
4. The sharp product uses raw base-100 convolution digits; dropping low coefficients then carrying gives the answer.

| term | meaning |
|---|---|
| `limbBase` | radix of each stored digit block, 10^9 |
| `BigNumber` | little-endian limb sequence |
| `convolution coefficient` | sum of digit products at one base-100 position |
| `skip` | number of low base-100 coefficients removed |

Raw coefficients, not the normalized product, define the sharp operation.

Script trace for a sample case:

```
left base-100 digits, low first: [10, 10]
right base-100 digits, low first: [20, 20]
raw convolution: [200, 400, 200]
drop coefficient index 0, then carry in base 100
digits, high first: 2 | 04 | 00
rendered integer: 20400
```

No rounding occurs. Division truncates toward zero, and the sharp result is an exact integer.

## Code

**Representation and constants.**

```nim
const limbBase = 1000000000
const flushBlockBytes = 1 shl 17
```

Nine decimal digits per limb keep products inside int64.

**Parsing and scaling.**

```nim
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
```

Digits enter one limb at a time, so no builtin integer is used.

**Addition, subtraction, multiplication.**

```nim
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

proc divideModulo(dividend: BigNumber, divisor: BigNumber): tuple[quotient: BigNumber, remainder: BigNumber] =
  if divisor.len == 0:
    return (@[], @[])
  if compareBig(dividend, divisor) < 0:
    return (@[], dividend)
  var remainder: BigNumber = @[]
  var quotient = newSeq[int32](dividend.len)
  for index in countdown(dividend.len - 1, 0):
    var shifted = newSeq[int32](remainder.len + 1)
    shifted[0] = dividend[index]
    for place in 0 .. remainder.len - 1:
      shifted[place + 1] = remainder[place]
    remainder = shifted
    trimBig(remainder)
    var low: int32 = 0
    var high: int32 = int32(limbBase - 1)
    while low < high:
      let middle = (low + high + 1) div 2
      let trial = scaledSmall(divisor, middle)
      if compareBig(trial, remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[index] = low
    if low > 0:
      remainder = subtractBig(remainder, scaledSmall(divisor, low))
  trimBig(quotient)
  return (quotient, remainder)

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
```

Schoolbook products cost one pass over each limb pair.

**Division and rendering.**

```nim
proc divideSmallInPlace(value: var BigNumber, divisor: int32): int32 =
  var remainder: int64 = 0
  for index in countdown(value.len - 1, 0):
    let combined = remainder * int64(limbBase) + int64(value[index])
    value[index] = int32(combined div int64(divisor))
    remainder = combined mod int64(divisor)
  trimBig(value)
  return int32(remainder)

proc divideModulo(dividend: BigNumber, divisor: BigNumber): tuple[quotient: BigNumber, remainder: BigNumber] =
  if divisor.len == 0:
    return (@[], @[])
  if compareBig(dividend, divisor) < 0:
    return (@[], dividend)
  var remainder: BigNumber = @[]
  var quotient = newSeq[int32](dividend.len)
  for index in countdown(dividend.len - 1, 0):
    var shifted = newSeq[int32](remainder.len + 1)
    shifted[0] = dividend[index]
    for place in 0 .. remainder.len - 1:
      shifted[place + 1] = remainder[place]
    remainder = shifted
    trimBig(remainder)
    var low: int32 = 0
    var high: int32 = int32(limbBase - 1)
    while low < high:
      let middle = (low + high + 1) div 2
      let trial = scaledSmall(divisor, middle)
      if compareBig(trial, remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[index] = low
    if low > 0:
      remainder = subtractBig(remainder, scaledSmall(divisor, low))
  trimBig(quotient)
  return (quotient, remainder)

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

proc baseHundredDigits(value: BigNumber): seq[int32] =
  var working = value
  var digits: seq[int32] = @[]
  while working.len > 0:
    digits.add divideSmallInPlace(working, 100)
  return digits
```

Binary search finds each quotient limb; the base-100 convolution handles sharp.

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

Each limb multiplication is quadratic; parsing is linear in input digits.
