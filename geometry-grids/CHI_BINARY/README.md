# CHI_BINARY — Binary numbers (SPOJ)

<https://www.spoj.com/problems/CHI_BINARY/>

## Problem

Read binary operation codes and binary operands, then print each binary result. Division prints a quotient and a remainder, and subtraction wraps the first operand when needed.

Input: a binary test count, then three binary tokens per case: operator, first operand, second operand.
Output: one line per case. Division prints two binary numbers separated by a space.

| code | operation | printed result |
|---|---|---|
| `0` | greater than | `1` or `0` |
| `1` | addition | the sum |
| `10` | subtraction | the difference after optional wrap |
| `11` | multiplication | the product |
| `100` | division | quotient, space, remainder |

For subtraction, if the first operand is smaller, add 2^N to it, where N is the smallest exponent with 2^N greater than the larger operand. A zero divisor prints `0 0`. Operands use at most 200 bits.

| item | bound |
|---|---|
| operand bit length | at most 200 |
| judge limit | 1000 ms |
| memory | 1536 MB |

Verbatim sample from the statement:

```
111
0 10 10
1 10 11
0 11 10 
11 101 11
10 11 10
100 1011 11
10 10 11
```

```
0
101
1 
1111
1
11 10
11
```

## Idea

Picture an abacus whose beads are grouped in blocks of thirty. Each block holds one 30-bit limb, and ordinary column arithmetic works on those blocks.

The real algorithm stores each number as little-endian 30-bit limbs, then uses grade-school carry addition, borrow subtraction, schoolbook multiplication, and restoring binary long division. Each limb costs a fixed number of word operations.

## Why It Works

1. A limb holds values below 2^30, so a product of two limbs stays below 2^60 and fits in a signed 64-bit integer.
2. Carry and borrow propagate one limb at a time, so addition and subtraction are exact.
3. Multiplication accumulates each partial product into its target limb and carries the overflow upward.
4. Long division shifts the remainder one bit at a time and subtracts the divisor whenever the remainder reaches it.
5. The loop invariant is that the current remainder is always smaller than the divisor after a subtraction.
6. For wrapped subtraction, 2^N exceeds the larger operand, so the wrapped first operand is at least the second one and the result is positive.

| term | meaning |
|---|---|
| `BigNumber` | little-endian sequence of 30-bit limbs |
| `limbBase` | 2^30, the radix of each limb |
| `limbMask` | 2^30 minus one, keeps the low 30 bits |
| `normalizeNumber` | removes leading zero limbs |
| `bitLength` | number of significant bits in a value |
| `divideNumbers` | returns the quotient and remainder together |

Script-generated examples:

```
4 - 5:  max = 5, N = 3, 2^N = 8
        4 + 8 - 5 = 7, printed as 111

11 / 3: 11 = 3 * 3 + 2
        printed as 11 10

0 / 1: divisor is zero, printed as 0 0
```

The sample subtraction `10 - 11` means 2 minus 3. N is 2, so 2 plus 4 minus 3 gives 3, printed as `11`.

## Code

**Constants, types, and token reader.** The radix and block size are fixed once.

```nim
const limbBits = 30
const limbBase = 1 shl 30
const limbMask = limbBase - 1
const flushBlockBytes = 1 shl 17

type BigNumber = seq[int]
type DivisionResult = tuple[quotient: BigNumber, remainder: BigNumber]

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  if start >= pos:
    return ""
  return data[start .. pos - 1]
```

`nextToken` returns one whitespace-delimited token. The pair of constants `limbBase` and `limbMask` replaces division and modulo by a power of two with shifts and masks.

**Parsing and size.** Converts a binary token into limbs and counts significant bits.

```nim
proc normalizeNumber(value: var BigNumber) =
  while value.len > 1 and value[value.len - 1] == 0:
    value.setLen value.len - 1

proc fromBinaryText(text: string): BigNumber =
  result = @[0]
  for character in text:
    let bitValue = ord(character) - 48
    if bitValue != 0 and bitValue != 1:
      continue
    var carry = bitValue
    for index in 0 ..< result.len:
      let combined = result[index] * 2 + carry
      result[index] = combined and limbMask
      carry = combined shr limbBits
    if carry > 0:
      result.add carry
  normalizeNumber result

proc bitLength(value: BigNumber): int =
  let topLimb = value[value.len - 1]
  var topBits = 0
  var probe = topLimb
  while probe > 0:
    probe = probe shr 1
    topBits += 1
  return (value.len - 1) * limbBits + topBits
```

Parsing doubles the limbs and adds one bit per input character. `bitLength` supplies the exponent used by wrapped subtraction and long division.

**Comparison, addition, and subtraction.** Three linear passes over the limbs.

```nim
proc compareNumbers(first: BigNumber, second: BigNumber): int =
  if first.len != second.len:
    if first.len > second.len:
      return 1
    return -1
  for index in countdown(first.len - 1, 0):
    if first[index] != second[index]:
      if first[index] > second[index]:
        return 1
      return -1
  return 0

proc addNumbers(first: BigNumber, second: BigNumber): BigNumber =
  result = @[]
  var carry = 0
  var longest = first.len
  if second.len > longest:
    longest = second.len
  for index in 0 ..< longest:
    var total = carry
    if index < first.len:
      total += first[index]
    if index < second.len:
      total += second[index]
    result.add total and limbMask
    carry = total shr limbBits
  if carry > 0:
    result.add carry
  normalizeNumber result

proc subtractNumbers(first: BigNumber, second: BigNumber): BigNumber =
  result = @[]
  var borrow = 0
  for index in 0 ..< first.len:
    var current = first[index] - borrow
    if index < second.len:
      current -= second[index]
    if current < 0:
      current += limbBase
      borrow = 1
    else:
      borrow = 0
    result.add current
  normalizeNumber result
```

