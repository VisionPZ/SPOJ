# CHI_SIN — The real sine (SPOJ)

<https://www.spoj.com/problems/CHI_SIN/>

## Problem
A decimal in the first half turn needs 101 significant digits of its sine.
The first line is the case count. Each next line holds one real number from zero up to but excluding pi.
Input numbers may use plain decimals or exponent notation.
Negative values and values past pi also occur in probe data.
| item | bound |
|---|---|
| test cases | first input line; generated inputs use about 160 |
| input | 0 <= x < pi, at most 101 decimal digits |
| output | 101 significant digits, zeros and point removed |
| working digits | 380 fractional digits |
| judge limit | 1000 ms, 1536 MB |

Arguments near pi/2 demand a precise circle constant.

Sample input:

```
2
0
1.5707963267948966
```

Sample output:

```
0
99999999999999999999999999999999981507813299633318447401631655066443910339246693874482714867916134939
```

## Idea
Think of folding a paper strip into a smaller quadrant before measuring. The solution uses fixed-point limbs, a Machin pi constant, and sine or cosine Taylor series. One case costs about a hundred limb products. Exponent tokens become plain decimals before parsing. Full turns are removed by repeated doubling.

## Why It Works
1. Pi comes from 16*atan(1/5) minus 4*atan(1/239), computed once.
2. Reflections map the argument into the first quadrant, then into the first eighth turn.
3. The sine series uses odd factorial denominators; the cosine series uses even ones.
4. Subtracting the input from pi/2 preserves the small gap that controls near-one answers.
5. Exponent notation expands by moving the decimal point, with no float rounding.
6. Doubling finds a full turn in logarithmic steps, then binary subtraction removes it.
7. A leading minus sign is carried through to the output when the sine is negative.

| term | meaning |
|---|---|
| `circleConstant` | pi in fixed-point form |
| `fullTurn` | two times pi |
| `halfCircle` | pi divided by two |
| `quarterCircle` | pi divided by four |
| `turnSign` | flag for a remainder above pi |
| `useCosine` | flag selecting cosine instead of sine after reflection |

Reflection makes the Taylor series converge quickly. Zero returns the digit zero. Tiny arguments give leading nines because their sine sits just below a power of ten.

Script trace for a sample case:

```
half-circle minus input: 1.92313216916397514420985846996875529104874722961539082031431044993140174126710585339910740432566411533235469223047752911158626797040642405587251420513509692605527798223114744774651909822144054878329667230642378241168933915826356009545728242834617301743052271633241066968036301245706368622935033031577940874407604604814146270458576821839462951800056652652744102333E-17
cosine term 1: 1.8492186700366681552598368344933556659595701574822813052339167966358085666820976670693573436847333912782004374693807982320634848860222290035167028410926238930294852167822159135594230509787054971515195316041312764537482196815491248821131557138274121295360821863357995369448843391678266594582417566152770285651743880487812948196366447943713411951545105739809328769878838620923219616E-34
subtract the term from 1, then keep the first 101 digits
first 101 digits: 999999999999999999999999999999999815...
```

Each fixed-point product truncates downward. The formatter truncates to 101 digits; the 380-place working scale leaves ample guard room for tiny arguments.

## Code

**Representation and constants.**

```nim
const limbBase = 1000000000
const fractionalDigits = 380
const outputDigits = 101
const flushBlockBytes = 1 shl 17
```

```nim
type BigNumber = seq[int32]
type Reduction = tuple[reduced: BigNumber, negative: bool]
```

The working scale is 380 places for every case.

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

Schoolbook multiplication keeps all decimal digits.

**Input expansion.**

```nim
proc expandExponent(token: string): string =
  var mantissa = ""
  var exponentText = ""
  var seenExponent = false
  for character in token:
    if character == 'e' or character == 'E':
      seenExponent = true
    elif seenExponent:
      exponentText.add character
    else:
      mantissa.add character
  if not seenExponent: return token
  var exponentValue = 0
  var exponentNegative = false
  for character in exponentText:
    if character == '-':
      exponentNegative = true
    elif character >= '0' and character <= '9':
      exponentValue = exponentValue * 10 + ord(character) - 48
  var wholeDigits = ""
  var fractionDigits = ""
  var afterPoint = false
  for character in mantissa:
    if character == '.':
      afterPoint = true
    elif character >= '0' and character <= '9':
      if afterPoint:
        fractionDigits.add character
      else:
        wholeDigits.add character
  var allDigits = wholeDigits & fractionDigits
  if allDigits.len == 0: return "0"
  var pointPosition = wholeDigits.len
  if exponentNegative:
    pointPosition = pointPosition - exponentValue
  else:
    pointPosition = pointPosition + exponentValue
  if pointPosition <= -101:
    var tiny = "0."
    for _ in 1 .. 100: tiny.add '0'
    tiny.add '1'
    return tiny
  if pointPosition > 400: pointPosition = 400
  var rendered = ""
  if pointPosition <= 0:
    rendered = "0."
    for _ in 1 .. -pointPosition: rendered.add '0'
    rendered.add allDigits
  elif pointPosition >= allDigits.len:
    rendered = allDigits
    for _ in 1 .. pointPosition - allDigits.len: rendered.add '0'
  else:
    for index in 0 .. pointPosition - 1: rendered.add allDigits[index]
    rendered.add '.'
    for index in pointPosition .. allDigits.len - 1: rendered.add allDigits[index]
  return rendered
```

