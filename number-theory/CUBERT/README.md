# CUBERT — Cube Root (SPOJ)
<https://www.spoj.com/problems/CUBERT/>

## Problem

For each large integer, print its cube root truncated after ten decimal places. Also print the sum of the printed digits modulo ten.

Read a count `t`, then `t` integers of up to 150 digits.
Blank lines and surrounding spaces may appear.
For each integer, print a checksum, a space, and the cube root truncated after ten decimal places.
The checksum is the sum of the printed root digits modulo 10.

The judge bounds follow.

| Quantity | Bound |
| --- | --- |
| Test cases `t` | at most 20 |
| Digits per number | up to 150 |
| Printed decimal places | 10 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The 150-digit bound rules out floating point.

The sample input and expected output follow verbatim.

```
5
1
        8
   1000

2
33076161
```

```
1 1.0000000000
2 2.0000000000
1 10.0000000000
0 1.2599210498
6 321.0000000000
```

Each line pairs a checksum with a root truncated at ten decimals.

## Idea

Scale first, like measuring a room in millimeters to keep fractions exact.
Multiply the number by 10^30, then take an integer cube root.

Because 10^30 equals (10^10)^3, the scaled root carries ten decimal digits of the answer.
The program splits the last ten digits off as the fraction.
A binary search finds the root in about 200 steps.
Each step multiplies limbs (chunks stored in base 10^9) using integer arithmetic.

Cost per step is a few dozen limb products.
Trying candidate roots from one upward would need about 10^50 attempts.
Exact integer scaling prints a truncated root with no rounding drift.

## Why It Works

Four facts prove the method.

1. The number 10^30 equals (10^10)^3.
   Therefore the integer cube root of `N * 10^30` equals the root of `N` times 10^10, rounded down.
2. The last ten digits of that root form the fraction.
   The earlier digits form the whole part.
3. Rounding down truncates, so no digit ever rounds up.
4. Adding every printed digit and reducing modulo 10 gives the checksum.

The main values and their roles follow.

| Term | Meaning |
| --- | --- |
| `baseValue` | 10^9, the base of every limb |
| `limbDigits` | 9, the digit count of one limb |
| `scaleZeros` | 30, the decimal shift applied before the root |
| `fractionDigits` | 10, digits split off after the root |
| `digitCount` | number of decimal digits in a big number |

The scale and the fraction width match by design.

A script expands the sample value `N = 2` and prints these digits.

```
scaled   = 2000000000000000000000000000000
root     = 12599210498
digits   = 1 2 5 9 9 2 1 0 4 9 8
whole    = 1
fraction = 2599210498
checksum = 0
output   = 0 1.2599210498
```

The printed digits sum to 50, so the checksum is 0.

## Code

**Constants and number type.**

```nim
const firstDigitValue = 48
const baseValue = 1000000000
const limbDigits = 9
const scaleZeros = 30
const fractionDigits = 10
const flushBlockBytes = 1 shl 18

type BigNumber = seq[int]
```

The base is 10^9, so one limb holds nine decimal digits. The scale is 30 zeros and the fraction is ten digits. A BigNumber is a list of limbs with the least significant limb first.

**Parsing and small multiply.**

```nim
proc normalizeNumber(value: var BigNumber) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc parseNumber(data: string, first: int, last: int): BigNumber =
  result = @[]
  var endPos = last
  while endPos > first:
    var limb = 0
    var place = 1
    var taken = 0
    while endPos > first and taken < limbDigits:
      endPos -= 1
      limb += (int(data[endPos]) - firstDigitValue) * place
      place *= 10
      taken += 1
    result.add limb
  normalizeNumber(result)

proc multiplySmall(value: BigNumber, factor: int): BigNumber =
  result = @[]
  var carry = 0
  for limb in value:
    var product = limb * factor + carry
    result.add(product mod baseValue)
    carry = product div baseValue
  while carry > 0:
    result.add(carry mod baseValue)
    carry = carry div baseValue
  normalizeNumber(result)
```

parseNumber reads digits from the right and groups them into limbs. Reading right to left handles leading zeros without a special pass. multiplySmall carries overflow into later limbs. Both operations cost one pass over the limb count.

**Comparison and limb arithmetic.**

```nim
proc compareNumbers(left: BigNumber, right: BigNumber): int =
  if left.len < right.len: return -1
  if left.len > right.len: return 1
  var k = left.len - 1
  while k >= 0:
    if left[k] < right[k]: return -1
    if left[k] > right[k]: return 1
    k -= 1
  return 0

proc addNumbers(left: BigNumber, right: BigNumber): BigNumber =
  result = @[]
  var carry = 0
  var k = 0
  while k < left.len or k < right.len or carry > 0:
    var leftLimb = if k < left.len: left[k] else: 0
    var rightLimb = if k < right.len: right[k] else: 0
    var total = leftLimb + rightLimb + carry
    result.add(total mod baseValue)
    carry = total div baseValue
    k += 1
  normalizeNumber(result)

proc subtractNumbers(left: BigNumber, right: BigNumber): BigNumber =
  result = @[]
  var borrow = 0
  var k = 0
  while k < left.len:
    var rightLimb = if k < right.len: right[k] else: 0
    var difference = left[k] - rightLimb - borrow
    if difference < 0:
      difference += baseValue
      borrow = 1
    else:
      borrow = 0
    result.add difference
    k += 1
  normalizeNumber(result)

proc halveNumber(value: BigNumber): BigNumber =
  var quotient = newSeq[int](value.len)
  var remainder = 0
  var k = value.len - 1
  while k >= 0:
    var current = remainder * baseValue + value[k]
    quotient[k] = current div 2
    remainder = current mod 2
    k -= 1
  result = quotient
  normalizeNumber(result)
```

