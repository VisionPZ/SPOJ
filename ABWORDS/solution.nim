import bitops, tables

{.passC: "-O3".}
{.passL: "-s".}
{.push checks: off, assertions: off, stacktrace: off, lineDir: off.}

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  maxComponents = 104
  internBits = 18
  internSize = 1 shl internBits
  internMask = internSize - 1
  simCacheBits = 20
  simCacheSize = 1 shl simCacheBits
  simCacheMask = simCacheSize - 1
  maxDpStates = 105 * 105 * 105
  maxGroupSize = 1024
  maxBitsetWords = 16
  hashIncrement = 0x9e3779b97f4a7c15'u64
  hashMixA = 0xbf58476d1ce4e5b9'u64
  hashMixB = 0x94d049bb133111eb'u64
  hashSeed = 0x517cc1b727220a95'u64

var inputData = ""

proc readInputStream() =
  var chunk = newString(flushBlockBytes)
  var totalBytes = 0
  while true:
    let bytesRead = stdin.readBuffer(addr chunk[0], flushBlockBytes)
    if bytesRead <= 0:
      break
    let previousLen = totalBytes
    totalBytes += bytesRead
    if inputData.len < totalBytes:
      let nextCapacity = max(totalBytes, inputData.len * 2)
      inputData.setLen(nextCapacity)
    copyMem(addr inputData[previousLen], addr chunk[0], bytesRead)
  inputData.setLen(totalBytes)

var scanPos = 0

proc nextInt(): int {.inline.} =
  let dataLen = inputData.len
  while scanPos < dataLen and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  var value = 0
  while scanPos < dataLen and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    inc scanPos
  return value

proc nextWordSpan(startPos, stopPos: var int) {.inline.} =
  let dataLen = inputData.len
  while scanPos < dataLen and inputData[scanPos] != 'a' and inputData[scanPos] != 'b':
    inc scanPos
  startPos = scanPos
  while scanPos < dataLen and (inputData[scanPos] == 'a' or inputData[scanPos] == 'b'):
    inc scanPos
  stopPos = scanPos

var outputBuffer = ""

proc appendInt(value: int) {.inline.} =
  outputBuffer.add($value)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

proc splitMix64(seed: uint64): uint64 {.inline.} =
  var mixed = seed + hashIncrement
  mixed = (mixed xor (mixed shr 30)) * hashMixA
  mixed = (mixed xor (mixed shr 27)) * hashMixB
  return mixed xor (mixed shr 31)

var weightPrimary: array[256, uint64]
var weightSecondary: array[256, uint64]

proc initWeights() =
  for i in 0..<256:
    weightPrimary[i] = splitMix64(uint64(i) * 2'u64 + 1'u64)
    weightSecondary[i] = splitMix64(uint64(i) * 2'u64 + 1000003'u64)

var exactChildren: seq[int32] = @[]
var exactChildStart: seq[int32] = @[]
var exactChildLen: seq[int16] = @[]
var canonOfExact: seq[int32] = @[]
var coreOfExact: seq[int32] = @[]

var canonChildren: seq[int32] = @[]
var canonChildStart: seq[int32] = @[]
var canonChildLen: seq[int16] = @[]
var canonUniversal: seq[bool] = @[]
var canonAllDistinct: seq[bool] = @[]
var canonAllChildrenUniv: seq[bool] = @[]
var canonMaxSymLocal: seq[int16] = @[]
var canonMaxSymCount: seq[int16] = @[]

var exactTableStamp: array[internSize, int32]
var exactTableHash: array[internSize, uint64]
var exactTableId: array[internSize, int32]

var canonTableStamp: array[internSize, int32]
var canonTableHash: array[internSize, uint64]
var canonTableId: array[internSize, int32]

var internCaseStamp: int32 = 0

proc resetCaseTrees() =
  inc internCaseStamp
  exactChildren.setLen(0)
  exactChildStart.setLen(0)
  exactChildLen.setLen(0)
  canonOfExact.setLen(0)
  coreOfExact.setLen(0)
  canonChildren.setLen(0)
  canonChildStart.setLen(0)
  canonChildLen.setLen(0)
  canonUniversal.setLen(0)
  canonAllDistinct.setLen(0)
  canonAllChildrenUniv.setLen(0)
  canonMaxSymLocal.setLen(0)
  canonMaxSymCount.setLen(0)

proc hashInt32Slice(values: openArray[int32], offset, length: int): uint64 {.inline.} =
  var digest = uint64(length) * hashIncrement + hashSeed
  for i in 0..<length:
    digest = splitMix64(digest xor uint64(values[offset + i]))
  return digest

proc internCanon(sortedIds: openArray[int32], offset, length: int): int32 =
  let digest = hashInt32Slice(sortedIds, offset, length)
  var slot = int(digest and uint64(internMask))
  while canonTableStamp[slot] == internCaseStamp:
    if canonTableHash[slot] == digest:
      let existingId = canonTableId[slot]
      if int(canonChildLen[existingId]) == length:
        let childBase = int(canonChildStart[existingId])
        var matches = true
        for i in 0..<length:
          if canonChildren[childBase + i] != sortedIds[offset + i]:
            matches = false
            break
        if matches:
          return existingId
    slot = (slot + 1) and internMask

  let newId = int32(canonChildStart.len)
  let childBase = int32(canonChildren.len)
  canonChildStart.add(childBase)
  canonChildLen.add(int16(length))
  for i in 0..<length:
    canonChildren.add(sortedIds[offset + i])

  var allChildrenUniversal = true
  var distinctKinds = 0
  var repeatedKinds = 0
  var maxCount = 0
  var maxLocalIndex = 0
  var cursor = 0
  while cursor < length:
    let kindId = sortedIds[offset + cursor]
    if not canonUniversal[kindId]:
      allChildrenUniversal = false
    var runEnd = cursor + 1
    while runEnd < length and sortedIds[offset + runEnd] == kindId:
      inc runEnd
    let runLen = runEnd - cursor
    if runLen > maxCount:
      maxCount = runLen
      maxLocalIndex = distinctKinds
    inc distinctKinds
    if runLen >= 2:
      inc repeatedKinds
    cursor = runEnd

  let universal = allChildrenUniversal and (distinctKinds <= 2 or (distinctKinds == 3 and repeatedKinds <= 1))
  canonUniversal.add(universal)
  canonAllDistinct.add(repeatedKinds == 0)
  canonAllChildrenUniv.add(allChildrenUniversal)
  canonMaxSymLocal.add(int16(maxLocalIndex))
  canonMaxSymCount.add(int16(maxCount))

  canonTableStamp[slot] = internCaseStamp
  canonTableHash[slot] = digest
  canonTableId[slot] = newId
  return newId

var sortedScratch: array[maxComponents, int32]

