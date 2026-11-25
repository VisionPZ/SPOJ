# NR1 — Kapti and Balu (SPOJ)

<https://www.spoj.com/problems/NR1/>

## Problem

Write a polynomial in falling-factorial form, apply the forward difference operator k times, and report the constant term of the result. The answer is an exact integer that can exceed 64 bits.

Input starts with a test count t below 30. Each test gives n at most 25 and k at most n, then n plus 1 coefficients in descending powers ending with the constant. Output one integer per test.

| item | bound |
|---|---|
| test count t | below 30 |
| polynomial degree n | 0 to 25 |
| difference order k | 0 to n |
| each polynomial coefficient | -50 to 50 |
| judge limit | 100 ms, 1536 MB |

The exact answer can reach 31 digits, so the output path needs big integers.

Sample input:

```
1
3 2
2 -3 3 -10
```

Sample output:

```
6
```

## Idea

Applying a difference k times and then reading the constant is like taking a snapshot of how the polynomial changes at zero; no full basis conversion is needed. The real algorithm evaluates the finite-difference sum through Stirling numbers of the second kind. Each test costs O(n k) small multiplications, while expanding differences symbolically costs far more.

Big integers built from small limbs hold the exact result.

## Why It Works

1. The falling factorial [x] at j has value zero at x = 0 whenever j is positive.
2. After k differences, only the coefficient of [x] at 0 survives at x = 0.
3. The forward difference of [x] at j is j times [x] at j minus 1.
4. Repeated differences give k factorial times the factorial-basis coefficient A at k.
5. Converting monomials uses Stirling numbers, since x to the power j is the sum of S(j, i) times [x] at i.

| term | meaning |
|---|---|
| `stirlingValues` | Stirling numbers of the second kind up to degree 25 |
| `differenceOrder` | the number of forward differences k |
| `coefficients` | polynomial coefficients indexed by exponent |
| `total` | running big-integer sum for the answer |
| `limbs` | base 1000000000 digits of a big integer |

For the sample f(x) = 2x cubed minus 3x squared plus 3x minus 10, take k = 2. The values f(0), f(1) and f(2) are -10, -8 and 0. The sum 0 minus 2 times -8 plus -10 equals 6.

Each limb product stays below 1e18, so int64 arithmetic is safe.
Negative coefficients use a sign flag with a magnitude, which keeps subtraction exact.

## Code

**Big integers.** Numbers live in base 1000000000 limbs with a separate sign flag.

```nim
const flushBlockBytes = 1 shl 17
const limbBase: int64 = 1000000000
const maxDegree = 25

type BigNumber = object
  negative: bool
  limbs: seq[int64]

proc normalizeNumber(value: var BigNumber) =
  while value.limbs.len > 1 and value.limbs[value.limbs.len - 1] == 0:
    value.limbs.setLen(value.limbs.len - 1)
  if value.limbs.len == 1 and value.limbs[0] == 0:
    value.negative = false

proc makeNumber(value: int64): BigNumber =
  result.negative = value < 0
  var magnitude = value
  if magnitude < 0:
    magnitude = -magnitude
  result.limbs = @[]
  if magnitude == 0:
    result.limbs.add 0
  else:
    while magnitude > 0:
      result.limbs.add(magnitude mod limbBase)
      magnitude = magnitude div limbBase
  normalizeNumber(result)

proc magnitudeCompare(left, right: BigNumber): int =
  if left.limbs.len != right.limbs.len:
    if left.limbs.len > right.limbs.len:
      return 1
    return -1
  var position = left.limbs.len - 1
  while position >= 0:
    if left.limbs[position] != right.limbs[position]:
      if left.limbs[position] > right.limbs[position]:
        return 1
      return -1
    position -= 1
  return 0

proc subtractMagnitude(left, right: BigNumber): BigNumber =
  result.negative = false
  result.limbs = newSeq[int64](left.limbs.len)
  var borrow: int64 = 0
  for position in 0 .. left.limbs.len - 1:
    var difference = left.limbs[position] - borrow
    if position < right.limbs.len:
      difference = difference - right.limbs[position]
    if difference < 0:
      difference = difference + limbBase
      borrow = 1
    else:
      borrow = 0
    result.limbs[position] = difference
  normalizeNumber(result)

proc addNumbers(left, right: BigNumber): BigNumber =
  if left.negative == right.negative:
    result.negative = left.negative
    result.limbs = newSeq[int64](max(left.limbs.len, right.limbs.len) + 1)
    var carry: int64 = 0
    for position in 0 .. result.limbs.len - 2:
      var total: int64 = carry
      if position < left.limbs.len:
        total = total + left.limbs[position]
      if position < right.limbs.len:
        total = total + right.limbs[position]
      result.limbs[position] = total mod limbBase
      carry = total div limbBase
    result.limbs[result.limbs.len - 1] = carry
    normalizeNumber(result)
  else:
    let order = magnitudeCompare(left, right)
    if order >= 0:
      result = subtractMagnitude(left, right)
      result.negative = left.negative and order != 0
    else:
      result = subtractMagnitude(right, left)
      result.negative = right.negative
    normalizeNumber(result)

proc scaleNumber(value: BigNumber, factor: int64): BigNumber =
  result.negative = value.negative != (factor < 0)
  var multiplier = factor
  if multiplier < 0:
    multiplier = -multiplier
  result.limbs = newSeq[int64](value.limbs.len + 1)
  var carry: int64 = 0
  for position in 0 .. value.limbs.len - 1:
    let product = value.limbs[position] * multiplier + carry
    result.limbs[position] = product mod limbBase
    carry = product div limbBase
  result.limbs[value.limbs.len] = carry
  normalizeNumber(result)

proc numberToText(value: BigNumber): string =
  if value.negative:
    result.add '-'
  let highest = value.limbs.len - 1
  result.add $value.limbs[highest]
  var position = highest - 1
  while position >= 0:
    let part = $value.limbs[position]
    var zeroCount = 9 - part.len
    while zeroCount > 0:
      result.add '0'
      zeroCount -= 1
    result.add part
    position -= 1
```

