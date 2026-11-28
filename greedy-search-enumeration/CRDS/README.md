# CRDS — Cards (SPOJ)
<https://www.spoj.com/problems/CRDS/>

## Problem

A pyramid with N levels uses `3 * level - 1` cards on each level. Report the total number of cards modulo 1,000,007 for each query.

Input starts with the query count T. Each of the next T lines holds one level N. Output one line per query with the reduced total.

| item | bound |
|---|---|
| queries T | 1 to 1000 |
| level N | 1 to 1000000 |
| modulus | 1000007 |
| judge limit | 1000 ms, 1536 MB |

The modulus is 1,000,007, which differs from the common 1,000,007,009 style constant.

Sample input:

```
2
3
7
```

Sample output:

```
15
77
```

## Idea

Each level adds a fixed count, like adding rungs to a ladder, so the whole total collapses to one product.

The algorithm is closed-form arithmetic. Level i contributes `3 * i - 1` cards. The sum is `3 * N * (N + 1) / 2 - N`. That equals `N * (3 * N + 1) / 2`. Each query costs one 64-bit multiply, one divide, and one modulo.

Summing all levels costs O(N) per query and overflows 32-bit integers. The closed form costs O(1) and keeps the product exact before reduction.

Precompute nothing. Read each level, apply the formula, and buffer the answer.

## Why It Works

1. Level i has i leaning pairs and i - 1 horizontal cards.
2. So level i uses `3 * i - 1` cards.
3. Summing `3 * i - 1` from 1 to N gives `3 * N * (N + 1) / 2 - N`.
4. That expression equals `N * (3 * N + 1) / 2`.
5. Taking the modulus after the exact division gives the required answer.

| term | meaning |
|---|---|
| `pyramidLevel` | the queried level N |
| `doubledNumerator` | `N * (3 * N + 1)`, always even |
| `cardTotal` | exact total reduced modulo 1,000,007 |
| `cardModulus` | the constant 1,000,007 |

The formula is exact for every level, so no rounding enters the computation.

For N = 7 the levels contribute 2, 5, 8, 11, 14, 17, and 20 cards. Their sum is 77, and 77 modulo 1,000,007 is 77.

| check | value |
|---|---|
| product `7 * 22` | 154 |
| exact half | 77 |
| printed answer | 77 |

64-bit arithmetic holds the product because N is at most 1,000,000, so the product stays below 3 trillion. Division happens before the modulo to keep the exact integer value.

## Code

**Input and output setup.** The reader loads all tokens, and the writer flushes in large blocks.

```nim
const flushBlockBytes = 1 shl 17
const cardModulus = 1000007

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

The scanner skips whitespace and reads digits by subtraction.
No negative values occur in this problem.
`scanPos` advances once per token.

**Query loop.** Each level becomes one reduced answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pyramidLevel = nextInt(inputData, scanPos)
  let doubledNumerator = int64(pyramidLevel) * int64(3 * pyramidLevel + 1)
  let cardTotal = (doubledNumerator div 2) mod int64(cardModulus)
  appendOutput($cardTotal)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The product is exact in 64 bits before division.
The modulo uses `mod`, never the `%` operator.
One final flush writes the remaining buffer.

## Complexity

Reading the query list is linear in the input size, and each query is constant time.

| phase | time | space |
|---|---|---|
| input read | one pass over T levels | one input string |
| formula | one multiply per query | constant |
| output | one line per query | block buffer |

Each query costs one arithmetic expression.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) beyond input and output |

Summing each level instead would cost O(N) per query and waste the pattern.

The closed form answers every query with one product, so the judge limit is easy to meet.
