# JULKA — Julka (SPOJ)

<https://www.spoj.com/problems/JULKA/>

## Problem

A preschool riddle asks: Klaudia and Natalia have 10 apples together, and Klaudia has 2 more. How many does each girl have? Julka answers 6 and 4 without hesitation. The teacher keeps increasing the numbers until they reach 10^100, where ordinary computer integers overflow. Read the total and the difference, then print each girl's count.

Input: exactly 10 test cases. Each case takes two lines: the total apples, then how many more Klaudia has. Output: two lines per case, Klaudia's count first.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases | exactly 10 |
| Apples per girl | at most 10^100, or 101 digits |
| Values | positive integers |
| Judge limit | 2000 ms, 1536 MB |

The numbers never fit in a 64-bit integer, which holds about 19 digits.

The smallest sample case:

```
10
2
```

```
6
4
```

## Idea

Solve the riddle as Julka does: hand Klaudia the extra apples first, then split what remains. Klaudia gets `(total + more) / 2`, Natalia gets `(total - more) / 2`. The numbers hold up to 101 digits. The program stores them as decimal strings and does the arithmetic by hand, the way you do it on paper. Addition walks right-to-left with a carry, subtraction walks right-to-left with a borrow, and halving walks left-to-right with a remainder. Cost per digit: a handful of integer operations.

A 64-bit integer tops out near 9.2 × 10^18, so it overflows on this input.

## Why It Works

Three facts carry the program.

1. The two formulas solve the riddle exactly. Their sum is `(total + more + total - more) / 2 = total`, and their difference is `more`.
2. The total and the difference always have the same parity, because both girls hold whole apples. Halving therefore leaves a remainder of zero, and `halveDecimal` can drop the remainder safely.
3. Grade-school arithmetic works column by column. Addition passes one carry to the next column, subtraction passes one borrow, and halving passes one remainder. Each digit needs only the state from the previous column.

The two outputs:

| Line | Meaning |
|---|---|
| `(total + more) / 2` | Klaudia's apples, the larger share |
| `(total - more) / 2` | Natalia's apples, the smaller share |

The two lines add back to the total and differ by the given difference.

A script-traced example with `total = 10`, `more = 2`:

```
add 10 + 2  -> 12  -> halve -> 6
sub 10 - 2  -> 8   -> halve -> 4
```

A longer example shows the carry chain. With `total = 999999999999999998` and `more = 2`:

```
add: 999999999999999998 + 2 -> 1000000000000000000 -> half -> 500000000000000000
sub: 999999999999999998 - 2 ->  999999999999999996 -> half -> 499999999999999998
```

The carry turns every trailing 9 into 0 and adds a new leading 1. The borrow turns the final 8 into 6. Both halves stay exact.

## Code

**Input and tokens.** The whole stream goes into one buffer, and the scanner walks it by index.

```nim
import strutils
const flushBlockBytes = 1 shl 17

proc readAllInput(): string =
  var inputData = ""
  var line: string
  while readLine(stdin, line):
    inputData.add line
    inputData.add "\n"
  return inputData

proc sliceBetween(text: string, i: int, j: int): string =
  if j <= i: return ""
  return text[i .. j - 1]

proc nextToken(inputData: string, i: var int): string =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var j = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  if i == j: return ""
  return sliceBetween(inputData, j, i)
```

The reader loops once over the input lines, so blank lines and odd spacing cannot desync the pairs. `nextToken` keeps `i` as a `var` parameter, so the scan position survives across calls. It allocates one small string slice per number, which is fine for 20 tokens.

**Digits in order.** One helper strips leading zeros, another reverses a digit string.

```nim
proc dropLeadingZeros(digits: string): string =
  var i = 0
  while i < digits.len - 1 and digits[i] == '0': i = i + 1
  return sliceBetween(digits, i, digits.len)

proc reverseDigits(reversed: string): string =
  var answer = newString(reversed.len)
  var i = reversed.len - 1
  var j = 0
  while i >= 0:
    answer[j] = reversed[i]
    i = i - 1
    j = j + 1
  return answer
```

