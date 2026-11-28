# TOPOLAND — To Poland (SPOJ)

<https://www.spoj.com/problems/TOPOLAND/>

## Problem

A journey has N parts, each needing a minimum number of balloons. We track the balloons currently carried and answer range queries that ask how many balloons must be added or removed for a stretch of parts. Updates change one part's requirement or the carried total.

The first input line holds the testcase count T. Each testcase starts with N and the initial balloon count M, followed by N required values. The next line holds the query count Q. Q lines follow. A K changes the carried count by K. B J K sets requirement J to K. C I J prints the carried count minus the largest requirement in range I to J, inclusive. Print a header line Testcase X: for each case, then each C answer on its own line, then one blank line.

| item | bound |
|---|---|
| testcases T | up to 100 |
| parts N | 1 to 100000 |
| queries Q | 1 to 100000 per testcase |
| requirement value | 0 to 1000000000 |
| judge limit | 106 ms, 1536 MB |

The query count drives the need for logarithmic range queries.

Sample input:

```
2
3 11
5 2 4
1
C 0 2
3 11
16 2 17
5
C 0 2
A -2
C 1 2
B 0 0
C 0 1
```

Sample output:

```
Testcase 0:
6

Testcase 1:
-6
-8
7

```

## Idea

Picture the parts as entries in a tournament bracket, where each higher rung stores the larger of two lower rungs. That bracket is a segment tree, and it finds a range maximum in logarithmic time. A point update climbs one bracket path. Scanning the whole range for every query would cost linear time per query and miss the tight limit.

One tree serves every query in a testcase.

## Why It Works

1. Leaves of the tree hold the requirement of one part each.
2. Each internal node stores the larger value of its two children.
3. The tree size is the smallest power of two at least N, doubled for both halves.
4. A range query walks from the right leaf up while shedding covered nodes.
5. It takes the left node whenever that node sits at an odd index.
6. It takes the right node whenever that node sits at an even index.
7. Both pointers then move to their parent, which halves the remaining interval.
8. A carried count may exceed or fall below the maximum, so answers can be negative.

| term | meaning |
|---|---|
| `segmentTree` | array holding the maximum of each bracket interval |
| `segmentSize` | leaf offset, the smallest power of two at least N |
| `houseBalloons` | balloons currently carried |
| `bestValue` | largest requirement found in the queried range |
| `nextCommand` | reader that returns the next command letter |

The bracket shape makes both updates and queries touch one path per level.

A script trace of the first sample case shows the tree and one query:

```
values 5 2 4, segmentSize 4
leaves: tree[4]=5, tree[5]=2, tree[6]=4
parents: tree[2]=5, tree[1]=5
C 0 2: take tree[6]=4, then tree[2]=5, bestValue 5
answer: houseBalloons 11 minus 5 gives 6
```

The trace reproduces the first sample answer.

Unused leaves stay zero, and all real requirements are non-negative, so padding never changes a maximum. The scanner accepts a minus sign because A K may remove balloons.

## Code

**Input, scanner, and buffer.** One read loads stdin, and separate readers handle signed numbers and command letters.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value * sign

proc nextCommand(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  if pos >= data.len:
    return ' '
  let command = data[pos]
  pos += 1
  if command >= 'a' and command <= 'z':
    return chr(int(command) - 32)
  return command

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sign branch supports negative changes from A queries.
Command letters are uppercased so both cases work.
The output buffer flushes after many kilobytes, not after each answer.

**Point update.** Changing one part rewrites its leaf and every ancestor above it.

```nim
proc updateValue(segmentTree: var seq[int64], leafIndex: int, newValue: int64) =
  var nodeIndex = leafIndex
  segmentTree[nodeIndex] = newValue
  nodeIndex = nodeIndex div 2
  while nodeIndex >= 1:
    segmentTree[nodeIndex] = max(segmentTree[nodeIndex * 2], segmentTree[nodeIndex * 2 + 1])
    nodeIndex = nodeIndex div 2
```

The leaf index equals the part index plus the tree offset.
Each parent recomputes from its two children.
The climb visits one node per tree level.

**Main loop and range query.** Each testcase builds a tree, then processes queries in order.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let partCount = nextInt(inputData, scanPos)
  var houseBalloons = int64(nextInt(inputData, scanPos))
  var segmentSize = 1
  while segmentSize < partCount:
    segmentSize = segmentSize * 2
  var segmentTree = newSeq[int64](segmentSize * 2)
  for partIndex in 0 .. partCount - 1:
    segmentTree[segmentSize + partIndex] = int64(nextInt(inputData, scanPos))
  for nodeIndex in countdown(segmentSize - 1, 1):
    segmentTree[nodeIndex] = max(segmentTree[nodeIndex * 2], segmentTree[nodeIndex * 2 + 1])
  appendOutput("Testcase " & $caseIndex & ":\n")
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let command = nextCommand(inputData, scanPos)
    if command == 'A':
      houseBalloons = houseBalloons + int64(nextInt(inputData, scanPos))
    elif command == 'B':
      let partIndex = nextInt(inputData, scanPos)
      let newMinimum = int64(nextInt(inputData, scanPos))
      updateValue(segmentTree, segmentSize + partIndex, newMinimum)
    else:
      let leftIndex = nextInt(inputData, scanPos)
      let rightIndex = nextInt(inputData, scanPos)
      var leftNode = segmentSize + leftIndex
      var rightNode = segmentSize + rightIndex
      var bestValue: int64 = -1
      while leftNode <= rightNode:
        if leftNode mod 2 == 1:
          bestValue = max(bestValue, segmentTree[leftNode])
          leftNode += 1
        if rightNode mod 2 == 0:
          bestValue = max(bestValue, segmentTree[rightNode])
          rightNode -= 1
        leftNode = leftNode div 2
        rightNode = rightNode div 2
      appendOutput($(houseBalloons - bestValue))
      outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The build fills leaves and then fills parents in reverse.
A C query collects covered nodes while both pointers climb.
Each testcase ends with one blank line as required.

## Complexity

Tree construction is linear, and each query touches one tree path.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| tree build | one pass over leaves and parents | tree of size 2 times the power of two |
| A query | one increment | no extra space |
| B query | one root-to-leaf climb | no extra space |
| C query | two climbs to the root | no extra space |
| output | one append per answer | block buffer |

Updates and queries have the same logarithmic cost per tree level.

| measure | Big O |
|---|---|
| time | O((N + Q) log N) per testcase |
| space | O(N) for the tree |

Rescanning the range for each C query would cost O(N Q) per testcase.
