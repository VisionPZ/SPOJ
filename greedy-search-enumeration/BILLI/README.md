# BILLI — Billi and Kaddu (SPOJ)

<https://www.spoj.com/problems/BILLI/>

## Problem

Each stolen word needs one payment to become some known magical word, and only the K cheapest payments count. Operations touch the end of a word only: deleting its last letter costs A, appending a letter costs B. Report the smallest total for converting exactly K stolen words.

Input begins with T test cases. Each case starts with A, B, K, N, M, followed by N magical words and then M stolen words. Output one line per case with the minimum total cost.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| words N, M | 1 to 100000 each |
| selections K | 1 to M |
| costs A, B | 1 to 1000 |
| word length | 1 to 100, lowercase letters |
| judge limit | 1000 ms, 1536 MB |

The word count drives the design: all M stolen words need a cost before the K smallest can be picked.

Verbatim sample input:

```
2
2 3 1 1 1
abc
bca
2 3 2 5 4
harry
potter
abcde
qqwweerr
ab
abc
abcd
qqwwweer
putter
```

Verbatim sample output:

```
15
5
```

## Idea

A trie is like a family tree of surnames: walk a stolen word down the tree, and every node you pass represents a shared prefix. Each visited node gives one candidate cost, and the lowest wins. Insert all magical words into a trie, then read each stolen word against it and keep only the K lowest costs in a small max-heap.

The trie visit costs O(length) per stolen word, and the heap costs O(log K) per word. Checking every pair of words costs O(N * M * length), which cannot handle 1e5 words. Takeaway: share prefixes through one trie, then select with a heap.

## Why It Works

1. Since edits happen at the end, a converted word and its target share a prefix and nothing else.
2. If the shared prefix has length L, deletion removes len(s) - L letters and addition appends len(t) - L letters.
3. A trie node at depth d stores every magical word whose prefix of length d matches the stolen word.
4. A terminal node at depth d gives cost (len(s) - d) * A with no additions.
5. The shallowest terminal deeper in that node's subtree gives the best cost needing additions, since B is positive.
6. A max-heap of size K keeps the K smallest costs seen so far, and its root is the largest of them.

The main terms and formulas:

| term | meaning |
|---|---|
| `trieMinDepth` | shortest word length stored in each node's subtree |
| `subtreeDepth` | that shortest length during a stolen-word walk |
| `removeCost` | price A of deleting one end letter |
| `addCost` | price B of appending one letter |
| `heap` | max-heap holding the chosen costs, indexed from one |

The subtree minimum chooses the cheapest extension, so no magical word is skipped.

A script-generated trace for the second sample case with A = 2 and B = 3:

```
abc      -> ab       costs 1 * 2 = 2
abcd     -> abcde    costs 1 * 3 = 3
abcd     -> ab       costs 2 * 2 = 4
qqwwweer -> qqwweerr costs 4 * 2 + 4 * 3 = 20
putter   -> ab       costs 6 * 2 + 2 * 3 = 18
two smallest costs: 2 + 3 = 5
```

The trace matches the sample output 5.

All costs are integers and fit in a 64-bit sum, since at most 1e5 words contribute at most 2e5 each. Words never contain empty strings, so a walk always starts at the root with depth zero.

## Code

**Input and token reader.** The reader loads all stdin and pulls numbers and words from one string.

```nim
const flushBlockBytes = 1 shl 17
const unreachableDepth = 1000000000

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or
                            data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and
        data[pos] != '\r' and data[pos] != '\t':
    token.add data[pos]
    pos += 1
  return token
```

`nextToken` stops at whitespace, so word lines parse without length prefixes.
The output buffer is defined next and flushed only when full.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer serves all cases, and a final write handles the remainder.

**Trie storage.** Edges live in flat arrays, and each node tracks its subtree's shortest word.

```nim
var trieHead = newSeq[int](1)
var trieMinDepth = newSeq[int](1)
var trieEndsWord = newSeq[bool](1)
var edgeNext = newSeq[int](0)
var edgeChar = newSeq[int](0)
var edgeChild = newSeq[int](0)

proc resetTrie() =
  trieHead.setLen 1
  trieMinDepth.setLen 1
  trieEndsWord.setLen 1
  edgeNext.setLen 0
  edgeChar.setLen 0
  edgeChild.setLen 0
  trieHead[0] = -1
  trieMinDepth[0] = unreachableDepth
  trieEndsWord[0] = false

proc findChild(node: int, character: int): int =
  var edgeIndex = trieHead[node]
  while edgeIndex != -1:
    if edgeChar[edgeIndex] == character:
      return edgeChild[edgeIndex]
    edgeIndex = edgeNext[edgeIndex]
  return -1
```

