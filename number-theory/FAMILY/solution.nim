{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const fractionScaleBits = 310
const limbBits = 30
const limbMask: uint64 = 1073741823'u64
const bigBase: uint64 = 1000000000'u64
const bigChunkDigits = 9

type BigNumber = seq[uint32]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc bigAdd(left, right: BigNumber): BigNumber =
  let longest = max(left.len, right.len)
  result = newSeq[uint32](longest + 1)
  var carry: uint32 = 0
  for chunkIdx in 0 ..< longest:
    var chunkSum: uint64 = uint64(carry)
    if chunkIdx < left.len:
      chunkSum += uint64(left[chunkIdx])
    if chunkIdx < right.len:
      chunkSum += uint64(right[chunkIdx])
    result[chunkIdx] = uint32(chunkSum and limbMask)
    carry = uint32(chunkSum shr limbBits)
  result[longest] = carry
  if carry == 0'u32:
    result.setLen(longest)
  return result

proc bigHalve(value: BigNumber): BigNumber =
  if value.len == 0:
    return @[]
  result = newSeq[uint32](value.len)
  var carry: uint32 = 0
  for chunkIdx in countdown(value.len - 1, 0):
    let current = (uint64(carry) shl limbBits) or uint64(value[chunkIdx])
    result[chunkIdx] = uint32(current shr 1'u64)
    carry = uint32(current and 1'u64)
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result

proc bigShiftRight(value: BigNumber, bits: int): BigNumber =
  if value.len == 0 or bits == 0:
    return value
  let wordShift = bits div limbBits
  let bitShift = bits mod limbBits
  if wordShift >= value.len:
    return @[]
  result = newSeq[uint32](value.len - wordShift)
  for chunkIdx in 0 ..< result.len:
    let highPart = uint64(value[chunkIdx + wordShift])
    var lowPart: uint64 = 0
    if chunkIdx + wordShift + 1 < value.len:
      lowPart = uint64(value[chunkIdx + wordShift + 1])
    let combined = highPart or (lowPart shl limbBits)
    result[chunkIdx] = uint32((combined shr bitShift) and limbMask)
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result

proc bigMultiply(left, right: BigNumber): BigNumber =
  if left.len == 0 or right.len == 0:
    return @[]
  result = newSeq[uint32](left.len + right.len + 1)
  for leftIdx in 0 ..< left.len:
    var carry: uint64 = 0
    let leftChunk = uint64(left[leftIdx])
    for rightIdx in 0 ..< right.len:
      let current = uint64(result[leftIdx + rightIdx]) + leftChunk * uint64(right[rightIdx]) + carry
      result[leftIdx + rightIdx] = uint32(current and limbMask)
      carry = current shr limbBits
    var carryPos = leftIdx + right.len
    while carry > 0'u64:
      let current = uint64(result[carryPos]) + carry
      result[carryPos] = uint32(current and limbMask)
      carry = current shr limbBits
      carryPos += 1
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result

proc bigMultiplySmall(value: BigNumber, factor: uint64): BigNumber =
  if value.len == 0 or factor == 0:
    return @[]
  result = newSeq[uint32](value.len + 2)
  var carry: uint64 = 0
  for chunkIdx in 0 ..< value.len:
    let current = uint64(value[chunkIdx]) * factor + carry
    result[chunkIdx] = uint32(current and limbMask)
    carry = current shr limbBits
  var carryPos = value.len
  while carry > 0'u64:
    result[carryPos] = uint32(carry and limbMask)
    carry = carry shr limbBits
    carryPos += 1
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result

proc bigToDecimal(value: BigNumber): string =
  if value.len == 0:
    return "0"
  var work = value
  var chunks: seq[uint32] = @[]
  while work.len > 0:
    var remainder: uint64 = 0
    for chunkIdx in countdown(work.len - 1, 0):
      let current = (remainder shl limbBits) or uint64(work[chunkIdx])
      work[chunkIdx] = uint32(current div bigBase)
      remainder = current mod bigBase
    chunks.add uint32(remainder)
    while work.len > 0 and work[work.len - 1] == 0'u32:
      work.setLen(work.len - 1)
  result = $uint64(chunks[chunks.len - 1])
  for chunkIdx in countdown(chunks.len - 2, 0):
    let chunkText = $uint64(chunks[chunkIdx])
    for padIdx in 0 ..< (bigChunkDigits - chunkText.len):
      result.add '0'
    result.add chunkText
  return result

var powerOfTwo: BigNumber = newSeq[uint32](fractionScaleBits div limbBits + 1)
powerOfTwo[fractionScaleBits div limbBits] = uint32(1'u64 shl (fractionScaleBits mod limbBits))

var pow5Table = newSeq[BigNumber](fractionScaleBits + 1)
pow5Table[0] = @[1'u32]
for bitIdx in 1 .. fractionScaleBits:
  pow5Table[bitIdx] = bigMultiplySmall(pow5Table[bitIdx - 1], 5'u64)

var currentParentOne: seq[int]
var currentParentTwo: seq[int]
var currentRank: seq[int]
var rankDone: seq[bool]
var currentStride = 0
var kinshipMemo: seq[BigNumber]
var kinshipDone: seq[bool]
var kinshipScale: seq[int]
var answerCache: seq[string]

proc computeRank(member: int): int =
  if rankDone[member]:
    return currentRank[member]
  if currentParentOne[member] == 0:
    currentRank[member] = 0
  else:
    let leftRank = computeRank(currentParentOne[member])
    let rightRank = computeRank(currentParentTwo[member])
    currentRank[member] = 1 + max(leftRank, rightRank)
  rankDone[member] = true
  return currentRank[member]

proc kinship(first, second: int): BigNumber =
  let memoIndex = first * currentStride + second
  if kinshipDone[memoIndex]:
    return kinshipMemo[memoIndex]
  var value: BigNumber = @[]
  var scaleValue = 0
  if first == second:
    value = powerOfTwo
    scaleValue = 0
  elif currentRank[first] < currentRank[second]:
    value = kinship(second, first)
    scaleValue = kinshipScale[second * currentStride + first]
  else:
    let olderMember = first
    let youngerMember = second
    let firstParent = currentParentOne[olderMember]
    if firstParent == 0:
      value = @[]
      scaleValue = 0
    else:
      let secondParent = currentParentTwo[olderMember]
      let leftValue = kinship(firstParent, youngerMember)
      let leftScale = kinshipScale[firstParent * currentStride + youngerMember]
      let rightValue = kinship(secondParent, youngerMember)
      let rightScale = kinshipScale[secondParent * currentStride + youngerMember]
      value = bigAdd(leftValue, rightValue)
      value = bigHalve(value)
      scaleValue = max(leftScale, rightScale) + 1
  kinshipDone[memoIndex] = true
  kinshipMemo[memoIndex] = value
  kinshipScale[memoIndex] = scaleValue
  return value

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let memberCount = nextInt(inputData, scanPos)
  let childCount = nextInt(inputData, scanPos)
  currentStride = memberCount + 1
  currentParentOne = newSeq[int](memberCount + 1)
  currentParentTwo = newSeq[int](memberCount + 1)
  for childIdx in 0 ..< childCount:
    let childMember = nextInt(inputData, scanPos)
    currentParentOne[childMember] = nextInt(inputData, scanPos)
    currentParentTwo[childMember] = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var queryFirst = newSeq[int](queryCount)
  var querySecond = newSeq[int](queryCount)
  for queryIdx in 0 ..< queryCount:
    queryFirst[queryIdx] = nextInt(inputData, scanPos)
    querySecond[queryIdx] = nextInt(inputData, scanPos)

  currentRank = newSeq[int](memberCount + 1)
  rankDone = newSeq[bool](memberCount + 1)
  for member in 1 .. memberCount:
    discard computeRank(member)

  let tableSize = currentStride * currentStride
  kinshipMemo = newSeq[BigNumber](tableSize)
  kinshipDone = newSeq[bool](tableSize)
  kinshipScale = newSeq[int](tableSize)
  answerCache = newSeq[string](tableSize)

  for queryIdx in 0 ..< queryCount:
    let firstMember = queryFirst[queryIdx]
    let secondMember = querySecond[queryIdx]
    let lowMember = min(firstMember, secondMember)
    let highMember = max(firstMember, secondMember)
    let cacheKey = lowMember * currentStride + highMember
    let cachedAnswer = answerCache[cacheKey]
    if cachedAnswer.len > 0:
      appendOutput(cachedAnswer)
      outputBuffer.add '\n'
      continue
    let ratio = kinship(firstMember, secondMember)
    var rendered: string = ""
    if ratio.len == 0:
      rendered = "0%"
    else:
      let scaleBits = kinshipScale[firstMember * currentStride + secondMember]
      var shiftBits = fractionScaleBits - scaleBits
      if shiftBits > fractionScaleBits:
        shiftBits = fractionScaleBits
      let oddNumerator = bigShiftRight(ratio, shiftBits)
      let numerator = bigMultiply(oddNumerator, pow5Table[scaleBits])
      let total = bigMultiplySmall(numerator, 100'u64)
      let decimalText = bigToDecimal(total)
      if scaleBits == 0:
        rendered = decimalText & "%"
      else:
        var padded = ""
        let paddingCount = scaleBits + 1 - decimalText.len
        if paddingCount > 0:
          for padIdx in 0 ..< paddingCount:
            padded.add '0'
        padded.add decimalText
        let cutPos = padded.len - scaleBits
        var wholePart = padded[0 .. cutPos - 1]
        var fractionPart = padded[cutPos .. padded.len - 1]
        while fractionPart.len > 0 and fractionPart[fractionPart.len - 1] == '0':
          fractionPart.setLen(fractionPart.len - 1)
        var leading = 0
        while leading < wholePart.len - 1 and wholePart[leading] == '0':
          leading += 1
        wholePart = wholePart[leading .. wholePart.len - 1]
        if fractionPart.len == 0:
          rendered = wholePart & "%"
        else:
          rendered = wholePart & "." & fractionPart & "%"
    answerCache[cacheKey] = rendered
    appendOutput(rendered)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
