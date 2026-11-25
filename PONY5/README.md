# PONY5 — Teaming up for the competition (SPOJ)

<https://www.spoj.com/problems/PONY5/>

## Problem

Each case lists a group of numbers. Find the largest modulus X that puts every number in the same remainder class, or report that no countable X works.

The first line holds the number of cases. Each case line has the form `Case #i: N a1 a2 ... aN`, where N is the group size. Print `Case #i: X`, or `Case #i: I can't count that high` when X exceeds 10^18.

| item | bound |
|---|---|
| group size N | 1 to 1000000 |
| each number | 1 to 10^18 |
| cases | line count from input |
| judge limit | 100 ms, 1536 MB |

The 10^18 value bound drives the design, since scanning candidate moduli is impossible.

Sample input:

```
2
Case #1: 3 178 928 440
Case #2: 1 1000000000000000000
```

Sample output:

```
Case #1: 2
Case #2: I can't count that high
```

## Idea

Equal remainders mean X divides every difference, so the answer is their greatest common divisor. Think of finding the longest ruler interval that lands on every cut mark.

The program subtracts each number from the first, then runs Euclid's gcd on the absolute differences. Each number costs one gcd step, and one case uses O(N log V) time.

Trying every X from 10^18 downward would never finish. A gcd reaches the same answer with a handful of divisions per number. The takeaway is to turn a search over moduli into one divisor computation.

## Why It Works

1. Two numbers share a remainder modulo X exactly when X divides their difference.
2. If every number matches the first, X divides every difference from that first number.
3. The largest divisor common to all differences is their greatest common divisor.
4. A zero difference means the numbers match for every X, so the answer is unbounded.
5. A single number imposes no restriction, so it also yields an unbounded answer.
6. All inputs fit in a signed 64-bit integer, and gcd never increases a value.

| term | meaning |
|---|---|
| `ponyCount` | number of values in one group |
| `firstNumber` | reference value for every difference |
| `difference` | absolute gap between the current value and the reference |
| `gcdInt` | Euclid routine for two integers |
| `differenceGcd` | greatest common divisor of all gaps seen so far |
| `countThreshold` | largest countable modulus, 10^18 |

The table names the values kept while scanning one case.

A script trace for 178, 928, 440 starts with gaps 750 and 262. Euclid reduces gcd(750, 262) through 226, 36, 10, 6, 4, and 2. The final divisor is 2.

| gap pair | reduction | result |
|---|---|---|
| 750, 262 | 750 mod 262 = 226 | continue |
| 262, 226 | 262 mod 226 = 36 | continue |
| 226, 36 | 226 mod 36 = 10 | continue |
| 36, 10 | 36 mod 10 = 6 | continue |
| 10, 6 then 6, 4 | remainder 2 then 0 | gcd = 2 |

The trace reproduces the first sample answer.

Negative differences are converted to positive values before the gcd. The threshold guard covers unbounded answers. No rounding applies because the data are integers.

## Code

**Input, scanner, and output buffer.** The reader loads all lines and slices numbers, including the case labels.

```nim
const flushBlockBytes = 1 shl 17
const countThreshold = 1000000000000000000

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

`nextInt` skips the words and hash marks in each case line.
It returns the case label before the group size.
The scanner handles numbers up to 10^18 in a 64-bit int.

**Euclid routine.** One loop reduces two integers until the smaller one reaches zero.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc gcdInt(firstValue: int, secondValue: int): int =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

`gcdInt` accepts zero as its first argument.
A zero second argument ends the loop.
`appendOutput` flushes after a fixed block of text.

**Case loop.** Each case folds all gaps into one divisor and prints the answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let ignoredCaseLabel = nextInt(inputData, scanPos)
  let ponyCount = nextInt(inputData, scanPos)
  let firstNumber = nextInt(inputData, scanPos)
  var differenceGcd = 0
  for ponyIndex in 1 .. ponyCount - 1:
    let currentNumber = nextInt(inputData, scanPos)
    var difference = currentNumber - firstNumber
    if difference < 0:
      difference = -difference
    differenceGcd = gcdInt(differenceGcd, difference)
  appendOutput("Case #")
  appendOutput($caseIndex)
  appendOutput(": ")
  if ponyCount <= 1 or differenceGcd == 0 or differenceGcd > countThreshold:
    appendOutput("I can't count that high")
  else:
    appendOutput($differenceGcd)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads every value even after the gcd reaches one.
The guard prints the fixed message for unbounded answers.
One final write flushes the buffered output.

## Complexity

Reading dominates on huge inputs, and each number adds one gcd computation.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| difference scan | one gcd per value | constant scratch |
| output | buffered writes | one output buffer |

The gcd loop uses O(log V) divisions per number.

| measure | Big O |
|---|---|
| time | O(N log V) per case, where V is the largest value |
| space | O(1) beyond the input string |

Scanning every candidate modulus would cost O(10^18) per case. The gcd approach removes that search entirely and keeps each case practical.
