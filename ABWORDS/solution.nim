import algorithm, tables, bitops

{.passC: "-O3".}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashPrime: uint64 = 1099511628211'u64
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

proc countBits(value: uint64): int =
  result = 0
  var rest = value
  while rest != 0:
    result += int(rest and 1'u64)
    rest = rest shr 1

proc maximumIndependentSet(adjacency: seq[seq[uint64]], count: int): int =
  let wordBlocks = (count + 63) div 64
  var best = 0
  var nodeCount = 0
  proc search(candidates: seq[uint64], chosen: int) =
    nodeCount += 1
    if nodeCount > 20000000:
      return
    var remaining = 0
    for segment in 0..<wordBlocks:
      remaining += countBits(candidates[segment])
    if chosen + remaining <= best:
      return
    if remaining == 0:
      best = chosen
      return
    var pivot = -1
    var pivotDegree = -1
    for vertex in 0..<count:
      if (candidates[vertex div 64] and (1'u64 shl uint(vertex mod 64))) == 0:
        continue
      var degree = 0
      for segment in 0..<wordBlocks:
        degree += countBits(adjacency[vertex][segment] and candidates[segment])
      if degree > pivotDegree:
        pivotDegree = degree
        pivot = vertex
    var excluded = candidates
    excluded[pivot div 64] = excluded[pivot div 64] and not (1'u64 shl uint(pivot mod 64))
    search(excluded, chosen)
    var included = excluded
    for segment in 0..<wordBlocks:
      included[segment] = included[segment] and not adjacency[pivot][segment]
    search(included, chosen + 1)
  var initial = newSeq[uint64](wordBlocks)
  for vertex in 0..<count:
    initial[vertex div 64] = initial[vertex div 64] or (1'u64 shl uint(vertex mod 64))
  var greedyLeft = initial
  var greedyCount = 0
  while true:
    var anyLeft = false
    for segment in 0..<wordBlocks:
      if greedyLeft[segment] != 0:
        anyLeft = true
        break
    if not anyLeft:
      break
    var chosenVertex = -1
    var chosenDegree = count + 1
    for vertex in 0..<count:
      if (greedyLeft[vertex div 64] and (1'u64 shl uint(vertex mod 64))) == 0:
        continue
      var degree = 0
      for segment in 0..<wordBlocks:
        var word = adjacency[vertex][segment] and greedyLeft[segment]
        while word != 0:
          degree += int(word and 1'u64)
          word = word shr 1
      if degree < chosenDegree:
        chosenDegree = degree
        chosenVertex = vertex
    greedyCount += 1
    greedyLeft[chosenVertex div 64] = greedyLeft[chosenVertex div 64] and not (1'u64 shl uint(chosenVertex mod 64))
    for segment in 0..<wordBlocks:
      greedyLeft[segment] = greedyLeft[segment] and not adjacency[chosenVertex][segment]
  best = greedyCount
  search(initial, 0)
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
      var canonicalTable: seq[seq[uint64]] = @[]
      for member in members:
        canonicalTable.add canonicalIds(words[member])
      let wordBlocks = (memberCount + 63) div 64
      var adjacency = newSeq[seq[uint64]](memberCount)
      for index in 0..<memberCount:
        adjacency[index] = newSeq[uint64](wordBlocks)
      for left in 0..<memberCount:
        for right in (left + 1)..<memberCount:
          if similarWords(words[members[left]], words[members[right]], canonicalTable[left], canonicalTable[right]):
            adjacency[left][right div 64] = adjacency[left][right div 64] or (1'u64 shl uint(right mod 64))
            adjacency[right][left div 64] = adjacency[right][left div 64] or (1'u64 shl uint(left mod 64))
      answer = answer - 1 + maximumIndependentSet(adjacency, memberCount)
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
