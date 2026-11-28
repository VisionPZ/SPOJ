# DIG — DIAGONAL (SPOJ)

<https://www.spoj.com/problems/DIG/>

## Problem

Count interior crossing points made by all diagonals of a convex polygon with n vertices. Every crossing point is assumed different, and large answers are reduced modulo 1000000007. The input gives a case count followed by one vertex count per case, and the output gives one answer per case.

Write `C(n,4)` for the number of ways to choose four vertices out of n.

| item | bound |
|---|---|
| vertices n | 1 to 100000000 |
| test cases | given by the first input number |
| judge limit | 1000 ms, 1536 MB |

The large upper bound rules out drawing or enumerating diagonals.

Sample input:

```
2
4
5
```

Sample output:

```
1
5
```

## Idea

Choose four vertices, like picking four corners of a quadrilateral. Its two diagonals cross once inside the polygon, and no other choice gives that crossing. So the answer is `C(n,4)` reduced modulo the prime.

Compute the falling product of four factors and multiply by the inverse of 24. Each case costs constant work, while enumerating diagonals costs quadratic work.

## Why It Works

1. Any crossing point uses two diagonals with four distinct endpoints.
2. Those four endpoints form a convex quadrilateral in cyclic order.
3. Its two diagonals cross exactly once inside the polygon.
4. The distinctness assumption makes different quadruples give different points.
5. Hence the count equals `C(n,4)`, which is n times n minus 1 times n minus 2 times n minus 3, divided by 24.

| term | meaning |
|---|---|
| `modulusValue` | the prime modulus 1000000007 |
| `inverseTwentyFour` | inverse of 24 under that modulus |
| `productValue` | running falling product of the four factors |
| `vertexCount` | number of polygon vertices in one case |

The factorial denominator becomes a modular inverse because the modulus is prime.

A script-generated trace for n = 6 shows the arithmetic.

| step | value |
|---|---|
| falling product | 6 times 5 times 4 times 3 = 360 |
| divide by 24 | 360 / 24 = 15 |
| reduced answer | 15 |

The trace gives 15 crossings for a hexagon, as the formula predicts.

## Code

**Input, scanning, and modular power.** The reader loads all cases and builds one inverse.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseNow = baseValue mod modulusValue
  var exponentNow = exponentValue
  var resultValue: int64 = 1
  while exponentNow > 0:
    if exponentNow mod 2 == 1:
      resultValue = (resultValue * baseNow) mod modulusValue
    baseNow = (baseNow * baseNow) mod modulusValue
    exponentNow = exponentNow div 2
  return resultValue
```

The power routine uses repeated squaring with about thirty steps.
Each multiplication stays below the square of the modulus.
One inverse serves every test case in the file.

**Combination and output.** Each case computes four factors modulo the prime.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
let inverseTwentyFour = powerMod(24, modulusValue - 2)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  if vertexCount < 4:
    appendOutput("0")
  else:
    var productValue: int64 = int64(vertexCount) mod modulusValue
    productValue = (productValue * int64(vertexCount - 1)) mod modulusValue
    productValue = (productValue * int64(vertexCount - 2)) mod modulusValue
    productValue = (productValue * int64(vertexCount - 3)) mod modulusValue
    appendOutput($(productValue * inverseTwentyFour mod modulusValue))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Small polygons have no crossing, so the code returns zero.
Taking the remainder after each factor avoids an overflowing product.
All answers leave through one buffered write path.

## Complexity

Each case uses a fixed number of modular operations.

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | one input string |
| inverse power | one logarithmic exponentiation | three integers |
| answer loop | four multiplications per case | block buffer |

The phase table shows that case work is constant.

| measure | Big O |
|---|---|
| time | O(T log modulus) |
| space | O(1) beyond the input string |

Drawing and testing every diagonal pair costs O(n^2) per case, while the formula costs O(1).
