# ISRANK — ISRANK (SPOJ)

<https://www.spoj.com/problems/ISRANK/>

## Problem

Schools hold students with unique predicted ranks and globally unique marks. For a query, take the named schools and the students whose predicted ranks fall in a closed range. Report the K-th highest mark among those students, or -1 when fewer than K exist.

The input gives school count, school sizes, predicted ranks, marks, then the query count. A query gives its school count, the school indices, the rank range, and K. Print one answer per query.

| item | bound |
|---|---|
| schools N | 1 to 10 |
| students per school | 1 to 10000 |
| marks | 1 to 1000000000 |
| queries Q | 1 to 10000 |
| judge limit | 3000 ms, 1536 MB |

Predicted ranks are a permutation inside each school, so each rank names one student.

Sample input:

```
4
1 3 4 1
1
1 2 3
2 3 1 4
1
28
20 11 8
6 18 22 26
7
4
1
2
3 3
1
1
2
3 3
1
3
1 3 4
4 4
1
4
1 2 3 4
4 4
4
```

Sample output:

```
8
8
26
-1
```

## Idea

Treat each school like a shelf of labeled boxes, one per predicted rank. A persistent segment tree keeps a snapshot after every rank, like saving a stack of photos.

The difference of two snapshots holds exactly the requested rank range. Descend all selected snapshots together to find the K-th highest mark without listing candidates. Sorting and scanning every candidate for each query would cost far more.

## Why It Works

1. Each school has one student for every predicted rank from one to its size.
2. Version r of a tree holds the marks of ranks one through r.
3. Version P2 minus version P1-1 holds the requested range from that school.
4. Adding counts across selected schools gives one combined multiset of marks.
5. The K-th highest mark is the (C-K+1)-th smallest, where C is the candidate count.

| term | meaning |
|---|---|
| `sortedMarks` | distinct marks in increasing order |
| `versionRoots` | persistent tree root for each school and rank prefix |
| `nodeCounts` | stored element count of a tree node |
| `candidateTotal` | number of students matching the query |

Script-generated trace for the second sample query:

| step | value |
|---|---|
| school 2, ranks 3 to 3 | mark 8 |
| compressed mark position | 3 of 9 |
| candidate count | 1 |
| requested K | 1 |
| answer | 8 |

The scan returns the mark at the found compressed position.

## Code

**Input, compression, and persistent insertion.** Each rank adds one mark to a new version.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const missingAnswer = -1
const maximumSchools = 10

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

proc compareMarks(leftValue: int, rightValue: int): int =
  return leftValue - rightValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let schoolCount = nextInt(inputData, scanPos)
