# TMB — Thousands ByteMan March (SPOJ)

<https://www.spoj.com/problems/TMB/>

## Problem

Count the set partitions of N times K distinct people into teams of one common size, over every common size that divides the total. Print the exact count, since it can exceed 64 bits.

Input starts with the test count. Each next line holds the bus count N and the common bus capacity K. Print one exact integer per line.

| item | bound |
|---|---|
| test count | 1 to 100 |
| bus count N | 1 to 100 |
| capacity K | 1 to 100 |
| total people | up to 10000 |
| judge limit | 2500 ms, 1536 MB |

The exact output drives the design because no modulus is given.

Sample input:

```
3
2 2
1 6
2 3
```

Sample output:

```
5
27
27
```

Six people give 27 in both bus layouts.

## Idea

The answer is the sum of uniform set partitions, like tallying every way to pack a crate into equal boxes then adding the box sizes. For a fixed team size d, the recurrence multiplies by a binomial when one more group is added. A small base-10^9 big integer holds each exact term. Enumerating all partitions would be factorial in the total. The recurrence grows each term with exact binomial steps, and a divisor sweep covers every team size.

## Why It Works

1. A team size d must divide the total n, so the sweep visits divisors only.
2. The count for size d is n factorial divided by d factorial to the m and m factorial, where m = n/d.
3. Starting from one group, adding a group multiplies by binomial(m*d-1, d-1).
4. Each binomial is built by multiply-then-divide steps that stay integral at every step.
5. Base 10^9 storage keeps each limb below one billion, so products fit in 64 bits.

| term | meaning |
|---|---|
| `totalSize` | N times K people |
| `uniformPartitionDigits` | count for one team size |
| `binomialDigits` | exact binomial as a big integer |
| `multiplyBigNumbers` | schoolbook big multiplication |
| `cachedAnswers` | repeated totals answered once |

The table names the helper that carries each exact count.

A script trace for six people follows:

```
divisor 1: 720/(1^6 * 720) = 1
divisor 2: 720/(2^3 * 6) = 15
divisor 3: 720/(6^2 * 2) = 10
divisor 6: 720/(720 * 1) = 1
sum = 27
```

The trace matches both six-person sample cases.

Carry propagation uses 64-bit intermediates, so no limb wraps during multiplication.

## Code

**Big integer limbs.** Every operation keeps exact base 10^9 digits.

```nim
const flushBlockBytes = 1 shl 17
const digitBaseValue = 1000000000

proc normalizeDigits(digits: var seq[int32]) =
  while digits.len > 0 and digits[digits.len - 1] == 0:
    digits.setLen(digits.len - 1)
  if digits.len == 0:
    digits.add 0

proc multiplyBySmall(digits: var seq[int32], factor: int64) =
  var carryValue = 0.int64
  for digitIndex in 0 .. digits.len - 1:
    let productValue = int64(digits[digitIndex]) * factor + carryValue
    digits[digitIndex] = int32(productValue mod int64(digitBaseValue))
    carryValue = productValue div int64(digitBaseValue)
  while carryValue > 0:
    digits.add int32(carryValue mod int64(digitBaseValue))
    carryValue = carryValue div int64(digitBaseValue)

proc divideBySmall(digits: var seq[int32], divisor: int) =
  var remainderValue = 0.int64
  for digitIndex in countdown(digits.len - 1, 0):
    let currentValue = remainderValue * int64(digitBaseValue) + int64(digits[digitIndex])
    digits[digitIndex] = int32(currentValue div int64(divisor))
    remainderValue = currentValue mod int64(divisor)
  normalizeDigits(digits)

proc addBigNumbers(result: var seq[int32], other: seq[int32]) =
  if result.len < other.len:
    result.setLen(other.len)
  var carryValue = 0.int64
  for digitIndex in 0 .. other.len - 1:
    let sumValue = int64(result[digitIndex]) + int64(other[digitIndex]) + carryValue
    result[digitIndex] = int32(sumValue mod int64(digitBaseValue))
    carryValue = sumValue div int64(digitBaseValue)
  var extensionIndex = other.len
  while carryValue > 0:
    if extensionIndex >= result.len:
      result.add 0
    let sumValue = int64(result[extensionIndex]) + carryValue
    result[extensionIndex] = int32(sumValue mod int64(digitBaseValue))
    carryValue = sumValue div int64(digitBaseValue)
    extensionIndex += 1

proc multiplyBigNumbers(leftValue, rightValue: seq[int32]): seq[int32] =
  var productDigits = newSeq[int32](leftValue.len + rightValue.len + 2)
  for leftIndex in 0 .. leftValue.len - 1:
    var carryValue = 0.int64
    for rightIndex in 0 .. rightValue.len - 1:
      let productIndex = leftIndex + rightIndex
      let productValue = int64(productDigits[productIndex]) +
                         int64(leftValue[leftIndex]) * int64(rightValue[rightIndex]) + carryValue
      productDigits[productIndex] = int32(productValue mod int64(digitBaseValue))
      carryValue = productValue div int64(digitBaseValue)
    var productIndex = leftIndex + rightValue.len
    while carryValue > 0:
      let productValue = int64(productDigits[productIndex]) + carryValue
      productDigits[productIndex] = int32(productValue mod int64(digitBaseValue))
      carryValue = productValue div int64(digitBaseValue)
      productIndex += 1
  normalizeDigits(productDigits)
  return productDigits

proc digitsToString(digits: seq[int32]): string =
  var text = $digits[digits.len - 1]
  for digitIndex in countdown(digits.len - 2, 0):
    var blockText = $digits[digitIndex]
    while blockText.len < 9:
      blockText = "0" & blockText
    text.add blockText
  return text
```

