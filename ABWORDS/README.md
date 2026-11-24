## Problem

Each test case gives a set S of nice ab-words. A nice word has equal counts of a and b, and every prefix has at least as many a as b. Two words are similar under an inductive rule set. Print the largest size of a subset of S with no similar pair.

| Quantity | Bound |
| --- | --- |
| Test cases | given on the first line |
| Words per case | 1 to 1000 |
| Word length | 1 to 200 |
| Time limit | 2640 ms |
| Memory limit | 1536 MB |

The word count and length set the cost of the pairwise checks.

## Idea

Similarity is an inductive relation, not an equivalence relation. The program computes it with a recurrence over word parts, then finds the largest subset with no similar pair.

A hash of each word's nesting tree gives a necessary condition. Words with different hashes are never similar, so they need no comparison. The program groups words by that hash and checks pairs only inside a group.

A recurrence over matching substrings decides each pair exactly. Inside a group, a bitset search finds the largest subset with no similar pair. The results of all groups are added.

Cost per pair: O(L^3) substring states, each with O(L) split choices, where L is the word length.

## Why It Works

A nice word splits into top-level components. Each component has the form a + inner + b. Similar words have the same length and the same nesting tree when child order is ignored. That tree hash is therefore a safe grouping key.

The recurrence mirrors the three definition rules. Let `equalPart` mean the parts starting at a and b with 2 * half letters are similar.

- A zero half gives the empty parts, which are similar.
- Wrap: both parts start with a, end with b, and their inner parts are similar.
- Straight split: the prefix parts match and the suffix parts match.
- Crossed split: the prefix of one part matches the suffix of the other.

The sample has three words. The first and third share the same tree `((), ((), ((),)))`, so they are similar. The second has tree `((), (), (), ((),))`, so it is not. The answer is 2.

A second example shows why grouping alone fails. Take four distinct words A, B, C, D of length 6. The words CADB, ACBD and ABCD share one tree. The first two are similar, and the last two are similar, but the first and last are not. The answer for that set is 2, while the number of tree hashes is 1.

## Code

The input is read once into one buffer. The scanner walks that buffer by index and builds integers from digit values.

```nim
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
```

The scanner stops at the first letter that is not a or b, so no word is scanned twice. Each word is at most 200 letters long.

The tree hash mixes child keys with a commutative sum. Order inside a component is ignored; order inside the whole word is still kept by the similarity check.

```nim
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
```

The empty tree gets key 0. The mixer spreads each child key over 64 bits before adding it. A collision would only merge two groups, which would add extra comparisons, not wrong answers.

The substring table holds a key for each balanced part of one word. The loop runs from right to left so inner keys exist before their parents.

```nim
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
```

The matching array gives the closing letter of each opening letter in one pass. A part is balanced only when its tree key exists; the largest unsigned value rejects the other parts. The table costs O(L^2) entries and is built once per word.

The similarity check tests substrings of equal length. A substring key mismatch ends the branch at once. Stamps avoid clearing the table between pairs.

```nim
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
```

The split loop uses k from 1 to half - 1, so both parts stay non-empty. The crossed test uses half - k as the offset into the other word. Each state is stored once; the stamp makes every pair start with a fresh table.

The group loop builds the similarity graph and calls the subset search. The search starts from a greedy set and branches on one word at a time.

```nim
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
```

A singleton group contributes one word. A larger group contributes the size of its largest subset with no similar pair. Each output line is appended to one buffer that flushes in 256 KiB blocks.

The subset search uses bitsets over the words of a group. A greedy pass gives a first lower bound. The branch step removes a word and its neighbors from the candidate set.

```nim
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
```

The pivot is the candidate with the most neighbors. Branching on it keeps the search small on dense graphs. The node budget bounds the work on hard graphs.

## Complexity

Building one tree hash takes O(L) time. Building the substring key table takes O(L^2 log L) time and O(L^2) space.

One pair check visits O(L^3) substring states and tests O(L) split positions per state. The graph search uses O(m^2 / 64) bitset words for a group of m words. The full program takes O(n L^2 log L + p L^4 + sum of group searches) time, where p is the number of compared pairs. A naive check retries every split without shared states and pays that cost on every pair.
