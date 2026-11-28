# WORDRING — Word Rings (SPOJ)

<https://www.spoj.com/problems/WORDRING/>

## Problem

A word ring links words so each word's last two letters equal the next word's first two letters. The last word also links back to the first. Find the largest possible average word length over any ring built from the given words, or report that no ring exists.

A ring may use one word when its first two letters equal its last two letters. Each word can be used at most once. Words contain lowercase letters and have length at most 1000; the statement notes that length-one words occur in the data.

Input contains blocks. Each block starts with a word count n, followed by n words. A block with n = 0 ends the input. Print one line per block with the average rounded to two digits after the decimal point by truncation, or `No solution.`. Here `No solution.` is an exact output string defined by this contract. The judge accepts values within 0.01 of the exact average.

The bounds size the graph:

| item | bound |
|---|---|
| words n | 1 to 100000 |
| word length | 1 to 1000 |
| graph vertices | 26 times 26 letter pairs |
| judge limit | 3000 ms, 1536 MB |

The word count sets edge volume; the fixed 676 vertices set the number of relaxation rounds.

Sample input:

```
3
intercommunicational
alkylbenzenesulfonate
tetraiodophenolphthalein
0
```

Sample output:

```
21.66
```

## Idea

Think of each letter pair as a station and each word as a one-way train whose travel time is its length. The best ring is the loop with the highest average travel time per train, like finding the slowest closed tour in a rail map.

Encode each two-letter endpoint as one number from 0 to 675. Add an edge from the first pair to the last pair with weight equal to word length. A word ring is a directed cycle, and the answer is the maximum cycle mean.

Karp's dynamic program computes that mean without searching cycles. For each walk length up to 676, keep the heaviest walk ending at each vertex. For a vertex v, compare the 676-step score with every shorter score ending at v; the smallest such slope is that vertex's cycle mean. The largest value over all vertices is the answer.

## Why It Works

1. A word of length at least 2 is an edge from its first pair to its last pair, weighted by its length.
2. A length-one word becomes a self-loop on the doubled letter, weighted 1, so a single-word ring still counts.
3. A word ring is exactly a directed cycle in this graph, and its average is total weight divided by edge count.
4. scores holds the maximum weight of any walk of k edges ending at each vertex; k = 0 starts every vertex at zero.
5. If a walk of 676 edges ends at a vertex, the graph has a cycle on the path to it. That vertex carries cycle information.
6. Karp's ratio divides the final score minus an earlier score by the missing length. That gives a cycle mean candidate. The minimum over earlier lengths is the tightest bound.
7. Taking the maximum of those tight bounds over all vertices gives the maximum cycle mean, and `appendAverage` truncates it to two digits.
8. If no vertex has a 676-edge walk, no cycle exists. The answer is `No solution.`

Terms and formulas:

| term | meaning |
|---|---|
| `vertexCount` | 676 possible ordered letter pairs |
| `edgeFrom` | source letter pair of each word |
| `edgeTo` | target letter pair of each word |
| `scores` | best walk weight for every length and endpoint |
| `candidateAverage` | (long score minus short score) divided by length gap |

The scan uses 676 rounds because a cycle on 676 vertices repeats within that many edges.

The sample trace from gen.py:

```
in->al length 20
al->te length 21
te->in length 24
cycle total 65 over 3 words -> 21.666666
```

The loop closes after three words, so 65 divided by 3 gives the printed 21.66.

## Code

**Input and edge encoding.** The reader tokenizes words and turns endpoints into vertex numbers.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const letterOffset = 97
const alphabetSize = 26
const vertexCount = alphabetSize * alphabetSize
const unreachableScore = -1 shl 50
const hugeAnswer = 1e50

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc letterCode(letter: char): int =
  return int(letter) - letterOffset

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendAverage(average: float) =
  let scaledValue = int64(average * 100.0)
  let wholePart = scaledValue div 100
  let fractionPart = scaledValue mod 100
  if fractionPart < 10:
    appendOutput($wholePart & ".0" & $fractionPart)
  else:
    appendOutput($wholePart & "." & $fractionPart)
