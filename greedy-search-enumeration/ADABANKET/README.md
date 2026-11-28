# ADABANKET — Ada and Banquet (SPOJ)

<https://www.spoj.com/problems/ADABANKET/>

## Problem

Split friends into two nonempty banquets so that the fewest friendships cross between the rooms. Each crossing friendship makes both friends dissatisfied once, so the answer is twice the number of crossing edges.

Input gives the friend count, then one line of N bits per friend. A one means friendship, the matrix is symmetric, and no friend befriends herself. Output the minimum total dissatisfaction.

| item | bound |
|---|---|
| friends N | 2 to 900 |
| matrix entries | 0 or 1, symmetric |
| graph | connected, about 10 percent of pairs |
| judge limit | 2000 ms, 1536 MB |

The friend count makes subset enumeration impossible, so the design uses a graph algorithm.

Sample input:

```
2
0 1
1 0
```

The sample has two friends who know each other.

Sample output:

```
2
```

Any split puts one friendship across the rooms, which costs one point per friend.

## Idea

Finding the thinnest seam in a fabric is like this split: pull vertices together until the last added one reveals a cut. Stoer-Wagner computes a minimum cut phase, records its cut value, and merges the last two vertices. Repeating the phase over a shrinking active set finds the global minimum cut. Each phase costs O(N^2) matrix steps and runs N times. Checking all 2^N partitions would cost far more at N = 900. Find the cut, then double it for the two dissatisfied friends per edge.

## Why It Works

1. In a minimum cut phase, adding the vertex with the largest connection weight to the grown set produces a cut equal to that vertex weight.
2. The last two vertices of a phase can be merged without changing the value of any global minimum cut.
3. Every phase contributes one candidate cut, and the smallest candidate over all phases is the global minimum cut.
4. Each crossing friendship costs one point for each endpoint, so the answer is twice the cut size.

| term | meaning |
|---|---|
| `friendshipMatrix` | adjacency weights, including weights of merged groups |
| `activeMembers` | group representatives still available for merging |
| `phaseCutValue` | cut found by the current phase |
| `bestCutValue` | smallest phase cut found so far |

The four terms describe the shrinking set of groups and their cut values.

A script trace of the second sample with five friends:

```
side A: 0 1 2 3
side B: 4
crossing edges: 0-4
cut size: 1
dissatisfaction: 2 * 1 = 2
```

The single crossing friendship produces the sample answer.

## Code

**Input and buffer.** The reader loads the symmetric matrix into one flat array.

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

let friendCount = nextInt(inputData, scanPos)
var friendshipMatrix = newSeq[int32](friendCount * friendCount)
for rowIndex in 0 .. friendCount - 1:
  for columnIndex in 0 .. friendCount - 1:
    friendshipMatrix[rowIndex * friendCount + columnIndex] = int32(nextInt(inputData, scanPos))
```

A flat array avoids nested sequence indirection in the hot loops.
Every matrix entry is read once as a zero or a one.
The scanner treats spaces and line breaks identically.

**Greedy phases and merges.** Each phase picks a vertex, records its cut, and merges the final pair.

```nim
var activeMembers = newSeq[int](friendCount)
for memberIndex in 0 .. friendCount - 1:
  activeMembers[memberIndex] = memberIndex
var activeCount = friendCount
var bestCutValue = high(int32)

while activeCount > 1:
  var phaseIncluded = newSeq[bool](friendCount)
  var phaseWeights = newSeq[int32](friendCount)
  var lastJoined = -1
  var previousJoined = -1
  var phaseCutValue: int32 = 0
  for phaseStep in 0 .. activeCount - 1:
    var chosenMember = -1
    for activeIndex in 0 .. activeCount - 1:
      let candidateMember = activeMembers[activeIndex]
      if not phaseIncluded[candidateMember] and
          (chosenMember == -1 or phaseWeights[candidateMember] > phaseWeights[chosenMember]):
        chosenMember = candidateMember
    phaseIncluded[chosenMember] = true
    phaseCutValue = phaseWeights[chosenMember]
    previousJoined = lastJoined
    lastJoined = chosenMember
    for activeIndex in 0 .. activeCount - 1:
      let candidateMember = activeMembers[activeIndex]
      if not phaseIncluded[candidateMember]:
        phaseWeights[candidateMember] += friendshipMatrix[chosenMember * friendCount + candidateMember]
  if phaseCutValue < bestCutValue:
    bestCutValue = phaseCutValue
  for activeIndex in 0 .. activeCount - 1:
    let candidateMember = activeMembers[activeIndex]
    if candidateMember != lastJoined and candidateMember != previousJoined:
      let mergedWeight = friendshipMatrix[previousJoined * friendCount + candidateMember] +
                         friendshipMatrix[lastJoined * friendCount + candidateMember]
      friendshipMatrix[previousJoined * friendCount + candidateMember] = mergedWeight
      friendshipMatrix[candidateMember * friendCount + previousJoined] = mergedWeight
  var writeIndex = 0
  for activeIndex in 0 .. activeCount - 1:
    let candidateMember = activeMembers[activeIndex]
    if candidateMember != lastJoined:
      activeMembers[writeIndex] = candidateMember
      writeIndex += 1
  activeCount -= 1

appendOutput($(2'i64 * int64(bestCutValue)))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The largest weight is scanned over active groups only.
Merging adds the two rows of weights into the surviving group.
The final output doubles the cut for both endpoints of each edge.

## Complexity

The active set shrinks by one group per phase.

| phase | time | space |
|---|---|---|
| input read | one token scan | input string |
| cut phases | O(N^2) steps per phase | two arrays of N entries |
| merges | O(N^2) steps per phase | flat N^2 matrix |
| output | one buffered write | block buffer |

The matrix dominates memory and stays fixed in size while groups merge.

| measure | Big O |
|---|---|
| time | O(N^3) |
| space | O(N^2) |

Trying all partitions would need 2^N checks, which is impossible at N = 900. Repeated greedy phases find the same cut in cubic time.
