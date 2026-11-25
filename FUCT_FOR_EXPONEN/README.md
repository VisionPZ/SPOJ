# FUCT_FOR_EXPONEN — Exponentiation (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_EXPONEN/>

## Problem

Each test gives a base x and an exponent n, and the task is to print xⁿ. A non-negative exponent prints the exact integer, like `2 4` → `16`. A negative exponent prints a decimal with six digits after the point, like `5 -2` → `0.040000`.

Input starts with a test count. Each test line holds x and n, either of which may be negative. Output holds one line per test.

| Item | Bound |
|---|---|
| Test count | 1 ≤ t ≤ 1000 |
| x, n | integers, negatives possible |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
1 7
2 4
0 9
-3 3
5 -2
```

```
1
16
0
-27
0.040000
```

## Idea

A big exponent such as 2¹⁰⁰⁰ has over 300 digits, so the program keeps powers as big numbers made of 30-bit chunks, like place-value columns in base 2³⁰. It raises by binary exponentiation — squaring the running base and multiplying it in only when the exponent's bit is set — then converts to decimal by repeated division by 10⁹, one decimal block per division. Repeated answers for the same (|x|, n) are cached in a table. Negative exponents are small reciprocals, so plain 64-bit floating point plus a hand-made six-decimal print is enough.

## Why It Works

1. Binary exponentiation uses at most 2·log₂(n) multiplications, because every squaring halves the exponent.
2. With 30-bit chunks, one chunk product plus carry stays under 2⁶³, so 64-bit `int` never overflows.
3. Repeated division by 10⁹ peels off decimal digits in groups of nine, low group first, exactly like long division.
4. `appendFixedSix` scales by 10⁶, rounds by adding 0.5, then prints integer part, dot, and a zero-padded six-digit fraction — the same result as C's `%.6f`.
5. A negative base with an odd exponent gets a leading `-`; the magnitude comes from |x|ⁿ.
6. `0 0` prints 1, the usual convention; `0` with a negative exponent prints `inf`.

| Term | Meaning |
|---|---|
| `bigMul` | multiplies two chunk lists, schoolbook style |
| `bigPowGroups` | binary exponentiation returning chunks |
| `decimalTextOf` | converts chunks to decimal text |
| `appendFixedSix` | prints a float with exactly six decimals |
| `answerCache` | memo table keyed by (|x|, n) |

Each distinct (|x|, n) is computed once, then replayed from the cache.

A script-traced example from `gen.py`:

```
base 5 exponent -2
value: 0.04
line: 0.040000
```

The trace matches the last sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const bigBaseBits = 30
const bigBase = 1 shl bigBaseBits
const bigMask = bigBase - 1
const decimalBase = 1000000000
const scaleMillion = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var isNegative = false
  if position < data.len and data[position] == '-':
    isNegative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if isNegative:
    return -value
  return value
```

One readLine loop collects all input bytes.
The '-' branch lets negative bases and exponents parse.
Scanning costs one pass over the consumed characters.

**Chunked multiply and power.** This block does the exact big-integer work.

```nim
proc bigMul(leftNumber: seq[int], rightNumber: seq[int]): seq[int] =
  var productGroups = newSeq[int](leftNumber.len + rightNumber.len)
  for leftIndex in 0..<leftNumber.len:
    var carry = 0
    var writeIndex = leftIndex
    for rightIndex in 0..<rightNumber.len:
      let cell = productGroups[writeIndex] + leftNumber[leftIndex] * rightNumber[rightIndex] + carry
      productGroups[writeIndex] = cell and bigMask
      carry = cell shr bigBaseBits
      writeIndex += 1
    while carry > 0:
      let cell = productGroups[writeIndex] + carry
      productGroups[writeIndex] = cell and bigMask
      carry = cell shr bigBaseBits
      writeIndex += 1
  return productGroups

proc bigPowGroups(baseValue: int, exponentValue: int): seq[int] =
  if baseValue == 0:
    if exponentValue == 0:
      return @[1]
    return @[0]
  var baseGroups: seq[int] = @[]
  var rest = baseValue
  while rest > 0:
    baseGroups.add rest mod bigBase
    rest = rest div bigBase
  var powerResult: seq[int] = @[1]
  var remainingPower = exponentValue
  while remainingPower > 0:
    if remainingPower mod 2 == 1:
      powerResult = bigMul(powerResult, baseGroups)
    remainingPower = remainingPower div 2
    if remainingPower > 0:
      baseGroups = bigMul(baseGroups, baseGroups)
  return powerResult
```

