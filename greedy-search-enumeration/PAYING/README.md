# PAYING — Paying in Byteland (SPOJ)
<https://www.spoj.com/problems/PAYING/>

## Problem

Byteland coins have values 2^i, and a set is perfect when it pays every amount up to its total. For each sum n, find the fewest coins in a perfect set totaling n.

You receive up to 50 large sums. Each sum can have 1000 digits, so ordinary machine integers cannot hold it. The answer is a small coin count.

Input: the first integer is c, the number of cases. Each following line holds one integer n. Output: one integer per line, the minimum number of coins.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases c | at most 50 |
| Sum n | at most 10^1000 |
| Coin denominations | 2^i for i = 0, 1, 2, … |
| Time limit | 5923 ms |
| Memory limit | 1536 MB |

The sample asks for five sums:

```
5
507
29
8574
233
149
```

```
14
7
21
11
10
```

The sum 29 needs seven coins.

## Idea

Add one to the sum, then count binary digits by repeated halving on paper. Picture halving a pile of coins: each halving is one binary digit, and each leftover coin is one more.

The program stores n as decimal digits, increments it by one with a carry, and halves it repeatedly. Each halving adds one to `bitLength`; each odd intermediate value adds one to `setBits`. The answer is `bitLength + setBits − 2`.

Why that formula works: coins 1, 2, 4, …, 2^(L−2) form a perfect chain covering zero through 2^(L−1)−1. Each extra one bit of n + 1 below its top bit needs one more coin. The chain count plus the extra count gives L − 1 + P − 1.

Halving costs O(D) per binary digit, with D ≤ 1000 digits, so one case costs O(D²). A coin search over huge sums has no practical bound.

Takeaway: decimal halving extracts a binary count without ever building a giant integer.

## Why It Works

Four facts prove the formula.

1. A perfect set of k coins covers at most 2^k − 1. Each next coin is at most one plus the total already covered, so coverage at most doubles.
2. The chain 1, 2, 4, …, 2^(L−2) is perfect and covers zero through 2^(L−1)−1 using L − 1 coins.
3. Let S = n + 1 and let its binary bits include positions e below the top. Adding one coin of value 2^e for each such bit keeps the set perfect, because 2^e never exceeds coverage plus one. The total becomes 2^(L−1)−1 + (S − 2^(L−1)) = n.
4. Fewer coins cannot work. The chain forces L − 1 coins, and each lower set bit of S forces one extra coin to reach the exact total.

These are the terms in the halving loop:

| Term | Meaning |
| --- | --- |
| `digits` | decimal digits of n + 1, least significant last |
| `carryOver` | carry produced when adding one |
| `halfCarry` | remainder 0 or 1 from dividing by two |
| `bitLength` | number of halving rounds, the binary length |
| `setBits` | number of odd intermediate values, the one bits |

A script traces the second sample case:

```
n=29, n+1=30
30 /2 = 15 remainder 0
15 /2 =  7 remainder 1
 7 /2 =  3 remainder 1
 3 /2 =  1 remainder 1
 1 /2 =  0 remainder 1
bitLength=5 setBits=4 answer=7
```

The first remainder is zero because 30 is even. Leading zeros after halving are skipped, so the loop counts exactly five bits. The answer 7 matches the sample.

## Code

**Input.** One buffer holds all lines, and the scanner finds the case count.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const decimalBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The scanner skips separators and stops at the buffer end. Only the small case count goes through `nextInt`. The cost is one pass over the input bytes.

**Coin count.** A digit slice is incremented and halved until nothing remains.

```nim
proc nextNumberBounds(data: string, i: var int, numberStart: var int, numberEnd: var int) =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  numberStart = i
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    i += 1
  numberEnd = i

proc coinCount(data: string, numberStart: int, numberEnd: int): int =
  var digits: seq[int] = @[0]
  for i in numberStart..<numberEnd:
    digits.add int(data[i]) - firstDigitValue

  var carryOver = 1
  var j = digits.len - 1
  while carryOver > 0:
    let updatedDigit = digits[j] + carryOver
    digits[j] = updatedDigit mod decimalBase
    carryOver = updatedDigit div decimalBase
    j -= 1

  var k = 0
  while k < digits.len and digits[k] == 0:
    k += 1
  var digitCount = digits.len - k

  var bitLength = 0
  var setBits = 0
  while digitCount > 0:
    bitLength += 1
    var halfCarry = 0
    for l in 0..<digitCount:
      let i = k + l
      let currentValue = halfCarry * decimalBase + digits[i]
      digits[i] = currentValue div 2
      halfCarry = currentValue mod 2
    setBits += halfCarry
    while digitCount > 0 and digits[k] == 0:
      k += 1
      digitCount -= 1

  return bitLength + setBits - 2
```

`nextNumberBounds` records a digit span without copying it. The leading zero in `digits` leaves room for a carry past the most significant digit. The inner loop divides each digit by two and passes `halfCarry`; dropping leading zeros keeps the loop short. Cost is O(D²) worst case for D digits.

**Output.** Answers gather in one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush triggers every `flushBlockBytes` bytes. No write happens inside the case loop. The cost is one pass over the answer text.

**Driver.** Each digit span becomes one answer line.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  var numberStart = 0
  var numberEnd = 0
  nextNumberBounds(inputData, i, numberStart, numberEnd)
  appendOutput($coinCount(inputData, numberStart, numberEnd))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The bounds helper advances the scan cursor for the next case. Each case allocates one digit array. The final write flushes the tail.

## Complexity

Decimal halving dominates each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Increment by one | O(D) | O(D) |
| Halving loop | O(D × bits) | O(D) |
| Output | O(cases) | O(block size) |

The halving loop dominates, with about 3.3 × 10³ rounds for a 1000-digit input.

| Measure | Big O |
| --- | --- |
| Time per case | O(D²), D = number of digits |
| Total time | O(sum of D² over cases) |
| Working space | O(D) |

Building coin values up to 10^1000 as integers is impossible, while digit halving stays tiny.
