# RLCAT — Robert Langdon & Class Attendance (SPOJ)

<https://www.spoj.com/problems/RLCAT/>

## Problem

Students sit in a row and pass one pen forward. A student uses a pen only when his compatibility value lies within threshold D of the pen owner's value. Find the fewest pens needed so every student signs without annoyance.

Input starts with the case count T. Each case gives N and D, then N compatibility values on the next line.

Output the minimum number of pens for each case.

| item | bound |
|---|---|
| cases T | 1 to 1000 |
| students N | 1 to 300000 |
| sum of N per file | at most 300000 |
| threshold D | 1 to 1000000000 |
| compatibility value | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The sum bound makes a logarithmic step per student affordable.

Sample input:

```
2
5 2
3 1 2 4 5
5 3
1 4 7 1 5
```

Sample output:

```
1
2
```

## Idea

Treat each pen like a relay baton: the starting runner sets who may carry it, and an early handoff can help the next leg.

A pen serves a consecutive block beginning at its owner. Every value in that block must sit within D of the owner's value. Taking the longest block is not always best, because a shorter first block can leave a better owner for the rest.

A suffix dynamic program tries every legal next start. Sparse tables find each block end, and a segment tree finds the cheapest next start. A rescan for every candidate would cost quadratic time.

Range queries keep the whole scan logarithmic per student.

## Why It Works

1. A pen introduced by a student serves a consecutive run that starts at that student.
2. The run is valid exactly when every value in it lies within D of the owner's value.
3. The longest valid run is not always the right first choice.
4. If end[i] is the farthest student reached from i, the next pen may start anywhere from i+1 to end[i]+1.
5. The minimum pens for suffix i equal one plus the smallest cost among those next starts.
6. Sparse tables return the minimum and maximum of any interval, so binary search finds end[i] in logarithmic steps.
7. A segment tree stores suffix costs as the scan runs right to left and answers each range minimum quickly.

| term | meaning |
|---|---|
| `compatibility` | compatibility value of each student |
| `threshold` | friendship distance D |
| `lastReachable` | farthest student one pen owner can serve |
| `sparseMin` | interval minimum table for binary search |
| `sparseMax` | interval maximum table for binary search |
| `segmentTree` | stored suffix costs during the right-to-left scan |
| `queryMinimum` | range minimum over suffix costs |
| `updateValue` | writes one finished suffix cost |
| `answerPens` | minimum pens for the case |

The table follows each value from input to the final count.

A script-traced run on a tricky case shows why the longest block loses:

```
values: [2, 4, 9, 2, 1, 1, 9]  threshold: 5
start 0: owner 2, covers through 1
start 1: owner 4, covers through 6
start 2: owner 9, covers through 2
start 3: owner 2, covers through 5
start 4: owner 1, covers through 5
start 5: owner 1, covers through 5
start 6: owner 9, covers through 6
minimum pens: 2
```

Starting at 1 reaches the end, so two pens beat the four from a longest-first choice.

The single-student shortcut avoids an empty range query.
The binary search stops at the first value outside the owner's friendly band.

## Code

**Input and scanner.** The reader loads all tokens before any case work.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const hugeValue = int64(1 shl 60)

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sentinel stands in for an unreachable next start.
The hand scanner parses one value per loop with no token objects.
The output buffer writes one answer per case in blocks.

**Range queries.** Sparse tables serve reach searches, and a segment tree serves the dynamic program.

```nim
var logarithm = newSeq[int]()
var sparseMin = newSeq[seq[int64]]()
var sparseMax = newSeq[seq[int64]]()
var treeSize = 1
var segmentTree = newSeq[int64]()

proc rangeMinimum(leftIndex: int, rightIndex: int): int64 =
  let spanLength = rightIndex - leftIndex + 1
  let level = logarithm[spanLength]
  let span = 1 shl level
  let tailIndex = rightIndex - span + 1
  if sparseMin[level][leftIndex] < sparseMin[level][tailIndex]:
    return sparseMin[level][leftIndex]
  return sparseMin[level][tailIndex]

proc rangeMaximum(leftIndex: int, rightIndex: int): int64 =
  let spanLength = rightIndex - leftIndex + 1
  let level = logarithm[spanLength]
  let span = 1 shl level
  let tailIndex = rightIndex - span + 1
  if sparseMax[level][leftIndex] > sparseMax[level][tailIndex]:
    return sparseMax[level][leftIndex]
  return sparseMax[level][tailIndex]

proc queryMinimum(leftIndex: int, rightIndex: int): int64 =
  var minimumValue = hugeValue
  var leftNode = leftIndex + treeSize
  var rightNode = rightIndex + treeSize
  while leftNode <= rightNode:
    if (leftNode and 1) == 1:
      if segmentTree[leftNode] < minimumValue:
        minimumValue = segmentTree[leftNode]
      leftNode += 1
    if (rightNode and 1) == 0:
      if segmentTree[rightNode] < minimumValue:
        minimumValue = segmentTree[rightNode]
      rightNode -= 1
    leftNode = leftNode div 2
    rightNode = rightNode div 2
  return minimumValue

proc updateValue(position: int, value: int64) =
  var nodeIndex = position + treeSize
  segmentTree[nodeIndex] = value
  while nodeIndex > 1:
    nodeIndex = nodeIndex div 2
    let leftChild = segmentTree[nodeIndex shl 1]
    let rightChild = segmentTree[(nodeIndex shl 1) + 1]
    if leftChild < rightChild:
      segmentTree[nodeIndex] = leftChild
    else:
      segmentTree[nodeIndex] = rightChild
```