`and bigMask` and `shr bigBaseBits` split a cell into chunk and carry in two cheap ops.
Squaring is skipped once the exponent reaches zero.
One multiply costs the product of the two chunk counts.

**Decimal conversion.** This block turns chunks into printable digits.

```nim
proc decimalTextOf(number: seq[int]): string =
  var work = number
  var decimalGroups: seq[int] = @[]
  while true:
    var topIndex = work.len - 1
    while topIndex > 0 and work[topIndex] == 0:
      topIndex -= 1
    if topIndex == 0 and work[0] == 0:
      break
    var carry = 0
    var readIndex = topIndex
    while readIndex >= 0:
      let cell = (carry shl bigBaseBits) + work[readIndex]
      work[readIndex] = cell div decimalBase
      carry = cell mod decimalBase
      readIndex -= 1
    decimalGroups.add carry
  if decimalGroups.len == 0:
    decimalGroups.add 0
  var text = ""
  var groupIndex = decimalGroups.len - 1
  text.add $(decimalGroups[groupIndex])
  groupIndex -= 1
  while groupIndex >= 0:
    var part = $(decimalGroups[groupIndex])
    while part.len < 9:
      part = "0" & part
    text.add part
    groupIndex -= 1
  return text
```

Each division pass peels the lowest nine decimal digits as the carry.
The top group prints unpadded, lower groups get leading zeros.
A 1000-digit power needs about 333 division passes.

**Fixed six-decimal print.** This block formats negative-exponent answers.

```nim
proc appendFixedSix(value: float) =
  var signText = ""
  var magnitude = value
  if value < 0:
    signText = "-"
    magnitude = -value
  if magnitude >= 1000000000000000.0:
    appendOutput(signText & "inf")
    return
  let scaled = int(magnitude * 1000000.0 + 0.5)
  appendOutput(signText)
  appendOutput($(scaled div scaleMillion))
  appendOutput(".")
  var fractionText = $(scaled mod scaleMillion)
  while fractionText.len < 6:
    fractionText = "0" & fractionText
  appendOutput(fractionText)
```

Scaling by 10⁶ and rounding by +0.5 reproduces `%.6f` rounding.
The huge-magnitude guard prints `inf` before the int cast would overflow.

**Query loop with cache.** This block answers each test.

```nim
var answerCache = initTable[(int, int), string]()

let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let baseNumber = nextSignedInt(inputData, scanPos)
  let exponentNumber = nextSignedInt(inputData, scanPos)
  if exponentNumber >= 0:
    let cacheKey = (abs(baseNumber), exponentNumber)
    var digitsText = ""
    if answerCache.hasKey(cacheKey):
      digitsText = answerCache[cacheKey]
    else:
      digitsText = decimalTextOf(bigPowGroups(abs(baseNumber), exponentNumber))
      answerCache[cacheKey] = digitsText
    if baseNumber < 0 and exponentNumber mod 2 == 1:
      appendOutput("-")
    appendOutput(digitsText)
    appendOutput("\n")
  else:
    appendFixedSix(pow(float(baseNumber), float(exponentNumber)))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The cache key uses |x| because the sign is printed separately.
A repeated query costs one table lookup instead of a full power.

## Complexity

Exact powers dominate the cost; the cache removes repeats.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Power | O(log n) chunk multiplies | chunks of xⁿ |
| Decimal print | O(D² / 9) division steps, D = digits | decimal groups |
| Negative n | constant float work | constant |

At n = 1000, x = 10 the answer has 1000 digits and prints in well under a millisecond.

| Measure | Big O |
|---|---|
| Time | O(N + t · (log n · M(n)² + D² / 9) + output), M = chunk count |
| Space | O(N + distinct answers) |

A naive loop multiplying x by itself n times costs O(t · n · M(n)²); binary exponentiation cuts the multiplications to O(log n).
