# DIVPALI — DIVISORES PALINDROMOS (SPOJ)

<https://www.spoj.com/problems/DIVPALI/>

## Problem

Given one positive integer, list its divisors whose decimal digits read the same in both directions.

The input holds a single integer `N` with `N` greater than zero. Print the matching divisors in increasing order. Separate them by commas and end the line with a newline.

| item | bound |
|---|---|
| input `N` | positive integer |
| divisor order | increasing |
| separator | comma, with no spaces |
| judge limit | 1000 ms, 1536 MB |

Every square divisor pair is recorded once, even when both members are equal.

Sample input:

```
121
```

Sample output:

```
1,11,121
```

A second example uses input 66 and output 1,2,3,6,11,22,33,66.

## Idea

A mirror shows the same label from either side; a palindrome digit string behaves the same way. Walk divisor candidates up to the square root and record each divisor with its partner. Then sort the matches and print them. This costs about sqrt(N) divisor tests. Testing every integer up to N doubles the work and adds nothing.

## Why It Works

1. Every divisor below the square root has a partner above it.
2. Trying candidates up to the square root finds both members of each pair.
3. A square divisor has itself as partner, so it is added once.
4. Comparing digits from both ends decides whether a divisor is a palindrome.
5. Sorting the collected values produces the required increasing list.

| term | meaning |
|---|---|
| `numberValue` | the input integer |
| `divisorCandidate` | current trial divisor up to the square root |
| `pairedDivisor` | partner found by dividing `numberValue` |
| `palindromicDivisors` | collected values that pass the digit test |

For 66, the candidates 1, 2, 3 and 6 pair with 66, 33, 22 and 11. All eight values read the same both ways, so the output is 1,2,3,6,11,22,33,66. For 121, the pairs are 1 with 121 and 11 with itself, giving 1,11,121.

The loop uses `int64` for products, so comparing squares stays safe.

## Code

**Palindrome test.** The digit string is compared from both ends inward.

```nim
const flushBlockBytes = 1 shl 17

proc isPalindrome(value: int64): bool =
  let digits = $value
  var leftIndex = 0
  var rightIndex = digits.len - 1
  while leftIndex < rightIndex:
    if digits[leftIndex] != digits[rightIndex]:
      return false
    leftIndex += 1
    rightIndex -= 1
  return true
```

The two indexes meet in the middle.
One mismatch ends the test early.
Single-digit values pass immediately.

**Input and divisors.** Candidates up to the square root collect both members of each pair.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberValue = int64(nextInt(inputData, scanPos))
var palindromicDivisors = newSeq[int64]()
var divisorCandidate: int64 = 1
while divisorCandidate * divisorCandidate <= numberValue:
  if numberValue mod divisorCandidate == 0:
    if isPalindrome(divisorCandidate):
      palindromicDivisors.add divisorCandidate
    let pairedDivisor = numberValue div divisorCandidate
    if pairedDivisor != divisorCandidate and isPalindrome(pairedDivisor):
      palindromicDivisors.add pairedDivisor
  divisorCandidate += 1
```

The square check keeps the loop short.
A square root divisor is added only once.
Each passing value enters the result list.

**Sort and print.** An insertion sort fixes the order before output.

```nim
for outerIndex in 1 .. palindromicDivisors.len - 1:
  let sortValue = palindromicDivisors[outerIndex]
  var innerIndex = outerIndex - 1
  while innerIndex >= 0 and palindromicDivisors[innerIndex] > sortValue:
    palindromicDivisors[innerIndex + 1] = palindromicDivisors[innerIndex]
    innerIndex -= 1
  palindromicDivisors[innerIndex + 1] = sortValue
for divisorIndex in 0 .. palindromicDivisors.len - 1:
  if divisorIndex > 0:
    appendOutput(",")
  appendOutput($palindromicDivisors[divisorIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Pairs arrive out of order, so sorting fixes the list.
A comma is printed only between values.
One newline ends the output.

## Complexity

The divisor sweep dominates; sorting affects only the divisor count.

| phase | time | space |
|---|---|---|
| divisor sweep | one test per candidate up to the square root | result list |
| sorting | insertion sort over the matches | result list |
| output | one pass over the matches | block output buffer |

| measure | Big O |
|---|---|
| time | O(sqrt(N) + d^2), with d matching divisors |
| space | O(d) |

Scanning every integer up to N wastes half the divisor tests.

Pairing divisors at the square root finds each one once and keeps the scan short.
