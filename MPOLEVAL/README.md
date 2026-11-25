# MPOLEVAL — Polynomial Evaluation - Angry Teacher (SPOJ)

<https://www.spoj.com/problems/MPOLEVAL/>

## Problem

A polynomial `p(x)` has integer coefficients, and the input start can be a number with a thousand digits. For each of `k` successive values, report the sum of squares of the last `m` decimal digits of the polynomial value. The sample uses `p(x) = x^3 + 2x + 1` with two output digits.

The first line holds `n`, `l`, `k`, and `m`. The next `n + 1` lines hold the coefficients from highest degree to constant term. Points run from `l` to `l+k-1` as `l+1`, `l+2`, and up to `l+n` for the seed values. The output holds `k` lines, one per evaluated point.

| item | bound |
|---|---|
| degree `n` | 0 to 10 |
| start `l` | 0 to 10^1000 |
| point count `k` | 1 to 1000 |
| digit count `m` | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

The digit count drives the design, since modulus 10^m exceeds any machine integer.

Sample input:

```
3 0 10 2
1
0
2
1
```

Sample output:

```
1
16
10
25
58
45
85
89
85
80
```

## Idea

Only the last `m` digits matter, so keep numbers modulo 10^m in chunks of four digits. Think of it as a receipt tape that keeps only the final digits of every calculation.

Evaluate the polynomial at `l`, `l+1`, up to `l+n` with Horner's rule. Finite differences then step to `l+k-1` using additions only, like extending a sequence from its first few terms.

Recomputing Horner for every point costs O(k*n*m^2) limb work. The difference walk replaces that with O(k*n*m).

## Why It Works

1. The last `m` digits of a sum or product depend only on the last `m` digits of the inputs.
2. Base 10000 stores four decimal digits per limb, so modulus 10^m uses about m/4 limbs.
3. Horner's rule evaluates the polynomial at the first `n + 1` points modulo 10^m.
4. Constant-step differences turn a degree-`n` polynomial into additions that advance the value by one.
5. Each advanced value is reduced modulo 10^m, and its limbs give the digit-square sum directly.

| term | meaning |
|---|---|
| `limbCount` | number of base-10000 limbs that hold m digits |
| `parseLimited` | keep the last m digits of an input token |
| `differences` | forward differences of the polynomial at the current point |
| `digitSquareSum` | sum of squares of the stored decimal digits |

The term table names the values that replace big-integer arithmetic.

A worked example from the sample uses p(x) with two output digits:

```
x = 0: p = 1   -> "01" -> 0^2 + 1^2 = 1
x = 1: p = 4   -> "04" -> 0^2 + 4^2 = 16
x = 2: p = 13  -> "13" -> 1^2 + 3^2 = 10
x = 3: p = 34  -> "34" -> 3^2 + 4^2 = 25
```

The fourth line matches the sample output, and the same walk produces all ten lines.

## Code

**Input and digit tokens.** One read pass loads the input, and two hand readers split numbers from digit strings.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 10000
const limbDigits = 4

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

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result.add data[pos]
    pos += 1
```

Small parameters use the integer reader.
The start and coefficients use the digit-string reader.
No value is ever stored as a machine integer when it can have 1000 digits.

**Buffered output.** All answer lines share one string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A block flush keeps the write path cheap.
The final write happens after the answer loop.

**Limited big-integer helpers.** Every operation keeps exactly m decimal digits.

```nim
var modulusDigits = 0
var limbCount = 0
var topMask = limbBase

proc maskTop(number: var seq[int]) =
  number[limbCount - 1] = number[limbCount - 1] mod topMask

proc parseLimited(digits: string): seq[int] =
  result = newSeq[int](limbCount)
  var digitPosition = digits.len - 1
  let firstDigit = if digits.len > modulusDigits: digits.len - modulusDigits else: 0
  var place = 1
  var limbIndex = 0
  while digitPosition >= firstDigit:
    result[limbIndex] = result[limbIndex] + (int(digits[digitPosition]) - 48) * place
    place = place * 10
    if place == limbBase:
      place = 1
      limbIndex = limbIndex + 1
    digitPosition = digitPosition - 1
  maskTop(result)

proc addLimited(firstNumber: seq[int], secondNumber: seq[int]): seq[int] =
  result = newSeq[int](limbCount)
  var carry = 0
  for limbIndex in 0 .. limbCount - 1:
    let total = firstNumber[limbIndex] + secondNumber[limbIndex] + carry
    result[limbIndex] = total mod limbBase
    carry = total div limbBase
  maskTop(result)

