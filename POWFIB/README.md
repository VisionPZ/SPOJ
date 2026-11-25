<https://www.spoj.com/problems/POWFIB/>

## Problem

For each rank N, compute the Nth non-Fibonacci number raised to the Nth Fibonacci number, modulo 1000000007. Fibonacci numbers start at 1, 1, 2, 3. The Nth non-Fibonacci number is guaranteed below the modulus.

| item | bound |
|---|---|
| test cases T | 1 to 100000 |
| rank N | 1 to 900000000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The exponent is taken modulo the modulus exactly as the statement defines it.

Sample input:

```
3
3
2
1
```

Sample output:

```
49
6
4
```

## Idea

Skipping Fibonacci numbers is like counting seats in a row while reserving a few labelled seats. Only about forty-five Fibonacci values fit below the modulus, so binary search finds the Nth gap in a few steps. Fast doubling finds the Nth Fibonacci value in logarithmic time, and binary exponentiation finishes the power.

## Why It Works

1. The non-Fibonacci values are the positive integers after removing the Fibonacci values.
2. The count of non-Fibonacci values up to x equals x minus the Fibonacci values at most x.
3. Binary search on x finds the smallest count reaching N, which is the Nth non-Fibonacci number.
4. Fast doubling computes a Fibonacci pair from the pair at half the index.
5. Binary exponentiation raises the base using the Fibonacci exponent modulo the modulus.

| term | meaning |
|---|---|
| `fibonacciValues` | distinct Fibonacci numbers below twice the modulus |
| `nonFibonacciAtRank` | binary search over the skip count |
| `fibonacciPair` | fast doubling step returning two adjacent Fibonacci values |
| `powerModulo` | modular binary exponentiation |

The precomputed Fibonacci list stays small because Fibonacci values grow exponentially.

## Code

**Input and table setup.** The reader loads all ranks and builds the Fibonacci list.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const searchWindow = 200

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

var fibonacciValues = newSeq[int64]()
var lowerFib: int64 = 1
var upperFib: int64 = 1
while lowerFib <= 2000000000:
  if fibonacciValues.len == 0 or fibonacciValues[fibonacciValues.len - 1] != lowerFib:
    fibonacciValues.add lowerFib
  let followingFib = lowerFib + upperFib
  lowerFib = upperFib
  upperFib = followingFib
```

Duplicate ones are stored once.
The list reaches beyond the modulus so every skip is counted.
All table values fit in a signed integer.

**Rank search and exponent.** Two binary searches replace a long scan over integers.

```nim
proc fibonacciPair(index: int64): (int64, int64) =
  if index == 0:
    return (int64(0), int64(1))
  let halfIndex = index div 2
  let (halfValue, halfNext) = fibonacciPair(halfIndex)
  let doubledNext = (2 * halfNext) mod modulusValue
  let correction = (doubledNext - halfValue + modulusValue) mod modulusValue
  let evenValue = (halfValue * correction) mod modulusValue
  let oddValue = (halfValue * halfValue + halfNext * halfNext) mod modulusValue
  if (index mod 2) == 0:
    return (evenValue, oddValue)
  return (oddValue, (evenValue + oddValue) mod modulusValue)

proc countFibonacciUpTo(limit: int64): int =
  var leftBound = 0
  var rightBound = fibonacciValues.len
  while leftBound < rightBound:
    let middle = (leftBound + rightBound) div 2
    if fibonacciValues[middle] <= limit:
      leftBound = middle + 1
    else:
      rightBound = middle
  return leftBound

proc nonFibonacciAtRank(rank: int64): int64 =
  var leftBound = rank
  var rightBound = rank + searchWindow
  while leftBound < rightBound:
    let middle = (leftBound + rightBound) div 2
    let skipped = int64(countFibonacciUpTo(middle))
    if middle - skipped >= rank:
      rightBound = middle
    else:
      leftBound = middle + 1
  return leftBound
```

The doubling formulas keep intermediates under the square of the modulus.
The skip count ignores the duplicate one by storing distinct values.
The search window exceeds the number of Fibonacci values below the modulus.

**Power and driver.** Modular exponentiation consumes the Fibonacci value and buffered output emits each answer.

```nim
proc powerModulo(baseValue: int64, exponent: int64): int64 =
  var runningBase = baseValue mod modulusValue
  var runningExponent = exponent
  var resultValue: int64 = 1
  while runningExponent > 0:
    if (runningExponent mod 2) == 1:
      resultValue = (resultValue * runningBase) mod modulusValue
    runningBase = (runningBase * runningBase) mod modulusValue
    runningExponent = runningExponent div 2
  return resultValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rankValue = int64(nextInt(inputData, scanPos))
  let nonFibValue = nonFibonacciAtRank(rankValue)
  let (fibValue, ignoredNext) = fibonacciPair(rankValue)
  let answerValue = powerModulo(nonFibValue, fibValue)
  appendOutput($answerValue)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case costs logarithmic work in the rank.
Products of two residues stay below nine quintillion.
The output buffer flushes in large blocks.

## Complexity

The Fibonacci list is built once before reading the answers.

| phase | time | space |
|---|---|---|
| table build | about forty Fibonacci steps | one small list |
| rank search | binary search per case | constant |
| Fibonacci exponent | fast doubling per case | logarithmic stack |
| power | binary exponentiation per case | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(T log N) |
| space | O(log N) |

Scanning every integer up to the Nth non-Fibonacci number would cost O(N) per case.