var schoolSizes = newSeq[int](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  schoolSizes[schoolIndex] = nextInt(inputData, scanPos)
var predictedRanks = newSeq[seq[int]](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  var ranks = newSeq[int](schoolSizes[schoolIndex])
  for studentIndex in 0 .. schoolSizes[schoolIndex] - 1:
    ranks[studentIndex] = nextInt(inputData, scanPos)
  predictedRanks[schoolIndex] = ranks
var actualMarks = newSeq[seq[int]](schoolCount)
var allMarks = newSeq[int](0)
for schoolIndex in 0 .. schoolCount - 1:
  var marks = newSeq[int](schoolSizes[schoolIndex])
  for studentIndex in 0 .. schoolSizes[schoolIndex] - 1:
    marks[studentIndex] = nextInt(inputData, scanPos)
    allMarks.add marks[studentIndex]
  actualMarks[schoolIndex] = marks
allMarks.sort(compareMarks)
var sortedMarks = newSeq[int](0)
for markValue in allMarks:
  if sortedMarks.len == 0 or sortedMarks[sortedMarks.len - 1] != markValue:
    sortedMarks.add markValue
let markCount = sortedMarks.len
var markAtRank = newSeq[seq[int]](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  var rankMarks = newSeq[int](schoolSizes[schoolIndex] + 1)
  for studentIndex in 0 .. schoolSizes[schoolIndex] - 1:
    rankMarks[predictedRanks[schoolIndex][studentIndex]] = actualMarks[schoolIndex][studentIndex]
  markAtRank[schoolIndex] = rankMarks

var leftChild = newSeq[int](1)
var rightChild = newSeq[int](1)
var nodeCounts = newSeq[int](1)
leftChild.add 0
rightChild.add 0
nodeCounts.add 0

proc insertMark(previousRoot: int, domainLow: int, domainHigh: int, position: int): int =
  let newNode = leftChild.len
  leftChild.add 0
  rightChild.add 0
  nodeCounts.add 0
  leftChild[newNode] = leftChild[previousRoot]
  rightChild[newNode] = rightChild[previousRoot]
  nodeCounts[newNode] = nodeCounts[previousRoot] + 1
  if domainLow != domainHigh:
    let domainMiddle = (domainLow + domainHigh) div 2
    if position <= domainMiddle:
      let insertedLeft = insertMark(leftChild[previousRoot], domainLow, domainMiddle, position)
      leftChild[newNode] = insertedLeft
    else:
      let insertedRight = insertMark(rightChild[previousRoot], domainMiddle + 1, domainHigh, position)
      rightChild[newNode] = insertedRight
  return newNode

var versionRoots = newSeq[seq[int]](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  var roots = newSeq[int](schoolSizes[schoolIndex] + 1)
  for rankIndex in 1 .. schoolSizes[schoolIndex]:
    let markValue = markAtRank[schoolIndex][rankIndex]
    var markPosition = 1
    var lowBound = 0
    var highBound = markCount - 1
    while lowBound <= highBound:
      let middle = (lowBound + highBound) div 2
      if sortedMarks[middle] < markValue:
        lowBound = middle + 1
      else:
        highBound = middle - 1
    markPosition = lowBound + 1
    roots[rankIndex] = insertMark(roots[rankIndex - 1], 1, markCount, markPosition)
  versionRoots[schoolIndex] = roots
```

A binary search maps a mark to its compressed position.
Insertion copies only the nodes along one root-to-leaf path.
All versions share the untouched nodes.

**Query descent.** All selected version pairs move through the tree together.

```nim
let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let selectedCount = nextInt(inputData, scanPos)
  var selectedSchools = newSeq[int](selectedCount)
  for selectedIndex in 0 .. selectedCount - 1:
    selectedSchools[selectedIndex] = nextInt(inputData, scanPos) - 1
  let rankLow = nextInt(inputData, scanPos)
  let rankHigh = nextInt(inputData, scanPos)
  let desiredRank = nextInt(inputData, scanPos)
  var candidateTotal = 0
  for selectedIndex in 0 .. selectedCount - 1:
    let schoolIndex = selectedSchools[selectedIndex]
    let effectiveHigh = rankHigh
    if effectiveHigh >= rankLow and rankLow <= schoolSizes[schoolIndex]:
      let actualHigh = effectiveHigh
      if actualHigh > schoolSizes[schoolIndex]:
        candidateTotal = candidateTotal + schoolSizes[schoolIndex] - rankLow + 1
      else:
        candidateTotal = candidateTotal + actualHigh - rankLow + 1
  if candidateTotal < desiredRank:
    appendOutput($missingAnswer)
    outputBuffer.add '\n'
    continue
  var currentHighRoots = newSeq[int](selectedCount)
  var currentLowRoots = newSeq[int](selectedCount)
  for selectedIndex in 0 .. selectedCount - 1:
    let schoolIndex = selectedSchools[selectedIndex]
    var lowIndex = rankLow - 1
    var highIndex = rankHigh
    if lowIndex > schoolSizes[schoolIndex]:
      lowIndex = schoolSizes[schoolIndex]
    if highIndex > schoolSizes[schoolIndex]:
      highIndex = schoolSizes[schoolIndex]
    if lowIndex < 0:
      lowIndex = 0
    currentLowRoots[selectedIndex] = versionRoots[schoolIndex][lowIndex]
    currentHighRoots[selectedIndex] = versionRoots[schoolIndex][highIndex]
  var domainLow = 1
  var domainHigh = markCount
  var remainingRank = candidateTotal - desiredRank + 1
  while domainLow < domainHigh:
    let domainMiddle = (domainLow + domainHigh) div 2
    var leftTotal = 0
    for selectedIndex in 0 .. selectedCount - 1:
      let highLeft = leftChild[currentHighRoots[selectedIndex]]
      let lowLeft = leftChild[currentLowRoots[selectedIndex]]
      leftTotal = leftTotal + nodeCounts[highLeft] - nodeCounts[lowLeft]
    if remainingRank <= leftTotal:
      for selectedIndex in 0 .. selectedCount - 1:
        currentHighRoots[selectedIndex] = leftChild[currentHighRoots[selectedIndex]]
        currentLowRoots[selectedIndex] = leftChild[currentLowRoots[selectedIndex]]
      domainHigh = domainMiddle
    else:
      remainingRank = remainingRank - leftTotal
      for selectedIndex in 0 .. selectedCount - 1:
        currentHighRoots[selectedIndex] = rightChild[currentHighRoots[selectedIndex]]
        currentLowRoots[selectedIndex] = rightChild[currentLowRoots[selectedIndex]]
      domainLow = domainMiddle + 1
  appendOutput($sortedMarks[domainLow - 1])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Clamped versions handle ranks beyond a smaller school.
Too few candidates produce the -1 answer.
One descent finds the answer among all selected schools.

## Complexity

Building versions dominates preprocessing, and each query costs one tree descent.

| phase | time | space |
|---|---|---|
| compression | O(S log S) for S students | one sorted mark list |
| version build | O(S log S) | one node per insertion level |
| query descent | O(L log S) for L schools | two root arrays of length L |

| measure | Big O |
|---|---|
| time | O(S log S + Q L log S) |
| space | O(S log S) |

Collecting and sorting all candidates per query would repeat work Q times.

Persistent versions turn each query into one shared tree walk.