proc subtractLimited(firstNumber: seq[int], secondNumber: seq[int]): seq[int] =
  result = newSeq[int](limbCount)
  var borrow = 0
  for limbIndex in 0 .. limbCount - 1:
    var difference = firstNumber[limbIndex] - secondNumber[limbIndex] - borrow
    if difference < 0:
      difference = difference + limbBase
      borrow = 1
    else:
      borrow = 0
    result[limbIndex] = difference
  maskTop(result)

proc multiplyLimited(firstNumber: seq[int], secondNumber: seq[int]): seq[int] =
  result = newSeq[int](limbCount)
  for outerIndex in 0 .. limbCount - 1:
    if firstNumber[outerIndex] == 0:
      continue
    var carry = 0
    for innerIndex in 0 .. limbCount - outerIndex - 1:
      let total = firstNumber[outerIndex] * secondNumber[innerIndex] +
                  result[outerIndex + innerIndex] + carry
      result[outerIndex + innerIndex] = total mod limbBase
      carry = total div limbBase
  maskTop(result)

proc addSmall(number: seq[int], extraValue: int): seq[int] =
  result = newSeq[int](limbCount)
  for limbIndex in 0 .. limbCount - 1:
    result[limbIndex] = number[limbIndex]
  var extra = extraValue
  var limbIndex = 0
  while extra > 0 and limbIndex < limbCount:
    let total = result[limbIndex] + extra
    result[limbIndex] = total mod limbBase
    extra = total div limbBase
    limbIndex = limbIndex + 1
  maskTop(result)

proc digitSquareSum(number: seq[int]): int =
  var sumOfSquares = 0
  let remainder = modulusDigits mod limbDigits
  for limbIndex in 0 .. limbCount - 1:
    var limbValue = number[limbIndex]
    var digitTotal = limbDigits
    if limbIndex == limbCount - 1 and remainder != 0:
      digitTotal = remainder
    for digitIndex in 0 .. digitTotal - 1:
      let digitValue = limbValue mod 10
      sumOfSquares = sumOfSquares + digitValue * digitValue
      limbValue = limbValue div 10
  return sumOfSquares
```

Parsing reads only the final m digits of each token.
Multiplication skips limbs above the modulus cutoff.
The top limb is masked when m is not a multiple of four.

**Evaluation and difference walk.** Horner seeds the table, and additions advance it.

```nim
let degree = nextInt(inputData, scanPos)
let startDigits = nextDigits(inputData, scanPos)
let answerCount = nextInt(inputData, scanPos)
modulusDigits = nextInt(inputData, scanPos)
limbCount = (modulusDigits + limbDigits - 1) div limbDigits
topMask = limbBase
let remainder = modulusDigits mod limbDigits
if remainder != 0:
  topMask = 1
  for digitIndex in 1 .. remainder:
    topMask = topMask * 10

var coefficients = newSeq[seq[int]](degree + 1)
for coefficientIndex in 0 .. degree:
  coefficients[coefficientIndex] = parseLimited(nextDigits(inputData, scanPos))
let startNumber = parseLimited(startDigits)

var evaluations = newSeq[seq[int]](degree + 1)
for offset in 0 .. degree:
  let evaluationPoint = addSmall(startNumber, offset)
  var accumulator = coefficients[0]
  for coefficientIndex in 1 .. degree:
    accumulator = addLimited(multiplyLimited(accumulator, evaluationPoint),
                             coefficients[coefficientIndex])
  evaluations[offset] = accumulator

var differences = newSeq[seq[int]](degree + 1)
for index in 0 .. degree:
  differences[index] = evaluations[index]
for order in 1 .. degree:
  var index = degree
  while index >= order:
    differences[index] = subtractLimited(differences[index], differences[index - 1])
    index = index - 1

for answerIndex in 0 .. answerCount - 1:
  appendOutput($digitSquareSum(differences[0]))
  outputBuffer.add '\n'
  for order in 0 .. degree - 1:
    differences[order] = addLimited(differences[order], differences[order + 1])

stdout.write outputBuffer
outputBuffer.setLen 0
```

Horner runs only `n + 1` times, once per seed point.
Each difference step advances every order with one addition.
The highest difference stays fixed, since the polynomial degree is `n`.

## Complexity

Seeding costs a handful of limited multiplications, and each answer costs a short chain of additions.

| phase | time | space |
|---|---|---|
| input and parsing | one pass over digit strings | input string |
| Horner seeds | O(n^2 * m^2 / 16) limb work | coefficient limbs |
| difference walk | O(k * n * m / 4) limb adds | difference table |
| output | one block flush per 128 KiB | output buffer |

The phase table shows that the per-answer work stays linear in the limb count.

| measure | Big O |
|---|---|
| time | O(n^2 * m^2 + k * n * m) limb operations |
| space | O(n * m) limbs |

Fresh Horner evaluation for every point costs O(k * n * m^2) limb operations, which the difference walk avoids.
