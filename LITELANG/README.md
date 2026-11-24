## Problem

Read t test cases. Each case gives n, the number of words, k, the alphabet size, and k letter weights. A word's weight is the sum of its letter weights. Print the smallest total weight of a prefix-free set of n words, where no word is a prefix of another. Blank lines separate cases in the input.

The judge limits are these:

| Quantity | Bound |
| --- | --- |
| Words n | 2 to 10000 |
| Letters k | 2 to 26 |
| Letter weight | 1 to 10000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The word count sets the scale because the program handles up to 10000 words per case.

## Idea

Keep the n lightest words in a growing word tree, where each child appends one letter. Expand the lightest word into its k children, then drop the heaviest word so the frontier holds n words again. The frontier stays prefix-free, so its sum is a valid language weight. Each expansion costs O(k log n).

## Why It Works

A prefix-free set is a group of tree nodes where no node lies above another. Expanding a word replaces it with its children, so no new prefix relation appears. Removing a word also keeps that property.

Expanding the lightest word first is safe. At any depth, a heavier word lies no closer to the root, so its children are no cheaper. An optimal frontier can therefore use the lightest expansion first.

The frontier sum is a candidate answer. Later expansions add heavier children, so the sum eventually rises. The sum that cannot improve is the answer.

The sum update follows from one removal and k insertions:

leafTotal = leafTotal - lightest + k*lightest + weightTotal.

The term - lightest removes the expanded word. The term k*lightest adds the shared part of the children. The term weightTotal adds one letter weight per child.

The sample gives this trace, produced by the generator's expansion oracle:

| Frontier from lightest to heaviest | Sum | Action |
| --- | --- | --- |
| 2, 5 | 7 | two single letters |
| 4, 5, 7 | 16 | three words, best becomes 16 |
| 5, 6, 7 | 18 | sum rises, stop |

The answer is 16, the lightest frontier that holds three words.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
```

The read loop runs once per input line and stops at end of stream. The scanner skips blank lines and spaces, so the separator between cases needs no special case. Parsing costs one pass over the input buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush check runs once per answer line, not per number. A 256 KiB block keeps writes infrequent. The final write after the main loop flushes the remainder.

```nim
var nodeValue: seq[int64]
var nodeAlive: seq[bool]
var minHeap: seq[int]
var maxHeap: seq[int]

proc pushMin(heap: var seq[int], id: int) =
  heap.add id
  var i = heap.len - 1
  while i > 0:
    let p = (i - 1) div 2
    if nodeValue[heap[p]] <= nodeValue[heap[i]]:
      break
    let swapId = heap[p]
    heap[p] = heap[i]
    heap[i] = swapId
    i = p

proc pushMax(heap: var seq[int], id: int) =
  heap.add id
  var i = heap.len - 1
  while i > 0:
    let p = (i - 1) div 2
    if nodeValue[heap[p]] >= nodeValue[heap[i]]:
      break
    let swapId = heap[p]
    heap[p] = heap[i]
    heap[i] = swapId
    i = p
```

Two heaps share one node array through integer ids. Each insertion climbs from a leaf to the root and costs O(log n). Equal values may order differently in the two heaps, which is harmless because only the value matters.

```nim
proc popMin(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var i = 0
  while true:
    let leftIndex = 2 * i + 1
    let rightIndex = leftIndex + 1
    var smallest = i
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] < nodeValue[heap[smallest]]:
      smallest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] < nodeValue[heap[smallest]]:
      smallest = rightIndex
    if smallest == i:
      break
    let swapId = heap[i]
    heap[i] = heap[smallest]
    heap[smallest] = swapId
    i = smallest

proc popMax(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var i = 0
  while true:
    let leftIndex = 2 * i + 1
    let rightIndex = leftIndex + 1
    var largest = i
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] > nodeValue[heap[largest]]:
      largest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] > nodeValue[heap[largest]]:
      largest = rightIndex
    if largest == i:
      break
    let swapId = heap[i]
    heap[i] = heap[largest]
    heap[largest] = swapId
    i = largest

proc addLeaf(value: int64) =
  let id = nodeValue.len
  nodeValue.add value
  nodeAlive.add true
  pushMin(minHeap, id)
  pushMax(maxHeap, id)

proc removeLightest(): int64 =
  while not nodeAlive[minHeap[0]]:
    discard popMin(minHeap)
  let id = popMin(minHeap)
  nodeAlive[id] = false
  return nodeValue[id]

proc removeHeaviest(): int64 =
  while not nodeAlive[maxHeap[0]]:
    discard popMax(maxHeap)
  let id = popMax(maxHeap)
  nodeAlive[id] = false
  return nodeValue[id]
```

Each pop pushes the last heap entry down, also O(log n). A dead id is skipped lazily when it reaches a heap root. The two removal helpers mark nodes dead and return their values.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let wordTarget = nextInt(inputData, scanPos)
  let letterCount = nextInt(inputData, scanPos)
  var letterWeights: seq[int64]
  letterWeights.setLen(letterCount)
  var weightTotal: int64 = 0
  for i in 0..<letterCount:
    letterWeights[i] = int64(nextInt(inputData, scanPos))
    weightTotal += letterWeights[i]
  for i in 1..<letterCount:
    let key = letterWeights[i]
    var j = i - 1
    while j >= 0 and letterWeights[j] > key:
      letterWeights[j + 1] = letterWeights[j]
      j -= 1
    letterWeights[j + 1] = key

  nodeValue.setLen(0)
  nodeAlive.setLen(0)
  minHeap.setLen(0)
  maxHeap.setLen(0)
  var leafTotal: int64 = 0
  let initialCount = min(wordTarget, letterCount)
  for i in 0..<initialCount:
    addLeaf(letterWeights[i])
    leafTotal += letterWeights[i]
  var leafCount = initialCount

  var bestTotal: int64 = high(int64)
  while leafTotal < bestTotal:
    if leafCount == wordTarget:
      bestTotal = leafTotal
    let lightest = removeLightest()
    leafTotal -= lightest
    leafCount -= 1
    for i in 0..<letterCount:
      let childWeight = lightest + letterWeights[i]
      addLeaf(childWeight)
      leafTotal += childWeight
      leafCount += 1
    while leafCount > wordTarget:
      leafTotal -= removeHeaviest()
      leafCount -= 1

  appendOutput($(bestTotal))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sorting loop runs k-1 times because k never exceeds 26. The expansion loop stops when the frontier sum stops falling. The trim loop keeps exactly wordTarget live leaves, so every candidate answer is prefix-free.

## Complexity

Reading input touches I bytes once, where I is the input size. Sorting the weights costs O(k^2). Let E be the number of expansions before the sum stops falling. Each expansion uses k insertions and two removals, so it costs O(k log n). Time is O(I + t(k^2 + E k log n)). Space is O(n + E k) for the heap nodes, plus I for the input buffer.

A search that lists every word to the needed depth has no fixed bound, because word weights grow without a stop rule. The heap keeps only the useful frontier.
