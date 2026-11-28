# GEOPROB — One Geometry Problem (SPOJ)

<https://www.spoj.com/problems/GEOPROB/>

## Problem

Given the three lengths b, c, and d from the figure, output the length a. The relation from the figure gives a = 2c - b - d.

| item | bound |
|---|---|
| test cases t | up to 300 |
| b, c, d | 0 to less than 10^200 |
| ordering | b < c and d < c |
| judge limit | 1000 ms, 1536 MB |

The lengths exceed machine integers, so decimal digit arithmetic is needed.

Sample input:

```
2
3 8 5
10 18 12
```

Sample output:

```
8
14
```

## Idea

Double the middle length and subtract the two shorter lengths, like measuring a board by adding twice one span and removing two gaps. Store each number as decimal digits in reverse order. One carry pass doubles c, and two borrow passes subtract b and d. A floating-point or machine-integer calculation would lose digits.

| term | meaning |
|---|---|
| `cToken` | decimal text of the middle length c |
| `digitValues` | decimal digits stored least significant first |
| `doubledDigits` | c doubled with a carry pass |
| `subtractDigits` | subtraction with a borrow pass |
| `digitsToString` | converts digits back to text |

Every pass touches each digit once.

## Why It Works

1. Reversing the digits puts the least significant digit at index zero.
2. Doubling processes carries from index zero upward, so each digit settles once.
3. Subtraction processes borrows in the same direction because left digits are at least right digits.
4. Since b < c and d < c, the value 2c - b - d stays positive.
5. Trailing zeroes in the reversed array are leading zeroes in the result, so they are removed.

| term | meaning |
|---|---|
| `carry` | value passed to the next digit during doubling |
| `borrow` | value passed to the next digit during subtraction |
| least significant first | digit order used by both passes |

Digit arithmetic preserves all 200 places.

A worked example with b = 3, c = 8, d = 5:

```
double c:      8 * 2 = 16
subtract b:   16 - 3 = 13
subtract d:   13 - 5 = 8
```

The trace returns the first sample answer.

## Code

**Input and digit reader.** The hand reader loads each large operand as text.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    token.add data[pos]
    pos += 1
  return token

proc digitValues(token: string): seq[int] =
  var digits = newSeq[int](token.len)
  for index in 0 .. token.len - 1:
    digits[index] = int(token[token.len - 1 - index]) - firstDigitValue
  var length = digits.len
  while length > 1 and digits[length - 1] == 0:
    length -= 1
  digits.setLen(length)
  return digits
```

The digit reader skips whitespace.
`digitValues` reverses the text for carry propagation.
Leading zeroes in the input are removed.

**Big-integer passes.** Doubling and subtraction use fixed digit arrays.

```nim
proc doubledDigits(digits: seq[int]): seq[int] =
  var doubledResult = newSeq[int](digits.len + 1)
  var carry = 0
  for index in 0 .. digits.len - 1:
    let doubled = digits[index] * 2 + carry
    doubledResult[index] = doubled mod 10
    carry = doubled div 10
  doubledResult[digits.len] = carry
  if carry == 0:
    doubledResult.setLen(digits.len)
  return doubledResult

proc subtractDigits(leftDigits: seq[int], rightDigits: seq[int]): seq[int] =
  var subtractedResult = newSeq[int](leftDigits.len)
  var borrow = 0
  for index in 0 .. leftDigits.len - 1:
    var digitValue = leftDigits[index] - borrow
    if index < rightDigits.len:
      digitValue -= rightDigits[index]
    if digitValue < 0:
      digitValue += 10
      borrow = 1
    else:
      borrow = 0
    subtractedResult[index] = digitValue
  var length = subtractedResult.len
  while length > 1 and subtractedResult[length - 1] == 0:
    length -= 1
  subtractedResult.setLen(length)
  return subtractedResult

proc digitsToString(digits: seq[int]): string =
  var text = ""
  var index = digits.len - 1
  while index >= 0:
    text.add char(digits[index] + firstDigitValue)
    index -= 1
  return text
```

Doubling may add one final carry digit.
Borrow never remains after the last place here.
Conversion reverses the stored order.

**Driver and output.** Each case performs two subtractions on the doubled middle length.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let bToken = nextDigits(inputData, scanPos)
  let cToken = nextDigits(inputData, scanPos)
  let dToken = nextDigits(inputData, scanPos)
  var answerDigits = doubledDigits(digitValues(cToken))
  answerDigits = subtractDigits(answerDigits, digitValues(bToken))
  answerDigits = subtractDigits(answerDigits, digitValues(dToken))
  appendOutput(digitsToString(answerDigits))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The ordering b < c and d < c keeps the result positive.
Buffered writes avoid one syscall per case.
The buffer flushes once after the loop.

## Complexity

Each digit pass is linear in the number length.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| doubling | one pass over c digits | array of c digits |
| two subtractions | two passes over the result digits | array of result digits |
| output | one line per case | block buffer |

At most 200 digits per operand keep the work small.

| measure | Big O |
|---|---|
| time | O(t * d) with d at most 200 |
| space | O(d) for one input string |

A floating-point evaluation would round away the low digits.

The digit passes give the exact answer for every test case.
