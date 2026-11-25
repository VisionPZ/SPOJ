# WORDS1 — Play on Words (SPOJ)

<https://www.spoj.com/problems/WORDS1/>

## Problem

A door holds magnetic plates, each with one word. Arrange the plates in a chain so every word begins with the letter the previous word ends with. Use every plate exactly once to open the door.

Input starts with `T`, about 500. Each case gives `N`, from 1 to 100000, then `N` words of 2 to 1000 lowercase letters. A word may repeat. Print one sentence per case, and match its text exactly. Use `Ordering is possible.` when a chain exists.
Otherwise print `The door cannot be opened.`

| Quantity | Bound |
| --- | --- |
| Test cases `T` | about 500 |
| Words per case `N` | 1 to 100000 |
| Word length | 2 to 1000 lowercase letters |
| Time limit | 20000 ms |
| Memory limit | 1536 MB |

Only the first and last letter of each word matter for the chain.

The sample input and output follow verbatim.

```
3
2
acm
ibm
3
acm
malform
mouse
2
ok
ok
```

```
The door cannot be opened.
Ordering is possible.
The door cannot be opened.
```

## Idea

Model each word as a directed edge from its first letter to its last letter. Think of planning a delivery route that uses every one-way street exactly once. The question becomes whether that letter graph has an Eulerian path.

Union-find checks that all letters with an edge share one connected component. Degree counts check the path endpoints. Each word costs one union and two counter updates.

Trying all word orderings takes factorial time. The Eulerian conditions finish in linear time.

An Eulerian path test replaces a factorial search.

## Why It Works

Three facts give the Eulerian test.

1. A directed graph has an Eulerian path when every vertex with nonzero degree lies in one component of the underlying undirected graph.
2. The degrees must also balance. In a circuit, each vertex has equal in and out degree. In an open path, one vertex has out degree one above in degree, and one has the reverse. All others stay balanced.
3. Union-find merges the two letters of each word, building the undirected component. The arrays `outDegree` and `inDegree` record the surplus at each letter.

The table names the degree values.

| Term | Meaning |
| --- | --- |
| `outDegree[k]` | words whose first letter is `k` |
| `inDegree[k]` | words whose last letter is `k` |
| `difference` | out degree minus in degree |
| `referenceVertex` | first letter seen, anchoring connectivity |
| `parent` | union-find parent over 26 letters |

The sample's second case gives these edges.

| Word | Edge |
| --- | --- |
| acm | a to m |
| malform | m to m |
| mouse | m to e |

Degree counts follow from those edges.

| Letter | Out | In | Surplus |
| --- | --- | --- | --- |
| a | 1 | 0 | +1 |
| e | 0 | 1 | -1 |
| m | 2 | 2 | 0 |

Letter `a` is the start and `e` is the end. All three letters connect, so the ordering `acm`, `malform`, `mouse` works.

## Code

**Input setup.** Constants and hand scanners read the whole input buffer without per-token allocation.

```nim
const flushBlockBytes = 1 shl 18
const digitBase = 48
const letterBase = 97
const letterCount = 26
const possibleMessage = "Ordering is possible.\n"
const impossibleMessage = "The door cannot be opened.\n"

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    i += 1

proc nextInt(data: string, i: var int): int =
  skipWhitespace(data, i)
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + (int(data[i]) - digitBase)
    i += 1

proc nextWordEnds(data: string, i: var int): tuple[first: char, last: char] =
  skipWhitespace(data, i)
  let j = i
  while i < data.len and data[i] > ' ':
    i += 1
  result.first = data[j]
  result.last = data[i - 1]
```

`nextWordEnds` reads only the two edge letters and skips the rest. This avoids one string allocation per word.

**Union-find.** Union-find keeps the 26 letters in components.

```nim
proc findRoot(parent: var array[letterCount, int], i: int): int =
  var j = i
  while parent[j] != j:
    parent[j] = parent[parent[j]]
    j = parent[j]
  result = j

proc unionLetters(parent: var array[letterCount, int], i: int, j: int) =
  let leftRoot = findRoot(parent, i)
  let rightRoot = findRoot(parent, j)
  if leftRoot != rightRoot:
    parent[leftRoot] = rightRoot
```

Path halving keeps `findRoot` fast. The fixed array holds 26 integers.

**Input arrays.** The program reads stdin once, then scans it with an index.

```nim
var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var i = 0
let testCount = nextInt(inputData, i)
var outputBuffer = ""

var parent: array[letterCount, int]
var outDegree: array[letterCount, int]
var inDegree: array[letterCount, int]
```

One pass builds `inputData`. The three arrays are reused for every case.

**Case driver.** The main loop counts edges, checks connectivity, and checks degrees.

```nim
for j in 0 ..< testCount:
  for k in 0 ..< letterCount:
    parent[k] = k
    outDegree[k] = 0
    inDegree[k] = 0

  let wordCount = nextInt(inputData, i)
  var referenceVertex = -1
  for l in 0 ..< wordCount:
    let wordEnds = nextWordEnds(inputData, i)
    let firstLetter = int(wordEnds.first) - letterBase
    let lastLetter = int(wordEnds.last) - letterBase
    outDegree[firstLetter] += 1
    inDegree[lastLetter] += 1
    unionLetters(parent, firstLetter, lastLetter)
    if referenceVertex < 0:
      referenceVertex = firstLetter

  var orderingPossible = true
  if wordCount > 0:
    for k in 0 ..< letterCount:
      if inDegree[k] + outDegree[k] > 0:
        if findRoot(parent, k) != findRoot(parent, referenceVertex):
          orderingPossible = false

    if orderingPossible:
      var startSurplusCount = 0
      var endSurplusCount = 0
      for k in 0 ..< letterCount:
        let difference = outDegree[k] - inDegree[k]
        if difference == 1:
          startSurplusCount += 1
        elif difference == -1:
          endSurplusCount += 1
        elif difference != 0:
          orderingPossible = false
      if not ((startSurplusCount == 1 and endSurplusCount == 1) or
              (startSurplusCount == 0 and endSurplusCount == 0)):
        orderingPossible = false

  if orderingPossible:
    outputBuffer.add possibleMessage
  else:
    outputBuffer.add impossibleMessage
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

Each case resets the arrays in `O(26)`. `referenceVertex` anchors the connectivity check. The surplus loop accepts one start and one end, or a balanced circuit. Output is flushed in blocks.

## Complexity

Reading dominates, since each word costs constant work.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(total input bytes) | one input string |
| Edge counting per word | O(1) | constant |
| Connectivity and degrees | O(26) per case | O(26) arrays |
| Output | O(T) | one flush block |

Only the first and last characters of each word are inspected.

The totals use the input size and the case count.

| Measure | Big O |
| --- | --- |
| Time | O(total input bytes + T) |
| Space | O(total input bytes) |

A naive search tries all `N!` word orderings, which grows far faster than the linear scan.
