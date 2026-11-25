# IITWPC4K — Maggu and Magguness Level (SPOJ)
<https://www.spoj.com/problems/IITWPC4K/>

## Problem

Given strict comparisons between students, find every rank one chosen student can hold in a valid ordering of distinct ranks. Print -1 when the comparisons contain a cycle.

The first line holds T. Each case starts with n, m and idx, followed by m pairs a b meaning a ranks below b.
For a possible case, print the number of ranks, then the ranks in ascending order on the next line.

The bounds are:

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| students n | 1 to 1000000 |
| relations m | at most 100000 |
| judge limit | 1000 ms, 1536 MB |

Large student counts call for linear adjacency arrays.

Sample input:

```
2
3 2 1
1 2
2 3
4 2 1
1 2
3 4
```

The first case forms a chain of three students.

Sample output:

```
1
1
3
1 2 3
```

The first case allows only rank one for student one.

## Idea

Think of each comparison as an arrow in a line-up, like a note saying one book must stand before another.

Detect cycles with Kahn's topological sort, which removes students whose incoming arrows are all gone. Then count ancestors and descendants of the chosen student by walking both arrow directions. Every rank between those counts can be reached. Listing all orderings would take factorial time.

Two graph walks and one topological sweep solve each case.

## Why It Works

1. A comparison a b becomes an arrow from a to b.
2. A cycle makes every valid ordering impossible, so the answer is -1.
3. Kahn's queue starts with students that have no incoming arrows.
4. Processing fewer than n students signals a cycle.
5. Every ancestor of idx must hold a lower rank number than idx.
6. Every descendant must hold a higher rank number than idx.
7. Other students fill the remaining slots in any order.

The main names are:

| term | meaning |
|---|---|
| `forwardHead` | first outgoing arrow for each student |
| `backwardHead` | first incoming arrow for each student |
| `indegree` | count of incoming arrows left to remove |
| `traversalQueue` | queue used by the sweep and both walks |
| `ancestorCount` | students that must rank below idx |
| `descendantCount` | students that must rank above idx |
| `lowestRank` | first reachable rank number |
| `highestRank` | last reachable rank number |

The adjacency arrays keep the graph compact.

The generator produced these numbers for the second sample case:

| item | value |
|---|---|
| students | 4 |
| comparisons | 1 below 2, and 3 below 4 |
| ancestors of student 1 | 0 |
| descendants of student 1 | 1 |
| lowestRank | 1 |
| highestRank | 3 |
| printed ranks | 1 2 3 |

Student 2 must rank above student 1, while students 3 and 4 can move around it.

Self comparisons become self loops, and Kahn's sweep marks them as cycles.

## Code

**Input and output helpers.** All input arrives in one string and integers come from a hand scanner.

```nim
const flushBlockBytes = 1 shl 17

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


```

The scanner skips every non-digit byte.
A block buffer collects output lines.
No answer is written while scanning input.

**Graph build and cycle sweep.** Forward and backward adjacency share one pair of edge arrays.

```nim
for caseIndex in 0 .. testCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let relationCount = nextInt(inputData, scanPos)
  let targetStudent = nextInt(inputData, scanPos)
  var forwardHead = newSeq[int](studentCount + 1)
  var backwardHead = newSeq[int](studentCount + 1)
  var indegree = newSeq[int](studentCount + 1)
  var edgeDestination = newSeq[int](relationCount)
  var edgeNext = newSeq[int](relationCount)
  var reverseDestination = newSeq[int](relationCount)
  var reverseNext = newSeq[int](relationCount)
  for nodeIndex in 0 .. studentCount:
    forwardHead[nodeIndex] = -1
    backwardHead[nodeIndex] = -1
  for edgeIndex in 0 .. relationCount - 1:
    let lowerStudent = nextInt(inputData, scanPos)
    let higherStudent = nextInt(inputData, scanPos)
    edgeDestination[edgeIndex] = higherStudent
    edgeNext[edgeIndex] = forwardHead[lowerStudent]
    forwardHead[lowerStudent] = edgeIndex
    reverseDestination[edgeIndex] = lowerStudent
    reverseNext[edgeIndex] = backwardHead[higherStudent]
    backwardHead[higherStudent] = edgeIndex
    indegree[higherStudent] += 1
  var traversalQueue = newSeq[int](studentCount)
  var queueHead = 0
  var queueTail = 0
  for nodeIndex in 1 .. studentCount:
    if indegree[nodeIndex] == 0:
      traversalQueue[queueTail] = nodeIndex
      queueTail += 1
  while queueHead < queueTail:
    let currentNode = traversalQueue[queueHead]
    queueHead += 1
    var edgeIndex = forwardHead[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeDestination[edgeIndex]
      indegree[neighbor] -= 1
      if indegree[neighbor] == 0:
        traversalQueue[queueTail] = neighbor
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  if queueTail != studentCount:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue

```

Each comparison increments the indegree of the higher student.
Kahn's queue removes zero-indegree students in order.
A short queue means a cycle and a single -1 line.

**Rank walks and answer.** Two walks count forced neighbours, then print one continuous range.

```nim
  var visited = newSeq[bool](studentCount + 1)
  visited[targetStudent] = true
  queueHead = 0
  queueTail = 0
  traversalQueue[queueTail] = targetStudent
  queueTail += 1
  var ancestorCount = 0
  while queueHead < queueTail:
    let currentNode = traversalQueue[queueHead]
    queueHead += 1
    var edgeIndex = backwardHead[currentNode]
    while edgeIndex != -1:
      let neighbor = reverseDestination[edgeIndex]
      if not visited[neighbor]:
        visited[neighbor] = true
        ancestorCount += 1
        traversalQueue[queueTail] = neighbor
        queueTail += 1
      edgeIndex = reverseNext[edgeIndex]
  for nodeIndex in 1 .. studentCount:
    visited[nodeIndex] = false
  visited[targetStudent] = true
  queueHead = 0
  queueTail = 0
  traversalQueue[queueTail] = targetStudent
  queueTail += 1
  var descendantCount = 0
  while queueHead < queueTail:
    let currentNode = traversalQueue[queueHead]
    queueHead += 1
    var edgeIndex = forwardHead[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeDestination[edgeIndex]
      if not visited[neighbor]:
        visited[neighbor] = true
        descendantCount += 1
        traversalQueue[queueTail] = neighbor
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  let lowestRank = ancestorCount + 1
  let highestRank = studentCount - descendantCount
  let possibleCount = highestRank - lowestRank + 1
  appendOutput($possibleCount)
  outputBuffer.add '\n'
  for rankValue in lowestRank .. highestRank:
    appendOutput($rankValue)
    if rankValue < highestRank:
      outputBuffer.add ' '
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

```

The backward walk counts ancestors and the forward walk counts descendants.
The lowest rank is the ancestor count plus one.
The highest rank subtracts descendants from the student count.

## Complexity

The work splits into phases:

| phase | time | space |
|---|---|---|
| input read | one pass over m pairs | one input string |
| graph build | one step per relation | two adjacency arrays |
| cycle sweep | one step per student and relation | indegree and queue |
| rank walks | one step per reachable student | one visited array |
| output | all reachable ranks | block buffer |

The cycle sweep and walks dominate the work.

The asymptotic costs are:

| measure | Big O |
|---|---|
| time | O(n + m) per case |
| space | O(n + m) per case |

Enumerating all orderings would take factorial time.

Linear graph walks give the answer without listing an ordering.
