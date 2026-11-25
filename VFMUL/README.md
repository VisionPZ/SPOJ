# VFMUL — Fast Multiplication of Big Numbers (SPOJ)

<https://www.spoj.com/problems/VFMUL/>

## Problem

A calculator must multiply decimal integers with up to 300000 digits each. Schoolbook multiplication would take far too long at that size.

Input starts with `n ≤ 100`, the number of products. Each following case holds two integers separated by a space, each at most 300000 decimal digits. Output one product per case, with no leading zeros except for the value zero itself.

The judge bounds are these.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 100 |
| Operand length | at most 300000 decimal digits |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The digit bound rules out schoolbook multiplication.

The sample input and output follow verbatim.

```
5
4 2
123 43
324 342
0 12
9999 12345
```

```
8
5289
110808
0
123437655
```

## Idea

Split each operand into three-digit chunks and convolve the chunk lists. Think of long multiplication on paper, but folding all columns together in one wave instead of one at a time.

A base-1000 number is a sum of chunk values times powers of 1000. Multiplying two such sums adds each pair of chunks into one position. That sum is a convolution, which a fast Fourier transform computes in `O(N log N)` steps. A carry pass in base 1000 then rebuilds the decimal digits.

Schoolbook multiplication takes `O(n^2)` chunk products. The transform takes about `N log N` operations for `N` chunks.

A convolution turns quadratic multiplication into near-linear work.

## Why It Works

Four facts justify the transform.

1. A base-1000 number equals the sum of `chunk[i]·1000^i`. Multiplying two sums adds `chunkA[i]·chunkB[j]` into position `i + j`.
2. Position `k` therefore holds the sum over `i` of `chunkA[i]·chunkB[k-i]`. That sum is the convolution the FFT computes.
3. The FFT evaluates both chunk lists at complex roots of unity. Pointwise multiplication there gives the convolution values, and the inverse transform returns the coefficients.
4. Each coefficient stays below about 10^11. Floating error stays below 0.001, so rounding recovers the exact integer. A carry pass then normalizes base-1000 digits.

The table names the key values.

| Term | Meaning |
| --- | --- |
| `digitBase` | 1000, the chunk radix |
| `digitGroup` | 3 decimal digits per chunk |
| `size` | first power of two at least the convolution length |
| `twiddleRe`, `twiddleIm` | current complex root in a butterfly |
| `carry` | overflow passed to the next base-1000 digit |

A worked example fixes the idea with visible numbers.

| Step | Value |
| --- | --- |
| Chunks of 12345 | 345, 12 |
| Chunks of 6789 | 789, 6 |
| Raw convolution | 272205, 11538, 72 |
| After carry in base 1000 | 205, 810, 83 |
| Decimal product | 83810205 |

The last row equals 12345 times 6789.

## Code

**Constants and input.** The constants set the chunk width, flush size, and transform precision.