proc internExact(childIds: openArray[int32], offset, length: int): int32 =
  let digest = hashInt32Slice(childIds, offset, length)
  var slot = int(digest and uint64(internMask))
  while exactTableStamp[slot] == internCaseStamp:
    if exactTableHash[slot] == digest:
      let existingId = exactTableId[slot]
      if int(exactChildLen[existingId]) == length:
        let childBase = int(exactChildStart[existingId])
        var matches = true
        for i in 0..<length:
          if exactChildren[childBase + i] != childIds[offset + i]:
            matches = false
            break
        if matches:
          return existingId
    slot = (slot + 1) and internMask

  let newId = int32(exactChildStart.len)
  let childBase = int32(exactChildren.len)
  exactChildStart.add(childBase)
  exactChildLen.add(int16(length))
  for i in 0..<length:
    exactChildren.add(childIds[offset + i])
    sortedScratch[i] = canonOfExact[childIds[offset + i]]
  for i in 1..<length:
    let currentKey = sortedScratch[i]
    var shiftIdx = i - 1
    while shiftIdx >= 0 and sortedScratch[shiftIdx] > currentKey:
      sortedScratch[shiftIdx + 1] = sortedScratch[shiftIdx]
      dec shiftIdx
    sortedScratch[shiftIdx + 1] = currentKey

  let canonId = internCanon(sortedScratch, 0, length)
  canonOfExact.add(canonId)
  if length == 1:
    coreOfExact.add(coreOfExact[childIds[offset]])
  else:
    coreOfExact.add(newId)

  exactTableStamp[slot] = internCaseStamp
  exactTableHash[slot] = digest
  exactTableId[slot] = newId
  return newId

var parseChildStack: array[256, int32]
var parseFrameStart: array[256, int]

proc parseWordToExactId(startPos, stopPos: int): int32 =
  var depth = 0
  var stackTop = 0
  parseFrameStart[0] = 0
  for pos in startPos..<stopPos:
    if inputData[pos] == 'a':
      inc depth
      parseFrameStart[depth] = stackTop
    else:
      let frameBase = parseFrameStart[depth]
      let childCount = stackTop - frameBase
      let nodeId = internExact(parseChildStack, frameBase, childCount)
      stackTop = frameBase
      dec depth
      parseChildStack[stackTop] = nodeId
      inc stackTop
  return internExact(parseChildStack, 0, stackTop)

var simCacheStamp: array[simCacheSize, int32]
var simCacheKey: array[simCacheSize, uint64]
var simCacheVal: array[simCacheSize, int8]
var simCacheCaseStamp: int32 = 0
var simCacheCount = 0

proc resetSimCache() =
  inc simCacheCaseStamp
  simCacheCount = 0

proc simCacheLookup(leftId, rightId: int32, found: var bool): bool {.inline.} =
  let pairKey = (uint64(leftId) shl 32) or uint64(rightId)
  var slot = int(splitMix64(pairKey) and uint64(simCacheMask))
  while simCacheStamp[slot] == simCacheCaseStamp:
    if simCacheKey[slot] == pairKey:
      found = true
      return simCacheVal[slot] == 1
    slot = (slot + 1) and simCacheMask
  found = false
  return false

proc simCacheStore(leftId, rightId: int32, similar: bool) {.inline.} =
  if simCacheCount >= (simCacheSize shr 1):
    return
  let pairKey = (uint64(leftId) shl 32) or uint64(rightId)
  var slot = int(splitMix64(pairKey) and uint64(simCacheMask))
  while simCacheStamp[slot] == simCacheCaseStamp:
    if simCacheKey[slot] == pairKey:
      simCacheVal[slot] = if similar: 1'i8 else: 0'i8
      return
    slot = (slot + 1) and simCacheMask
  simCacheStamp[slot] = simCacheCaseStamp
  simCacheKey[slot] = pairKey
  simCacheVal[slot] = if similar: 1'i8 else: 0'i8
  inc simCacheCount

proc isSeparablePermutation(perm: openArray[int], length: int): bool {.inline.} =
  var stackLow: array[maxComponents, int]
  var stackHigh: array[maxComponents, int]
  var stackTop = 0
  for i in 0..<length:
    var rangeLow = perm[i]
    var rangeHigh = rangeLow
    while stackTop > 0:
      if stackHigh[stackTop - 1] + 1 == rangeLow:
        rangeLow = stackLow[stackTop - 1]
        dec stackTop
      elif rangeHigh + 1 == stackLow[stackTop - 1]:
        rangeHigh = stackHigh[stackTop - 1]
        dec stackTop
      else:
        break
    stackLow[stackTop] = rangeLow
    stackHigh[stackTop] = rangeHigh
    inc stackTop
  return stackTop == 1

type PreparedSeq = object
  symbols: array[maxComponents, int16]
  prefixPrimary: array[maxComponents + 1, uint64]
  prefixSecondary: array[maxComponents + 1, uint64]
  easyEnd: array[maxComponents, int16]
  runRight: array[maxComponents, int16]
  runLeft: array[maxComponents, int16]
  length: int16

proc buildPreparedSeq(target: var PreparedSeq, source: openArray[int16], length: int) =
  target.length = int16(length)
  target.prefixPrimary[0] = 0'u64
  target.prefixSecondary[0] = 0'u64
  for i in 0..<length:
    let sym = source[i]
    target.symbols[i] = sym
    target.prefixPrimary[i + 1] = target.prefixPrimary[i] + weightPrimary[int(sym)]
    target.prefixSecondary[i + 1] = target.prefixSecondary[i] + weightSecondary[int(sym)]
  for i in 0..<length:
    target.runLeft[i] = if i > 0 and source[i] == source[i - 1]: target.runLeft[i - 1] + 1 else: 1
  for i in countdown(length - 1, 0):
    target.runRight[i] = if i + 1 < length and source[i] == source[i + 1]: target.runRight[i + 1] + 1 else: 1
  var counts: array[maxComponents, int16]
  for i in 0..<length:
    var distinctKinds = 0
    var repeatedKinds = 0
    var rightPos = i
    while rightPos < length:
      let sym = int(source[rightPos])
      let previousCount = counts[sym]
      counts[sym] = previousCount + 1
      if previousCount == 0: inc distinctKinds
      elif previousCount == 1: inc repeatedKinds
      if not (distinctKinds <= 2 or (distinctKinds == 3 and repeatedKinds <= 1)):
        counts[sym] = previousCount
        break
      inc rightPos
    target.easyEnd[i] = int16(rightPos)
    for k in i..<rightPos:
      counts[int(source[k])] = 0

var dpStamp: array[maxDpStates, int32]
var dpValue: array[maxDpStates, int8]
var dpCurStamp: int32 = 0
var dpRowLen, dpStride: int
var dpLeftPtr, dpRightPtr: ptr PreparedSeq
var leafSimilar: array[maxComponents, array[maxComponents, int8]]

