## Problem

Read a count, then that many lines. Each line holds one positive integer of at most 150 decimal digits, with optional surrounding spaces and possible blank lines. Print one line per number: the sum of the printed digits modulo 10, a space, and the cube root truncated after its tenth decimal place.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | 20 |
| Digits per number | 150 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The 150-digit bound exceeds floating-point range, so the program uses integer arithmetic only.

## Idea

Scale each number by 10^30, then take an integer cube root. Because 10^30 is a perfect cube, the scaled root carries ten decimal digits of the answer inside one integer.

The program splits that integer at the last ten digits and adds its digits for the checksum. A binary search finds the root in about 200 steps, and each step multiplies small numbers stored in base 10^9.

Cost: about 200 cube computations per case, each on numbers of at most 60 digits.

## Why It Works

Write N for the input number and R for the integer cube root of N times 10^30.

- 10^30 equals (10^10)^3, so R equals the cube root of N times 10^10, rounded down.
- The last ten digits of R are the fraction. The digits before them are the whole part.
- Rounding down truncates, so no digit rounds up.
- Adding every digit of R and taking the result modulo 10 gives the checksum.

The generator computes this example for N = 2:

```
scaled   = 2000000000000000000000000000000
root     = 12599210498
digits   = '12599210498'
whole    = '1'
fraction = '2599210498'
checksum = 0
output   = 0 1.2599210498
```

The printed digits sum to 50, which gives checksum 0.

## Code

First the constants, the number type, and the smallest operations. `parseNumber` groups digits into nine-digit limbs. `multiplySmall` keeps each limb below `baseValue`.

```nim
const firstDigitValue = 48
const baseValue = 1000000000
const limbDigits = 9
const scaleZeros = 30
const fractionDigits = 10
const flushBlockBytes = 1 shl 18

type BigNumber = seq[int]

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

The group is nine digits because `limbDigits` is 9, so each limb stays below 1,000,000,000. The loop reads digits from the right, which handles leading zeros without a separate pass. The cost is linear in the digit count.

Comparison checks the most significant limb first, then walks down. Subtraction borrows one `baseValue` when a limb goes negative. Halving walks from the most significant limb so the remainder flows downward. Each operation costs one pass over at most 20 limbs.

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

Multiplication collects at most seven products per output limb, so a 64-bit `int` holds the sum. The carry moves to the next limb on each step. Multiplication costs at most 98 limb products here.

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

`powerOfTen` builds the search bound with repeated small multiplies. `integerCubeRoot` searches the inclusive range from zero to that bound. The loop stops when the low and high ends meet, so the result is the largest cube not exceeding the target. `numberToString` pads each lower limb with leading zeros to keep place values aligned.

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

The input loop reads the whole stream once into `inputData`. `nextToken` returns digit runs, so spaces and blank lines never reach the parser. The loop scales each number by `scaleZeros` zeros, then builds one output line. `appendOutput` flushes a completed block, which keeps memory use at `flushBlockBytes`.

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

## Complexity

Let d be the digit count, at most 150.

- Parsing and scaling take O(d) limb work.
- The search takes about 200 iterations, each with at most 98 limb products because numbers stay under 60 digits.
- Printing takes O(d).

Total per case: O(d) limb work with a fixed cost of about 200 multiplications. Testing every candidate root up to the answer would need about 10^60 trials, which is impossible.