The sign flag handles negative polynomial coefficients.
Addition compares magnitudes before borrowing.
A 31-digit answer uses four limbs at most.

**Input and Stirling table.** The scanner accepts minus signs and the table is built once.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var stirlingValues = newSeq[seq[int64]](maxDegree + 1)
for outerIndex in 0 .. maxDegree:
  stirlingValues[outerIndex] = newSeq[int64](maxDegree + 1)
stirlingValues[0][0] = 1
for degreeIndex in 1 .. maxDegree:
  for subsetIndex in 1 .. degreeIndex:
    stirlingValues[degreeIndex][subsetIndex] =
      stirlingValues[degreeIndex - 1][subsetIndex - 1] +
      int64(subsetIndex) * stirlingValues[degreeIndex - 1][subsetIndex]
```

The scanner stops at a minus sign before reading digits.
The Stirling table needs 26 rows for the largest degree.
Every table entry fits in int64.

**Per-test sum.** Each exponent contributes one big-integer term.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let degree = nextInt(inputData, scanPos)
  let differenceOrder = nextInt(inputData, scanPos)
  var coefficients = newSeq[int64](degree + 1)
  for placeIndex in 0 .. degree:
    coefficients[degree - placeIndex] = int64(nextInt(inputData, scanPos))
  var total = makeNumber(0)
  for exponent in differenceOrder .. degree:
    var term = makeNumber(stirlingValues[exponent][differenceOrder])
    for multiplier in 1 .. differenceOrder:
      term = scaleNumber(term, int64(multiplier))
    let coefficient = coefficients[exponent]
    if coefficient != 0:
      term = scaleNumber(term, coefficient)
      total = addNumbers(total, term)
  appendOutput(numberToText(total))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Input coefficients arrive in descending powers and are stored by exponent.
Multiplying by every value up to k builds k factorial without a large type.
The final text conversion pads each limb to nine digits.

## Complexity

Stirling precomputation is tiny, and each test adds a few big-integer terms.

| phase | time | space |
|---|---|---|
| input read | one pass over all coefficients | one input string |
| Stirling table | 26 squared fill steps | 26 squared integers |
| per test | up to 26 scaled additions | four limbs per number |
| output | one flush after all tests | block buffer |

At most 29 tests keep the total work small.

| measure | Big O |
|---|---|
| time | O(25 squared + t times 25 times k) |
| space | O(25 squared) plus one input string |

Expanding symbolic differences would need far more storage than the Stirling table.

The big-integer path keeps exact answers across all allowed coefficients.
