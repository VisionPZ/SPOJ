# LITELANG — The lightest language (SPOJ)

<https://www.spoj.com/problems/LITELANG/>

## Problem

Words cost the sum of their letter prices, and no word starts another word. Choose `n` words with the smallest total price.

Read `t` cases. Each case gives `n`, `k`, and then `k` letter weights. Print the minimal total weight of an `n`-word prefix-free language.

Blank lines between cases carry no meaning.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Words `n` | 2 to 10000 |
| Letters `k` | 2 to 26 |
| Letter weight | 1 to 10000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The word count sets the scale, so the frontier must stay small.

The sample case:

```
1
3 2
2 5
```

```
16
```

## Idea

Keep the `n` cheapest words in a growing tree, like a gardener pruning branches. Cut the cheapest branch into children, then trim the most expensive twig.

A frontier of `n` words stays prefix-free after each step. The program expands the lightest word into its `k` children, then removes the heaviest word so `n` words remain. A min-heap (smallest first) finds the lightest word.

A max-heap (largest first) finds the heaviest. Dead heap entries leave lazily, marked by a live flag.

Each expansion costs O(k log n). Listing every word to the needed depth has no fixed bound, because word weights keep growing. The heap frontier keeps only the useful words.

## Why It Works

Five facts prove the greedy frontier optimal.

1. A prefix-free set is a group of tree nodes where no node lies above another. Expanding a word replaces it with its children, so no new prefix relation appears.
2. Sorting the letter weights puts the cheapest letters first. The child of the lightest word is then no heavier than any other child.
3. Expanding the lightest word first stays safe. A heavier word lies no closer to the root, so its children cannot be cheaper.
4. The sum changes by `leafTotal - lightest + k * lightest + weightTotal`. The subtraction drops the parent, `k * lightest` adds each child's shared part, and `weightTotal` adds one letter weight per child.
5. The program stops when `leafTotal` no longer falls. Later expansions add heavier children, so the sum cannot improve.

The arrays and their roles:

| Term | Meaning |
| --- | --- |
| `nodeValue` | weight of each frontier or child node |
| `nodeAlive` | flag marking a node still on the frontier |
| `minHeap` | node ids ordered by increasing weight |
| `maxHeap` | node ids ordered by decreasing weight |
| `leafTotal` | sum of the current frontier weights |
| `wordTarget` | number of words the language must hold |

Both heaps share the same node ids, so one expansion touches two small arrays.

The generator traces the sample `n = 3`, `k = 2`, weights `[2, 5]`:

```
frontier: 2 5          sum 7  start
frontier: 4 5 7        sum 16 expand 2 -> children 4, 7
frontier: 5 6 7        sum 18 expand 4 -> children 6, 9, trim 9
answer: 16
```

The sum rises after the second expansion, so the program keeps 16. The matching words are `b`, `aa`, and `ab`.

## Code

**Setup and scanner.** One buffer holds the input, and a hand scanner parses integers.

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

The read loop runs once per input line and stops at end of stream. The scanner skips blank lines and spaces. Parsing costs one pass over the input buffer.

**Buffered output.** A single string collects the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush check runs once per answer line, not per number. A 256 KiB block keeps writes infrequent. The final write after the loop flushes the remainder.

**Heap state and pushes.** Two heaps share one node array through integer ids.

```nim
var nodeValue: seq[int64]
var nodeAlive: seq[bool]
var minHeap: seq[int]
var maxHeap: seq[int]

proc pushMin(heap: var seq[int], nodeId: int) =
  heap.add nodeId
  var idx = heap.len - 1
  while idx > 0:
    let parentIdx = (idx - 1) div 2
    if nodeValue[heap[parentIdx]] <= nodeValue[heap[idx]]:
      break
    let swapId = heap[parentIdx]
    heap[parentIdx] = heap[idx]
    heap[idx] = swapId
    idx = parentIdx

proc pushMax(heap: var seq[int], nodeId: int) =
  heap.add nodeId
  var idx = heap.len - 1
  while idx > 0:
    let parentIdx = (idx - 1) div 2
    if nodeValue[heap[parentIdx]] >= nodeValue[heap[idx]]:
      break
    let swapId = heap[parentIdx]
    heap[parentIdx] = heap[idx]
    heap[idx] = swapId
    idx = parentIdx
```

