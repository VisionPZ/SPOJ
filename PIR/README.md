## Problem

Read the number of test cases, then six edge lengths for each pyramid. The edges arrive in the order AB, AC, AD, BC, BD, CD. Print the volume of each pyramid with four digits after the decimal point.

The input bounds and judge limits are fixed.

| Item | Bound |
| --- | --- |
| Edge lengths | integers from 1 to 1000 |
| Test cases | given by the first integer |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

All six edges fit in six integers, so the work per case stays constant.

## Idea

Place vertex D at the origin and read vectors DA, DB, and DC from the edge lengths. The volume is one sixth of their scalar triple product, so its square divides the dot-product matrix determinant (the Gram determinant) by 36. The law of cosines gives every dot product from two squared edges, and five exact integer terms finish the calculation.

Each case uses a fixed number of integer operations and one decimal format.

## Why It Works

Let u equal AD squared, v equal BD squared, and w equal CD squared. Let p equal u plus v minus AB squared. Let q equal u plus w minus AC squared.

Let r equal v plus w minus BC squared. Each value is an integer. The law of cosines makes p, q, and r twice the dot products of the three vectors.

The dot-product matrix has half-integer entries, so the program doubles it. Doubling a three-row matrix multiplies its determinant by eight. The doubled determinant equals 288 times the squared volume, so half of it equals 144 times the squared volume. Call that half S.

S = 4uvw + pqr - ur² - vq² - wp²

The five terms carry these meanings.

| Term | Meaning |
| --- | --- |
| 4uvw | four times the product of the squared edges from D |
| pqr | the product of the three doubled dot products |
| ur² | one squared edge times one squared doubled dot product |
| vq² | the same product for the second edge |
| wp² | the same product for the third edge |

The last three terms are subtracted. Each term alone fits in a signed 64-bit word, but their sum can pass that limit. The `addProduct` procedure stores the carry in `highWord` and the value in `lowWord`. The final S never exceeds 2·10^18, so `lowWord` holds it exactly.

A script generated this example from a tall tetrahedron with edges 1, 1, 1000, 1, 1000, 1000.

| Quantity | Value |
| --- | --- |
| u, v, w | 1,000,000 each |
| p, q, r | 1,999,999 each |
| 4uvw | 4,000,000,000,000,000,000 |
| pqr | 7,999,988,000,005,999,999 |
| ur² + vq² + wp² | 11,999,988,000,003,000,000 |
| S | 2,999,999 |
| Volume | 144.3375 |

The first two terms already exceed a 64-bit word, while S is only 2,999,999.

## Code

```nim
import math, strutils

const flushBlockBytes = 1 shl 18
const digitBase = 48

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and int(inputData[scanPos]) < digitBase:
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and int(inputData[scanPos]) >= digitBase:
    value = value * 10 + (int(inputData[scanPos]) - digitBase)
    scanPos += 1
  return value
```

Both loops advance `scanPos` once per byte, so scanning costs one pass over the input buffer. The cast turns a character into a number before the comparison. The scanner skips spaces and newlines without allocating tokens.

```nim
proc addProduct(highWord: var int64, lowWord: var uint64, term: int64) =
  let termBits = cast[uint64](term)
  let addedLow = lowWord + termBits
  let carryWord: int64 = if addedLow < lowWord: 1 else: 0
  let extendWord: int64 = if term < 0: -1 else: 0
  lowWord = addedLow
  highWord += carryWord + extendWord
```

The carry and sign extension keep the two words in balance. Without the sign extension, a negative term would add a large positive value. Five calls produce the exact sum.

```nim
proc flushOutput(outputBuffer: var string) =
  stdout.write outputBuffer
  outputBuffer.setLen 0

var inputData = ""
var nextLine = ""
while readLine(stdin, nextLine):
  inputData.add nextLine
  inputData.add '\n'

var scanPos = 0
let testCount = nextInt(inputData, scanPos)
var outputBuffer = ""
var highWord: int64 = 0
var lowWord: uint64 = 0
```

The read loop adds a newline after each line, so tokens never join across lines. `flushOutput` clears the same buffer with `setLen 0`, so memory stays at one block. Reading finishes before the case loop starts.

```nim
var caseIndex = 0
while caseIndex < testCount:
  let edgeAB = nextInt(inputData, scanPos)
  let edgeAC = nextInt(inputData, scanPos)
  let edgeAD = nextInt(inputData, scanPos)
  let edgeBC = nextInt(inputData, scanPos)
  let edgeBD = nextInt(inputData, scanPos)
  let edgeCD = nextInt(inputData, scanPos)

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
  caseIndex += 1

if outputBuffer.len > 0:
  flushOutput(outputBuffer)
```

The while loop runs exactly `testCount` times. Each pass reads six tokens and adds five terms to the exact accumulator. `formatFloat` writes four decimals, and `flushBlockBytes` caps the buffer at one block.

## Complexity

Let L be the input length in bytes and t be the number of cases.

| Phase | Time | Space |
| --- | --- | --- |
| Read and scan | O(L) | O(L) |
| Per case | O(1) | O(1) |
| Write output | O(t) | O(flushBlockBytes) |

The total is O(L + t) time and O(L + flushBlockBytes) space. A naive program builds the Cayley-Menger matrix and runs Gaussian elimination in floating point for each case. That uses dozens of steps instead of five and can round away the answer after a large cancellation.
