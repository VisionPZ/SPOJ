# CHI_LOG — The real logarithm (SPOJ)

<https://www.spoj.com/problems/CHI_LOG/>

## Problem
A decimal between 1 and 100 needs 101 significant digits of its natural logarithm.
The first line is the case count. Each next line holds one real number between 1 and 100.
| item | bound |
|---|---|
| test cases | not stated; generated inputs use about 160 |
| input | 1 <= x <= 100, at most 101 decimal digits |
| output | 101 significant digits, zeros and point removed |
| working digits | 380 fractional digits |
| judge limit | 1000 ms, 1536 MB |

Small logarithms need many fractional places.

Sample input:

```
2
1
3.1415926535897932384626433832
```

Sample output:

```
0
1144729885849400174143427351327752157627210731401746036785205942589070827177558730931032351538638113
```

## Idea
Think of peeling off powers of two until the number sits near one. The solution uses fixed-point limbs, repeated halving, and the atanh series. One case costs about two hundred limb products.

## Why It Works
1. Halving reduces the argument to the interval from one to two.
2. With t = (m-1)/(m+1), at most one third, the atanh series shrinks geometrically.
3. The odd powers use a separate power variable, so no extra denominator factor appears.
4. Adding k copies of the precomputed ln(2) restores the removed halvings.

| term | meaning |
|---|---|
| `mantissa` | the argument after all halvings |
| `twosRemoved` | number of halvings |
| `t` | atanh argument in the interval zero to one third |
| `logarithmOfTwo` | ln(2) computed once from the 1/3 series |

The reduction keeps the series short and accurate.

Script trace for a sample case:

```
one halving gives mantissa 1.5707963267948965579989817342720925807952880859375
atanh argument: 0.22203094070331456023118689397508173665851217275975523855627600140878723229318421200618646754609075904373459907707421030123870448943062807773131211788651788671308337093428002037348032661396437570587952786734328553317932546187782938780732258334354153290368658191787639978701155848861821855986396838823677417166375404995685840806681542301868748008112931117430187193488379954708510477
term 1: 0.0036485410941586492397016887740587579779686383381287436767160310578678065691089705226053237061396740653673231977559692731233919406782514012759514651992806818685581675046818095870252960845422578996046576586284190026087417900541090659479745017475360642310340230428221080642027534904281619578277297853603398132425577084303886535735623938100590219554520234492274262688979574419604769303
term 2: 0.00010791889514351007927297171679516875822802579109242296441385034610990513634282811104368748158605864996592098877994169098863155510486671733037123638265393039649623051028901789484000956050406820412840092073429270773396787682323863571506135349338938597395985933907173094239080564542461624600222939673008916830223272699653543331281239254907953466015488579317539725557535776715141122940
term 3: 0.0000038001124899855983529375001797437374000785931626010256597582439143703699521256283424032350916568247623707419076086380690261421422404220767406798840721485388685308880050385566482274442037601620611017239536993961646832135164489207192019342958494881548785211109915802087972768578940270438738889516680829358778769532741348378934956669239268005401574152732536443637678143088841831740959
double the sum, then add ln(2)
first 101 digits: 114472988584940013516170...
```

Truncation toward zero is used at every fixed-point shift. The formatter truncates to 101 digits, and 279 guard digits keep those digits correct.

## Code

**Representation and constants.**

```nim
const limbBase = 1000000000
const fractionalDigits = 380
const outputDigits = 101
const flushBlockBytes = 1 shl 17
```

Precision is fixed at 380 fractional digits.

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

Counts and shifts stay exact inside int64.

**Fixed-point division.**

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

Reciprocal Newton avoids a slow long division.

**Logarithm evaluation.**

```nim
proc atanhSeries(argument: BigNumber): BigNumber =
  let squared = multiplyFixed(argument, argument)
  var power = argument
  var total = argument
  var denominator = 1
  while denominator <= 900:
    power = multiplyFixed(power, squared)
    denominator = denominator + 2
    let term = divideSmall(power, int32(denominator))
    if term.len == 0: break
    total = addBig(total, term)
  return scaledSmall(total, 2)

proc logarithmFixed(value: BigNumber, logarithmOfTwo: BigNumber): BigNumber =
  let unitValue = powerOfTen(fractionalDigits)
  let twoValue = scaledSmall(unitValue, 2)
  var mantissa = value
  var twosRemoved = 0
  while compareBig(mantissa, twoValue) >= 0:
    mantissa = divideSmall(mantissa, 2)
    twosRemoved = twosRemoved + 1
  let numerator = subtractBig(mantissa, unitValue)
  let denominator = addBig(mantissa, unitValue)
  let argument = divideFixed(numerator, denominator)
  var answer = atanhSeries(argument)
  if twosRemoved > 0:
    answer = addBig(answer, scaledSmall(logarithmOfTwo, int32(twosRemoved)))
  return answer
```

A separate power variable prevents a wrong term recurrence.

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

The atanh series shrinks by 1/9 per term after halving.