```

Three flat arrays hold the edges without storing any word text.
The length-one branch produces a valid self-loop for short words.
Truncating after multiplying by 100 matches the sample format.

**Walk scores.** Each round extends every reachable walk by one edge.

```nim
while true:
  let wordCount = nextInt(inputData, scanPos)
  if wordCount == 0:
    break
  var edgeFrom = newSeq[int](wordCount)
  var edgeTo = newSeq[int](wordCount)
  var edgeLength = newSeq[int](wordCount)
  var edgeCount = 0
  for wordIndex in 0 .. wordCount - 1:
    while scanPos < inputData.len and inputData[scanPos] <= ' ':
      scanPos += 1
    let wordStart = scanPos
    while scanPos < inputData.len and inputData[scanPos] > ' ':
      scanPos += 1
    let currentLength = scanPos - wordStart
    var sourceCode = 0
    var targetCode = 0
    if currentLength == 1:
      sourceCode = letterCode(inputData[wordStart]) * alphabetSize + letterCode(inputData[wordStart])
      targetCode = sourceCode
    else:
      sourceCode = letterCode(inputData[wordStart]) * alphabetSize +
        letterCode(inputData[wordStart + 1])
      targetCode = letterCode(inputData[wordStart + currentLength - 2]) * alphabetSize +
        letterCode(inputData[wordStart + currentLength - 1])
    edgeFrom[edgeCount] = sourceCode
    edgeTo[edgeCount] = targetCode
    edgeLength[edgeCount] = currentLength
    edgeCount += 1
  var scores = newSeq[int]((vertexCount + 1) * vertexCount)
  for position in vertexCount .. (vertexCount + 1) * vertexCount - 1:
    scores[position] = unreachableScore
  for pathLength in 1 .. vertexCount:
    let previousOffset = (pathLength - 1) * vertexCount
    let currentOffset = pathLength * vertexCount
    for edgeIndex in 0 .. edgeCount - 1:
      let sourceScore = scores[previousOffset + edgeFrom[edgeIndex]]
      if sourceScore > unreachableScore:
        let candidate = sourceScore + edgeLength[edgeIndex]
        let targetPosition = currentOffset + edgeTo[edgeIndex]
        if candidate > scores[targetPosition]:
          scores[targetPosition] = candidate
```

Round zero starts all 676 vertices with score zero.
Scores for later rounds begin at `unreachableScore`, so missing walks stay absent.
Each round sweeps the edge list once and keeps only the best walk per endpoint.

**Cycle mean extraction.** Each vertex contributes one tight slope, and the largest slope wins.

```nim
  var bestAverage = -hugeAnswer
  for targetVertex in 0 .. vertexCount - 1:
    let finalScore = scores[vertexCount * vertexCount + targetVertex]
    if finalScore == unreachableScore:
      continue
    var vertexBest = hugeAnswer
    for pathLength in 0 .. vertexCount - 1:
      let earlierScore = scores[pathLength * vertexCount + targetVertex]
      if earlierScore == unreachableScore:
        continue
      let candidateAverage = float(finalScore - earlierScore) /
        float(vertexCount - pathLength)
      if candidateAverage < vertexBest:
        vertexBest = candidateAverage
    if vertexBest > bestAverage:
      bestAverage = vertexBest
  if bestAverage <= -hugeAnswer / 2.0:
    appendOutput("No solution.")
  else:
    appendAverage(bestAverage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A missing 676-step walk proves that the vertex cannot reveal a cycle.
The inner loop keeps the smallest slope, which is the tightest bound for that vertex.
The outer loop keeps the largest bound, which is the maximum cycle mean.

## Complexity

Reading, relaxation and slope extraction have two independent size factors.

| phase | time | space |
|---|---|---|
| input read | one pass over n words | one input string |
| edge build | one edge per word | three arrays of n integers |
| walk relaxation | 676 rounds over all edges | 677 score arrays of 676 entries |
| slope extraction | 676 checks per vertex | none beyond the score table |

The relaxation table holds 457376 integers and stays flat in memory.

| measure | Big O |
|---|---|
| time | O(V * n) per block, with V = 676 |
| space | O(V^2 + n) |

Enumerating all rings is exponential, while the walk table stays linear in word count.
The fixed letter-pair alphabet keeps V constant across all inputs.
