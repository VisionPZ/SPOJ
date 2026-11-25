# TJANDRA2 — Tjandra 19th birthday present (HARD) (SPOJ)

<https://www.spoj.com/problems/TJANDRA2/>

## Problem

Given a pile of matches, arrange some of them as unit grid edges so the number of rectangles of every size is largest. Count every axis-aligned rectangle whose border edges are present.

Input starts with the test count T. Each following line holds one integer N, the number of matches available. Output one line per test with the maximum rectangle count. That count can have 35 digits, so it needs big integers.

| item | bound |
|---|---|
| test count T | up to 100 |
| matches N | 1 < N <= 10^18 |
| answer size | up to about 35 digits |
| judge limit | 3000 ms, 1536 MB |

Sample input:

```
6
3
4
8
12
15
987654321123456789
```

Sample output:

```
0
1
3
9
12
60966316127114768913148159571503206
```

## Idea

Think of a nearly filled grid as a tiled floor with one corner strip missing, like a carpet trimmed along one edge. The best shapes have h rows, with k rows of width w and the rest of width w-1.

A full w by h grid uses 2wh + w + h matches and contains C(w+1,2) times C(h+1,2) rectangles. Removing one cell from the short column saves two matches and costs a known block of rectangles. For each row count h the best width and the best number of full rows follow from one division. A small sweep covers thin shapes, and divisors of 2N+1 cover the large near-square shapes that need big integer arithmetic.

## Why It Works

1. A full w by h grid uses 2wh + w + h matches, since each shared edge is counted once.
2. Its rectangles are C(w+1,2) times C(h+1,2), one pair of grid lines in each direction.
3. Shortening h-k rows by one cell gives the match count 2wh + w - h + 2k.
4. That shape has C(w+1,2)C(k,2) plus C(w,2)(C(h+1,2)-C(k,2)) rectangles.
5. For fixed h the width changes by at most one across all k, so four widths suffice.
6. A full grid of width w and height h satisfies (2w+1)(2h+1) = 2N+1 when it uses all matches.

| term | meaning |
|---|---|
| `sweepLimit` | largest row count checked directly |
| `span` | matches used before adding full-row bonuses |
| `fullRows` | number of rows kept at full width |
| `BigNum` | decimal limbs in base 10^9 |

Take N = 12. The shape w = 2, h = 2, k = 2 uses 2 times 2 times 2 plus 2 plus 2, which is 12 matches. It contains C(3,2) times C(3,2), or 9 rectangles.

The huge sample has 2N+1 = 4057 times 593531 times 820326137. Choosing the divisor pair 820326137 and 2407955267 gives width 1203977633 and height 410163068. The product of the two triangle counts above is the printed 35-digit answer.

## Code

**Input and buffered output.** The reader loads stdin once and keeps one output buffer.

```nim
import math

const flushBlockBytes = 1 shl 17
const sweepLimit = 2000000
const trialLimit = 2000000
const bigBase = 1000000000'i64

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
```

The answer exceeds 64 bits, so the program keeps its own decimal limbs. The block buffer flushes once it reaches 128 KiB.

**Big integers.** Addition, subtraction and multiplication work on base 10^9 limbs.

```nim
type BigNum = seq[int64]

proc normalizeBig(value: var BigNum) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc fromSmall(value: int64): BigNum =
  result = newSeq[int64]()
  if value >= bigBase:
    result.add value mod bigBase
    result.add value div bigBase
  elif value > 0:
    result.add value
  normalizeBig(result)

proc addBig(left, right: BigNum): BigNum =
  var result = newSeq[int64](left.len + right.len)
  var index: int = 0
  var carry: int64 = 0
  while index < left.len or index < right.len:
    var total = carry
    if index < left.len:
      total += left[index]
    if index < right.len:
      total += right[index]
    result[index] = total mod bigBase
    carry = total div bigBase
    index += 1
  if carry > 0:
    if index < result.len:
      result[index] = carry
    else:
      result.add carry
  normalizeBig(result)
  return result

proc subBig(left, right: BigNum): BigNum =
  var result = newSeq[int64](left.len)
  var index: int = 0
  var borrow: int64 = 0
  while index < left.len:
    var difference = left[index] - borrow
    if index < right.len:
      difference -= right[index]
    if difference < 0:
      difference += bigBase
      borrow = 1
    else:
      borrow = 0
    result[index] = difference
    index += 1
  normalizeBig(result)
  return result

proc mulBig(left, right: BigNum): BigNum =
  if left.len == 0 or right.len == 0:
    return @[]
  var result = newSeq[int64](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry: int64 = 0
    for rightIndex in 0 .. right.len - 1:
      let position = leftIndex + rightIndex
      let product = left[leftIndex] * right[rightIndex] + result[position] + carry
      result[position] = product mod bigBase
      carry = product div bigBase
    var position = leftIndex + right.len
    while carry > 0:
      let accumulated = result[position] + carry
      result[position] = accumulated mod bigBase
      carry = accumulated div bigBase
      position += 1
  normalizeBig(result)
  return result

proc compareBig(left, right: BigNum): int =
  if left.len != right.len:
    if left.len > right.len:
      return 1
    return -1
  var index = left.len - 1
  while index >= 0:
    if left[index] != right[index]:
      if left[index] > right[index]:
        return 1
      return -1
    index -= 1
  return 0

proc toStringBig(value: BigNum): string =
  if value.len == 0:
    return "0"
  result = $value[value.len - 1]
  var index = value.len - 2
  while index >= 0:
    let limb = value[index]
    result.add chr(48 + int(limb div 100000000))
    result.add chr(48 + int((limb div 10000000) mod 10))
    result.add chr(48 + int((limb div 1000000) mod 10))
    result.add chr(48 + int((limb div 100000) mod 10))
    result.add chr(48 + int((limb div 10000) mod 10))
    result.add chr(48 + int((limb div 1000) mod 10))
    result.add chr(48 + int((limb div 100) mod 10))
    result.add chr(48 + int((limb div 10) mod 10))
    result.add chr(48 + int(limb mod 10))
    index -= 1
```

