# BINSTIRL — Binary Stirling Numbers (SPOJ)
<https://www.spoj.com/problems/BINSTIRL/>

## Problem

A teacher splits n students into m non-empty groups. The Stirling number S(n, m) counts the splits, and the problem asks only whether that count is odd. Print 1 for odd and 0 for even.

Input starts with a data set count d. Each following line holds two integers n and m with 1 ≤ m ≤ n ≤ 10^9. Output one bit per line.

The bounds keep each answer tiny:

| Value | Bound |
| --- | --- |
| Data sets d | at most 200 |
| Items n | up to 10^9 |
| Groups m | 1 to n |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Each answer is one bit, so the output stays small.

The sample input and output:

```
1
4 2
```

```
1
```

The single case asks for the parity of S(4, 2), which is 1.

## Idea

Replace the big counting table with one bitwise test. Write t for n - m and a for (m - 1) div 2. The answer is 1 exactly when t and a share no set bit. Think of two bit strings as two stacks of coins: adding them without a carry keeps every coin visible, so the parity survives.

The program reads each pair and applies a single AND test. This is a closed form derived from the Stirling recurrence and Lucas's theorem (a rule for binomial coefficients modulo a prime). It costs O(1) per data set. Filling the recurrence table would need n times m entries and cannot fit at n = 10^9.

Takeaway: one AND replaces a billion-cell table.

## Why It Works

1. Let F_m(t) = S(t + m, m) mod 2, so t counts the items beyond one per group.
2. The recurrence S(n, m) = m S(n-1, m) + S(n-1, m-1) becomes F_m(t) = (m mod 2) F_m(t-1) + F_{m-1}(t).
3. A generating function (a polynomial whose coefficients form a sequence) turns that rule into a closed form. The result is P_m = 1 / (1 + z)^h, with h = (m + 1) div 2.
4. The coefficient of z^t is C(t + h - 1, h - 1), and h - 1 equals a.
5. Lucas's theorem makes that coefficient odd exactly when every 1-bit of a also appears in t + a.
6. Adding t and a creates no carry precisely when t and a share no 1-bit, so the AND test decides parity.

The terms map to code variables.

| Term | Meaning |
| --- | --- |
| t | extraItems, which is n - m |
| a | maskBits, which is (m - 1) div 2 |
| t and a | the bitwise AND written `(extraItems and maskBits)` |
| result 1 | the AND is zero, so the parity is odd |

Every pair reduces to those four entries.

A script generated two examples:

| Quantity | n = 12, m = 5 | n = 10, m = 5 |
| --- | --- | --- |
| t = n - m | 7 = 0111 | 5 = 0101 |
| a = (m - 1) div 2 | 2 = 0010 | 2 = 0010 |
| t and a | 2 = 0010 | 0 = 0000 |
| Answer | 0 | 1 |

The first pair shares a bit and prints 0; the second shares none and prints 1.

## Code

**Scanner and buffered input.**
```nim
proc nextInt(inputData: string, i: var int): int =
  const firstDigitValue = 48
  while i < inputData.len and ord(inputData[i]) < firstDigitValue:
    inc i
  result = 0
  while i < inputData.len and ord(inputData[i]) >= firstDigitValue:
    result = result * 10 + ord(inputData[i]) - firstDigitValue
    inc i

const flushBlockBytes = 1 shl 18

var inputData = newStringOfCap(1 shl 16)
var inputLine: string
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')

var outputBuffer = newStringOfCap(flushBlockBytes)
```
The scanner skips bytes below the digit zero and builds each integer. `flushBlockBytes` sets the output block size. The line loop gathers the whole stream into `inputData`.

**Main loop.**
```nim
let dataSetCount = nextInt(inputData, i)
for j in 0 ..< dataSetCount:
  let totalItems = nextInt(inputData, i)
  let subsetCount = nextInt(inputData, i)
  let extraItems = totalItems - subsetCount
  let maskBits = (subsetCount - 1) div 2
  if (extraItems and maskBits) == 0:
    outputBuffer.add('1')
  else:
    outputBuffer.add('0')
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
if outputBuffer.len > 0:
  stdout.write outputBuffer
```
For each data set, the program reads `totalItems` and `subsetCount`. `extraItems` and `maskBits` hold t and a. A zero AND appends '1', otherwise '0', and the buffer flushes at the block boundary.

## Complexity

Input and output dominate a fixed amount of arithmetic.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Per data set | one subtraction, one division, one AND | O(1) |
| Output | one write per block | flushBlockBytes |
| Total | O(input bytes + d) | O(input bytes) |

Work per data set never grows with n.

| Measure | Big O |
| --- | --- |
| Time per data set | O(1) |
| Space per data set | O(1) |

The recurrence builds an n by m table in O(n m) time. That table cannot fit at n = 10^9. This closed form answers each case instantly.
