# SBW — Super Borboletas World (SPOJ)

<https://www.spoj.com/problems/SBW/>

## Problem

The game keeps many indexed lists. Operations append a value, clear a range of lists, or ask for the largest XOR of consecutive values across a range of lists. Each query prints one integer.

Input holds several test cases. A case starts with Q, followed by Q operations. Operation `2 x y` appends y to list x. Operation `1 x y` clears lists x through y. Operation `0 x y` queries lists x through y. A line holding a single zero ends the input. Both x and y stay below 10^14.

| item | bound |
|---|---|
| operations per case Q | 1 to 100000 |
| list index and value | 0 to 100000000000000 |
| multiple test cases | until a single zero |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
14
2 2 1
2 2 2
2 2 1
2 2 1
2 2 2
2 3 1
2 3 2
2 3 7
0 1 2
0 2 3
1 3 3
0 1 3
1 1 3
0 1 3
0
```

Sample output:

```
3
7
3
0
```

## Idea

Two prefixes of a list mark the ends of a consecutive block. Their XOR is that block's XOR. Think of two landmarks naming a stretch of road. The maximum subarray XOR is therefore the largest XOR of any two prefixes.

A binary trie of prefix XOR values answers that largest-pair question in one root-to-leaf walk. Offline compression turns arbitrary list indices into array slots, and a segment tree over those slots answers a range of lists in logarithmic time. Appends touch one leaf, and clears reset a slice of leaves.

## Why It Works

1. A consecutive block from index i to j has XOR equal to prefix[j] XOR prefix[i].
2. A binary trie walks bits from high to low and prefers the opposite bit at each step.
3. Inserting a new prefix gives its best partner among all earlier prefixes in one walk.
4. The segment tree stores the best value of each list at its leaf and the maximum at each internal node.
5. A range query returns the maximum over exactly the lists whose indices lie inside the range.

| term | meaning |
|---|---|
| `insertKeys` | sorted distinct list indices used by append operations |
| `listRoot` | trie root for one list, zero when the list is empty |
| `listBest` | largest subarray XOR of one list |
| `segmentMax` | maximum list value stored at each tree node |

Take the sample. List 2 holds 1, 2, 1, 1, 2. Its best consecutive XOR is 3. List 3 holds 1, 2, 7 and its best is 7. The first query returns 3, and the second returns 7. Clearing list 3 leaves only list 2, so the next query returns 3.

The trie stores 47 bits, which covers values below 10^14. Each appended value creates at most 47 nodes. A cleared list keeps its old nodes but starts a fresh trie when it is filled again.

## Code

**Input and compression.** The reader collects all operations first, then sorts the distinct appended list indices.

```nim
const flushBlockBytes = 1 shl 17
const highestValueBit = 46

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var opKind = newSeq[int]()
var opFirst = newSeq[int64]()
var opSecond = newSeq[int64]()
var caseStarts = newSeq[int]()
var insertKeys = newSeq[int64]()

while true:
  let operationCount = nextInt(inputData, scanPos)
  if operationCount == 0:
    break
  caseStarts.add opKind.len
  for operationIndex in 0 .. operationCount - 1:
    let kind = nextInt(inputData, scanPos)
    let firstValue = int64(nextInt(inputData, scanPos))
    let secondValue = int64(nextInt(inputData, scanPos))
    opKind.add kind
    opFirst.add firstValue
    opSecond.add secondValue
    if kind == 2:
      insertKeys.add firstValue
```

The case boundaries are recorded while reading. Only appended indices enter the compressed key list.

**Index lookup.** Sorting and deduplication make binary search possible.

```nim
var keyCount = insertKeys.len
if keyCount > 1:
  for outerIndex in 1 .. keyCount - 1:
    let carried = insertKeys[outerIndex]
    var innerIndex = outerIndex - 1
    while innerIndex >= 0 and insertKeys[innerIndex] > carried:
      insertKeys[innerIndex + 1] = insertKeys[innerIndex]
      innerIndex -= 1
    insertKeys[innerIndex + 1] = carried
var uniqueCount = 0
for keyIndex in 0 .. keyCount - 1:
  if keyIndex == 0 or insertKeys[keyIndex] != insertKeys[keyIndex - 1]:
    insertKeys[uniqueCount] = insertKeys[keyIndex]
    uniqueCount += 1
keyCount = uniqueCount

proc findExact(key: int64): int =
  var low = 0
  var high = keyCount - 1
  while low <= high:
    let middle = (low + high) div 2
    if insertKeys[middle] == key:
      return middle
    if insertKeys[middle] < key:
      low = middle + 1
    else:
      high = middle - 1
  return -1

proc lowerBound(key: int64): int =
  var low = 0
  var high = keyCount
  while low < high:
    let middle = (low + high) div 2
    if insertKeys[middle] < key:
      low = middle + 1
    else:
      high = middle
  return low

proc upperBound(key: int64): int =
  var low = 0
  var high = keyCount
  while low < high:
    let middle = (low + high) div 2
    if insertKeys[middle] <= key:
      low = middle + 1
    else:
      high = middle
  return low
```

An exact lookup serves appends. The two bounds describe a closed range for clear and query.

**Prefix trie.** Each list owns one trie of its prefix XOR values.

```nim
var trieZero = newSeq[int](1)
var trieOne = newSeq[int](1)

proc newNode(): int =
  trieZero.add 0
  trieOne.add 0
  return trieZero.len - 1

