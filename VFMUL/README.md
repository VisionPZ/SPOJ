## Problem

Read a count, then that many pairs of decimal integers. Each integer has at most 300000 digits. Print the product of each pair on its own line.

The judge bounds are as follows.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 100 |
| Operand length | at most 300000 decimal digits |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The digit bound rules out schoolbook multiplication.

## Idea

Split each operand into base-1000 chunks of three decimal digits. The product chunks form the convolution of the two chunk lists. A fast Fourier transform (FFT) computes that convolution in O(N log N) steps, where N is the next power of two.

Cost per multiplication: O(N log N) for N output chunks, against O(n^2) for schoolbook.

## Why It Works

A base-1000 number equals the sum of chunk[i] times 1000^i. Multiplying two such sums adds chunkA[i] times chunkB[j] into position i+j.

Position k therefore holds the sum of chunkA[i] times chunkB[k-i]. That sum is the convolution the FFT computes.

The FFT evaluates both lists at complex roots of unity. Pointwise multiplication there gives the convolution values. The inverse transform returns the coefficients.

Each coefficient stays below about 10^11. Floating error stays below 0.001, so rounding recovers the exact integer. A carry pass in base 1000 then builds the decimal result.

A script-generated example fixes the idea.

| Step | Value |
| --- | --- |
| Chunks of 12345 | 345, 12 |
| Chunks of 6789 | 789, 6 |
| Raw convolution | 272205, 11538, 72 |
| After carry | 205, 810, 83 |
| Decimal product | 83810205 |

The last row equals 12345 times 6789.

## Code

The constants set the chunk width, the flush size, and the transform precision.

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

The read loop runs until stdin ends. One newline follows every input line in the buffer. Reading costs O(input bytes), and the buffer holds all of them.

The scanner walks the buffer by index.

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

`readCount` parses the small test count. `readToken` keeps a long operand as a slice, so no huge integer is ever built. The loop ends at the next space and costs O(token bytes).

Chunking reads each operand from its last digit.

```nim
proc toChunks(data: string, start: int, finish: int): seq[int] =
  result = @[]
  var right = finish - 1
  while right >= start:
    var chunk = 0
    var place = 1
    var k = 0
    while right >= start and k < digitGroup:
      chunk += (int(data[right]) - firstDigitValue) * place
      place *= 10
      right -= 1
      k += 1
    result.add chunk
  while result.len > 1 and result[result.len - 1] == 0:
    result.setLen(result.len - 1)
```

The outer loop walks right to left over the token. Three digits become one chunk, with the least significant chunk first. Trailing zero chunks are dropped, so zero stays a single chunk.

The transform works on two real arrays and two imaginary arrays.

```nim
proc fft(re: var seq[float], im: var seq[float], invert: bool) =
  let n = re.len
  var j = 0
  for i in 1 .. n - 1:
    var bit = n div 2
    while (j and bit) != 0:
      j = j xor bit
      bit = bit div 2
    j = j xor bit
    if i < j:
      swap re[i], re[j]
      swap im[i], im[j]
  var len = 2
  while len <= n:
    let angle = (if invert: 2.0 else: -2.0) * piValue / float(len)
    let stepRe = cos(angle)
    let stepIm = sin(angle)
    var i = 0
    while i < n:
      var twiddleRe = 1.0
      var twiddleIm = 0.0
      let half = len div 2
      var k = 0
      while k < half:
        let leftRe = re[i + k]
        let leftIm = im[i + k]
        let rightRe = re[i + k + half] * twiddleRe - im[i + k + half] * twiddleIm
        let rightIm = re[i + k + half] * twiddleIm + im[i + k + half] * twiddleRe
        re[i + k] = leftRe + rightRe
        im[i + k] = leftIm + rightIm
        re[i + k + half] = leftRe - rightRe
        im[i + k + half] = leftIm - rightIm
        let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
        twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
        twiddleRe = nextRe
        k += 1
      i += len
    len *= 2
  if invert:
    for i in 0 .. n - 1:
      re[i] = re[i] / float(n)
      im[i] = im[i] / float(n)
```

`len` doubles until it reaches n. Bit reversal puts the input in butterfly order once. The sign of `angle` selects the forward or inverse transform. The three nested loops cost O(n log n).

Multiplication combines two transforms into one result.

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
  for i in 0 .. first.len - 1:
    firstRe[i] = float(first[i])
  for i in 0 .. second.len - 1:
    secondRe[i] = float(second[i])
  fft(firstRe, firstIm, false)
  fft(secondRe, secondIm, false)
  for i in 0 .. size - 1:
    let newRe = firstRe[i] * secondRe[i] - firstIm[i] * secondIm[i]
    firstIm[i] = firstRe[i] * secondIm[i] + firstIm[i] * secondRe[i]
    firstRe[i] = newRe
  fft(firstRe, firstIm, true)
  var digits = newSeq[int](size + 1)
  for i in 0 .. size - 1:
    digits[i] = int(round(firstRe[i]))
  var carry = 0
  for i in 0 .. size - 1:
    var value = digits[i] + carry
    carry = value div digitBase
    digits[i] = value mod digitBase
  digits[size] = carry
  while digits.len > 1 and digits[digits.len - 1] == 0:
    digits.setLen(digits.len - 1)
  return digits
```

`size` is the first power of two at least `need`. Pointwise complex multiplication combines both forward transforms. Rounding and carry take O(size) time.

The driver writes padded chunks and flushes the output buffer in blocks.

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
  var i = top - 1
  while i >= 0:
    if digits[i] < 10:
      appendOutput("00")
    elif digits[i] < 100:
      appendOutput("0")
    appendOutput($digits[i])
    i -= 1

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

`appendOutput` flushes only after `flushBlockBytes`. Chunks below 100 get leading zeros, and the top chunk gets none. The last write flushes the remaining bytes.

## Complexity

Reading takes O(B) time and O(B) space for B input bytes. Chunking takes O(D) time and O(D) space for D digits.

Each multiplication runs three transforms of length N. That costs O(N log N) time and O(N) space. Carry propagation and formatting take O(N) time.

The total is O(N log N) time and O(N) space per test case. Schoolbook multiplication takes O(n^2) chunk products for contrast.
