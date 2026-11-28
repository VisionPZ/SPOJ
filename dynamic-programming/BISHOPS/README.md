# BISHOPS — Bishops (SPOJ)

<https://www.spoj.com/problems/BISHOPS/>

## Problem

For each board size N, report the most bishops that fit on an N×N board with no two on the same diagonal. The answer is 1 for N=1 and 2*N-2 otherwise.

Input: several lines, each holding one positive integer N, with no test count. Output: one answer per line, in the same order.

The bounds from the statement and judge:

| Item | Bound |
|---|---|
| board size N | 1 ≤ N ≤ 10^100 |
| number of boards | until end of input |
| answer digits | at most 101 |
| judge limit | 1000 ms, 1536 MB |

Only the digit count drives the design, and it never exceeds 101.

The sample case:

```
2
3
```

```
2
4
```

## Idea

Give each sloping lane at most one bishop, like parking one car per marked lane. A bishop never leaves its diagonal, so one bishop per lane already fills the board's capacity.

There are 2*N-1 lanes in one sloping direction. For N≥2, the two one-square lanes sit at opposite corners on the same other lane, so only one of them can hold a bishop. That gives 2*N-2. The one-square board is the single exception.

The algorithm is decimal string arithmetic with borrow and carry. It decrements the board size, then doubles the result. Each pass costs O(D) digit steps, where D is the digit count and D ≤ 101.

A placement search branches over squares and grows exponentially with N. Machine integers also overflow above 10^19. Two digit passes avoid both problems and stay exact.

## Why It Works

1. Two bishops on the same sloping lane threaten each other, so every lane holds at most one bishop.
2. One sloping direction has 2*N-1 lanes. The two shortest lanes are opposite corners sharing the other sloping direction, so they cannot both be used for N≥2. The upper bound is 2*N-2.
3. Put N bishops on one edge and N-2 on the opposite edge, skipping its two corners. No pair shares a lane, so the bound is reached.
4. The one-square board holds one bishop. Decimal digits keep the answer exact at 10^100, where fixed-width integers fail.

The terms used below:

| Term | Meaning |
|---|---|
| `2*N-2` | answer for two or more squares per side |
| `1` | answer for one square |
| `D` | digit count of N, at most 101 |
| `decrementDecimal` | schoolbook borrow that computes N-1 |
| `doubleDecimal` | schoolbook carry that computes 2*(N-1) |

Both passes touch each digit once, so the arithmetic stays exact.

A script-traced worked example:

```
N=3 (1 digits)
  decrementDecimal -> 2
  doubleDecimal    -> 4
  check            -> 2*N-2 = 4

N=10 (2 digits)
  decrementDecimal -> 9
  doubleDecimal    -> 18
  check            -> 2*N-2 = 18

N=100 (3 digits)
  decrementDecimal -> 99
  doubleDecimal    -> 198
  check            -> 2*N-2 = 198

N=1000...000 (101 digits)
  decrementDecimal -> 9999...999
  doubleDecimal    -> 1999...998
  check            -> 2*N-2 = 1999...998
```

The trace turns 3 into 4 and 10 into 18, matching the sample rule.

## Code

**Constants.** The byte offset and block size are fixed.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
```

The digit offset converts a byte into a value. The block size keeps writes near 128 KiB. Neither value changes per board.

**Digit reversal.** Turns reversed digits back into decimal order.

```nim
proc reverseDigits(value: string): string =
  result = newString(value.len)
  for digitIndex in 0 ..< value.len:
    result[digitIndex] = value[value.len - 1 - digitIndex]
```

The allocation matches the digit count. The loop runs once per answer. Cost is O(D).

**Doubling.** Multiplies the decimal digits by two.

```nim
proc doubleDecimal(value: string): string =
  var reversedDigits = ""
  var carry = 0
  for digitIndex in countdown(value.len - 1, 0):
    let digitValue = int(value[digitIndex]) - firstDigitValue
    let doubledValue = digitValue * 2 + carry
    reversedDigits.add char(doubledValue mod 10 + firstDigitValue)
    carry = doubledValue div 10
  if carry > 0:
    reversedDigits.add char(carry + firstDigitValue)
  return reverseDigits(reversedDigits)
```

Digits are processed right to left, as on paper. `carry` never exceeds one. Cost is O(D) per board.

**Decrement.** Subtracts one with a borrow.

```nim
proc decrementDecimal(value: string): string =
  var digits = newString(value.len)
  for digitIndex in 0 ..< value.len:
    digits[digitIndex] = value[digitIndex]
  var borrowIndex = value.len - 1
  while borrowIndex >= 0 and digits[borrowIndex] == '0':
    digits[borrowIndex] = '9'
    borrowIndex -= 1
  if borrowIndex >= 0:
    digits[borrowIndex] = char(int(digits[borrowIndex]) - 1)
  var firstNonZero = 0
  while firstNonZero < digits.len - 1 and digits[firstNonZero] == '0':
    firstNonZero += 1
  return digits[firstNonZero .. digits.len - 1]
```

The loop borrows across trailing zeros. `firstNonZero` removes the leading zero after a borrow. Cost is O(D).

**Answer rule.** Applies the closed form.

```nim
proc bishopsAnswer(boardSize: string): string =
  if boardSize == "0": return "0"
  if boardSize == "1": return "1"
  return doubleDecimal(decrementDecimal(boardSize))
```

The single square and zero end at once. Every larger board uses two digit passes. No placement search runs.

**Token reader.** Finds the next run of digits.

```nim
proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  if tokenStart == pos:
    return ""
  var firstDigit = tokenStart
  while firstDigit < pos - 1 and data[firstDigit] == '0':
    firstDigit += 1
  return data[firstDigit .. pos - 1]
```

Line breaks and spaces are skipped by index. Leading zero bytes are dropped. The `pos` parameter keeps the scan position across calls.

**Driver.** Reads the stream once and writes in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

while true:
  let boardSize = nextToken(inputData, scanPos)
  if boardSize.len == 0: break
  outputBuffer.add bishopsAnswer(boardSize)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops when no digits remain. One newline follows each answer. The final write covers the tail.

## Complexity

The work splits into reading, two digit passes, and buffered writes.

| Phase | Time | Space |
|---|---|---|
| input read | one pass over input bytes | input bytes |
| token scan | one pass over each board's digits | one token slice |
| digit arithmetic | two passes over at most 101 digits | one answer string |
| output | one write per 128 KiB block | block buffer |

Each board costs a few hundred byte operations, independent of the number of boards.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| time | O(total input digits) |
| space | O(input bytes + 128 KiB) |

A placement search grows exponentially with board size, while this method stays linear in digits.