Comparison checks the most significant limb first. Addition keeps a carry, and subtraction borrows one whole radix when a limb goes negative.

**Multiplication and powers of two.** Product limbs are accumulated then normalized.

```nim
proc multiplyNumbers(first: BigNumber, second: BigNumber): BigNumber =
  result = newSeq[int](first.len + second.len)
  for firstIndex in 0 ..< first.len:
    var carry = 0
    for secondIndex in 0 ..< second.len:
      let target = firstIndex + secondIndex
      let combined = result[target] + first[firstIndex] * second[secondIndex] + carry
      result[target] = combined and limbMask
      carry = combined shr limbBits
    var target = firstIndex + second.len
    while carry > 0:
      let combined = result[target] + carry
      result[target] = combined and limbMask
      carry = combined shr limbBits
      target += 1
  normalizeNumber result

proc powerOfTwo(exponent: int): BigNumber =
  let limbIndex = exponent div limbBits
  result = newSeq[int](limbIndex + 1)
  result[limbIndex] = 1 shl (exponent mod limbBits)
```

Each pair of limbs contributes to one column. `powerOfTwo` builds the wrap value with a single set bit.

**Division.** Restoring long division produces quotient and remainder.

```nim
proc divideNumbers(dividend: BigNumber, divisor: BigNumber): DivisionResult =
  result.quotient = newSeq[int](dividend.len + 1)
  result.remainder = @[0]
  let totalBits = bitLength(dividend)
  for bitIndex in countdown(totalBits - 1, 0):
    var carry = (dividend[bitIndex div limbBits] shr (bitIndex mod limbBits)) and 1
    for index in 0 ..< result.remainder.len:
      let combined = result.remainder[index] * 2 + carry
      result.remainder[index] = combined and limbMask
      carry = combined shr limbBits
    if carry > 0:
      result.remainder.add carry
    normalizeNumber result.remainder
    if compareNumbers(result.remainder, divisor) >= 0:
      result.remainder = subtractNumbers(result.remainder, divisor)
      let limbIndex = bitIndex div limbBits
      result.quotient[limbIndex] = result.quotient[limbIndex] or (1 shl (bitIndex mod limbBits))
  normalizeNumber result.quotient
```

The remainder is doubled and the next dividend bit is appended each round. A quotient bit is set exactly when one subtraction succeeds.

**Binary formatting.** Converts limbs back into a text token.

```nim
proc toBinaryText(value: BigNumber): string =
  if value.len == 1 and value[0] == 0:
    return "0"
  result = ""
  let topIndex = value.len - 1
  var mask = 1
  while mask <= value[topIndex]:
    mask = mask shl 1
  mask = mask shr 1
  while mask > 0:
    if (value[topIndex] and mask) != 0:
      result.add '1'
    else:
      result.add '0'
    mask = mask shr 1
  if topIndex > 0:
    for index in countdown(topIndex - 1, 0):
      mask = 1 shl (limbBits - 1)
      while mask > 0:
        if (value[index] and mask) != 0:
          result.add '1'
        else:
          result.add '0'
        mask = mask shr 1
```

The top limb drops its leading zeros. Lower limbs always print all thirty bits, so place values stay aligned.

**Driver.** Reads the cases and dispatches each operation.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = fromBinaryText(nextToken(inputData, pos))[0]
var outputBuffer = ""
for _ in 0 ..< caseCount:
  let operatorToken = nextToken(inputData, pos)
  let firstToken = nextToken(inputData, pos)
  let secondToken = nextToken(inputData, pos)
  let operation = fromBinaryText(operatorToken)[0]
  let firstValue = fromBinaryText(firstToken)
  let secondValue = fromBinaryText(secondToken)
  case operation
  of 0:
    if compareNumbers(firstValue, secondValue) > 0:
      outputBuffer.add '1'
    else:
      outputBuffer.add '0'
  of 1:
    outputBuffer.add toBinaryText(addNumbers(firstValue, secondValue))
  of 2:
    if compareNumbers(firstValue, secondValue) >= 0:
      outputBuffer.add toBinaryText(subtractNumbers(firstValue, secondValue))
    else:
      var larger = firstValue
      if compareNumbers(secondValue, larger) > 0:
        larger = secondValue
      let shiftAmount = bitLength(larger)
      let wrapped = addNumbers(firstValue, powerOfTwo(shiftAmount))
      outputBuffer.add toBinaryText(subtractNumbers(wrapped, secondValue))
  of 3:
    outputBuffer.add toBinaryText(multiplyNumbers(firstValue, secondValue))
  of 4:
    if secondValue.len == 1 and secondValue[0] == 0:
      outputBuffer.add "0 0"
    else:
      let division = divideNumbers(firstValue, secondValue)
      outputBuffer.add toBinaryText(division.quotient)
      outputBuffer.add ' '
      outputBuffer.add toBinaryText(division.remainder)
  else:
    discard
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The five branches mirror the five codes. Subtraction picks the larger operand to compute the wrap exponent, and division handles a zero divisor before dividing.

## Complexity

| phase | time | space |
|---|---|---|
| token read | one pass over the input | input bytes |
| parse and format | one pass per bit | about seven limbs |
| add, subtract, compare | one pass per limb | about seven limbs |
| multiply | one pass per limb pair | about fourteen limbs |
| divide | one pass per bit | about seven limbs |
| output | one write per 128 KiB block | 128 KiB |

| measure | Big O |
|---|---|
| time | O(B^2) for multiplication, O(B) for other operations, with B at most 200 |
| space | O(B) per number |

A decimal big integer would need division by ten during parsing and formatting for every digit. A power-of-two radix turns those steps into shifts and masks.
