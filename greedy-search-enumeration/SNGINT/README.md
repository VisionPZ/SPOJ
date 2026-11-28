# SNGINT — Encode Integer (SPOJ)

<https://www.spoj.com/problems/SNGINT/>

## Problem

Find the smallest positive integer whose digits multiply to N, or report that none exists. Leading zeros do not count, so the product for N = 0 comes from 10.

Input begins with T, the number of test cases. Each following line holds one integer N with 0 <= N < 10^7. Print one line per case: the encoded integer M, or -1 when no encoding exists.

| item | bound |
|---|---|
| test cases T | fewer than 10001 |
| target product N | 0 to 9999999 |
| judge limit | 100 ms, 1536 MB |

The bound on N leaves at most 22 prime factors, so the answer stays a short digit string.

Sample input:

```
3
24
5
11
```

Sample output:

```
38
5
-1
```

## Idea

Factor N with digit-sized pieces, like packing a box with the largest boxes that fit first. Try digits from 9 down to 2 and divide whenever a digit fits the remaining product.

The algorithm is greedy factorization. Each case tests eight divisors, so the cost per case is constant. Scanning every candidate integer would test up to 10^7 numbers per case. Sorting the collected digits ascending yields the smallest integer for that digit multiset.

Greedy division turns an encoding problem into eight cheap divisibility tests.

## Why It Works

1. A digit d contributes a factor of d, so dividing N by d reverses one digit choice.
2. Larger digits remove more product per digit, so trying them first shortens the answer.
3. A leftover value above 1 contains a prime factor larger than 9, which no digit can supply.
4. Digit 1 adds length without changing the product, so it never appears in the smallest answer.
5. For a fixed digit multiset, ascending order gives the smallest integer.

| term | meaning |
|---|---|
| `remainingProduct` | product still left to encode |
| `collectedDigits` | digit pieces accepted so far |
| `divisor` | candidate digit, tested from 9 down to 2 |
| `smallestInteger` | output string built from sorted digits |

Each term maps to one variable in the main loop.

The worked trace uses N = 24:

```
divisor 9: 24 mod 9 != 0, skip
divisor 8: 24 / 8 = 3, keep digit 8
divisor 7, 6, 5, 4: skip
divisor 3: 3 / 3 = 1, keep digit 3
digits 8 and 3, sorted ascending, give 38
```

The trace reaches digit 3 at the end, which matches the sample answer 38.

Two guards handle N = 0 and N = 1 before the loop. A nonzero remainder after all divisors prints -1.

## Code

**Input and scanning.** One read pass builds the input string, and the hand scanner extracts integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const smallestUsefulDigit = 2
const largestUsefulDigit = 9

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
```

The scanner skips whitespace and line breaks.
Each call consumes exactly one integer.
The block costs one pass over the input bytes.

**Greedy encoding.** Each case divides by digits 9 down to 2, then emits the reversed digit list.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetProduct = nextInt(inputData, scanPos)
  if targetProduct == 0:
    appendOutput("10")
  elif targetProduct == 1:
    appendOutput("1")
  else:
    var remainingProduct = targetProduct
    var collectedDigits: array[23, char]
    var digitCount = 0
    var divisor = largestUsefulDigit
    while divisor >= smallestUsefulDigit:
      while remainingProduct mod divisor == 0:
        remainingProduct = remainingProduct div divisor
        collectedDigits[digitCount] = chr(divisor + firstDigitValue)
        digitCount += 1
      divisor -= 1
    if remainingProduct != 1:
      appendOutput("-1")
    else:
      var smallestInteger = ""
      for digitIndex in countdown(digitCount - 1, 0):
        smallestInteger.add collectedDigits[digitIndex]
      appendOutput(smallestInteger)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The digit array holds 23 slots, more than the 22 possible factors.
Countdown reverses the descending digits into ascending order.
The buffer flushes by block, never per case.

## Complexity

The work is one input pass plus a fixed number of divisions per case.

| phase | time | space |
|---|---|---|
| input read | one pass over T integers | one input string |
| factorization | eight divisor tests per case | digit array of 23 slots |
| output | one buffered line per case | block buffer |

The factorization loop dominates, and its trip count never changes.

| measure | Big O |
|---|---|
| time | O(T), with at most eight divisions per case |
| space | O(1) beyond the input and output buffers |

Scanning candidate integers instead would cost up to 10^7 checks per case, while this method uses a handful of divisions.
