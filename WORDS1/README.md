## Problem

Read T test cases. Each case gives N words. Order the words so that every word starts with the letter the previous word ends with. Use each word exactly once. Print one of two fixed sentences per case: "Ordering is possible." or "The door cannot be opened."

| Quantity | Bound |
| --- | --- |
| Test cases T | about 500 |
| Words per case N | 1 to 100000 |
| Word length | 2 to 1000 lowercase letters |
| Time limit | 20000 ms |
| Memory limit | 1536 MB |

All letters are lowercase. The output is one sentence per case.

## Idea

Model each letter as a vertex and each word as a directed edge. The edge runs from the first letter of the word to its last letter. The task then asks whether this directed graph has an Eulerian path that uses every edge once. Union-find checks that all letters with an edge share one connected component. Degree counts check the path endpoints. Each word costs one union and two counter updates. Trying every word ordering would be far slower.

Cost per word: O(1).

## Why It Works

A directed graph has an Eulerian path when two facts hold. First, every vertex with nonzero degree lies in one connected component of the underlying undirected graph. Second, the degrees must balance. In a circuit, every vertex has equal in and out degree. In an open path, one vertex has out degree one above in degree. One other vertex has in degree one above out degree. All remaining vertices stay balanced.

Union-find merges the two letters of each word. This builds the undirected component. The arrays `outDegree` and `inDegree` record the surplus at each letter.

For an edge from first letter f to last letter l:

- The `outDegree` entry for f grows by one.
- The `inDegree` entry for l grows by one.
- `unionLetters` joins the components of f and l.

The sample's second case gives the edges below.

| Word | Edge |
| --- | --- |
| acm | a -> m |
| malform | m -> m |
| mouse | m -> e |

Degree counts follow from those edges.

| Letter | Out | In | Surplus |
| --- | --- | --- | --- |
| a | 1 | 0 | +1 |
| e | 0 | 1 | -1 |
| m | 2 | 2 | 0 |

Letter a is the start and e is the end. All three letters connect. The ordering acm, malform, mouse works.

## Code

Constants and hand scanners read the whole input buffer without per-token allocation.

```nim
const flushBlockBytes = 1 shl 18
const digitBase = 48
const letterBase = 97
const letterCount = 26
const possibleMessage = "Ordering is possible.\n"
const impossibleMessage = "The door cannot be opened.\n"

proc skipWhitespace(data: string, scanPos: var int) =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1

proc nextInt(data: string, scanPos: var int): int =
  skipWhitespace(data, scanPos)
  result = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    result = result * 10 + (int(data[scanPos]) - digitBase)
    scanPos += 1

proc nextWordEnds(data: string, scanPos: var int): tuple[first: char, last: char] =
  skipWhitespace(data, scanPos)
  let wordStart = scanPos
  while scanPos < data.len and data[scanPos] > ' ':
    scanPos += 1
  result.first = data[wordStart]
  result.last = data[scanPos - 1]
```

`nextWordEnds` reads only the two edge letters. It skips the rest of each word. This avoids one string allocation per word.

Union-find keeps the 26 letters in components.

```nim
proc findRoot(parent: var array[letterCount, int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  result = current

proc unionLetters(parent: var array[letterCount, int], left: int, right: int) =
  let leftRoot = findRoot(parent, left)
  let rightRoot = findRoot(parent, right)
  if leftRoot != rightRoot:
    parent[leftRoot] = rightRoot
```

Path halving keeps `findRoot` fast. The fixed array holds 26 integers.

The program reads stdin once into `inputData`, then scans it with an index.

```nim
var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var scanPos = 0
let testCount = nextInt(inputData, scanPos)
var outputBuffer = ""

var parent: array[letterCount, int]
var outDegree: array[letterCount, int]
var inDegree: array[letterCount, int]
```

One pass builds `inputData`. The three arrays are reused for every case.

The main loop counts edges, checks connectivity, and checks degrees.

```nim
for caseIndex in 0 ..< testCount:
  for letter in 0 ..< letterCount:
    parent[letter] = letter
    outDegree[letter] = 0
    inDegree[letter] = 0

  let wordCount = nextInt(inputData, scanPos)
  var referenceVertex = -1
  for wordIndex in 0 ..< wordCount:
    let wordEnds = nextWordEnds(inputData, scanPos)
    let firstLetter = int(wordEnds.first) - letterBase
    let lastLetter = int(wordEnds.last) - letterBase
    outDegree[firstLetter] += 1
    inDegree[lastLetter] += 1
    unionLetters(parent, firstLetter, lastLetter)
    if referenceVertex < 0:
      referenceVertex = firstLetter

  var orderingPossible = true
  if wordCount > 0:
    for letter in 0 ..< letterCount:
      if inDegree[letter] + outDegree[letter] > 0:
        if findRoot(parent, letter) != findRoot(parent, referenceVertex):
          orderingPossible = false

    if orderingPossible:
      var startSurplusCount = 0
      var endSurplusCount = 0
      for letter in 0 ..< letterCount:
        let difference = outDegree[letter] - inDegree[letter]
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

Each case resets the arrays in O(26). `referenceVertex` anchors the connectivity check. The surplus loop accepts one start and one end, or a balanced circuit. Output is flushed in blocks of `flushBlockBytes`.

## Complexity

Reading input takes O(total input bytes). Each word costs O(1) counting and union work. Connectivity and degree checks cost O(26) per case. Output costs O(T). Total time is O(total input bytes + T). Space is O(total input bytes) for the buffer plus O(26) for the arrays.

A naive search tries all N! word orderings. That grows far faster than the linear scan used here.
