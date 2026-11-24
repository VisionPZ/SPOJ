## Problem

Read d data sets from one input. Each data set holds two integers n and m with 1 ≤ m ≤ n ≤ 10^9. Write S(n,m) mod 2, the parity of the Stirling number of the second kind. That number counts the ways to split n items into m nonempty groups. Print one 0 or 1 per line. Write t for n - m and a for (m - 1) div 2.

The judge bounds are fixed:

| Value | Bound |
| --- | --- |
| Data sets d | 200 |
| Items n | 10^9 |
| Groups m | n |
| Time | 3000 ms |
| Memory | 1536 MB |

Every answer is one bit, so the output stays small.

## Idea

The trick replaces the recurrence with one bitwise test. Write t for n - m and a for (m - 1) div 2; the answer is 1 exactly when t and a share no set bit. This costs O(1) per data set, while the recurrence fills an n by m table that cannot fit at n = 10^9.

## Why It Works

Set F_m(t) = S(t + m, m) mod 2, so t counts the items beyond one per group. The recurrence S(n,m) = m·S(n-1,m) + S(n-1,m-1) becomes a rule on F. Substituting n = t + m gives F_m(t) = (m mod 2)·F_m(t-1) + F_{m-1}(t).

Let P_m(z) be the sum of F_m(t)·z^t over all t, with coefficients taken modulo 2. For even m, the rule gives P_m = P_{m-1}. For odd m, it gives (1 + z)·P_m = P_{m-1}.

Since S(t+1,1) = 1, the first polynomial is 1 + z + z^2 + ... . With coefficients modulo 2, dividing by 1 + z is the same as multiplying by that sum. The two rules give P_m = 1/(1+z)^h with h = (m+1) div 2.

The coefficient of z^t in 1/(1+z)^h is C(t + h - 1, h - 1), taken modulo 2. Here h - 1 equals a. Lucas's theorem says C(N,K) is odd when each 1-bit of K is also a 1-bit of N. Put N = t + a and K = a.

If t and a share no set bit, adding them creates no carry, so N keeps every 1-bit of a. If they share a bit, take the lowest shared position. No carry reaches that position from below, so 1 + 1 writes 0 there and N loses a 1-bit of a. Thus C(t+a,a) is odd exactly when t & a is zero.

A script generated these two examples:

| Quantity | n = 12, m = 5 | n = 10, m = 5 |
| --- | --- | --- |
| t = n - m | 7 = 0111 | 5 = 0101 |
| a = (m-1) div 2 | 2 = 0010 | 2 = 0010 |
| t & a | 2 = 0010 | 0 = 0000 |
| answer | 0 | 1 |

The first case shares a 1-bit and prints 0. The second case shares none and prints 1.

## Code

This scanner reads one integer from the input buffer.

```
proc nextInt(inputData: string, i: var int): int =
  const firstDigitValue = 48
  while i < inputData.len and ord(inputData[i]) < firstDigitValue:
    inc i
  result = 0
  while i < inputData.len and ord(inputData[i]) >= firstDigitValue:
    result = result * 10 + ord(inputData[i]) - firstDigitValue
    inc i
```

Every byte below the digit zero is a space or a line break. The scanner skips those bytes and builds a number from its digits. It walks the buffer once, so parsing costs O(input bytes).

Nim 0.19.4 has no single call that reads all of stdin, so lines are appended to one string.

```
const flushBlockBytes = 1 shl 18

var inputData = newStringOfCap(1 shl 16)
var inputLine: string
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')
```

The added line break keeps the numbers separate for the scanner. This pass costs O(input bytes) time and space.

The main loop reads both values, applies the bit test, and buffers the answer.

```
var outputBuffer = newStringOfCap(flushBlockBytes)
var i = 0
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

The loop runs dataSetCount times, the count read from the first line. maskBits is (m - 1) div 2, and the bitwise AND decides the answer. The buffer flushes after flushBlockBytes bytes, so output writes stay in large blocks.

## Complexity

Input reading takes O(input bytes) time and space. Each data set takes O(1) time: one subtraction, one division by two, one bitwise AND, and one byte added to the buffer. The output buffer holds at most flushBlockBytes bytes between writes. Total time is O(input size + d), and total space is O(input size + flushBlockBytes). The naive recurrence builds a table with n·m entries and runs in O(n·m) time.
