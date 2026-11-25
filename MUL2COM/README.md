# MUL2COM — Binary multiplication (SPOJ)

<https://www.spoj.com/problems/MUL2COM/>

## Problem

Multiply two n-bit two's-complement integers. Write the product in the same form, or write overflow when the exact product cannot be stored in n bits.

Input starts with the bit width, then two strings of n bits. A single 0 ends the input. Output one line per case.

| item | bound |
|---|---|
| bit width n | 1 to 1024 |
| test cases | at most 40 |
| stored range | -2^(n-1) to 2^(n-1)-1 |
| judge limit | 204 ms, 1536 MB |

The leading bit carries the sign. A leading 1 means the unsigned value minus 2^n.

Sample input:

```
3
110
011
4
0011
1110
0
```

Sample output:

```
overflow
1010
```

## Idea

Strip the signs from two temperatures before multiplying them, then decide whether the result fits the thermometer: work with magnitudes first and attach the sign later.

Convert each bit string into base-2^32 limbs. Negate a negative operand within its width to get the magnitude. Schoolbook multiplication gives the exact product in limbs. Compare that magnitude with the limit for the product sign. A fitting product takes its low n bits, negated when negative.

Each limb pair costs one 64-bit multiply. Naive bit-by-bit multiplication would do 32 times more inner steps. Magnitudes decide overflow, and low bits decide the result.

## Why It Works

1. A leading 1 makes the signed value equal to the unsigned value minus 2^n.
2. Negating unsigned limbs and masking to n bits gives the exact magnitude.
3. A 64-bit accumulator holds a limb product plus carry, so no intermediate value overflows.
4. A positive product fits through 2^(n-1)-1, and a negative product fits through -2^(n-1).
5. The low n bits of a fitting product equal its two's-complement form.

| term | meaning |
|---|---|
| `bitsPerLimb` | bits held in one 32-bit limb |
| `leftMagnitude` | absolute value of the first operand |
| `productMagnitude` | absolute value of the exact product |
| `limitLimbs` | largest allowed magnitude for the product sign |
| `resultNegative` | sign of a nonzero product |

A worked example uses n = 4 with 0011 and 1110. The signs give 3 and -2, so the magnitude product is 6. A negative product may reach 8, and 6 fits. The low four bits of 6 are 0110; negating them yields 1010.

The width mask removes unused high bits after negation. Zero products keep a positive sign because no bits are set.

## Code

**Input and output.** One read loop loads all lines, and one buffer writes all answers.

```nim
const flushBlockBytes = 1 shl 17
const bitsPerLimb = 32
const limbMask = 0xFFFFFFFF'u64

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

proc nextBinary(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand scanner skips spaces and keeps each binary token whole. The output buffer flushes only after reaching its block size.

**Limb helpers.** Magnitudes, multiplication, and limit comparison stay in 32-bit pieces.

```nim
proc toLimbs(bits: string, limbCount: int): seq[uint32] =
  var limbs = newSeq[uint32](limbCount)
  for charIndex in 0 .. bits.len - 1:
    if bits[charIndex] == '1':
      let bitIndex = bits.len - 1 - charIndex
      limbs[bitIndex div bitsPerLimb] = limbs[bitIndex div bitsPerLimb] or
        (uint32(1) shl (bitIndex mod bitsPerLimb))
  return limbs

proc negateLimbs(limbs: var seq[uint32]) =
  var carry = 1'u32
  for limbIndex in 0 .. limbs.len - 1:
    let inverted = not limbs[limbIndex]
    let combined = inverted + carry
    limbs[limbIndex] = combined
    if combined < inverted:
      carry = 1'u32
    else:
      carry = 0'u32