Each limb stays below the base.
Schoolbook multiplication needs no allocation inside the loop.
Decimal output pads every lower limb to nine places.

**Uniform partitions.** A binomial step grows one team size at a time.

```nim
proc binomialDigits(totalCount, chosenCount: int): seq[int32] =
  var resultDigits = @[1.int32]
  for stepValue in 1 .. chosenCount:
    multiplyBySmall(resultDigits, int64(totalCount - chosenCount + stepValue))
    divideBySmall(resultDigits, stepValue)
  return resultDigits

proc uniformPartitionDigits(groupTotal, groupSize: int): seq[int32] =
  var resultDigits = @[1.int32]
  let groupMultiple = groupTotal div groupSize
  var currentMultiple = 2
  while currentMultiple <= groupMultiple:
    let combinedDigits = binomialDigits(currentMultiple * groupSize - 1, groupSize - 1)
    resultDigits = multiplyBigNumbers(resultDigits, combinedDigits)
    currentMultiple += 1
  return resultDigits
```

Multiplying before dividing keeps each step exact.
The first group contributes one arrangement.
One group is added per loop pass.

**Input and divisor sweep.** Repeated totals are computed once.

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var totalSizes = newSeq[int](caseCount)
var largestSize = 0
for caseIndex in 0 .. caseCount - 1:
  let busCount = nextInt(inputData, scanPos)
  let busCapacity = nextInt(inputData, scanPos)
  let totalSize = busCount * busCapacity
  totalSizes[caseIndex] = totalSize
  if totalSize > largestSize:
    largestSize = totalSize

var cachedAnswers = newSeq[seq[int32]](largestSize + 1)
for caseIndex in 0 .. caseCount - 1:
  let totalSize = totalSizes[caseIndex]
  if cachedAnswers[totalSize].len == 0:
    var answerDigits = @[0.int32]
    for divisor in 1 .. totalSize:
      if totalSize mod divisor == 0:
        let termDigits = uniformPartitionDigits(totalSize, divisor)
        addBigNumbers(answerDigits, termDigits)
    cachedAnswers[totalSize] = answerDigits
  appendOutput(digitsToString(cachedAnswers[totalSize]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Total people is the product N times K.
Cache slots start empty and fill on first use.
Buffered output emits all exact answers together.

## Complexity

The divisor sweep dominates each distinct total.

| phase | time | space |
|---|---|---|
| input read | one pass over pairs | array of totals |
| binomial build | d steps per group | big integer limbs |
| divisor sweep | m groups per divisor | cache of answers |
| output | one buffered write | block buffer |

The phase table shows where groups and divisors add work.

| measure | Big O |
|---|---|
| time | O(n squared log n) worst case for one total |
| space | O(n) limbs per cached total |

Listing all set partitions takes factorial time. The uniform recurrence and divisor sweep replace that list with exact integer products.