compareNumbers checks the most significant limb first. addNumbers and subtractNumbers carry or borrow one base value per limb. halveNumber walks from the top so the remainder flows downward. Each operation costs one pass over at most 20 limbs.

**Full multiplication.**

```nim
proc multiplyNumbers(left: BigNumber, right: BigNumber): BigNumber =
  if left.len == 0 or right.len == 0:
    return @[]
  result = newSeq[int](left.len + right.len)
  var k = 0
  while k < left.len:
    var carry = 0
    var l = 0
    while l < right.len:
      var place = k + l
      var current = result[place] + left[k] * right[l] + carry
      result[place] = current mod baseValue
      carry = current div baseValue
      l += 1
    var place = k + right.len
    while carry > 0:
      var current = result[place] + carry
      result[place] = current mod baseValue
      carry = current div baseValue
      place += 1
    k += 1
  normalizeNumber(result)
```

The product of two limbs plus a carry stays below 2^63. Each output limb collects its products, then passes the carry upward. The double loop costs O(L²) limb products for L limbs.

**Root search and formatting.**

```nim
proc powerOfTen(exponent: int): BigNumber =
  result = @[1]
  var k = 0
  while k < exponent:
    result = multiplySmall(result, 10)
    k += 1

proc digitCount(value: BigNumber): int =
  if value.len == 0: return 1
  var top = value[value.len - 1]
  var count = 0
  while top > 0:
    top = top div 10
    count += 1
  return (value.len - 1) * limbDigits + count

proc integerCubeRoot(target: BigNumber): BigNumber =
  if target.len == 0: return @[]
  var low: BigNumber = @[]
  var high = powerOfTen((digitCount(target) + 2) div 3)
  var one: BigNumber = @[1]
  while compareNumbers(low, high) < 0:
    var sum = addNumbers(low, high)
    sum = addNumbers(sum, one)
    var middle = halveNumber(sum)
    var square = multiplyNumbers(middle, middle)
    var cube = multiplyNumbers(square, middle)
    if compareNumbers(cube, target) <= 0:
      low = middle
    else:
      high = subtractNumbers(middle, one)
  return low

proc numberToString(value: BigNumber): string =
  if value.len == 0: return "0"
  result = $value[value.len - 1]
  var k = value.len - 2
  while k >= 0:
    var part = $value[k]
    var missing = limbDigits - part.len
    while missing > 0:
      result.add '0'
      missing -= 1
    result.add part
    k -= 1
```

powerOfTen builds the search bound with repeated small multiplies. integerCubeRoot searches until low and high meet. That gives the largest cube not exceeding the target. numberToString pads lower limbs to nine digits to preserve place values.

**Input, tokens, and output buffer.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int, first: var int, last: var int) =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  first = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  last = pos

proc tokenCount(data: string, first: int, last: int): int =
  result = 0
  var k = first
  while k < last:
    result = result * 10 + int(data[k]) - firstDigitValue
    k += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop stores the whole stream in one buffer. nextToken returns digit runs, so spaces and blank lines never reach the parser. appendOutput flushes a full 256 KiB block. The scanner never allocates a token string.

**Driver.**

```nim
var firstPos = 0
var lastPos = 0
nextToken(inputData, scanPos, firstPos, lastPos)
let caseCount = tokenCount(inputData, firstPos, lastPos)
for caseIndex in 0..<caseCount:
  nextToken(inputData, scanPos, firstPos, lastPos)
  var number = parseNumber(inputData, firstPos, lastPos)
  var scaled = number
  var zeroIndex = 0
  while zeroIndex < scaleZeros:
    scaled = multiplySmall(scaled, 10)
    zeroIndex += 1
  var root = integerCubeRoot(scaled)
  var rootText = numberToString(root)
  var checksum = 0
  for digitChar in rootText:
    checksum += int(digitChar) - firstDigitValue
  checksum = checksum mod 10
  var line = $checksum
  line.add ' '
  line.add rootText[0 .. rootText.len - fractionDigits - 1]
  line.add '.'
  line.add rootText[rootText.len - fractionDigits .. rootText.len - 1]
  line.add '\n'
  appendOutput line

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case scales its number by 30 decimal zeros. The root text is split at the last ten digits. The checksum sums those digits modulo 10. The final write emits the remaining output bytes.

## Complexity

Let `d` be the digit count of one number, at most 150.

The phases and their costs follow.

| Phase | Time | Space |
| --- | --- | --- |
| Parse and scale | O(d) | O(d) limbs |
| Binary search | about 200 cube computations | O(d) limbs |
| Format and checksum | O(d) | one line string |

The limb count stays small because 150 digits need about 17 limbs.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(d) limb work with a fixed search count per case |
| Space | O(d) per case plus the output block |

Trying every candidate root up to the answer needs about 10^50 trials, which cannot finish.
