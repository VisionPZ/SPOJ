# P3FIFELE — Il Quinto Elemento (SPOJ)

<https://www.spoj.com/problems/P3FIFELE/>

## Problem

Read a bracketed list of integers and print the square of its fifth element, or 0 when no fifth element exists.

The input holds one line with bracketed integers separated by commas. The output holds one integer on one line.

The statement and judge give these bounds:

| item | bound |
|---|---|
| list values | signed integers, up to 10^18 in the generated tests |
| list length | any length, including zero |
| judge limit | 1000 ms, 1536 MB |

A short list cannot supply a fifth value.

Sample input:

```
[3,4,2,7,3,6,12]
```

Sample output:

```
9
```

## Idea

Take the fifth number like picking the fifth card from a row, then multiply it by itself.

A hand scanner walks the input once and stops after five numbers. Schoolbook digit multiplication squares the value without overflowing a fixed integer type. Scanning and storing the whole list would waste time on huge inputs. Stopping early keeps the scan short.

Early exit and exact digit arithmetic give a short, safe path.

## Why It Works

1. The scanner skips every character except minus signs and digits.
2. A minus sign flips the sign of the digits that follow it.
3. The fifth parsed value is the number to square.
4. A list with fewer than five values yields 0.
5. Digit pairs multiply into small integer buckets that carry to the next place.
6. The digit arrays stay short, so every digit of the square survives.

The main terms are these:

| term | meaning |
|---|---|
| `foundCount` | how many numbers the scanner has read |
| `fifthValue` | the value stored from the fifth number |
| `digits` | the target number, least significant digit first |
| `product` | the digit buckets before carrying |
| `digitText` | the square written from most significant digit down |

The buckets hold the exact square before the text is built.

A script-traced example from `gen.py`:

```
list 3 4 2 7 3 6 12
fifth element 3
square 9
```

The fifth value is 3, so the printed square is 9.

## Code

**Bulk input and hand scanner.** This block loads stdin and reads signed integers by index.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, value: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
    if pos >= data.len or data[pos] < '0' or data[pos] > '9':
      return false
  value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -value
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts minus signs because the list can hold negative values.
A lone minus sign is ignored instead of becoming a zero.
The buffer flushes after about 128 KiB of text.
Each parsed token costs one pass over its digits.

**Exact square.** This block multiplies the decimal digits and carries the totals.

```nim
proc squareDigits(value: int64): string =
  var magnitude = value
  if magnitude < 0:
    magnitude = -magnitude
  var digits = newSeq[int]()
  while magnitude > 0:
    digits.add(int(magnitude mod 10))
    magnitude = magnitude div 10
  if digits.len == 0:
    digits.add 0
  var product = newSeq[int](digits.len * 2 + 1)
  for leftIndex in 0 .. digits.len - 1:
    for rightIndex in 0 .. digits.len - 1:
      product[leftIndex + rightIndex] += digits[leftIndex] * digits[rightIndex]
  for carryIndex in 0 .. product.len - 2:
    product[carryIndex + 1] += product[carryIndex] div 10
    product[carryIndex] = product[carryIndex] mod 10
  var topIndex = product.len - 1
  while topIndex > 0 and product[topIndex] == 0:
    topIndex -= 1
  var digitText = ""
  var digitIndex = topIndex
  while digitIndex >= 0:
    digitText.add char(ord('0') + product[digitIndex])
    digitIndex -= 1
  return digitText
```

The sign is dropped because a square is never negative.
One carry pass turns every bucket into a single decimal digit.
Leading zero buckets are skipped when the text is built.
The cost is quadratic in the number of input digits.

**Driver.** This block keeps the fifth value and writes the answer.

```nim
var foundCount = 0
var fifthValue: int64 = 0
var currentValue: int64 = 0
while nextInt(inputData, scanPos, currentValue):
  foundCount += 1
  if foundCount == 5:
    fifthValue = currentValue
    break
if foundCount >= 5:
  appendOutput(squareDigits(fifthValue))
else:
  appendOutput("0")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop exits after the fifth number, not after the end of the list.
The count distinguishes a missing fifth value from a fifth value of zero.
One final write flushes the remaining text.

## Complexity

The work splits into input scanning, digit multiplication, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over all stdin bytes | one input string |
| squaring | one pass over digit pairs | two small digit arrays |
| output | one line | block buffer |

The bulk read touches every input byte; the later phases stay tiny.

The asymptotic costs are these:

| measure | Big O |
|---|---|
| time | O(input bytes + digits × digits) |
| space | O(input bytes + digits) |

A fixed-width multiply would overflow for large fifth values.
The digit method keeps every digit exact.