Each limb stays below 10^9. The carry from the final addition fills an existing slot, never a new zero slot.

**Shape evaluation.** A triangle count is a product of two factors, with the halving done before multiplication.

```nim
proc triangularBig(value: int64): BigNum =
  if (value and 1'i64) == 0:
    return mulBig(fromSmall(value div 2), fromSmall(value + 1))
  return mulBig(fromSmall(value), fromSmall((value + 1) div 2))

proc integerSquareRoot(value: int64): int64 =
  var candidate = int64(sqrt(float64(value)))
  while (candidate + 1) * (candidate + 1) <= value:
    candidate += 1
  while candidate * candidate > value:
    candidate -= 1
  return candidate

proc considerShape(width, height: int64, availableMatches: int64, bestValue: var BigNum) =
  if width < 1 or height < 1:
    return
  let span = 2 * width * height + width - height
  if span > availableMatches:
    return
  var fullRows = (availableMatches - span) div 2
  if fullRows > height:
    fullRows = height
  if fullRows < 1:
    return
  if fullRows < height and width < 2:
    return
  let widthTriangles = triangularBig(width)
  let heightTriangles = triangularBig(height)
  let fullTriangles = triangularBig(fullRows)
  var candidate = mulBig(widthTriangles, fullTriangles)
  if fullRows < height:
    let remainder = subBig(heightTriangles, fullTriangles)
    candidate = addBig(candidate, mulBig(triangularBig(width - 1), remainder))
  if compareBig(candidate, bestValue) > 0:
    bestValue = candidate
```

A shape is rejected when its row lengths would fall below one. The remaining matches determine the largest valid number of full rows.

**Row sweep.** For each small row count, four widths bracketing the division result are enough.

```nim
proc sweepShapes(matchCount: int64, bestValue: var BigNum) =
  let sweepHeight = min(integerSquareRoot(matchCount div 2) + 2, int64(sweepLimit))
  var height: int64 = 1
  while height <= sweepHeight:
    let span = 2 * height + 1
    let approximateWidth = (matchCount + height) div span
    var offset = -2
    while offset <= 1:
      considerShape(approximateWidth + offset, height, matchCount, bestValue)
      offset += 1
    height += 1
```

The sweep covers every shape with few rows. Larger row counts are handled by divisor pairs.

**Divisor candidates.** Factoring 2N+1 provides the large near-square grids.

```nim
proc factorValue(value: int64): seq[int64] =
  var factors = newSeq[int64]()
  var remainder = value
  var candidate: int64 = 2
  while candidate <= trialLimit and candidate * candidate <= remainder:
    if remainder mod candidate == 0:
      factors.add candidate
      while remainder mod candidate == 0:
        remainder = remainder div candidate
    if candidate == 2:
      candidate = 3
    else:
      candidate += 2
  if remainder > 1:
    factors.add remainder
  return factors

proc divisorCandidates(matchCount: int64, bestValue: var BigNum) =
  let product = 2 * matchCount + 1
  let factors = factorValue(product)
  var divisors = newSeq[int64]()
  divisors.add 1
  for factor in factors:
    var exponent: int = 0
    var probe = product
    while probe mod factor == 0:
      probe = probe div factor
      exponent += 1
    let currentCount = divisors.len
    var multiplier: int64 = 1
    for powerIndex in 1 .. exponent:
      multiplier *= factor
      for index in 0 .. currentCount - 1:
        divisors.add divisors[index] * multiplier
  for divisor in divisors:
    if divisor > product:
      continue
    if product mod divisor != 0:
      continue
    let other = product div divisor
    if divisor > other:
      continue
    let height = (divisor - 1) div 2
    let width = (other - 1) div 2
    considerShape(width, height, matchCount, bestValue)
```

Trial division stops at two million, so a remaining large cofactor is treated as prime. Each divisor pair becomes one full grid candidate.

**Driver.** Each case takes the better of the sweep and the divisor candidates.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matchCount = int64(nextInt(inputData, scanPos))
  var bestValue = fromSmall(0)
  sweepShapes(matchCount, bestValue)
  divisorCandidates(matchCount, bestValue)
  appendOutput(toStringBig(bestValue))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

One buffered line is written per test case. The final flush empties the remaining buffer.

## Complexity

The sweep is linear in the capped row count, and trial division is linear in its cap. Big number operations take a few limbs each.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| row sweep | up to 2 million row counts | constant |
| factorization | up to 2 million trial divisors | divisor list |
| comparison | five limbs per candidate | one big integer |

| measure | Big O |
|---|---|
| time | O(min(sqrt(N), 2e6) + 2e6) per test |
| space | O(number of divisors) |

Checking every grid pair up to N would cost O(N^2). The sweep and the divisor pairs reduce each case to a fixed budget.
