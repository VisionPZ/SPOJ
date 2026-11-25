# KOPC12B — K12-Combinations (SPOJ)

<https://www.spoj.com/problems/KOPC12B/>

## Problem

For each `n`, compute the weighted sum of squared binomial coefficients: one times C(n,1) squared, plus two times C(n,2) squared, and so on up to `n`. Return the sum modulo `MOD` = 1000000007.

Input starts with the test count `T`, followed by one value `n` per line. Output one answer per test.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 1000 |
| Query value `n` | 1 to 1000000 |
| Modulo `MOD` | 1000000007 |
| Judge limit | 1000 ms, 1536 MB |

Notation: C(n,r) is the number of ways to choose `r` items from `n` items.

Here is the sample input:

```
2
1
2
```

Here is the sample output:

```
1
6
```

## Idea

The long weighted sum collapses to one binomial coefficient, like replacing a row of additions with a single multiplication. The identity is n times C(2n-1, n-1). Multiply by r over n-1 using the factorial form, then evaluate every query in constant time after one shared factorial table. A direct summation walks all `n` terms for each test and grows too costly for a thousand queries.

## Why It Works

1. The identity r times C(n,r) equals n times C(n-1, r-1).
2. Substituting it into the sum leaves n times a sum of products C(n-1, r-1) times C(n, n-r).
3. Vandermonde's convolution evaluates that sum as C(2n-1, n-1).
4. The factorial form C(2n-1, n-1) equals factorial(2n-1) over factorial(n-1) times factorial(n).
5. Modular inverses of factorials turn the division into multiplication under `MOD`.
6. Reducing after each multiplication keeps every intermediate product inside 64 bits.

| Term | Meaning |
|---|---|
| `factorials` | factorial values up to twice the largest query |
| `inverseFactorials` | modular inverses of those factorials |
| `modularPower` | fast exponentiation used for the first inverse |
| `queries` | all query values kept from input |
| `largestQuery` | drives the shared table size |
| `chooseValue` | the evaluated binomial coefficient |

The table lists the values built by the shared precomputation.

A worked trace of the sample follows.

```
n=1: terms 1*C(1,1)^2 = 1, closed form 1*C(1,0) = 1
n=2: terms 1*4 + 2*1 = 6, closed form 2*C(3,1) = 6
n=3: terms 1*9 + 2*9 + 3*1 = 30, closed form 3*C(5,2) = 30
```

The trace matches the sample and confirms the identity on the next value.

## Code

**Input and buffer setup.** The reader loads stdin once and defines the buffered writer.

```nim
const flushBlockBytes = 1 shl 17
const modValue = 1000000007

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

proc modularPower(baseValue: int, exponentValue: int): int =
  var baseRest = int64(baseValue)
  var exponentRest = exponentValue
  result = 1
  while exponentRest > 0:
    if (exponentRest and 1) == 1:
      result = int(result * baseRest mod int64(modValue))
    baseRest = baseRest * baseRest mod int64(modValue)
    exponentRest = exponentRest div 2
```

The scanner reads every query before work begins. The power helper computes one modular inverse with repeated squaring.

**Shared table and answers.** The code builds factorials once, then answers each query in constant time.

```nim
let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var largestQuery = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > largestQuery:
    largestQuery = queries[caseIndex]
let tableLimit = 2 * largestQuery
var factorials = newSeq[int](tableLimit + 1)
var inverseFactorials = newSeq[int](tableLimit + 1)
factorials[0] = 1
for tableIndex in 1 .. tableLimit:
  factorials[tableIndex] = int(int64(factorials[tableIndex - 1]) *
                               int64(tableIndex) mod int64(modValue))
inverseFactorials[tableLimit] = modularPower(factorials[tableLimit], modValue - 2)
var tableIndex = tableLimit
while tableIndex >= 1:
  inverseFactorials[tableIndex - 1] = int(int64(inverseFactorials[tableIndex]) *
                                          int64(tableIndex) mod int64(modValue))
  tableIndex -= 1
for caseIndex in 0 .. caseCount - 1:
  let queryValue = queries[caseIndex]
  let upperIndex = 2 * queryValue - 1
  let chooseValue = int(int64(factorials[upperIndex]) *
                        int64(inverseFactorials[queryValue - 1]) mod int64(modValue))
  let scaledValue = int64(queryValue) * int64(chooseValue) mod int64(modValue)
  let answerValue = int(scaledValue * int64(inverseFactorials[queryValue]) mod int64(modValue))
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Reading all queries first fixes the table size before precomputation. The descending loop fills inverse factorials from the largest entry. Each answer reduces after every product, so no multiplication overflows.

## Complexity

Precomputation depends on the largest query, and each answer costs constant time.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input text | one input string |
| Factorial table | O(largest query) | two factorial arrays |
| Query answers | O(1) per test | query array |
| Output | one line per test | block buffer |

The table is built once and shared by all tests.

| Measure | Big O |
|---|---|
| Time | O(largest query plus test count) |
| Space | O(largest query plus test count) |

Summing every term for every query would cost O(n times test count); the closed form removes that inner loop.