```nim
import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const digitBase = 1000
const digitGroup = 3
const piValue = 3.14159265358979323846

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

The read loop runs until stdin ends. One newline follows every input line. Reading costs one pass over the input bytes.

**Scanners.** The scanner walks the buffer by index.

```nim
proc skipSpaces(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1

proc readCount(data: string, pos: var int): int =
  skipSpaces(data, pos)
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc readToken(data: string, pos: var int, start: var int, finish: var int) =
  skipSpaces(data, pos)
  start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  finish = pos
```

`readCount` parses the small test count. `readToken` keeps a long operand as a slice, so no huge integer is ever built. The loop ends at the next space.

**Chunking.** Chunking reads each operand from its last digit.

```nim
proc toChunks(data: string, start: int, finish: int): seq[int] =
  result = @[]
  var right = finish - 1
  while right >= start:
    var chunk = 0
    var place = 1
    var digitIdx = 0
    while right >= start and digitIdx < digitGroup:
      chunk += (int(data[right]) - firstDigitValue) * place
      place *= 10
      right -= 1
      digitIdx += 1
    result.add chunk
  while result.len > 1 and result[result.len - 1] == 0:
    result.setLen(result.len - 1)
```

The outer loop walks right to left. Three digits become one chunk, least significant first. Trailing zero chunks are dropped, so zero stays a single chunk.

**FFT core.** The transform swaps into butterfly order, then folds blocks upward.

```nim
proc fft(realPart: var seq[float], imagPart: var seq[float], invert: bool) =
  let size = realPart.len
  var revIdx = 0
  for idx in 1 .. size - 1:
    var bit = size div 2
    while (revIdx and bit) != 0:
      revIdx = revIdx xor bit
      bit = bit div 2
    revIdx = revIdx xor bit
    if idx < revIdx:
      swap realPart[idx], realPart[revIdx]
      swap imagPart[idx], imagPart[revIdx]
  var blockLen = 2
  while blockLen <= size:
    let angle = (if invert: 2.0 else: -2.0) * piValue / float(blockLen)
    let stepRe = cos(angle)
    let stepIm = sin(angle)
    var blockStart = 0
    while blockStart < size:
      var twiddleRe = 1.0
      var twiddleIm = 0.0
      let half = blockLen div 2
      var offset = 0
      while offset < half:
        let leftRe = realPart[blockStart + offset]
        let leftIm = imagPart[blockStart + offset]
        let rightRe = realPart[blockStart + offset + half] * twiddleRe - imagPart[blockStart + offset + half] * twiddleIm
        let rightIm = realPart[blockStart + offset + half] * twiddleIm + imagPart[blockStart + offset + half] * twiddleRe
        realPart[blockStart + offset] = leftRe + rightRe
        imagPart[blockStart + offset] = leftIm + rightIm
        realPart[blockStart + offset + half] = leftRe - rightRe
        imagPart[blockStart + offset + half] = leftIm - rightIm
        let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
        twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
        twiddleRe = nextRe
        offset += 1
      blockStart += blockLen
    blockLen *= 2
  if invert:
    for idx in 0 .. size - 1:
      realPart[idx] = realPart[idx] / float(size)
      imagPart[idx] = imagPart[idx] / float(size)
```

`blockLen` doubles until it reaches `size`. Bit reversal arranges the input once. The sign of `angle` selects the forward or inverse transform. The nested loops cost `O(size log size)`.

**Convolution.** Multiplication combines two transforms and propagates carries.

```nim
proc multiply(first: seq[int], second: seq[int]): seq[int] =
  let need = first.len + second.len - 1
  var size = 1
  while size < need:
    size = size * 2
  var firstRe = newSeq[float](size)
  var firstIm = newSeq[float](size)
  var secondRe = newSeq[float](size)
  var secondIm = newSeq[float](size)
  for idx in 0 .. first.len - 1:
    firstRe[idx] = float(first[idx])
  for idx in 0 .. second.len - 1:
    secondRe[idx] = float(second[idx])
  fft(firstRe, firstIm, false)
  fft(secondRe, secondIm, false)
  for idx in 0 .. size - 1:
    let newRe = firstRe[idx] * secondRe[idx] - firstIm[idx] * secondIm[idx]
    firstIm[idx] = firstRe[idx] * secondIm[idx] + firstIm[idx] * secondRe[idx]
    firstRe[idx] = newRe
  fft(firstRe, firstIm, true)
  var digits = newSeq[int](size + 1)
  for idx in 0 .. size - 1:
    digits[idx] = int(round(firstRe[idx]))
  var carry = 0
  for idx in 0 .. size - 1:
    var value = digits[idx] + carry
    carry = value div digitBase
    digits[idx] = value mod digitBase
  digits[size] = carry
  while digits.len > 1 and digits[digits.len - 1] == 0:
    digits.setLen(digits.len - 1)
  return digits
```

`size` is the first power of two at least `need`. Pointwise complex multiplication combines both forward transforms. Rounding and carry take `O(size)` time.

**Writer and driver.** The writer pads chunks and the driver parses each pair.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendNumber(digits: seq[int]) =
  if digits.len == 1 and digits[0] == 0:
    appendOutput("0")
    return
  let top = digits.len - 1
  appendOutput($digits[top])
  var chunkIdx = top - 1
  while chunkIdx >= 0:
    if digits[chunkIdx] < 10:
      appendOutput("00")
    elif digits[chunkIdx] < 100:
      appendOutput("0")
    appendOutput($digits[chunkIdx])
    chunkIdx -= 1

let caseCount = readCount(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var startFirst = 0
  var finishFirst = 0
  var startSecond = 0
  var finishSecond = 0
  readToken(inputData, scanPos, startFirst, finishFirst)
  readToken(inputData, scanPos, startSecond, finishSecond)
  let first = toChunks(inputData, startFirst, finishFirst)
  let second = toChunks(inputData, startSecond, finishSecond)
  let product = multiply(first, second)
  appendNumber(product)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes only after `flushBlockBytes`. Chunks below 100 get leading zeros. The last write flushes the remaining bytes.

## Complexity

Chunking and conversion scale with digit count, while the transform scales with chunk count.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B input bytes | O(B) |
| Chunking | O(D) for D digits | O(D) chunks |
| Three transforms | O(N log N) | O(N) arrays |
| Carry and print | O(N) | one flush block |

The transform dominates for large operands.

The totals use the chunk count `N`.

| Measure | Big O |
| --- | --- |
| Time | O(N log N) per product |
| Space | O(N) per product |

Schoolbook multiplication takes `O(n^2)` chunk products for contrast.