`dropLeadingZeros` stops with one digit left, so zero prints as `0` and never as an empty string. `reverseDigits` runs in O(D) time and allocates one string of length D.

**Addition.** The carry moves from the last digit to the first.

```nim
proc addDecimal(first, second: string): string =
  var i = first.len - 1
  var j = second.len - 1
  var carryIndex = 0
  var reversed: string
  while i >= 0 or j >= 0 or carryIndex > 0:
    var digitSum = carryIndex
    if i >= 0:
      digitSum = digitSum + int(first[i]) - 48
      i = i - 1
    if j >= 0:
      digitSum = digitSum + int(second[j]) - 48
      j = j - 1
    reversed.add char(48 + digitSum mod 10)
    carryIndex = digitSum div 10
  var answer = reverseDigits(reversed)
  return answer
```

The loop bound is the longer input plus one possible carry digit. The final `carryIndex > 0` condition is what keeps the new leading 1 in the long example. The block costs one pass over D digits.

**Subtraction.** The borrow moves right-to-left, and the larger number comes first.

```nim
proc subtractDecimal(first, second: string): string =
  var i = first.len - 1
  var j = second.len - 1
  var borrowIndex = 0
  var reversed: string
  while i >= 0:
    var digitDiff = int(first[i]) - 48 - borrowIndex
    if j >= 0: digitDiff = digitDiff - (int(second[j]) - 48)
    if digitDiff < 0:
      digitDiff = digitDiff + 10
      borrowIndex = 1
    else:
      borrowIndex = 0
    reversed.add char(48 + digitDiff)
    i = i - 1
    if j >= 0: j = j - 1
  return dropLeadingZeros(reverseDigits(reversed))
```

The loop stops at the last digit of `first`, which is the total and never vanishes. The borrow branch adds 10 and remembers 1 for the next column. The block costs one pass over D digits.

**Halving.** The remainder moves from the first digit to the last.

```nim
proc halveDecimal(digits: string): string =
  var i = 0
  var remainder = 0
  var quotient: string
  while i < digits.len:
    var dividend = remainder * 10 + (int(digits[i]) - 48)
    quotient.add char(48 + dividend div 2)
    remainder = dividend mod 2
    i = i + 1
  return dropLeadingZeros(quotient)
```

The direction flips here because division walks left-to-right. `remainder` can only be 0 or 1, so the next dividend never exceeds 19. The last remainder is zero by parity, and the block costs one pass over D digits.

**Driver.** One case produces two lines, and output goes out in 128 KiB blocks.

```nim
var inputData = readAllInput()
var i = 0
var outputBuffer: string
while true:
  var applesTotal = nextToken(inputData, i)
  if applesTotal.len == 0: break
  var applesMore = nextToken(inputData, i)
  outputBuffer.add halveDecimal(addDecimal(applesTotal, applesMore))
  outputBuffer.add "\n"
  outputBuffer.add halveDecimal(subtractDecimal(applesTotal, applesMore))
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The `len == 0` check ends the run when the token scanner reaches the end of input. `setLen 0` reuses one allocation for the next block. The final write covers the tail, so no bytes stay in the buffer.

## Complexity

Each phase costs one pass over the D digits of a number.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Addition | O(D) with one carry | O(D) result |
| Subtraction | O(D) with one borrow | O(D) result |
| Halving | O(D) with one remainder | O(D) result |
| Output | one write per 128 KiB block | 128 KiB |
| Total, 10 cases | about 60 digit steps plus output | O(D) |

D is at most 101, so the whole run stays tiny.

| Measure | Big O |
|---|---|
| Time | O(T × D), with T = 10 and D ≤ 101 |
| Space | O(D) per operation |

A 64-bit integer fails at 19 digits. A big-integer library would work, but the three loops above are shorter and cost the same O(D).