Each sparse query overlaps two precomputed blocks of equal length.
Each tree walk touches one node per level of the tree.
Both procedures run in logarithmic time.

**Reach and suffix scan.** The loop builds tables, finds block ends, then walks suffixes.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let threshold = int64(nextInt(inputData, scanPos))
  var compatibility = newSeq[int64](studentCount)
  for studentIndex in 0 .. studentCount - 1:
    compatibility[studentIndex] = int64(nextInt(inputData, scanPos))
  if studentCount == 1:
    appendOutput("1")
    outputBuffer.add '\n'
    continue
  logarithm = newSeq[int](studentCount + 1)
  for spanLength in 2 .. studentCount:
    logarithm[spanLength] = logarithm[spanLength div 2] + 1
  let levelCount = logarithm[studentCount] + 1
  sparseMin = newSeq[seq[int64]](levelCount)
  sparseMax = newSeq[seq[int64]](levelCount)
  sparseMin[0] = compatibility
  sparseMax[0] = compatibility
  var level = 1
  while (1 shl level) <= studentCount:
    let span = 1 shl level
    let half = 1 shl (level - 1)
    let entryCount = studentCount - span + 1
    sparseMin[level] = newSeq[int64](entryCount)
    sparseMax[level] = newSeq[int64](entryCount)
    for startIndex in 0 .. entryCount - 1:
      let leftMin = sparseMin[level - 1][startIndex]
      let rightMin = sparseMin[level - 1][startIndex + half]
      let leftMax = sparseMax[level - 1][startIndex]
      let rightMax = sparseMax[level - 1][startIndex + half]
      if leftMin < rightMin:
        sparseMin[level][startIndex] = leftMin
      else:
        sparseMin[level][startIndex] = rightMin
      if leftMax > rightMax:
        sparseMax[level][startIndex] = leftMax
      else:
        sparseMax[level][startIndex] = rightMax
    level += 1
  var lastReachable = newSeq[int](studentCount)
  for startIndex in 0 .. studentCount - 1:
    let lowerBound = compatibility[startIndex] - threshold
    let upperBound = compatibility[startIndex] + threshold
    var lowIndex = startIndex
    var highIndex = studentCount - 1
    while lowIndex < highIndex:
      let middleIndex = (lowIndex + highIndex + 1) div 2
      if rangeMaximum(startIndex, middleIndex) <= upperBound and
         rangeMinimum(startIndex, middleIndex) >= lowerBound:
        lowIndex = middleIndex
      else:
        highIndex = middleIndex - 1
    lastReachable[startIndex] = lowIndex
  treeSize = 1
  while treeSize < studentCount + 1:
    treeSize = treeSize shl 1
  segmentTree = newSeq[int64](treeSize shl 1)
  for treeIndex in 0 .. segmentTree.len - 1:
    segmentTree[treeIndex] = hugeValue
  segmentTree[treeSize + studentCount] = 0
  var nodeIndex = treeSize - 1
  while nodeIndex >= 1:
    let leftChild = segmentTree[nodeIndex shl 1]
    let rightChild = segmentTree[(nodeIndex shl 1) + 1]
    if leftChild < rightChild:
      segmentTree[nodeIndex] = leftChild
    else:
      segmentTree[nodeIndex] = rightChild
    nodeIndex -= 1
  var answerPens = 0
  var studentIndex = studentCount - 1
  while studentIndex >= 0:
    let nextStart = queryMinimum(studentIndex + 1, lastReachable[studentIndex] + 1)
    answerPens = 1 + int(nextStart)
    updateValue(studentIndex, int64(answerPens))
    studentIndex -= 1
  appendOutput($answerPens)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The table build loops over levels up to the binary logarithm of N.
The binary search checks both the maximum and the minimum of a middle interval.
The right-to-left scan writes each suffix cost once before moving left.

## Complexity

Each case builds tables once and answers one suffix query per student.

| phase | time | space |
|---|---|---|
| input read | one pass over values | one input string |
| table build | one entry per level and student | two sparse tables |
| suffix scan | one search and one tree query per student | one cost array and tree |

The largest table holds about N times log N values.

| measure | Big O |
|---|---|
| time | O(N log N) per case |
| space | O(N log N) |

Rescanning every candidate next start would cost quadratic time per case.
Range queries reduce each decision to a logarithmic step.
