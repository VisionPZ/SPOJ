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
