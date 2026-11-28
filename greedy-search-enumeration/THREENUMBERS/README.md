# THREENUMBERS — nth number (SPOJ)

<https://www.spoj.com/problems/THREENUMBERS/>

## Problem

List the positive integers divisible by a or by b in increasing order and report the one at position n. The input gives many independent (a, b, n) triples, so each answer depends only on its own triple.

Input starts with T, the number of test cases. Each following line holds three positive integers a, b and n. Output one line per case: the n-th number divisible by a or b.

| item | bound |
|---|---|
| test cases T | 1 to 100000 |
| divisors a, b | 1 to 10000 |
| position n | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The position bound drives the design: n reaches 1e9, so the answer must be found without listing numbers.

Verbatim sample input:

```
1
2 3 10
```

Verbatim sample output:

```
15
```

## Idea

Count how many qualifying numbers lie at or below a guess, then move the guess like a librarian locating a shelf by its label count. Binary search finds the smallest value whose count reaches n. Each count costs a few divisions using inclusion-exclusion, because multiples of both a and b were counted twice.

Counting by formula costs O(1) per probe and O(log answer) probes per case. Scanning every integer up to the answer costs O(answer) per case and cannot handle n = 1e9. The search bound n times the smaller divisor always contains the answer, since every multiple of that divisor qualifies. Takeaway: replace enumeration by a monotone count and binary search.

## Why It Works

1. The multiples of a up to x number x/a; the multiples of b number x/b.
2. Multiples of lcm(a, b) appear in both lists, so subtract x/lcm(a, b) once.
3. The resulting count never decreases as x grows, which makes binary search valid.
4. Every multiple of the smaller divisor qualifies, so the n-th answer is at most n times that divisor.
5. Binary search returns the smallest x whose count is at least n, which is exactly the answer.

The main terms and formulas:

| term | meaning |
|---|---|
| `commonMultiple` | lcm(a, b), the overlap period of the two divisor lists |
| `divisibleCount` | number of values up to a limit divisible by a or b |
| `smallerDivisor` | the tighter upper-bound step, min(a, b) |
| `highValue` | exclusive search bound, n times the smaller divisor plus one |

The count formula removes double counting, so each probe is exact.

A script-generated trace for the sample triple (a = 2, b = 3, n = 10):

```
gcd(2, 3) = 1
period = 2 / 1 * 3 = 6
first period = [2, 3, 4, 6], length 4
blocks = (10 - 1) // 4 = 2, offset = (10 - 1) % 4 = 1
answer = 2 * 6 + 3 = 15
```

The trace matches the sample output 15.

No floating point appears: integer division and integer gcd keep every step exact. The answer reaches about 1e13, which fits in a signed 64-bit value.

## Code

**Input and scanner.** One read loads stdin and a hand scanner skips whitespace between numbers.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The loop appends a newline after every line, including the last one.
Digit parsing uses `int(data[pos]) - 48`, which avoids `ord` on a char.
The scanner advances `scanPos` past each parsed number.

**Buffered output.** Text accumulates and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer serves all test cases, so writes stay rare.
The final flush happens after the case loop.

**Counting helper.** Inclusion-exclusion counts qualifying values under a limit.

```nim
proc gcdValues(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    var remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

proc divisibleCount(limit: int64, divisorA: int64, divisorB: int64,
                    commonMultiple: int64): int64 =
  return limit div divisorA + limit div divisorB - limit div commonMultiple
```

Euclid's algorithm computes the gcd with remainders only.
All arithmetic uses `int64`, since the search limit can exceed 1e12.

**Binary search per case.** The search narrows to the smallest valid value.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let divisorA = int64(nextInt(inputData, scanPos))
  let divisorB = int64(nextInt(inputData, scanPos))
  let targetIndex = int64(nextInt(inputData, scanPos))
  let commonMultiple = divisorA div gcdValues(divisorA, divisorB) * divisorB
  let smallerDivisor = if divisorA < divisorB: divisorA else: divisorB
  var lowValue: int64 = 0
  var highValue: int64 = targetIndex * smallerDivisor + 1
  while lowValue < highValue:
    let middleValue = lowValue + (highValue - lowValue) div 2
    if divisibleCount(middleValue, divisorA, divisorB, commonMultiple) >= targetIndex:
      highValue = middleValue
    else:
      lowValue = middleValue + 1
  appendOutput($lowValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The bound `highValue` always satisfies the count condition, so the search converges.
The midpoint avoids overflow by adding half the gap to the lower bound.
Each case emits one line through the shared buffer.

## Complexity

The work per case is a handful of divisions times a logarithmic number of probes.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| gcd and bound | constant per case | constant |
| binary search | O(log(n * min(a, b))) probes | constant |
| output | one buffered line per case | block buffer |

The dominant phase is the search, whose probe count is logarithmic in the answer.

| measure | Big O |
|---|---|
| time per case | O(log(n * min(a, b))) |
| total time | O(T log(n * min(a, b))) |
| space | O(input size) |

Scanning integers up to the answer would take O(n * min(a, b)) per case, far beyond the logarithmic search. Takeaway: count first, then locate the boundary.