`edgeNext` links siblings, so a node stores only one head index.
Each case resets the arrays, so no word leaks between test cases.

**Word insertion.** Every node on a word's path records that word's length.

```nim
proc insertWord(word: string) =
  var node = 0
  let wordLength = word.len
  if wordLength < trieMinDepth[0]:
    trieMinDepth[0] = wordLength
  for charIndex in 0 .. wordLength - 1:
    let character = int(word[charIndex]) - 97
    var child = findChild(node, character)
    if child == -1:
      child = trieHead.len
      trieHead.add -1
      trieMinDepth.add unreachableDepth
      trieEndsWord.add false
      let edgeIndex = edgeNext.len
      edgeNext.add trieHead[node]
      edgeChar.add character
      edgeChild.add child
      trieHead[node] = edgeIndex
    if wordLength < trieMinDepth[child]:
      trieMinDepth[child] = wordLength
    node = child
  trieEndsWord[node] = true
```

The final node marks a complete magical word.
The minimum updated along the path answers subtree queries later.

**Cost of one stolen word.** The walk checks terminal nodes and the subtree minimum.

```nim
proc conversionCost(word: string, removeCost: int64, addCost: int64): int64 =
  let wordLength = word.len
  var node = 0
  var depth = 0
  var best = int64(unreachableDepth) * removeCost
  while true:
    if trieEndsWord[node]:
      let candidate = int64(wordLength - depth) * removeCost
      if candidate < best:
        best = candidate
    let subtreeDepth = trieMinDepth[node]
    if subtreeDepth > depth and subtreeDepth < unreachableDepth:
      let candidate = int64(wordLength - depth) * removeCost +
                      int64(subtreeDepth - depth) * addCost
      if candidate < best:
        best = candidate
    if depth == wordLength:
      break
    let child = findChild(node, int(word[depth]) - 97)
    if child == -1:
      break
    node = child
    depth += 1
  return best
```

The strict `subtreeDepth > depth` guard prevents a negative addition count.
A mismatch simply stops the walk; the deepest matched node still gives a valid cost.

**Heap selection.** A size-K max-heap retains the cheapest conversions.

```nim
proc siftDown(heap: var seq[int64], heapSize: int, start: int) =
  var parent = start
  while true:
    let leftChild = parent * 2
    if leftChild > heapSize:
      break
    let rightChild = leftChild + 1
    var largerChild = leftChild
    if rightChild <= heapSize and heap[rightChild] > heap[leftChild]:
      largerChild = rightChild
    if heap[parent] >= heap[largerChild]:
      break
    swap(heap[parent], heap[largerChild])
    parent = largerChild
```

The heap is one-indexed, so children of position p sit at 2p and 2p + 1.
Replacing the root restores the heap in logarithmic time.

**Driver.** Cases build a trie, then accumulate the selected costs.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let removeCost = int64(nextInt(inputData, scanPos))
  let addCost = int64(nextInt(inputData, scanPos))
  let needCount = nextInt(inputData, scanPos)
  let magicCount = nextInt(inputData, scanPos)
  let stolenCount = nextInt(inputData, scanPos)
  resetTrie()
  for magicIndex in 0 .. magicCount - 1:
    insertWord(nextToken(inputData, scanPos))
  var heap = newSeq[int64](needCount + 1)
  var heapSize = 0
  for stolenIndex in 0 .. stolenCount - 1:
    let cost = conversionCost(nextToken(inputData, scanPos), removeCost, addCost)
    if heapSize < needCount:
      heapSize += 1
      heap[heapSize] = cost
      var child = heapSize
      while child > 1:
        let parent = child div 2
        if heap[parent] >= heap[child]:
          break
        swap(heap[parent], heap[child])
        child = parent
    elif cost < heap[1]:
      heap[1] = cost
      siftDown(heap, heapSize, 1)
  var totalCost: int64 = 0
  for heapIndex in 1 .. heapSize:
    totalCost = totalCost + heap[heapIndex]
  appendOutput($totalCost)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

When a stolen word costs at least the heap root, it is discarded.
The heap sum is the answer, written once per case.

## Complexity

Insertion and lookup share the same trie, and the heap bounds the selection work.

| phase | time | space |
|---|---|---|
| trie insertion | O(N * word length) | one node per distinct prefix |
| stolen lookup | O(M * word length) | no extra storage |
| heap selection | O(M log K) | K cost slots |
| output | one buffered line per case | block buffer |

The trie walk dominates when words are long, and the heap dominates when K is large.

| measure | Big O |
|---|---|
| time per case | O((N + M) * word length + M log K) |
| space per case | O(N * word length + K) |

Checking all pairs would cost O(N * M * word length), which explodes at 1e5 words. Takeaway: share the prefixes once, then keep only K costs.