proc trieInsert(rootIndex: var int, value: int64) =
  if rootIndex == 0:
    rootIndex = newNode()
  var node = rootIndex
  for bit in countdown(highestValueBit, 0):
    let oneBit = int((value shr bit) and 1'i64)
    if oneBit == 0:
      if trieZero[node] == 0:
        let freshNode = newNode()
        trieZero[node] = freshNode
      node = trieZero[node]
    else:
      if trieOne[node] == 0:
        let freshNode = newNode()
        trieOne[node] = freshNode
      node = trieOne[node]

proc trieMaxXor(rootIndex: int, value: int64): int64 =
  if rootIndex == 0:
    return 0
  var node = rootIndex
  var best: int64 = 0
  for bit in countdown(highestValueBit, 0):
    if node == 0:
      break
    let oneBit = int((value shr bit) and 1'i64)
    let wanted = 1 - oneBit
    if wanted == 0 and trieZero[node] != 0:
      best = best or (1'i64 shl bit)
      node = trieZero[node]
    elif wanted == 1 and trieOne[node] != 0:
      best = best or (1'i64 shl bit)
      node = trieOne[node]
    elif oneBit == 0:
      node = trieZero[node]
    else:
      node = trieOne[node]
  return best
```

A fresh node index is stored in a local before the write. That avoids writing through a stale reference after the sequence grows.

**Segment tree.** Internal nodes hold the maximum list value in their range.

```nim
var segmentMax = newSeq[int64](1)
var segmentSize = 1

proc segmentInit(count: int) =
  segmentSize = 1
  while segmentSize < count:
    segmentSize = segmentSize * 2
  segmentMax = newSeq[int64](segmentSize * 2)

proc segmentSet(index: int, value: int64) =
  var position = segmentSize + index
  segmentMax[position] = value
  position = position div 2
  while position >= 1:
    var largest = segmentMax[position * 2]
    if segmentMax[position * 2 + 1] > largest:
      largest = segmentMax[position * 2 + 1]
    segmentMax[position] = largest
    position = position div 2

proc segmentQuery(leftIndex, rightIndex: int): int64 =
  var left = segmentSize + leftIndex
  var right = segmentSize + rightIndex
  var best: int64 = 0
  while left < right:
    if (left and 1) != 0:
      if segmentMax[left] > best:
        best = segmentMax[left]
      left += 1
    if (right and 1) != 0:
      right -= 1
      if segmentMax[right] > best:
        best = segmentMax[right]
    left = left div 2
    right = right div 2
  return best
```

The tree is rebuilt per case with all leaves set to zero. A half-open index range covers each query.

**Driver.** Each operation updates one leaf or reads one range.

```nim
var listActive = newSeq[bool](keyCount)
var listRoot = newSeq[int](keyCount)
var listPrefix = newSeq[int64](keyCount)
var listBest = newSeq[int64](keyCount)

for caseIndex in 0 .. caseStarts.len - 1:
  let caseBegin = caseStarts[caseIndex]
  var caseFinish = opKind.len
  if caseIndex + 1 < caseStarts.len:
    caseFinish = caseStarts[caseIndex + 1]
  for listIndex in 0 .. keyCount - 1:
    listActive[listIndex] = false
    listRoot[listIndex] = 0
    listPrefix[listIndex] = 0
    listBest[listIndex] = 0
  trieZero.setLen(1)
  trieOne.setLen(1)
  segmentInit(keyCount)
  for operationIndex in caseBegin .. caseFinish - 1:
    let kind = opKind[operationIndex]
    let firstValue = opFirst[operationIndex]
    let secondValue = opSecond[operationIndex]
    if kind == 2:
      let listIndex = findExact(firstValue)
      if not listActive[listIndex]:
        listActive[listIndex] = true
        listRoot[listIndex] = 0
        listPrefix[listIndex] = 0
        listBest[listIndex] = 0
        trieInsert(listRoot[listIndex], 0)
      let newPrefix = listPrefix[listIndex] xor secondValue
      let candidate = trieMaxXor(listRoot[listIndex], newPrefix)
      if candidate > listBest[listIndex]:
        listBest[listIndex] = candidate
      trieInsert(listRoot[listIndex], newPrefix)
      listPrefix[listIndex] = newPrefix
      segmentSet(listIndex, listBest[listIndex])
    elif kind == 1:
      let leftIndex = lowerBound(firstValue)
      let rightIndex = upperBound(secondValue)
      for listIndex in leftIndex .. rightIndex - 1:
        if listActive[listIndex]:
          listActive[listIndex] = false
          listRoot[listIndex] = 0
          listPrefix[listIndex] = 0
          listBest[listIndex] = 0
          segmentSet(listIndex, 0)
    else:
      let leftIndex = lowerBound(firstValue)
      let rightIndex = upperBound(secondValue)
      let answer = segmentQuery(leftIndex, rightIndex)
      appendOutput($answer)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

An append keeps the running prefix and the best pair. A clear resets the affected leaves. A query writes one buffered line.

## Complexity

Compression is one sort over appended indices. Each operation touches one trie path or one segment tree path, except a clear that visits the lists it removes.

| phase | time | space |
|---|---|---|
| input read | one pass over operations | arrays of Q operations |
| compression | one insertion sort over K keys | K compressed indices |
| append | 47 trie steps and one leaf update | trie nodes per list |
| clear | one leaf update per removed list | unchanged trie pool |
| query | one segment tree walk | none beyond arrays |

| measure | Big O |
|---|---|
| time | O(Q log K + 47Q) plus cleared leaves |
| space | O(Q + 47Q) in the worst case |

Scanning every list on each query would cost O(QK). The segment tree replaces that scan with one logarithmic walk.
