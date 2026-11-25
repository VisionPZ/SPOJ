# RABBIT1 — Counting Rabbits (SPOJ)

<https://www.spoj.com/problems/RABBIT1/>

## Problem

Count rabbit couples after many months, then report how many cannot fit into boxes of fixed size. Rabbits follow Fibonacci growth, and a box holds a power of two couples.

Each test case gives months `N` and box exponent `M`. Print the total couples after `N` months modulo `2^M`. Input ends after `C` lines of queries.

| item | bound |
|---|---|
| calculations C | 1 to 100 |
| months N | 1 to 2147483647 |
| box exponent M | 1 to 20 |
| judge limit | 1000 ms, 1536 MB |

The month bound forces logarithmic work per query.

Sample input:

```
1
5 2
```

Sample output:

```
0
```

## Idea

Think of each month as one step of a doubling ladder, like folding a rope in half repeatedly. Fast doubling computes Fibonacci pairs in logarithmic steps instead of walking every month.

The total couples after `N` months is Fibonacci `F(N+1)`. Boxes hold `2^M` couples, so leftovers are the total modulo `2^M`. Linear iteration would need billions of steps for large `N`.

Fast doubling finishes each query in about 31 steps.

## Why It Works

1. Month one starts with one adult couple, so totals are 1, 2, 3, 5, 8.
2. Those totals match Fibonacci numbers `F(2), F(3), F(4), F(5), F(6)`.
3. After `N` months the total is `F(N+1)`.
4. `F(2k) = F(k)(2F(k+1) - F(k))`.
5. `F(2k+1) = F(k)^2 + F(k+1)^2`.
6. Boxes hold exactly `2^M` couples, so the remainder is the unboxed count.

| term | meaning |
|---|---|
| `monthCount` | months of rabbit growth |
| `boxCapacity` | couples per box, `2^M` |
| `rabbitPair` | `F(N+1)` and `F(N+2)` from fast doubling |
| `unboxedCouples` | total couples modulo box capacity |

A worked trace follows for `N = 5`, `M = 2`.

```
F(6) = 8
2^2 = 4
8 mod 4 = 0
```

The trace matches the sample answer of zero.

## Code

**Input and scanner.** The hand reader loads every query into one buffer.

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

All queries share one input string.
The scanner skips spaces and newlines.
No negative values occur in this problem.

**Fast doubling.** Each recursive level halves the index.

```nim
proc fibPair(indexValue: int64, modulusValue: int64): (int64, int64) =
  if indexValue == 0:
    return (int64(0), int64(1))
  let halfPair = fibPair(indexValue div 2, modulusValue)
  let firstPart = halfPair[0]
  let secondPart = halfPair[1]
  var innerValue = (2 * secondPart - firstPart) mod modulusValue
  if innerValue < 0:
    innerValue = innerValue + modulusValue
  let middle = (firstPart * innerValue) mod modulusValue
  let last = (firstPart * firstPart + secondPart * secondPart) mod modulusValue
  if (indexValue and 1) == 0:
    return (middle, last)
  return (last, (middle + last) mod modulusValue)
```

The pair holds consecutive Fibonacci values.
The negative branch corrects Nim's signed remainder.
All products stay under one trillion.

**Query loop and buffered output.** Each query adds one line to the buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let calculationCount = nextInt(inputData, scanPos)
for calculationIndex in 0 .. calculationCount - 1:
  let monthCount = int64(nextInt(inputData, scanPos))
  let boxExponent = nextInt(inputData, scanPos)
  let boxCapacity = int64(1) shl boxExponent
  let rabbitPair = fibPair(monthCount + 1, boxCapacity)
  let unboxedCouples = rabbitPair[0]
  appendOutput($unboxedCouples)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The shift builds the power of two capacity.
Fast doubling runs in logarithmic time.
The final flush writes all remaining lines.

## Complexity

Fast doubling dominates the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over query bytes | input string |
| fibonacci | about 31 halvings per query | recursion stack |
| output | one buffered write per block | block buffer |

Stack depth stays tiny across all queries.

| measure | Big O |
|---|---|
| time | O(C log N) |
| space | O(log N) |

Walking each month would cost O(N) per query, which is impossible here.

Fast doubling resolves every query in logarithmic time, so all one hundred queries fit the limit.