proc dpUniversal(leftStart, rightStart, spanLen: int): bool =
  if spanLen <= 3 or leftStart + spanLen <= int(dpLeftPtr.easyEnd[leftStart]):
    return true
  let statePos = spanLen * dpStride + leftStart * dpRowLen + rightStart
  if dpStamp[statePos] == dpCurStamp:
    return dpValue[statePos] == 1

  var matched = false
  let leftFirst = dpLeftPtr.symbols[leftStart]
  let leftLast = dpLeftPtr.symbols[leftStart + spanLen - 1]
  let rightFirst = dpRightPtr.symbols[rightStart]
  let rightLast = dpRightPtr.symbols[rightStart + spanLen - 1]
  if leftFirst == rightFirst and dpUniversal(leftStart + 1, rightStart + 1, spanLen - 1):
    matched = true
  elif leftFirst == rightLast and dpUniversal(leftStart + 1, rightStart, spanLen - 1):
    matched = true
  elif leftLast == rightLast and dpUniversal(leftStart, rightStart, spanLen - 1):
    matched = true
  elif leftLast == rightFirst and dpUniversal(leftStart, rightStart + 1, spanLen - 1):
    matched = true
  else:
    let baseLeftA = dpLeftPtr.prefixPrimary[leftStart]
    let baseLeftB = dpLeftPtr.prefixSecondary[leftStart]
    let baseRightA = dpRightPtr.prefixPrimary[rightStart]
    let baseRightB = dpRightPtr.prefixSecondary[rightStart]
    let endRightA = dpRightPtr.prefixPrimary[rightStart + spanLen]
    let endRightB = dpRightPtr.prefixSecondary[rightStart + spanLen]
    let headRun = min(int(dpLeftPtr.runRight[leftStart]), spanLen)
    let tailRun = min(int(dpLeftPtr.runLeft[leftStart + spanLen - 1]), spanLen)
    var splitLow = max(2, headRun + 1)
    var splitHigh = min(spanLen - 2, spanLen - tailRun - 1)
    while splitLow <= splitHigh:
      let cutLeft = splitLow
      let deltaA = dpLeftPtr.prefixPrimary[leftStart + cutLeft] - baseLeftA
      let deltaB = dpLeftPtr.prefixSecondary[leftStart + cutLeft] - baseLeftB
      if deltaA == dpRightPtr.prefixPrimary[rightStart + cutLeft] - baseRightA and
         deltaB == dpRightPtr.prefixSecondary[rightStart + cutLeft] - baseRightB:
        if dpUniversal(leftStart, rightStart, cutLeft) and
           dpUniversal(leftStart + cutLeft, rightStart + cutLeft, spanLen - cutLeft):
          matched = true
          break
      if deltaA == endRightA - dpRightPtr.prefixPrimary[rightStart + spanLen - cutLeft] and
         deltaB == endRightB - dpRightPtr.prefixSecondary[rightStart + spanLen - cutLeft]:
        if dpUniversal(leftStart, rightStart + spanLen - cutLeft, cutLeft) and
           dpUniversal(leftStart + cutLeft, rightStart, spanLen - cutLeft):
          matched = true
          break
      if splitHigh != splitLow:
        let cutRight = splitHigh
        let deltaA2 = dpLeftPtr.prefixPrimary[leftStart + cutRight] - baseLeftA
        let deltaB2 = dpLeftPtr.prefixSecondary[leftStart + cutRight] - baseLeftB
        if deltaA2 == dpRightPtr.prefixPrimary[rightStart + cutRight] - baseRightA and
           deltaB2 == dpRightPtr.prefixSecondary[rightStart + cutRight] - baseRightB:
          if dpUniversal(leftStart, rightStart, cutRight) and
             dpUniversal(leftStart + cutRight, rightStart + cutRight, spanLen - cutRight):
            matched = true
            break
        if deltaA2 == endRightA - dpRightPtr.prefixPrimary[rightStart + spanLen - cutRight] and
           deltaB2 == endRightB - dpRightPtr.prefixSecondary[rightStart + spanLen - cutRight]:
          if dpUniversal(leftStart, rightStart + spanLen - cutRight, cutRight) and
             dpUniversal(leftStart + cutRight, rightStart, spanLen - cutRight):
            matched = true
            break
      inc splitLow
      dec splitHigh

  dpStamp[statePos] = dpCurStamp
  dpValue[statePos] = if matched: 1'i8 else: 0'i8
  return matched

proc dpGeneral(leftStart, rightStart, spanLen: int): bool =
  if spanLen == 0: return true
  if spanLen == 1: return leafSimilar[leftStart][rightStart] == 1
  let statePos = spanLen * dpStride + leftStart * dpRowLen + rightStart
  if dpStamp[statePos] == dpCurStamp:
    return dpValue[statePos] == 1

  var matched = false
  let baseLeftA = dpLeftPtr.prefixPrimary[leftStart]
  let baseLeftB = dpLeftPtr.prefixSecondary[leftStart]
  let baseRightA = dpRightPtr.prefixPrimary[rightStart]
  let baseRightB = dpRightPtr.prefixSecondary[rightStart]
  let endRightA = dpRightPtr.prefixPrimary[rightStart + spanLen]
  let endRightB = dpRightPtr.prefixSecondary[rightStart + spanLen]
  var splitLow = 1
  var splitHigh = spanLen - 1
  while splitLow <= splitHigh:
    let cutLeft = splitLow
    let deltaA = dpLeftPtr.prefixPrimary[leftStart + cutLeft] - baseLeftA
    let deltaB = dpLeftPtr.prefixSecondary[leftStart + cutLeft] - baseLeftB
    if deltaA == dpRightPtr.prefixPrimary[rightStart + cutLeft] - baseRightA and
       deltaB == dpRightPtr.prefixSecondary[rightStart + cutLeft] - baseRightB:
      if dpGeneral(leftStart, rightStart, cutLeft) and
         dpGeneral(leftStart + cutLeft, rightStart + cutLeft, spanLen - cutLeft):
        matched = true
        break
    if deltaA == endRightA - dpRightPtr.prefixPrimary[rightStart + spanLen - cutLeft] and
       deltaB == endRightB - dpRightPtr.prefixSecondary[rightStart + spanLen - cutLeft]:
      if dpGeneral(leftStart, rightStart + spanLen - cutLeft, cutLeft) and
         dpGeneral(leftStart + cutLeft, rightStart, spanLen - cutLeft):
        matched = true
        break
    if splitHigh != splitLow:
      let cutRight = splitHigh
      let deltaA2 = dpLeftPtr.prefixPrimary[leftStart + cutRight] - baseLeftA
      let deltaB2 = dpLeftPtr.prefixSecondary[leftStart + cutRight] - baseLeftB
      if deltaA2 == dpRightPtr.prefixPrimary[rightStart + cutRight] - baseRightA and
         deltaB2 == dpRightPtr.prefixSecondary[rightStart + cutRight] - baseRightB:
        if dpGeneral(leftStart, rightStart, cutRight) and
           dpGeneral(leftStart + cutRight, rightStart + cutRight, spanLen - cutRight):
          matched = true
          break
      if deltaA2 == endRightA - dpRightPtr.prefixPrimary[rightStart + spanLen - cutRight] and
         deltaB2 == endRightB - dpRightPtr.prefixSecondary[rightStart + spanLen - cutRight]:
        if dpGeneral(leftStart, rightStart + spanLen - cutRight, cutRight) and
           dpGeneral(leftStart + cutRight, rightStart, spanLen - cutRight):
          matched = true
          break
    inc splitLow
    dec splitHigh

  dpStamp[statePos] = dpCurStamp
  dpValue[statePos] = if matched: 1'i8 else: 0'i8
  return matched