proc maskToWidth(limbs: var seq[uint32], bitCount: int) =
  let remainder = bitCount mod bitsPerLimb
  if remainder != 0:
    limbs[limbs.len - 1] = limbs[limbs.len - 1] and
      ((uint32(1) shl remainder) - 1'u32)

proc multiplyLimbs(left: seq[uint32], right: seq[uint32]): seq[uint32] =
  var productLimbs = newSeq[uint32](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry = 0'u64
    for rightIndex in 0 .. right.len - 1:
      let position = leftIndex + rightIndex
      let accumulator = uint64(left[leftIndex]) * uint64(right[rightIndex]) +
        uint64(productLimbs[position]) + carry
      productLimbs[position] = uint32(accumulator and limbMask)
      carry = accumulator shr bitsPerLimb
    var position = leftIndex + right.len
    while carry != 0'u64:
      let accumulator = uint64(productLimbs[position]) + carry
      productLimbs[position] = uint32(accumulator and limbMask)
      carry = accumulator shr bitsPerLimb
      position += 1
  return productLimbs

proc exceedsLimit(productLimbs: seq[uint32], limitLimbs: seq[uint32]): bool =
  for limbIndex in limitLimbs.len .. productLimbs.len - 1:
    if productLimbs[limbIndex] != 0'u32:
      return true
  for limbIndex in countdown(limitLimbs.len - 1, 0):
    if productLimbs[limbIndex] > limitLimbs[limbIndex]:
      return true
    if productLimbs[limbIndex] < limitLimbs[limbIndex]:
      return false
  return false
```

Two's-complement negation works by inverting limbs and adding one. Each accumulated limb product uses 64 bits. The limit comparison checks high limbs before low limbs.

**Main loop.** Each case signs the operands, multiplies magnitudes, and formats the answer.

```nim
while true:
  let bitCount = nextInt(inputData, scanPos)
  if bitCount == 0:
    break
  let firstBits = nextBinary(inputData, scanPos)
  let secondBits = nextBinary(inputData, scanPos)
  let limbCount = (bitCount + bitsPerLimb - 1) div bitsPerLimb
  var leftMagnitude = toLimbs(firstBits, limbCount)
  var rightMagnitude = toLimbs(secondBits, limbCount)
  let firstNegative = firstBits[0] == '1'
  let secondNegative = secondBits[0] == '1'
  if firstNegative:
    negateLimbs(leftMagnitude)
    maskToWidth(leftMagnitude, bitCount)
  if secondNegative:
    negateLimbs(rightMagnitude)
    maskToWidth(rightMagnitude, bitCount)
  let productMagnitude = multiplyLimbs(leftMagnitude, rightMagnitude)
  var magnitudeIsZero = true
  for limbIndex in 0 .. productMagnitude.len - 1:
    if productMagnitude[limbIndex] != 0'u32:
      magnitudeIsZero = false
  let resultNegative = firstNegative != secondNegative and not magnitudeIsZero
  var limitLimbs = newSeq[uint32](limbCount)
  if resultNegative:
    limitLimbs[(bitCount - 1) div bitsPerLimb] =
      uint32(1) shl ((bitCount - 1) mod bitsPerLimb)
  else:
    for bitIndex in 0 .. bitCount - 2:
      limitLimbs[bitIndex div bitsPerLimb] = limitLimbs[bitIndex div bitsPerLimb] or
        (uint32(1) shl (bitIndex mod bitsPerLimb))
  if exceedsLimit(productMagnitude, limitLimbs):
    appendOutput("overflow")
  else:
    var resultLimbs = newSeq[uint32](limbCount)
    for limbIndex in 0 .. limbCount - 1:
      resultLimbs[limbIndex] = productMagnitude[limbIndex]
    if resultNegative:
      negateLimbs(resultLimbs)
    var resultBits = ""
    for bitIndex in countdown(bitCount - 1, 0):
      if (resultLimbs[bitIndex div bitsPerLimb] and
          (uint32(1) shl (bitIndex mod bitsPerLimb))) != 0'u32:
        resultBits.add '1'
      else:
        resultBits.add '0'
    appendOutput(resultBits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sign of a zero product stays positive. A negative fitting result negates the low n bits before printing.

## Complexity

Each case converts two strings, multiplies limbs, and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over the file | one input string |
| limb multiply | n^2 / 32^2 limb steps | 2n/32 limbs |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| time per case | O(n^2 / 32^2) |
| space per case | O(n / 32) |

Bit-by-bit multiplication would need 32 times more inner steps per case. The limb method keeps 1024-bit products within the time limit.

Takeaway: compare magnitudes for overflow and low bits for the stored result.