```nim
proc isNegative(token: string): bool =
  for character in token:
    if character == '-': return true
    if character >= '0' and character <= '9': return false
  return false
```

Exponent expansion moves the point before fixed-point parsing. A leading minus is recorded separately.

**Circle constant.**

```nim
proc arctanSeries(argument: BigNumber): BigNumber =
  let squared = multiplyFixed(argument, argument)
  var term = argument
  var total = argument
  var sign = -1
  var denominator = 1
  while denominator <= 1400:
    term = multiplyFixed(term, squared)
    denominator = denominator + 2
    if sign > 0:
      total = addBig(total, divideSmall(term, int32(denominator)))
    else:
      let quotient = divideSmall(term, int32(denominator))
      if compareBig(total, quotient) < 0: break
      total = subtractBig(total, quotient)
    sign = -sign
    if term.len == 0: break
  return total

proc machinPi(): BigNumber =
  let unitValue = powerOfTen(fractionalDigits)
  let fifth = divideSmall(unitValue, 5)
  let twoThirtyNinth = divideSmall(unitValue, 239)
  let first = scaledSmall(arctanSeries(fifth), 16)
  let second = scaledSmall(arctanSeries(twoThirtyNinth), 4)
  return subtractBig(first, second)
```

Machin formula terms alternate and shrink by 1/25.

**Sine evaluation.**

```nim
proc sineSeries(argument: BigNumber): BigNumber =
  let squared = multiplyFixed(argument, argument)
  var term = argument
  var total = argument
  var denominator = 1
  var sign = -1
  while denominator <= 900:
    term = multiplyFixed(term, squared)
    denominator = denominator + 1
    term = divideSmall(term, int32(denominator))
    denominator = denominator + 1
    term = divideSmall(term, int32(denominator))
    if term.len == 0: break
    if sign > 0:
      total = addBig(total, term)
    else:
      total = subtractBig(total, term)
    sign = -sign
  return total
```

```nim
proc cosineSeries(argument: BigNumber): BigNumber =
  let unitValue = powerOfTen(fractionalDigits)
  let squared = multiplyFixed(argument, argument)
  var term = unitValue
  var total = unitValue
  var denominator = 0
  var sign = -1
  while denominator <= 900:
    term = multiplyFixed(term, squared)
    denominator = denominator + 1
    term = divideSmall(term, int32(denominator))
    denominator = denominator + 1
    term = divideSmall(term, int32(denominator))
    if term.len == 0: break
    if sign > 0:
      total = addBig(total, term)
    else:
      total = subtractBig(total, term)
    sign = -sign
  return total
```

```nim
proc reduceToHalfTurn(value: BigNumber, circleConstant: BigNumber): Reduction =
  let fullTurn = scaledSmall(circleConstant, 2)
  var remainder = value
  if compareBig(remainder, fullTurn) >= 0:
    var multiples: seq[BigNumber] = @[fullTurn]
    while true:
      let next = addBig(multiples[multiples.len - 1], multiples[multiples.len - 1])
      if compareBig(next, remainder) > 0: break
      multiples.add next
    for index in countdown(multiples.len - 1, 0):
      if compareBig(remainder, multiples[index]) >= 0:
        remainder = subtractBig(remainder, multiples[index])
  var turnSign = false
  if compareBig(remainder, circleConstant) >= 0:
    remainder = subtractBig(fullTurn, remainder)
    turnSign = true
  return (remainder, turnSign)
```

```nim
proc sineFixed(value: BigNumber, circleConstant: BigNumber): BigNumber =
  let unitValue = powerOfTen(fractionalDigits)
  let halfCircle = divideSmall(circleConstant, 2)
  let quarterCircle = divideSmall(circleConstant, 4)
  var reduced = value
  if compareBig(reduced, halfCircle) > 0:
    reduced = subtractBig(circleConstant, reduced)
  var useCosine = false
  if compareBig(reduced, quarterCircle) > 0:
    reduced = subtractBig(halfCircle, reduced)
    useCosine = true
  if useCosine:
    return cosineSeries(reduced)
  return sineSeries(reduced)
```

Reflection, series choice, range reduction, and formatting finish each case.

**Bulk input and block output.**

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var position = 0
let caseCount = nextIndex(inputData, position)
let circleConstant = machinPi()
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let argumentToken = nextToken(inputData, position)
  let tokenNegative = isNegative(argumentToken)
  let argumentValue = parseFixed(expandExponent(argumentToken))
  let reduction = reduceToHalfTurn(argumentValue, circleConstant)
  let answer = sineFixed(reduction.reduced, circleConstant)
  var rendered = formatSignificant(answer)
  if (tokenNegative xor reduction.negative) and answer.len > 0:
    rendered = "-" & rendered
  outputBuffer.add rendered
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The main loop reads all lines, then writes one block per 128 KiB.

## Complexity
| phase | time | space |
|---|---|---|
| input read | one pass over lines, then one digit pass per token | input bytes |
| input expansion | one pass per exponent token | token bytes |
| turn reduction | logarithmic doubling and subtraction | turn list |
| big-integer core | schoolbook limb products and shifts per call | limb arrays |
| series evaluation | one fixed-point evaluation per test case | constant limb arrays |
| output write | one `stdout.write` per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(k * d^2) for d working limbs and k series steps, plus O(log x) turns |
| space | O(d) limbs plus the input buffer |

A naive float or builtin integer path loses the required digits. Fixed-point limbs
keep every digit, so the extra cost buys exact decimal output.

The Machin series runs once, not once per test case.