proc runUniversalPair(leftSeq, rightSeq: var PreparedSeq): bool {.inline.} =
  let length = int(leftSeq.length)
  if length <= 3 or length <= int(leftSeq.easyEnd[0]):
    return true
  let endRightA = rightSeq.prefixPrimary[length]
  let endRightB = rightSeq.prefixSecondary[length]
  var hasSplit = false
  for cut in 1..<length:
    let deltaA = leftSeq.prefixPrimary[cut]
    let deltaB = leftSeq.prefixSecondary[cut]
    if (deltaA == rightSeq.prefixPrimary[cut] and deltaB == rightSeq.prefixSecondary[cut]) or
       (deltaA == endRightA - rightSeq.prefixPrimary[length - cut] and
        deltaB == endRightB - rightSeq.prefixSecondary[length - cut]):
      hasSplit = true
      break
  if not hasSplit:
    return false
  inc dpCurStamp
  dpLeftPtr = addr leftSeq
  dpRightPtr = addr rightSeq
  dpRowLen = length + 1
  dpStride = dpRowLen * dpRowLen
  return dpUniversal(0, 0, length)

proc mapCanonToLocal(targetId: int32, uniqueIds: openArray[int32], uniqueCount: int): int16 {.inline.} =
  var lowIdx = 0
  var highIdx = uniqueCount - 1
  while lowIdx <= highIdx:
    let midIdx = (lowIdx + highIdx) shr 1
    let midVal = uniqueIds[midIdx]
    if midVal == targetId: return int16(midIdx)
    elif midVal < targetId: lowIdx = midIdx + 1
    else: highIdx = midIdx - 1
  return 0'i16

var scratchLeftSeq, scratchRightSeq, scratchProjLeft, scratchProjRight: PreparedSeq

proc similarTrees(rawLeftId, rawRightId: int32): bool =
  if rawLeftId == rawRightId: return true
  let rawCanon = canonOfExact[rawLeftId]
  if rawCanon != canonOfExact[rawRightId]: return false
  if canonUniversal[rawCanon]: return true
  var leftId = coreOfExact[rawLeftId]
  var rightId = coreOfExact[rawRightId]
  if leftId == rightId: return true
  if leftId > rightId: swap(leftId, rightId)

  var found = false
  let cached = simCacheLookup(leftId, rightId, found)
  if found: return cached

  let canonId = canonOfExact[leftId]
  let childCount = int(exactChildLen[leftId])
  let leftBase = int(exactChildStart[leftId])
  let rightBase = int(exactChildStart[rightId])
  let canonBase = int(canonChildStart[canonId])

  var uniqueIds: array[maxComponents, int32]
  var uniqueFreq: array[maxComponents, int16]
  var uniqueCount = 0
  var cursor = 0
  while cursor < childCount:
    let kindId = canonChildren[canonBase + cursor]
    var runEnd = cursor + 1
    while runEnd < childCount and canonChildren[canonBase + runEnd] == kindId:
      inc runEnd
    uniqueIds[uniqueCount] = kindId
    uniqueFreq[uniqueCount] = int16(runEnd - cursor)
    inc uniqueCount
    cursor = runEnd

  if canonAllDistinct[canonId]:
    var rightPosByKind: array[maxComponents, int]
    var perm: array[maxComponents, int]
    for i in 0..<childCount:
      let localKind = int(mapCanonToLocal(canonOfExact[exactChildren[rightBase + i]], uniqueIds, uniqueCount))
      rightPosByKind[localKind] = i
    for i in 0..<childCount:
      let localKind = int(mapCanonToLocal(canonOfExact[exactChildren[leftBase + i]], uniqueIds, uniqueCount))
      perm[i] = rightPosByKind[localKind]
    var similar = isSeparablePermutation(perm, childCount)
    if similar and not canonAllChildrenUniv[canonId]:
      for i in 0..<childCount:
        let childLeft = exactChildren[leftBase + i]
        let childRight = exactChildren[rightBase + perm[i]]
        if not canonUniversal[canonOfExact[childLeft]]:
          if not similarTrees(childLeft, childRight):
            similar = false
            break
    simCacheStore(leftId, rightId, similar)
    return similar

  var allChildPairsSimilar = true
  var localLeafMatrix: array[maxComponents, array[maxComponents, int8]]
  if not canonAllChildrenUniv[canonId]:
    for i in 0..<childCount:
      let childLeft = exactChildren[leftBase + i]
      let childCanon = canonOfExact[childLeft]
      for j in 0..<childCount:
        let childRight = exactChildren[rightBase + j]
        if canonOfExact[childRight] == childCanon:
          let pairMatch = similarTrees(childLeft, childRight)
          localLeafMatrix[i][j] = if pairMatch: 1'i8 else: 0'i8
          if not pairMatch:
            allChildPairsSimilar = false
        else:
          localLeafMatrix[i][j] = 0'i8

  var localLeft, localRight: array[maxComponents, int16]
  for i in 0..<childCount:
    localLeft[i] = mapCanonToLocal(canonOfExact[exactChildren[leftBase + i]], uniqueIds, uniqueCount)
    localRight[i] = mapCanonToLocal(canonOfExact[exactChildren[rightBase + i]], uniqueIds, uniqueCount)

  var singletonCount = 0
  for i in 0..<uniqueCount:
    if uniqueFreq[i] == 1: inc singletonCount
  if singletonCount >= 4:
    var rightPos, permSingleton: array[maxComponents, int]
    var posIdx = 0
    for i in 0..<childCount:
      let sym = int(localRight[i])
      if uniqueFreq[sym] == 1:
        rightPos[sym] = posIdx
        inc posIdx
    posIdx = 0
    for i in 0..<childCount:
      let sym = int(localLeft[i])
      if uniqueFreq[sym] == 1:
        permSingleton[posIdx] = rightPos[sym]
        inc posIdx
    if not isSeparablePermutation(permSingleton, singletonCount):
      simCacheStore(leftId, rightId, false)
      return false

  var similar: bool
  if allChildPairsSimilar:
    let dominantCount = int(canonMaxSymCount[canonId])
    let dominantSym = canonMaxSymLocal[canonId]
    if dominantCount * 3 >= childCount * 2 and childCount - dominantCount >= 4:
      var projLeft, projRight: array[maxComponents, int16]
      var projLen = 0
      for i in 0..<childCount:
        if localLeft[i] != dominantSym:
          projLeft[projLen] = localLeft[i]
          inc projLen
      projLen = 0
      for i in 0..<childCount:
        if localRight[i] != dominantSym:
          projRight[projLen] = localRight[i]
          inc projLen
      buildPreparedSeq(scratchProjLeft, projLeft, projLen)
      buildPreparedSeq(scratchProjRight, projRight, projLen)
      if not runUniversalPair(scratchProjLeft, scratchProjRight):
        simCacheStore(leftId, rightId, false)
        return false
    buildPreparedSeq(scratchLeftSeq, localLeft, childCount)
    buildPreparedSeq(scratchRightSeq, localRight, childCount)
    similar = runUniversalPair(scratchLeftSeq, scratchRightSeq)
  else:
    for i in 0..<childCount:
      for j in 0..<childCount:
        leafSimilar[i][j] = localLeafMatrix[i][j]
    buildPreparedSeq(scratchLeftSeq, localLeft, childCount)
    buildPreparedSeq(scratchRightSeq, localRight, childCount)
    let endRightA = scratchRightSeq.prefixPrimary[childCount]
    let endRightB = scratchRightSeq.prefixSecondary[childCount]
    var hasSplit = false
    for cut in 1..<childCount:
      let deltaA = scratchLeftSeq.prefixPrimary[cut]
      let deltaB = scratchLeftSeq.prefixSecondary[cut]
      if (deltaA == scratchRightSeq.prefixPrimary[cut] and deltaB == scratchRightSeq.prefixSecondary[cut]) or
         (deltaA == endRightA - scratchRightSeq.prefixPrimary[childCount - cut] and
          deltaB == endRightB - scratchRightSeq.prefixSecondary[childCount - cut]):
        hasSplit = true
        break
    if not hasSplit:
      similar = false
    else:
      inc dpCurStamp
      dpLeftPtr = addr scratchLeftSeq
      dpRightPtr = addr scratchRightSeq
      dpRowLen = childCount + 1
      dpStride = dpRowLen * dpRowLen
      similar = dpGeneral(0, 0, childCount)

  simCacheStore(leftId, rightId, similar)
  return similar

