## Problem

Read a count of test cases, then one decimal sum per case. A coin set is perfect when it pays every amount from zero to its total. Print the smallest coin count of a perfect set whose total equals each sum.

| Quantity | Bound |
| --- | --- |
| Test cases | c ≤ 50 |
| Sum | n ≤ 10^1000 |
| Time limit | 5923 ms |
| Memory limit | 1536 MB |

The 1000-digit sum drives the design, while the case count stays small.

## Idea

Sort the coins of a perfect set by value. Each coin must not exceed the total of smaller coins plus one. So the largest coin is at most half of n + 1, and the smaller coins form a perfect set again. Remove that largest power of two and repeat until nothing remains. The number of removals equals the bit length plus the set-bit count of n + 1, minus two. Each case costs O(d²) digit operations for d decimal digits. Enumerating all coin sets takes exponential time.

## Why It Works

A sorted coin set is perfect exactly when every coin stays at most one above the reachable total. Start with reach zero, add each coin, and extend reach by that coin. A gap appears as soon as a coin passes reach plus one. For the largest coin, the smaller coins must already be perfect, and the largest coin must fit the same rule. This gives the removal condition.

Let m stand for n + 1. The largest power of two at most m is the top power. The coin is that power divided by two, and m drops by the coin. The answer is bitLength(n + 1) + setBits(n + 1) - 2.

Let h be the bit length of m. If bit h - 2 of m is zero, removing the coin lowers the bit length by one and keeps the set-bit count. If that bit is one, the bit length stays and the set-bit count drops by one. One removal always lowers the answer formula by one, so the formula counts the removals.

The table below traces n = 29. The coins in sorted order are 1, 2, 2, 4, 4, 8, 8.

| Coin | Reach before | Fits | Reach after |
| --- | --- | --- | --- |
| 1 | 0 | yes | 1 |
| 2 | 1 | yes | 3 |
| 2 | 3 | yes | 5 |
| 4 | 5 | yes | 9 |
| 4 | 9 | yes | 13 |
| 8 | 13 | yes | 21 |
| 8 | 21 | yes | 29 |

Here n + 1 is 30. It has bit length five and four set bits. The answer is five plus four minus two, which is seven.

## Code

The first block reads the whole stream and splits it into tokens.

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

proc nextNumberBounds(data: string, i: var int, numberStart: var int, numberEnd: var int) =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  numberStart = i
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    i += 1
  numberEnd = i
```

The read loop ends at end of input, so one buffer holds every token. `nextInt` reads the small case count. `nextNumberBounds` keeps a long sum as a slice, so no big integer parse is needed. The scan visits each input byte once.

The next block adds one and counts bits by repeated halving.

```nim
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

The leading zero absorbs the carry from adding one. `digitCount` skips leading zeros before each halving pass. `halfCarry` moves from one decimal digit to the next, and its final value is the bit. The outer loop runs once per bit, so the work is quadratic in the digit count.

The last block writes the answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

The loop runs once per case. `appendOutput` flushes only after 256 KiB, so no per-line write reaches the stream. The final write empties the remaining buffer.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read and scan | O(total input bytes) | O(input size) |
| Add one | O(d) | O(d) |
| Halving passes | O(d²) | O(d) |
| Output | O(c) | O(block size) |

Here c is the case count and d is the digit count, at most 1001. Total time is O(c · d²) and total working space is O(d) plus the input buffer. Enumeration of coin sets grows exponentially with n and cannot handle these sums.
