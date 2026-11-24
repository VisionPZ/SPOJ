import algorithm, tables, bitops

{.passC: "-O3 -march=native -fno-stack-protector".}
{.passL: "-s".}
{.push checks: off, assertions: off, stacktrace: off, lineDir: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashBasis: uint64 = 1469598103934665603'u64
const mixA: uint64 = 0xbf58476d1ce4e5b9'u64
const mixB: uint64 = 0x94d049bb133111eb'u64

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

proc nextWord(data: string, position: var int): string =
  while position < data.len and (data[position] != 'a' and data[position] != 'b'):
    position += 1
  result = ""
  while position < data.len and (data[position] == 'a' or data[position] == 'b'):
    result.add data[position]
    position += 1

proc forestKey(children: var seq[uint64]): uint64 =
  if children.len == 0:
    return 0
  var total: uint64 = 0
  for key in children:
    var part = key + hashBasis
    part = (part xor (part shr 30)) * mixA
    part = (part xor (part shr 27)) * mixB
    total += part xor (part shr 31)
  return total

proc wordKey(word: string): uint64 =
  let numberLength = word.len
  var matching = newSeq[int](numberLength)
  var openings: seq[int] = @[]
  for position in 0..<numberLength:
    if word[position] == 'a':
      openings.add position
    else:
      let opening = openings[openings.len - 1]
      openings.setLen(openings.len - 1)
      matching[opening] = position
  proc keyOf(start, stop: int): uint64 =
    var children: seq[uint64] = @[]
    var pos = start
    while pos < stop:
      let closing = matching[pos]
      children.add keyOf(pos + 1, closing)
      pos = closing + 1
    return forestKey(children)
  return keyOf(0, numberLength)

proc canonicalIds(word: string): seq[uint64] =
  let numberLength = word.len
  let rowLength = numberLength + 1
  result = newSeq[uint64]((numberLength div 2 + 1) * rowLength)
  for position in 0..<result.len:
    result[position] = 0xffffffffffffffff'u64
  for start in 0..numberLength:
    result[start] = 0
  var matching = newSeq[int](numberLength)
  var openings: seq[int] = @[]
  for position in 0..<numberLength:
    if word[position] == 'a':
      openings.add position
    else:
      let opening = openings[openings.len - 1]
      openings.setLen(openings.len - 1)
      matching[opening] = position
  for start in countdown(numberLength - 1, 0):
    if word[start] != 'a':
      continue
    var children: seq[uint64] = @[]
    var pos = start
    while pos < numberLength and word[pos] == 'a':
      let closing = matching[pos]
      let innerHalf = (closing - pos - 1) div 2
      let innerId = result[innerHalf * rowLength + pos + 1]
      if innerId == 0xffffffffffffffff'u64:
        break
      children.add innerId
      pos = closing + 1
      let half = (pos - start) div 2
      result[half * rowLength + start] = forestKey(children)

# ---------- exact DP fallback ----------
var simStamp: seq[int32] = @[]
var simValue: seq[int8] = @[]
var stampCounter: int32 = 0

proc equalPart(x, y: string, cx, cy: seq[uint64], rowLength, stride: int, a, b, half: int): bool =
  let leftId = cx[half * rowLength + a]
  if leftId == 0xffffffffffffffff'u64 or leftId != cy[half * rowLength + b]:
    return false
  let position = half * stride + a * rowLength + b
  if simStamp[position] == stampCounter:
    return simValue[position] == 1
  var answer = false
  if half == 0:
    answer = true
  elif x[a] == 'a' and y[b] == 'a' and x[a + 2 * half - 1] == 'b' and y[b + 2 * half - 1] == 'b' and equalPart(x, y, cx, cy, rowLength, stride, a + 1, b + 1, half - 1):
    answer = true
  else:
    for k in 1..<half:
      if equalPart(x, y, cx, cy, rowLength, stride, a, b, k) and equalPart(x, y, cx, cy, rowLength, stride, a + 2 * k, b + 2 * k, half - k):
        answer = true
        break
      if equalPart(x, y, cx, cy, rowLength, stride, a, b + 2 * (half - k), k) and equalPart(x, y, cx, cy, rowLength, stride, a + 2 * k, b, half - k):
        answer = true
        break
  simStamp[position] = stampCounter
  simValue[position] = (if answer: 1 else: 0)
  return answer

proc similarWords(x, y: string, cx, cy: seq[uint64]): bool =
  let numberLength = x.len
  let rowLength = numberLength + 1
  let stride = rowLength * rowLength
  let needed = stride * (numberLength div 2 + 1)
  if simStamp.len < needed:
    simStamp = newSeq[int32](needed)
    simValue = newSeq[int8](needed)
  stampCounter += 1
  result = equalPart(x, y, cx, cy, rowLength, stride, 0, 0, numberLength div 2)

# ---------- fast separable-matching check ----------
# A sequence of primitive components can be matched by repeated direct and
# crossed splits. Each leaf compares two primitive components; equality of
# their exact strings or a recursive match of their interiors proves
# similarity, so a positive answer is always sound.
var componentIds = initTable[string, int]()
var nextComponentId = 0
proc internComponent(s: string): int =
  if componentIds.hasKey(s):
    return componentIds[s]
  let id = nextComponentId
  nextComponentId += 1
  componentIds[s] = id
  return id

var typeKeyIds = initTable[uint64, int]()
var nextTypeId = 0
proc internTypeKey(key: uint64): int =
  if typeKeyIds.hasKey(key):
    return typeKeyIds[key]
  let id = nextTypeId
  nextTypeId += 1
  typeKeyIds[key] = id
  return id

proc splitMix(value: uint64): uint64 =
  var z = value + 0x9e3779b97f4a7c15'u64
  z = (z xor (z shr 30)) * 0xbf58476d1ce4e5b9'u64
  z = (z xor (z shr 27)) * 0x94d049bb133111eb'u64
  return z xor (z shr 31)

var weightA: seq[uint64] = @[]
proc ensureWeights(count: int) =
  while weightA.len < count:
    weightA.add splitMix(uint64(weightA.len) * 2'u64 + 1'u64)

type CompRec = object
  exactId: int
  typeId: int
  startPos: int
  length: int
  wordLocal: int
  innerSeq: int

type SeqRec = object
  comps: seq[int]
  prefix1: seq[uint64]

var classWords: seq[string] = @[]
var classCanonical: seq[seq[uint64]] = @[]
var canonicalReady: seq[bool] = @[]

proc ensureCanonical(local: int) =
  if not canonicalReady[local]:
    classCanonical[local] = canonicalIds(classWords[local])
    canonicalReady[local] = true
var wordMatching: seq[seq[int]] = @[]
var compAt: seq[seq[int]] = @[]
var compRecords: seq[CompRec] = @[]
var compSeqs: seq[SeqRec] = @[]

proc getRecord(wordLocal, start: int): int =
  let existing = compAt[wordLocal][start]
  if existing >= 0:
    return existing
  let closing = wordMatching[wordLocal][start]
  let length = closing - start + 1
  let text = classWords[wordLocal][start .. closing]
  let key = wordKey(text)
  let typ = internTypeKey(key)
  let exact = internComponent(text)
  compRecords.add CompRec(exactId: exact, typeId: typ, startPos: start,
                          length: length, wordLocal: wordLocal, innerSeq: -1)
  let index = compRecords.len - 1
  compAt[wordLocal][start] = index
  return index

proc buildSeqForRange(wordLocal, lo, hi: int): int =
  var ids: seq[int] = @[]
  var p1: seq[uint64] = @[0'u64]
  var pos = lo
  while pos < hi:
    if classWords[wordLocal][pos] == 'a':
      let closing = wordMatching[wordLocal][pos]
      if closing >= hi:
        break
      let record = getRecord(wordLocal, pos)
      ids.add record
      let typ = compRecords[record].typeId
      ensureWeights(nextTypeId + 1)
      p1.add p1[p1.len - 1] + weightA[typ]
      pos = closing + 1
    else:
      pos += 1
  compSeqs.add SeqRec(comps: ids, prefix1: p1)
  return compSeqs.len - 1

const memoBits = 20
const memoSize = 1 shl memoBits
var memoStamp = newSeq[int32](memoSize)
var memoKey1 = newSeq[uint64](memoSize)
var memoValue = newSeq[int8](memoSize)
var memoCounter: int32 = 0
var fastStates = 0
var typeStatus: seq[int8] = @[]
var fastExact = false
var fastIncomplete = false


proc fastSeq(sidX, sidY: int): bool

proc checkTypeUniversal(typ: int) =
  var representatives = initTable[int, int]()
  for index in 0..<compRecords.len:
    let record = compRecords[index]
    if record.typeId == typ and not representatives.hasKey(record.exactId):
      representatives[record.exactId] = index
  if representatives.len > 48:
    typeStatus[typ] = 2
    return
  var keys: seq[int] = @[]
  for key in representatives.keys:
    keys.add key
  for i in 0..<keys.len:
    for j in (i + 1)..<keys.len:
      let ra = compRecords[representatives[keys[i]]]
      let rb = compRecords[representatives[keys[j]]]
      let xa = classWords[ra.wordLocal][ra.startPos .. ra.startPos + ra.length - 1]
      let xb = classWords[rb.wordLocal][rb.startPos .. rb.startPos + rb.length - 1]
      ensureCanonical(ra.wordLocal)
      ensureCanonical(rb.wordLocal)
      if not similarWords(xa, xb, classCanonical[ra.wordLocal], classCanonical[rb.wordLocal]):
        typeStatus[typ] = 2
        return
  typeStatus[typ] = 1

proc fastPrim(recX, recY: int): bool =
  let a = compRecords[recX]
  let b = compRecords[recY]
  if a.exactId == b.exactId:
    return true
  if a.typeId != b.typeId or a.length != b.length:
    return false
  if typeStatus[a.typeId] == 0:
    checkTypeUniversal(a.typeId)
  if typeStatus[a.typeId] == 1:
    return true
  if a.innerSeq < 0:
    compRecords[recX].innerSeq = buildSeqForRange(a.wordLocal, a.startPos + 1, a.startPos + a.length - 1)
  if b.innerSeq < 0:
    compRecords[recY].innerSeq = buildSeqForRange(b.wordLocal, b.startPos + 1, b.startPos + b.length - 1)
  return fastSeq(compRecords[recX].innerSeq, compRecords[recY].innerSeq)

proc recSeq(sidX, sidY, xLo, yLo, len: int): bool =
  if len == 0:
    return true
  if len == 1:
    return fastPrim(compSeqs[sidX].comps[xLo], compSeqs[sidY].comps[yLo])
  let key = uint64(sidX) or (uint64(sidY) shl 17) or (uint64(xLo) shl 34) or
            (uint64(yLo) shl 42) or (uint64(len) shl 50)
  let baseSlot = int(splitMix(key) and uint64(memoSize - 1))
  var slot = -1
  for probe in 0..3:
    let position = (baseSlot + probe) and (memoSize - 1)
    if memoStamp[position] == memoCounter:
      if memoKey1[position] == key:
        return memoValue[position] == 1
    else:
      slot = position
      break
  if slot < 0:
    fastIncomplete = true
    return false
  fastStates += 1
  if fastStates > 300000:
    fastIncomplete = true
    return false
  var answer = false
  let px1 = compSeqs[sidX].prefix1
  let py1 = compSeqs[sidY].prefix1
  let xHi = xLo + len
  let yHi = yLo + len
  for m in 1..<len:
    if px1[xLo + m] - px1[xLo] == py1[yLo + m] - py1[yLo]:
      if recSeq(sidX, sidY, xLo, yLo, m) and recSeq(sidX, sidY, xLo + m, yLo + m, len - m):
        answer = true
        break
    if px1[xLo + m] - px1[xLo] == py1[yHi] - py1[yHi - m]:
      if recSeq(sidX, sidY, xLo, yHi - m, m) and recSeq(sidX, sidY, xLo + m, yLo, len - m):
        answer = true
        break
  memoStamp[slot] = memoCounter
  memoKey1[slot] = key
  memoValue[slot] = (if answer: 1 else: 0)
  return answer

proc fastSeq(sidX, sidY: int): bool =
  if compSeqs[sidX].comps.len != compSeqs[sidY].comps.len:
    return false
  return recSeq(sidX, sidY, 0, 0, compSeqs[sidX].comps.len)

# ---------- maximum independent set ----------
proc countBits(value: uint64): int =
  result = 0
  var rest = value
  while rest != 0:
    result += int(rest and 1'u64)
    rest = rest shr 1

proc maximumIndependentSet(nonAdj: seq[seq[uint64]], count: int): int =
  # Maximum independent set in the similarity graph is maximum clique in
  # the graph whose edges join non-similar pairs.
  let blocks = (count + 63) div 64
  var best = 0
  var nodeCount = 0
  var order: seq[int] = newSeq[int](count)
  var colors: seq[int] = newSeq[int](count)
  var orderedCount = 0

  proc anyLeft(bits: seq[uint64]): bool =
    for segment in 0..<blocks:
      if bits[segment] != 0:
        return true
    return false

  proc colorSort(candidates: seq[uint64]): int =
    var remaining = candidates
    var available = newSeq[uint64](blocks)
    orderedCount = 0
    var color = 0
    while true:
      var empty = true
      for segment in 0..<blocks:
        if remaining[segment] != 0:
          empty = false
          break
      if empty:
        break
      color += 1
      for segment in 0..<blocks:
        available[segment] = remaining[segment]
      for segment in 0..<blocks:
        var bits = available[segment]
        while bits != 0:
          let bitIndex = countTrailingZeroBits(bits)
          let mask = 1'u64 shl uint(bitIndex)
          bits = bits and (bits - 1'u64)
          if (available[segment] and mask) == 0:
            continue
          let vertex = segment * 64 + bitIndex
          if vertex < count:
            order[orderedCount] = vertex
            colors[orderedCount] = color
            orderedCount += 1
            remaining[segment] = remaining[segment] and not mask
            for other in 0..<blocks:
              available[other] = available[other] and not nonAdj[vertex][other]

  proc expand(depth: int, candidates: var seq[uint64]) =
    nodeCount += 1
    if nodeCount > 500000:
      return
    let colorCount = colorSort(candidates)
    if depth + orderedCount < best:
      return
    for i in countdown(orderedCount - 1, 0):
      if depth + colors[i] <= best:
        return
      let vertex = order[i]
      var next: seq[uint64] = newSeq[uint64](blocks)
      for segment in 0..<blocks:
        next[segment] = candidates[segment] and nonAdj[vertex][segment]
      if anyLeft(next):
        expand(depth + 1, next)
      elif depth + 1 > best:
        best = depth + 1
      candidates[vertex div 64] = candidates[vertex div 64] and not (1'u64 shl uint(vertex mod 64))

  var initial = newSeq[uint64](blocks)
  for vertex in 0..<count:
    initial[vertex div 64] = initial[vertex div 64] or (1'u64 shl uint(vertex mod 64))
  var greedyLeft = initial
  while anyLeft(greedyLeft):
    var pick = -1
    var pickDegree = -1
    for vertex in 0..<count:
      if (greedyLeft[vertex div 64] and (1'u64 shl uint(vertex mod 64))) == 0:
        continue
      var degree = 0
      for segment in 0..<blocks:
        degree += countBits(nonAdj[vertex][segment] and greedyLeft[segment])
      if degree > pickDegree:
        pickDegree = degree
        pick = vertex
    best += 1
    for segment in 0..<blocks:
      greedyLeft[segment] = greedyLeft[segment] and nonAdj[pick][segment]
    greedyLeft[pick div 64] = greedyLeft[pick div 64] and not (1'u64 shl uint(pick mod 64))
  expand(0, initial)
  return best

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let wordCount = nextInt(inputData, scanPos)
  var words: seq[string] = @[]
  var keys: seq[uint64] = @[]
  for wordIndex in 0..<wordCount:
    let word = nextWord(inputData, scanPos)
    words.add word
    keys.add wordKey(word)
  var groups = initTable[uint64, seq[int]]()
  for wordIndex in 0..<wordCount:
    if hasKey(groups, keys[wordIndex]):
      groups[keys[wordIndex]].add wordIndex
    else:
      groups[keys[wordIndex]] = @[wordIndex]
  var answer = 0
  for key in groups.keys:
    let members = groups[key]
    answer += 1
    if members.len > 1:
      let memberCount = members.len
      classWords = @[]
      for member in members:
        classWords.add words[member]
      classCanonical = newSeq[seq[uint64]](memberCount)
      canonicalReady = newSeq[bool](memberCount)
      wordMatching = @[]
      compAt = @[]
      compRecords.setLen 0
      compSeqs.setLen 0
      var topSeqs: seq[int] = @[]
      for local in 0..<memberCount:
        let w = classWords[local]
        var matching = newSeq[int](w.len)
        var openings: seq[int] = @[]
        for i in 0..<w.len:
          if w[i] == 'a':
            openings.add i
          else:
            let opening = openings[openings.len - 1]
            openings.setLen(openings.len - 1)
            matching[opening] = i
        wordMatching.add matching
        var at = newSeq[int](w.len + 1)
        for position in 0..<at.len:
          at[position] = -1
        compAt.add at
      for local in 0..<memberCount:
        topSeqs.add buildSeqForRange(local, 0, classWords[local].len)
      var recordIndex = 0
      while recordIndex < compRecords.len:
        if compRecords[recordIndex].innerSeq < 0:
          let record = compRecords[recordIndex]
          compRecords[recordIndex].innerSeq = buildSeqForRange(record.wordLocal, record.startPos + 1, record.startPos + record.length - 1)
        recordIndex += 1
      typeStatus = newSeq[int8](nextTypeId)
      fastExact = true
      for record in compRecords:
        if typeStatus[record.typeId] == 0:
          checkTypeUniversal(record.typeId)
        if typeStatus[record.typeId] == 2:
          fastExact = false
      var typePresent = initTable[int, bool]()
      for record in compRecords:
        typePresent[record.typeId] = true
      let distinctTypeCount = typePresent.len
      var distinctSet = initTable[int, bool]()
      for s in topSeqs:
        for r in compSeqs[s].comps:
          distinctSet[compRecords[r].exactId] = true
      let distinctCount = distinctSet.len
      var distinctIds: seq[int] = @[]
      for id in distinctSet.keys:
        distinctIds.add id
      let wordBlocks = (memberCount + 63) div 64
      var adjacency = newSeq[seq[uint64]](memberCount)
      for index in 0..<memberCount:
        adjacency[index] = newSeq[uint64](wordBlocks)
      for left in 0..<memberCount:
        for right in (left + 1)..<memberCount:
          if not (fastExact and distinctTypeCount <= 2):
            adjacency[left][right div 64] = adjacency[left][right div 64] or (1'u64 shl uint(right mod 64))
            adjacency[right][left div 64] = adjacency[right][left div 64] or (1'u64 shl uint(left mod 64))
      if fastExact and distinctTypeCount <= 2:
        answer = answer - 1 + 1
        continue
      for left in 0..<memberCount:
        for right in (left + 1)..<memberCount:
          var similar = false
          if classWords[left] == classWords[right]:
            similar = true
          elif distinctCount <= 2:
            let id0 = distinctIds[0]
            var cl0 = 0
            var cr0 = 0
            for r in compSeqs[topSeqs[left]].comps:
              if compRecords[r].exactId == id0:
                cl0 += 1
            for r in compSeqs[topSeqs[right]].comps:
              if compRecords[r].exactId == id0:
                cr0 += 1
            if cl0 == cr0:
              similar = true
          if not similar:
            memoCounter += 1
            fastStates = 0
            fastIncomplete = false
            similar = fastSeq(topSeqs[left], topSeqs[right])
            if not similar and (not fastExact or fastIncomplete):
              ensureCanonical(left)
              ensureCanonical(right)
              similar = similarWords(classWords[left], classWords[right], classCanonical[left], classCanonical[right])
          if similar:
            adjacency[left][right div 64] = adjacency[left][right div 64] and not (1'u64 shl uint(right mod 64))
            adjacency[right][left div 64] = adjacency[right][left div 64] and not (1'u64 shl uint(left mod 64))
      answer = answer - 1 + maximumIndependentSet(adjacency, memberCount)
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