type Bitset = array[maxBitsetWords, uint64]

proc isEmptyBitset(bits: Bitset, wordCount: int): bool {.inline.} =
  for i in 0..<wordCount:
    if bits[i] != 0'u64: return false
  return true

proc countBitset(bits: Bitset, wordCount: int): int {.inline.} =
  for i in 0..<wordCount:
    result += countSetBits(bits[i])

var cliqueAdj: array[maxGroupSize, Bitset]
var cliqueVertexCount, cliqueWordCount: int
var bestCliqueSize: int
var candStack: array[maxGroupSize + 2, Bitset]
var orderStack: array[maxGroupSize + 2, array[maxGroupSize, int16]]
var colorStack: array[maxGroupSize + 2, array[maxGroupSize, int16]]
var colorBuckets: array[maxGroupSize + 2, Bitset]

proc colorAndRenumber(depth: int, candidates: Bitset, emittedCount: var int) =
  let minNeededColor = bestCliqueSize - depth + 1
  var remaining = candidates
  var colorIndex = 0
  emittedCount = 0
  let colorLimit = minNeededColor - 1
  while colorIndex < colorLimit and not isEmptyBitset(remaining, cliqueWordCount):
    inc colorIndex
    for wordIdx in 0..<cliqueWordCount: colorBuckets[colorIndex][wordIdx] = 0'u64
    var available = remaining
    for wordIdx in 0..<cliqueWordCount:
      while available[wordIdx] != 0'u64:
        let bitPos = countTrailingZeroBits(available[wordIdx])
        let bitMask = 1'u64 shl uint(bitPos)
        let vertex = (wordIdx shl 6) + bitPos
        colorBuckets[colorIndex][wordIdx] = colorBuckets[colorIndex][wordIdx] or bitMask
        remaining[wordIdx] = remaining[wordIdx] and not bitMask
        available[wordIdx] = available[wordIdx] and not bitMask
        for scanIdx in wordIdx..<cliqueWordCount:
          available[scanIdx] = available[scanIdx] and not cliqueAdj[vertex][scanIdx]
  if isEmptyBitset(remaining, cliqueWordCount):
    return
  if colorLimit >= 2:
    for wordIdx in 0..<cliqueWordCount:
      var wordBits = remaining[wordIdx]
      while wordBits != 0'u64:
        let bitPos = countTrailingZeroBits(wordBits)
        wordBits = wordBits and (wordBits - 1'u64)
        let vertex = (wordIdx shl 6) + bitPos
        var recolored = false
        for firstColor in 1..<colorLimit:
          var conflictVertex = -1
          var conflictCount = 0
          for scanIdx in 0..<cliqueWordCount:
            let overlap = colorBuckets[firstColor][scanIdx] and cliqueAdj[vertex][scanIdx]
            if overlap != 0'u64:
              conflictCount += countSetBits(overlap)
              if conflictCount > 1: break
              conflictVertex = (scanIdx shl 6) + countTrailingZeroBits(overlap)
          if conflictCount == 1:
            for secondColor in (firstColor + 1)..colorLimit:
              var blocked = false
              for scanIdx in 0..<cliqueWordCount:
                if (colorBuckets[secondColor][scanIdx] and cliqueAdj[conflictVertex][scanIdx]) != 0'u64:
                  blocked = true
                  break
              if not blocked:
                let conflictMask = 1'u64 shl uint(conflictVertex and 63)
                colorBuckets[firstColor][conflictVertex shr 6] = colorBuckets[firstColor][conflictVertex shr 6] and not conflictMask
                colorBuckets[secondColor][conflictVertex shr 6] = colorBuckets[secondColor][conflictVertex shr 6] or conflictMask
                let vertexMask = 1'u64 shl uint(bitPos)
                colorBuckets[firstColor][wordIdx] = colorBuckets[firstColor][wordIdx] or vertexMask
                remaining[wordIdx] = remaining[wordIdx] and not vertexMask
                recolored = true
                break
          if recolored: break
  if isEmptyBitset(remaining, cliqueWordCount):
    return
  while not isEmptyBitset(remaining, cliqueWordCount):
    inc colorIndex
    var available = remaining
    for wordIdx in 0..<cliqueWordCount:
      while available[wordIdx] != 0'u64:
        let bitPos = countTrailingZeroBits(available[wordIdx])
        let bitMask = 1'u64 shl uint(bitPos)
        let vertex = (wordIdx shl 6) + bitPos
        orderStack[depth][emittedCount] = int16(vertex)
        colorStack[depth][emittedCount] = int16(colorIndex)
        inc emittedCount
        remaining[wordIdx] = remaining[wordIdx] and not bitMask
        available[wordIdx] = available[wordIdx] and not bitMask
        for scanIdx in wordIdx..<cliqueWordCount:
          available[scanIdx] = available[scanIdx] and not cliqueAdj[vertex][scanIdx]

proc expandClique(depth: int) =
  var branchCount = 0
  colorAndRenumber(depth, candStack[depth], branchCount)
  if branchCount == 0: return
  var currentPool = candStack[depth]
  for i in countdown(branchCount - 1, 0):
    if depth + int(colorStack[depth][i]) <= bestCliqueSize:
      return
    let vertex = int(orderStack[depth][i])
    var hasNext = false
    for wordIdx in 0..<cliqueWordCount:
      let nextWord = currentPool[wordIdx] and cliqueAdj[vertex][wordIdx]
      candStack[depth + 1][wordIdx] = nextWord
      if nextWord != 0'u64: hasNext = true
    if hasNext:
      expandClique(depth + 1)
    elif depth + 1 > bestCliqueSize:
      bestCliqueSize = depth + 1
    currentPool[vertex shr 6] = currentPool[vertex shr 6] and not (1'u64 shl uint(vertex and 63))

proc solveMaxClique(vertices: seq[int], rawNonAdj: seq[Bitset]): int =
  let vertexCount = vertices.len
  let wordCount = (vertexCount + 63) div 64
  var localAdj = newSeq[Bitset](vertexCount)
  var degree = newSeq[int](vertexCount)
  for i in 0..<vertexCount:
    let origLeft = vertices[i]
    for j in (i + 1)..<vertexCount:
      let origRight = vertices[j]
      if (rawNonAdj[origLeft][origRight shr 6] and (1'u64 shl uint(origRight and 63))) != 0'u64:
        localAdj[i][j shr 6] = localAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
        localAdj[j][i shr 6] = localAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
        inc degree[i]
        inc degree[j]

  var alive: Bitset
  for i in 0..<vertexCount: alive[i shr 6] = alive[i shr 6] or (1'u64 shl uint(i and 63))
  var vertexOrder = newSeq[int](vertexCount)
  for orderPos in countdown(vertexCount - 1, 0):
    var minVertex = -1
    var minDegree = 1_000_000_000
    for vertex in 0..<vertexCount:
      if (alive[vertex shr 6] and (1'u64 shl uint(vertex and 63))) != 0'u64:
        if degree[vertex] < minDegree:
          minDegree = degree[vertex]
          minVertex = vertex
    vertexOrder[orderPos] = minVertex
    alive[minVertex shr 6] = alive[minVertex shr 6] and not (1'u64 shl uint(minVertex and 63))
    for wordIdx in 0..<wordCount:
      var neighborBits = localAdj[minVertex][wordIdx] and alive[wordIdx]
      while neighborBits != 0'u64:
        let bitPos = countTrailingZeroBits(neighborBits)
        neighborBits = neighborBits and (neighborBits - 1'u64)
        dec degree[(wordIdx shl 6) + bitPos]

  cliqueVertexCount = vertexCount
  cliqueWordCount = wordCount
  for i in 0..<vertexCount:
    for wordIdx in 0..<wordCount: cliqueAdj[i][wordIdx] = 0'u64
  for i in 0..<vertexCount:
    let mappedLeft = vertexOrder[i]
    for j in 0..<vertexCount:
      let mappedRight = vertexOrder[j]
      if (localAdj[mappedLeft][mappedRight shr 6] and (1'u64 shl uint(mappedRight and 63))) != 0'u64:
        cliqueAdj[i][j shr 6] = cliqueAdj[i][j shr 6] or (1'u64 shl uint(j and 63))

  var initialPool: Bitset
  for i in 0..<vertexCount: initialPool[i shr 6] = initialPool[i shr 6] or (1'u64 shl uint(i and 63))

  bestCliqueSize = 1
  var rngState = hashIncrement
  let startCount = min(vertexCount, 24)
  for trial in 0..<startCount:
    var greedyPool = initialPool
    let seedVertex =
      if trial < min(vertexCount, 6): trial
      else:
        rngState = splitMix64(rngState)
        int(rngState mod uint64(vertexCount))
    var greedySize = 1
    for wordIdx in 0..<wordCount: greedyPool[wordIdx] = greedyPool[wordIdx] and cliqueAdj[seedVertex][wordIdx]
    while not isEmptyBitset(greedyPool, wordCount):
      var bestVertex = -1
      var bestDegree = -1
      for wordIdx in 0..<wordCount:
        var wordBits = greedyPool[wordIdx]
        while wordBits != 0'u64:
          let bitPos = countTrailingZeroBits(wordBits)
          wordBits = wordBits and (wordBits - 1'u64)
          let vertex = (wordIdx shl 6) + bitPos
          var subDegree = 0
          for scanIdx in 0..<wordCount: subDegree += countSetBits(greedyPool[scanIdx] and cliqueAdj[vertex][scanIdx])
          if subDegree > bestDegree:
            bestDegree = subDegree
            bestVertex = vertex
      inc greedySize
      for wordIdx in 0..<wordCount: greedyPool[wordIdx] = greedyPool[wordIdx] and cliqueAdj[bestVertex][wordIdx]
    if greedySize > bestCliqueSize: bestCliqueSize = greedySize

  candStack[0] = initialPool
  expandClique(0)
  return bestCliqueSize

var simAdj: seq[Bitset]
var nonAdj: seq[Bitset]
var groupWordCount: int

proc cliqueCoverUpperBound(activeMask: Bitset): int =
  var remaining = activeMask
  var coverCount = 0
  while not isEmptyBitset(remaining, groupWordCount):
    inc coverCount
    var available = remaining
    for wordIdx in 0..<groupWordCount:
      while available[wordIdx] != 0'u64:
        let bitPos = countTrailingZeroBits(available[wordIdx])
        let bitMask = 1'u64 shl uint(bitPos)
        let vertex = (wordIdx shl 6) + bitPos
        remaining[wordIdx] = remaining[wordIdx] and not bitMask
        available[wordIdx] = available[wordIdx] and not bitMask
        for scanIdx in wordIdx..<groupWordCount:
          available[scanIdx] = available[scanIdx] and simAdj[vertex][scanIdx]
  return coverCount

proc solveIndependentSet(initialMask: Bitset, lowerBound: int = 0): int =
  var activeMask = initialMask
  var pickedCount = 0

  while not isEmptyBitset(activeMask, groupWordCount):
    var reduced = false
    let remainingCount = countBitset(activeMask, groupWordCount)
    if remainingCount <= 1:
      return pickedCount + remainingCount
    if pickedCount + remainingCount <= lowerBound:
      return pickedCount

    for wordIdx in 0..<groupWordCount:
      var wordBits = activeMask[wordIdx]
      while wordBits != 0'u64:
        let bitPos = countTrailingZeroBits(wordBits)
        let bitMask = 1'u64 shl uint(bitPos)
        wordBits = wordBits and (wordBits - 1'u64)
        if (activeMask[wordIdx] and bitMask) == 0'u64: continue
        let vertex = (wordIdx shl 6) + bitPos
        var deg = 0
        for scanIdx in 0..<groupWordCount: deg += countSetBits(simAdj[vertex][scanIdx] and activeMask[scanIdx])
        if deg == 0:
          inc pickedCount
          activeMask[wordIdx] = activeMask[wordIdx] and not bitMask
          reduced = true
        elif deg == 1:
          inc pickedCount
          activeMask[wordIdx] = activeMask[wordIdx] and not bitMask
          for scanIdx in 0..<groupWordCount: activeMask[scanIdx] = activeMask[scanIdx] and not simAdj[vertex][scanIdx]
          reduced = true
        elif deg == remainingCount - 1:
          activeMask[wordIdx] = activeMask[wordIdx] and not bitMask
          reduced = true
          break
        elif deg <= 8:
          var neighbors: Bitset
          for scanIdx in 0..<groupWordCount: neighbors[scanIdx] = simAdj[vertex][scanIdx] and activeMask[scanIdx]
          var simplicial = true
          for scanIdx in 0..<groupWordCount:
            var nbBits = neighbors[scanIdx]
            while nbBits != 0'u64:
              let nbBitPos = countTrailingZeroBits(nbBits)
              nbBits = nbBits and (nbBits - 1'u64)
              let neighbor = (scanIdx shl 6) + nbBitPos
              for checkIdx in 0..<groupWordCount:
                if (neighbors[checkIdx] and nonAdj[neighbor][checkIdx]) != 0'u64:
                  simplicial = false
                  break
              if not simplicial: break
            if not simplicial: break
          if simplicial:
            inc pickedCount
            activeMask[wordIdx] = activeMask[wordIdx] and not bitMask
            for scanIdx in 0..<groupWordCount: activeMask[scanIdx] = activeMask[scanIdx] and not neighbors[scanIdx]
            reduced = true
    if reduced: continue

    let currentCount = countBitset(activeMask, groupWordCount)
    if currentCount <= 256:
      var activeVerts: array[256, int]
      var nonDegree: array[256, int]
      var activeLen = 0
      for wordIdx in 0..<groupWordCount:
        var wordBits = activeMask[wordIdx]
        while wordBits != 0'u64:
          let bitPos = countTrailingZeroBits(wordBits)
          wordBits = wordBits and (wordBits - 1'u64)
          let vertex = (wordIdx shl 6) + bitPos
          activeVerts[activeLen] = vertex
          var degNon = 0
          for scanIdx in 0..<groupWordCount: degNon += countSetBits(nonAdj[vertex][scanIdx] and activeMask[scanIdx])
          nonDegree[activeLen] = degNon
          inc activeLen
      for i in 0..<activeLen:
        let vertex = activeVerts[i]
        if (activeMask[vertex shr 6] and (1'u64 shl uint(vertex and 63))) == 0'u64: continue
        let degV = nonDegree[i]
        var dominated = false
        for j in 0..<activeLen:
          if i == j: continue
          let other = activeVerts[j]
          if (activeMask[other shr 6] and (1'u64 shl uint(other and 63))) == 0'u64: continue
          if nonDegree[j] < degV: continue
          if (simAdj[vertex][other shr 6] and (1'u64 shl uint(other and 63))) == 0'u64: continue
          var subset = true
          for scanIdx in 0..<groupWordCount:
            if ((nonAdj[vertex][scanIdx] and activeMask[scanIdx]) and not nonAdj[other][scanIdx]) != 0'u64:
              subset = false
              break
          if subset:
            dominated = true
            break
        if dominated:
          activeMask[vertex shr 6] = activeMask[vertex shr 6] and not (1'u64 shl uint(vertex and 63))
          reduced = true
          break
      if reduced: continue
    break

  if isEmptyBitset(activeMask, groupWordCount):
    return pickedCount

  block splitComponents:
    var remaining = activeMask
    var components: seq[Bitset] = @[]
    while not isEmptyBitset(remaining, groupWordCount):
      var compMask: Bitset
      var frontier: Bitset
      for wordIdx in 0..<groupWordCount:
        if remaining[wordIdx] != 0'u64:
          let firstBit = remaining[wordIdx] and (not remaining[wordIdx] + 1'u64)
          frontier[wordIdx] = firstBit
          remaining[wordIdx] = remaining[wordIdx] and not firstBit
          break
      while not isEmptyBitset(frontier, groupWordCount):
        for wordIdx in 0..<groupWordCount:
          while frontier[wordIdx] != 0'u64:
            let bitPos = countTrailingZeroBits(frontier[wordIdx])
            let bitMask = 1'u64 shl uint(bitPos)
            frontier[wordIdx] = frontier[wordIdx] and not bitMask
            compMask[wordIdx] = compMask[wordIdx] or bitMask
            let vertex = (wordIdx shl 6) + bitPos
            for scanIdx in 0..<groupWordCount:
              let nextBits = simAdj[vertex][scanIdx] and remaining[scanIdx]
              if nextBits != 0'u64:
                frontier[scanIdx] = frontier[scanIdx] or nextBits
                remaining[scanIdx] = remaining[scanIdx] and not nextBits
      components.add(compMask)
    if components.len > 1:
      var total = pickedCount
      for compMask in components:
        total += solveIndependentSet(compMask, 0)
      return total

  block splitCoComponents:
    var remaining = activeMask
    var coComponents: seq[Bitset] = @[]
    while not isEmptyBitset(remaining, groupWordCount):
      var compMask: Bitset
      var frontier: Bitset
      for wordIdx in 0..<groupWordCount:
        if remaining[wordIdx] != 0'u64:
          let firstBit = remaining[wordIdx] and (not remaining[wordIdx] + 1'u64)
          frontier[wordIdx] = firstBit
          remaining[wordIdx] = remaining[wordIdx] and not firstBit
          break
      while not isEmptyBitset(frontier, groupWordCount):
        for wordIdx in 0..<groupWordCount:
          while frontier[wordIdx] != 0'u64:
            let bitPos = countTrailingZeroBits(frontier[wordIdx])
            let bitMask = 1'u64 shl uint(bitPos)
            frontier[wordIdx] = frontier[wordIdx] and not bitMask
            compMask[wordIdx] = compMask[wordIdx] or bitMask
            let vertex = (wordIdx shl 6) + bitPos
            for scanIdx in 0..<groupWordCount:
              let nextBits = nonAdj[vertex][scanIdx] and remaining[scanIdx]
              if nextBits != 0'u64:
                frontier[scanIdx] = frontier[scanIdx] or nextBits
                remaining[scanIdx] = remaining[scanIdx] and not nextBits
      coComponents.add(compMask)
    if coComponents.len > 1:
      var bestPart = max(0, lowerBound - pickedCount)
      for compMask in coComponents:
        let partResult = solveIndependentSet(compMask, bestPart)
        if partResult > bestPart: bestPart = partResult
      return pickedCount + bestPart

  var vertices: seq[int] = @[]
  var maxDeg = -1
  var pivotVertex = -1
  var degreeSum = 0
  for wordIdx in 0..<groupWordCount:
    var wordBits = activeMask[wordIdx]
    while wordBits != 0'u64:
      let bitPos = countTrailingZeroBits(wordBits)
      wordBits = wordBits and (wordBits - 1'u64)
      let vertex = (wordIdx shl 6) + bitPos
      vertices.add(vertex)
      var deg = 0
      for scanIdx in 0..<groupWordCount: deg += countSetBits(simAdj[vertex][scanIdx] and activeMask[scanIdx])
      degreeSum += deg
      if deg > maxDeg:
        maxDeg = deg
        pivotVertex = vertex

  let vertexCount = vertices.len
  if vertexCount <= 2:
    return pickedCount + 1
  if maxDeg == 2:
    return pickedCount + (vertexCount div 2)
  if lowerBound > pickedCount and pickedCount + cliqueCoverUpperBound(activeMask) <= lowerBound:
    return pickedCount

  let edgeCount = degreeSum div 2
  let pairCount = vertexCount * (vertexCount - 1) div 2
  if degreeSum <= vertexCount * 8 or (vertexCount <= 80 and edgeCount * 6 < pairCount):
    var includedMask = activeMask
    includedMask[pivotVertex shr 6] = includedMask[pivotVertex shr 6] and not (1'u64 shl uint(pivotVertex and 63))
    for scanIdx in 0..<groupWordCount: includedMask[scanIdx] = includedMask[scanIdx] and not simAdj[pivotVertex][scanIdx]
    let withPivot = 1 + solveIndependentSet(includedMask, max(0, lowerBound - pickedCount - 1))
    let currentBest = max(lowerBound - pickedCount, withPivot)
    var excludedMask = activeMask
    excludedMask[pivotVertex shr 6] = excludedMask[pivotVertex shr 6] and not (1'u64 shl uint(pivotVertex and 63))
    let withoutPivot = solveIndependentSet(excludedMask, currentBest)
    return pickedCount + max(withPivot, withoutPivot)
  else:
    return pickedCount + solveMaxClique(vertices, nonAdj)

proc solveGroup(uniqueExacts: seq[int32]): int =
  let memberCount = uniqueExacts.len
  if memberCount <= 1: return memberCount

  var coreIds = newSeq[int32](memberCount)
  for i in 0..<memberCount:
    coreIds[i] = coreOfExact[uniqueExacts[i]]

  let canonId = canonOfExact[coreIds[0]]
  if canonUniversal[canonId]:
    return 1

  let childCount = int(exactChildLen[coreIds[0]])
  let canonBase = int(canonChildStart[canonId])

  var uniqueIds: array[maxComponents, int32]
  var uniqueFreq: array[maxComponents, int16]
  var uniqueCount = 0
  var cursor = 0
  while cursor < childCount:
    let kindId = canonChildren[canonBase + cursor]
    var runEnd = cursor + 1
    while runEnd < childCount and canonChildren[canonBase + runEnd] == kindId:
      inc runEnd
    uniqueIds[uniqueCount] = kindId
    uniqueFreq[uniqueCount] = int16(runEnd - cursor)
    inc uniqueCount
    cursor = runEnd

  groupWordCount = (memberCount + 63) div 64
  simAdj = newSeq[Bitset](memberCount)
  nonAdj = newSeq[Bitset](memberCount)
  var hasNonSimilar = false

  if canonAllDistinct[canonId]:
    var localSeqs = newSeq[array[maxComponents, int16]](memberCount)
    var posTables = newSeq[array[maxComponents, int16]](memberCount)
    for i in 0..<memberCount:
      let childBase = int(exactChildStart[coreIds[i]])
      for k in 0..<childCount:
        let localKind = mapCanonToLocal(canonOfExact[exactChildren[childBase + k]], uniqueIds, uniqueCount)
        localSeqs[i][k] = localKind
        posTables[i][int(localKind)] = int16(k)
    let allChildrenUniversal = canonAllChildrenUniv[canonId]
    var perm: array[maxComponents, int]
    for i in 0..<memberCount:
      let leftBase = int(exactChildStart[coreIds[i]])
      for j in (i + 1)..<memberCount:
        for k in 0..<childCount:
          perm[k] = int(posTables[j][int(localSeqs[i][k])])
        var similar = isSeparablePermutation(perm, childCount)
        if similar and not allChildrenUniversal:
          let rightBase = int(exactChildStart[coreIds[j]])
          for k in 0..<childCount:
            let childLeft = exactChildren[leftBase + k]
            let childRight = exactChildren[rightBase + perm[k]]
            if not canonUniversal[canonOfExact[childLeft]]:
              if not similarTrees(childLeft, childRight):
                similar = false
                break
        if similar:
          simAdj[i][j shr 6] = simAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
          simAdj[j][i shr 6] = simAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
        else:
          nonAdj[i][j shr 6] = nonAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
          nonAdj[j][i shr 6] = nonAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
          hasNonSimilar = true
  elif canonAllChildrenUniv[canonId]:
    var prepared = newSeq[PreparedSeq](memberCount)
    var localBuffer: array[maxComponents, int16]

    var singletonCount = 0
    for i in 0..<uniqueCount:
      if uniqueFreq[i] == 1: inc singletonCount
    let useSingletonFilter = singletonCount >= 4
    var singletonSeqs: seq[array[maxComponents, int16]] = @[]
    var singletonPos: seq[array[maxComponents, int16]] = @[]
    if useSingletonFilter:
      singletonSeqs = newSeq[array[maxComponents, int16]](memberCount)
      singletonPos = newSeq[array[maxComponents, int16]](memberCount)

    let dominantCount = int(canonMaxSymCount[canonId])
    let dominantSym = canonMaxSymLocal[canonId]
    let useProjection = (dominantCount * 3 >= childCount * 2) and (childCount - dominantCount >= 4)
    var projected: seq[PreparedSeq] = @[]
    if useProjection:
      projected = newSeq[PreparedSeq](memberCount)

    for i in 0..<memberCount:
      let childBase = int(exactChildStart[coreIds[i]])
      for k in 0..<childCount:
        localBuffer[k] = mapCanonToLocal(canonOfExact[exactChildren[childBase + k]], uniqueIds, uniqueCount)
      buildPreparedSeq(prepared[i], localBuffer, childCount)
      if useSingletonFilter:
        var posIdx = 0
        for k in 0..<childCount:
          let sym = int(localBuffer[k])
          if uniqueFreq[sym] == 1:
            singletonSeqs[i][posIdx] = int16(sym)
            singletonPos[i][sym] = int16(posIdx)
            inc posIdx
      if useProjection:
        var projBuffer: array[maxComponents, int16]
        var projLen = 0
        for k in 0..<childCount:
          if localBuffer[k] != dominantSym:
            projBuffer[projLen] = localBuffer[k]
            inc projLen
        buildPreparedSeq(projected[i], projBuffer, projLen)

    var permSingleton: array[maxComponents, int]
    for i in 0..<memberCount:
      for j in (i + 1)..<memberCount:
        var similar = true
        if useSingletonFilter:
          for k in 0..<singletonCount:
            permSingleton[k] = int(singletonPos[j][int(singletonSeqs[i][k])])
          if not isSeparablePermutation(permSingleton, singletonCount):
            similar = false
        if similar and useProjection:
          if not runUniversalPair(projected[i], projected[j]):
            similar = false
        if similar:
          similar = runUniversalPair(prepared[i], prepared[j])
        if similar:
          simAdj[i][j shr 6] = simAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
          simAdj[j][i shr 6] = simAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
        else:
          nonAdj[i][j shr 6] = nonAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
          nonAdj[j][i shr 6] = nonAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
          hasNonSimilar = true
  else:
    for i in 0..<memberCount:
      let leftId = coreIds[i]
      for j in (i + 1)..<memberCount:
        if similarTrees(leftId, coreIds[j]):
          simAdj[i][j shr 6] = simAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
          simAdj[j][i shr 6] = simAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
        else:
          nonAdj[i][j shr 6] = nonAdj[i][j shr 6] or (1'u64 shl uint(j and 63))
          nonAdj[j][i shr 6] = nonAdj[j][i shr 6] or (1'u64 shl uint(i and 63))
          hasNonSimilar = true

  if not hasNonSimilar:
    return 1
  var fullMask: Bitset
  for i in 0..<memberCount:
    fullMask[i shr 6] = fullMask[i shr 6] or (1'u64 shl uint(i and 63))
  return solveIndependentSet(fullMask, 0)

initWeights()
readInputStream()

let caseCount = nextInt()
for _ in 0..<caseCount:
  let wordCount = nextInt()
  resetCaseTrees()
  resetSimCache()
  var groups = initTable[int32, seq[int32]]()
  var seenExact = initTable[int32, bool]()
  for _ in 0..<wordCount:
    var startPos, stopPos: int
    nextWordSpan(startPos, stopPos)
    let exactId = parseWordToExactId(startPos, stopPos)
    if not seenExact.hasKey(exactId):
      seenExact[exactId] = true
      let canonId = canonOfExact[exactId]
      if groups.hasKey(canonId):
        groups[canonId].add(exactId)
      else:
        groups[canonId] = @[exactId]

  var diversity = 0
  for canonId, members in groups:
    if members.len <= 1 or canonUniversal[canonId]:
      inc diversity
    else:
      diversity += solveGroup(members)
  appendInt(diversity)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)
