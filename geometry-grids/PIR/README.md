# PIR — Pyramids (SPOJ)
<https://www.spoj.com/problems/PIR/>

## Problem

A tetrahedron is described by the lengths of its six edges, given in a fixed order. Compute its volume and print it with four digits after the decimal point.

Input: the first integer is t, the number of tests. Each following line holds six positive integers: AB, AC, AD, BC, BD, CD. Output: one real number per test, rounded to four decimals.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | from the input |
| Edge lengths | positive integers up to 1000 |
| Output precision | four digits after the decimal point |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The sample has a regular tetrahedron and a skewed one:

```
2
1 1 1 1 1 1
1000 1000 1000 3 4 5
```

```
0.1179
1999.9937
```

The regular tetrahedron of edge 1 has volume √2 / 12.

## Idea

Recover the corner angles from the edge lengths, then apply a determinant formula. Picture a three-legged tripod: knowing the three legs and the distances between their feet fixes the shape, so the enclosed volume is determined.

The program places vertex D at the origin and treats DA, DB, DC as vectors. The law of cosines gives their pairwise dot products from the opposite edges AB, AC, and BC. The Gram determinant of those three vectors expands into five integer terms.

The terms use squares up to 10⁶ and products up to about 1.6 × 10⁹, but their signed sum needs more than 64 bits. The program accumulates into a 128-bit pair built from an int64 and a uint64. It takes one square root at the end and formats four decimals.

Each test costs O(1). A floating-point determinant subtracts nearly equal large values and loses the four decimal digits.

Takeaway: an exact integer expansion plus one square root keeps the printed digits stable.

## Why It Works

Four facts support the formula.

1. Put D at the origin. Then 2·DA·DB = |DA|² + |DB|² − |AB|², and similarly for the other pairs. These are `twiceDotAB`, `twiceDotAC`, and `twiceDotBC`.
2. The Gram determinant of three vectors equals 36 V². Write a = |DA|², b = |DB|², c = |DC|². The expansion gives 144 V² = 4abc + (2u)(2v)(2w) − a(2w)² − b(2v)² − c(2u)². Here u, v, w are the three dot products.
3. Each term can exceed int64 only after summation. `addProduct` tracks carries and sign extension across a 64-bit low word and a 64-bit high word, so the total stays exact.
4. `formatFloat(volume, ffDecimal, 4)` rounds the single square root to four decimals. Rounding happens once, after all exact arithmetic.

These are the values in one test:

| Term | Meaning |
| --- | --- |
| `squaredAD`, `squaredBD`, `squaredCD` | squared lengths a, b, c of the three edges from D |
| `twiceDotAB` | a + b − AB², twice the DA·DB dot product |
| `twiceDotAC` | a + c − AC² |
| `twiceDotBC` | b + c − BC² |
| `scaledSquaredVolume` | the exact value of 144 V² |
| `volume` | sqrt(scaledSquaredVolume / 144) |

A script evaluates the five terms for both sample cases:

```
edges (1,1,1,1,1,1)      terms [4,1,-1,-1,-1] sum 2 -> 0.11785
edges (1000,1000,1000,3,4,5) terms [1600000000,12800,-1024000000,-10000,-6400] sum 575996400 -> 1999.99375
```

The first sum gives √2 / 12, printed as 0.1179. The second gives √3999975, printed as 1999.9937. Both round once at the output step.

## Code

**Setup.** The scanner reads integers, and a helper adds signed terms into a wide accumulator.

```nim
import math, strutils

const flushBlockBytes = 1 shl 18
const digitBase = 48

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and int(inputData[i]) < digitBase:
    i += 1
  var value = 0
  while i < inputData.len and int(inputData[i]) >= digitBase:
    value = value * 10 + (int(inputData[i]) - digitBase)
    i += 1
  return value

proc addProduct(highWord: var int64, lowWord: var uint64, term: int64) =
  let termBits = cast[uint64](term)
  let addedLow = lowWord + termBits
  let carryWord: int64 = if addedLow < lowWord: 1 else: 0
  let extendWord: int64 = if term < 0: -1 else: 0
  lowWord = addedLow
  highWord += carryWord + extendWord

proc flushOutput(outputBuffer: var string) =
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

`addProduct` extends a negative term through the high word with `extendWord`. The unsigned overflow flag supplies the carry. Each addition costs O(1); no big-integer library is needed.

**Driver.** Each line of six edges becomes one volume.

```nim
var inputData = ""
var nextLine = ""
while readLine(stdin, nextLine):
  inputData.add nextLine
  inputData.add '\n'

var i = 0
let testCount = nextInt(inputData, i)
var outputBuffer = ""
var highWord: int64 = 0
var lowWord: uint64 = 0

var j = 0
while j < testCount:
  let edgeAB = nextInt(inputData, i)
  let edgeAC = nextInt(inputData, i)
  let edgeAD = nextInt(inputData, i)
  let edgeBC = nextInt(inputData, i)
  let edgeBD = nextInt(inputData, i)
  let edgeCD = nextInt(inputData, i)

  let squaredAD = edgeAD * edgeAD
  let squaredBD = edgeBD * edgeBD
  let squaredCD = edgeCD * edgeCD
  let twiceDotAB = squaredAD + squaredBD - edgeAB * edgeAB
  let twiceDotAC = squaredAD + squaredCD - edgeAC * edgeAC
  let twiceDotBC = squaredBD + squaredCD - edgeBC * edgeBC

  highWord = 0
  lowWord = 0
  addProduct(highWord, lowWord, 4 * squaredAD * squaredBD * squaredCD)
  addProduct(highWord, lowWord, twiceDotAB * twiceDotAC * twiceDotBC)
  addProduct(highWord, lowWord, -(squaredAD * twiceDotBC * twiceDotBC))
  addProduct(highWord, lowWord, -(squaredBD * twiceDotAC * twiceDotAC))
  addProduct(highWord, lowWord, -(squaredCD * twiceDotAB * twiceDotAB))

  let scaledSquaredVolume = int64(lowWord)
  let volume = sqrt(float(scaledSquaredVolume) / 144.0)
  outputBuffer.add formatFloat(volume, ffDecimal, 4)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    flushOutput(outputBuffer)
  j += 1

if outputBuffer.len > 0:
  flushOutput(outputBuffer)
```

The read loop puts all lines in one buffer. The five `addProduct` calls match the expanded determinant exactly. `scaledSquaredVolume` stays within int64 after the sum, so the low word holds it; the final flush writes the tail.

## Complexity

Each test uses a fixed number of operations.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Dot products and terms | O(1) | O(1) |
| Square root and formatting | O(1) | O(1) |
| Output | O(tests) | O(block size) |

Every test costs O(1) time and O(1) working space.

| Measure | Big O |
| --- | --- |
| Time per test | O(1) |
| Total time | O(t) |
| Working space | O(1) |

A floating-point determinant risks cancellation; the exact integer sum avoids it at the same constant cost.
