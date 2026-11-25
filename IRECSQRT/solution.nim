const flushBlockBytes = 1 shl 17
const lowMask = 4294967295'u64
const twoPower64 = 18446744073709551616.0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextUInt(data: string, pos: var int): uint64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'u64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10'u64 + uint64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc addMod(left, right, modulus: uint64): uint64 =
  if left >= modulus - right:
    return left - (modulus - right)
  return left + right

proc subMod(left, right, modulus: uint64): uint64 =
  if left >= right:
    return left - right
  return modulus - (right - left)

proc product128(left, right: uint64): tuple[hi, lo: uint64] =
  let leftLow = left and lowMask
  let leftHigh = left shr 32
  let rightLow = right and lowMask
  let rightHigh = right shr 32
  let lowLow = leftLow * rightLow
  let lowHigh = leftLow * rightHigh
  let highLow = leftHigh * rightLow
  let highHigh = leftHigh * rightHigh
  let middle = (lowLow shr 32) + (lowHigh and lowMask) + (highLow and lowMask)
  result.lo = (lowLow and lowMask) or (middle shl 32)
  result.hi = highHigh + (lowHigh shr 32) + (highLow shr 32) + (middle shr 32)

proc mulMod(left, right, modulus: uint64): uint64 =
  if modulus <= 1'u64:
    return 0'u64
  let full = product128(left, right)
  var limbs = [full.hi shr 32, full.hi and lowMask, full.lo shr 32, full.lo and lowMask]
  var remHi = 0'u64
  var remLo = 0'u64
  for limb in limbs:
    remHi = (remHi shl 32) or (remLo shr 32)
    remLo = ((remLo and lowMask) shl 32) or limb
    if remHi == 0'u64 and remLo < modulus:
      continue
    let estimate = (float(remHi) * twoPower64 + float(remLo)) / float(modulus)
    var quotient = uint64(estimate)
    var quotProd = product128(quotient, modulus)
    while quotProd.hi > remHi or (quotProd.hi == remHi and quotProd.lo > remLo):
      quotient -= 1'u64
      quotProd = product128(quotient, modulus)
    while true:
      let nextQuotient = quotient + 1'u64
      let nextProd = product128(nextQuotient, modulus)
      if nextProd.hi < remHi or (nextProd.hi == remHi and nextProd.lo <= remLo):
        quotient = nextQuotient
        quotProd = nextProd
      else:
        break
    let borrow: uint64 = if remLo < quotProd.lo: 1'u64 else: 0'u64
    remLo = remLo - quotProd.lo
    remHi = remHi - quotProd.hi - borrow
  return remLo

proc multiplyPoly(left, right: array[3, uint64], modulus: uint64): array[3, uint64] =
  let lowLow = mulMod(left[0], right[0], modulus)
  let lowMiddle = addMod(mulMod(left[0], right[1], modulus), mulMod(left[1], right[0], modulus), modulus)
  let middle = addMod(addMod(mulMod(left[0], right[2], modulus), mulMod(left[1], right[1], modulus), modulus), mulMod(left[2], right[0], modulus), modulus)
  let highMiddle = addMod(mulMod(left[1], right[2], modulus), mulMod(left[2], right[1], modulus), modulus)
  let high = mulMod(left[2], right[2], modulus)
  result[0] = addMod(addMod(lowLow, mulMod(highMiddle, 8'u64, modulus), modulus), mulMod(high, 56'u64, modulus), modulus)
  result[1] = subMod(subMod(lowMiddle, mulMod(highMiddle, 14'u64, modulus), modulus), mulMod(high, 90'u64, modulus), modulus)
  result[2] = addMod(addMod(middle, mulMod(highMiddle, 7'u64, modulus), modulus), mulMod(high, 35'u64, modulus), modulus)

proc sequenceTerm(exponent, modulus: uint64): uint64 =
  if modulus <= 1'u64:
    return 0'u64
  var resultPoly = [1'u64, 0'u64, 0'u64]
  var basePoly = [0'u64, 1'u64, 0'u64]
  var remaining = exponent
  while remaining > 0'u64:
    if (remaining and 1'u64) == 1'u64:
      resultPoly = multiplyPoly(resultPoly, basePoly, modulus)
    remaining = remaining shr 1
    if remaining > 0'u64:
      basePoly = multiplyPoly(basePoly, basePoly, modulus)
  let firstTerm = mulMod(resultPoly[0], 1'u64, modulus)
  let secondTerm = mulMod(resultPoly[1], 2'u64, modulus)
  let thirdTerm = mulMod(resultPoly[2], 5'u64, modulus)
  return addMod(addMod(firstTerm, secondTerm, modulus), thirdTerm, modulus)

let caseCount = nextUInt(inputData, scanPos)
for caseIndex in 0 .. int(caseCount) - 1:
  let exponent = nextUInt(inputData, scanPos)
  let modulus = nextUInt(inputData, scanPos)
  appendOutput($sequenceTerm(exponent, modulus))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
