# BUET19B — GCD (SPOJ)

<https://www.spoj.com/problems/BUET19B/>

## Problem

A list of integers is given. Print the largest number that divides every value in the list.

Input starts with N, the list length, then N integers on the next line. Output is one line holding that common divisor.

| item | bound |
|---|---|
| list length N | 1 to 100000 |
| each value | below 100000 |
| judge limit | 1000 ms, 1536 MB |

The list length drives the work; each value stays small enough for one division step.

The sample case:

```
5
2 4 6 8 2
```

```
2
```

## Idea

Keep one running divisor and shrink it per number, like a sieve that drops holes as stones pass. The algorithm folds Euclid's gcd over the list. Each step costs a handful of divisions, so the whole pass stays near the input size. Testing every divisor of every number would cost far more work. A running value of 1 ends the pass early, since a divisor can never grow back.

## Why It Works

1. The gcd of zero and any number is that number, so the first value sets the running divisor.
2. Folding in any order gives the gcd of all numbers read so far.
3. Euclid's step swaps the pair and keeps the remainder, so the value shrinks and the answer holds.
4. A common divisor must divide every number, so adding a number can only shrink it.
5. Once the running value reaches 1, no later number can raise it, so stopping is safe.

| Term | Meaning |
|---|---|
| `runningGcd` | the gcd of all numbers read so far |
| `gcdPair` | Euclid's algorithm applied to two numbers |
| `numberCount` | N, the length of the list |
| `readIndex` | how many numbers have been folded in |

The running value holds the whole answer when the loop ends.

A script-traced example for the sample list:

```
numbers 2 4 6 8 2
shared prime factors 2^1
answer 2
```

The trace matches the sample answer.

## Code

**Input and hand scanner.** This block loads the input and reads integers by index.

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

The scanner skips all non-digits, so spaces and newlines need no special case.
Each call advances the index past exactly one number.
Reading the input once keeps the scan linear in the byte count.

**Euclid step.** This block returns the gcd of two numbers.

```nim
proc gcdPair(leftValue: int, rightValue: int): int =
  var largerValue = leftValue
  var smallerValue = rightValue
  while smallerValue != 0:
    let remainder = largerValue mod smallerValue
    largerValue = smallerValue
    smallerValue = remainder
  return largerValue
```

Locals hold the pair because the arguments stay unchanged.
Each round replaces the pair with a smaller one.
The loop ends when the second value hits zero.

**Buffered fold and output.** This block folds every number and writes the answer once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var runningGcd = 0
var readIndex = 0
while readIndex < numberCount and runningGcd != 1:
  runningGcd = gcdPair(runningGcd, nextInt(inputData, scanPos))
  readIndex += 1
appendOutput($runningGcd)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops early once the running value reaches 1.
One fold is applied per number that is read.
A single write emits the final answer line.

## Complexity

The cost splits into reading, one gcd fold per number, and one write.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Folds | a few divisions per number | constant |
| Output | one write | block buffer |

The input buffer dominates memory; the fold needs only two integers.

| Measure | Big O |
|---|---|
| Time | O(N log V), with V below 100000 |
| Space | O(N) for the stored input |

Each fold drops a factor, so the logarithmic term stays small.

Listing every divisor of every number would cost about N times the square root of V. Folding with Euclid keeps the work near the input size.