Each insertion climbs from a leaf to the root and costs O(log n). Equal values can order differently in the two heaps, which is harmless because only the value matters.

**Heap pops and helpers.** Pushes and pops share the live-flag scheme.

```nim
proc popMin(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var idx = 0
  while true:
    let leftIndex = 2 * idx + 1
    let rightIndex = leftIndex + 1
    var smallest = idx
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] < nodeValue[heap[smallest]]:
      smallest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] < nodeValue[heap[smallest]]:
      smallest = rightIndex
    if smallest == idx:
      break
    let swapId = heap[idx]
    heap[idx] = heap[smallest]
    heap[smallest] = swapId
    idx = smallest

proc popMax(heap: var seq[int]): int =
  result = heap[0]
  let lastId = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len == 0:
    return
  heap[0] = lastId
  var idx = 0
  while true:
    let leftIndex = 2 * idx + 1
    let rightIndex = leftIndex + 1
    var largest = idx
    if leftIndex < heap.len and nodeValue[heap[leftIndex]] > nodeValue[heap[largest]]:
      largest = leftIndex
    if rightIndex < heap.len and nodeValue[heap[rightIndex]] > nodeValue[heap[largest]]:
      largest = rightIndex
    if largest == idx:
      break
    let swapId = heap[idx]
    heap[idx] = heap[largest]
    heap[largest] = swapId
    idx = largest

proc addLeaf(value: int64) =
  let nodeId = nodeValue.len
  nodeValue.add value
  nodeAlive.add true
  pushMin(minHeap, nodeId)
  pushMax(maxHeap, nodeId)

proc removeLightest(): int64 =
  while not nodeAlive[minHeap[0]]:
    discard popMin(minHeap)
  let nodeId = popMin(minHeap)
  nodeAlive[nodeId] = false
  return nodeValue[nodeId]

proc removeHeaviest(): int64 =
  while not nodeAlive[maxHeap[0]]:
    discard popMax(maxHeap)
  let nodeId = popMax(maxHeap)
  nodeAlive[nodeId] = false
  return nodeValue[nodeId]
```

Each pop pushes the last heap entry down, also O(log n). A dead id is skipped lazily when it reaches a heap root. The removal helpers mark nodes dead and return their values.

**Case driver.** Sorting, expansion, and trimming fill one case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let wordTarget = nextInt(inputData, scanPos)
  let letterCount = nextInt(inputData, scanPos)
  var letterWeights: seq[int64]
  letterWeights.setLen(letterCount)
  for idx in 0..<letterCount:
    letterWeights[idx] = int64(nextInt(inputData, scanPos))
  for curIdx in 1..<letterCount:
    let key = letterWeights[curIdx]
    var prevIdx = curIdx - 1
    while prevIdx >= 0 and letterWeights[prevIdx] > key:
      letterWeights[prevIdx + 1] = letterWeights[prevIdx]
      prevIdx -= 1
    letterWeights[prevIdx + 1] = key

  nodeValue.setLen(0)
  nodeAlive.setLen(0)
  minHeap.setLen(0)
  maxHeap.setLen(0)
  var leafTotal: int64 = 0
  let initialCount = min(wordTarget, letterCount)
  for idx in 0..<initialCount:
    addLeaf(letterWeights[idx])
    leafTotal += letterWeights[idx]
  var leafCount = initialCount

  var bestTotal: int64 = high(int64)
  while leafTotal < bestTotal:
    if leafCount == wordTarget:
      bestTotal = leafTotal
    let lightest = removeLightest()
    leafTotal -= lightest
    leafCount -= 1
    for idx in 0..<letterCount:
      let childWeight = lightest + letterWeights[idx]
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

Insertion sort runs `letterCount - 1` times because `k` never exceeds 26. The expansion loop stops when the frontier sum stops falling. The trim loop keeps exactly `wordTarget` live leaves.

## Complexity

Heap work dominates once weights are sorted.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | input buffer |
| Sort letter weights | O(k^2) | O(k) weights |
| Each expansion | O(k log n) | O(k) new nodes |
| Output | O(t) | one output block |

Let `E` be the number of expansions before the sum stops falling.

| Measure | Big O |
| --- | --- |
| Time | O(input bytes + t (k^2 + E k log n)) |
| Space | O(n + E k) plus buffers |

A search that lists every word to the needed depth has no fixed bound. The heap keeps only the useful frontier.
