# EXPLOSN — The Explosion (SPOJ)

<https://www.spoj.com/problems/EXPLOSN/>

## Problem

Each detained person names one suspect, and an innocent person always tells the truth.
Choose the smallest group of suspects so that every innocent testimony points inside that group.
Report the group size for each test case.

The first line holds `T`, the number of test cases, from 1 to 10.
Each case starts with `N`, from 2 to 100000, then `N` lines with one suspect number each.
People are numbered from 1 to `N`, and a suspect number may equal the speaker's own number.
Print one integer per case: the minimum group size.

| Item | Bound |
|---|---|
| Test cases T | 1 to 10 |
| People N | 2 to 100000 |
| Testimony Pi | 1 to N |
| Judge limit | 1000 ms, 1536 MB |

For every person `i`, either `i` belongs to the group or the named person belongs to it.
This is exactly a minimum vertex cover of a graph where each vertex has one outgoing edge.

Sample input:

```
1
3
2
3
1
```

Sample output:

```
2
```

## Idea

Think of guards on one-way roads: every road needs a guard at one end, and each junction has one outgoing road.
Peel away people with no incoming testimonies, then solve each remaining cycle separately.
Tree dynamic programming handles the peeled branches; a two-state cycle pass handles the loops.
Each person is visited a constant number of times, so a case costs O(N).
Trying every group would take exponential time.

## Why It Works

1. The rule for person `i` is: `i` is guilty, or the person `i` names is guilty.
2. Each person has one outgoing arrow, so every component is one cycle with trees feeding into it.
3. Repeatedly removing vertices with no incoming arrows leaves exactly the cycle vertices.
4. Processing peeled vertices in removal order gives each child's answer before its parent's answer.
5. A peeled vertex left out of the group forces every child into the group.
6. A peeled vertex placed in the group lets each child choose its cheaper option.
7. A cycle pass tracks whether the previous cycle vertex is in the group, then closes the loop.

| Term | Meaning |
|---|---|
| `accusedBy` | the person named by each witness |
| `peelOrder` | vertices removed by the incoming-arrow sweep |
| `coverWhenFree` | minimum group size below a vertex left out of the group |
| `coverWhenGuilty` | minimum group size below a vertex placed in the group |
| `cycleFreeCost` | branch cost for a cycle vertex left out |
| `cycleGuiltyCost` | branch cost for a cycle vertex placed in the group |

In the sample, three people form one cycle of length three.
A group of one person leaves an arrow whose speaker and target are both outside the group.
Two people cover all three arrows, so the answer is 2.

A self-loop forces its vertex into the group.
An odd cycle needs one more than half its length; an even cycle needs half its length.
Costs stay below 100000, so plain integers are enough.

## Code

**Input and hand scanner.** The reader loads all text once and parses integers without library calls.

```nim
const flushBlockBytes = 1 shl 17
const infiniteCost = 1000000000

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
```

`infiniteCost` marks states that cannot occur.
`scanPos` moves past separators and digits.
The whole input stays in `inputData`.

**Buffered output and arrow sweep.** Each testimony becomes one edge, and a queue removes non-cycle vertices.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
for testCaseIndex in 0 .. testCaseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  var accusedBy = newSeq[int](personCount)
  var incomingHead = newSeq[int](personCount)
  var incomingNext = newSeq[int](personCount)
  var incomingPerson = newSeq[int](personCount)
  var incomingCount = newSeq[int](personCount)
  var edgeIndex = 0
  for personIndex in 0 .. personCount - 1:
    incomingHead[personIndex] = -1
  for personIndex in 0 .. personCount - 1:
    let accusedPerson = nextInt(inputData, scanPos) - 1
    accusedBy[personIndex] = accusedPerson
    incomingCount[accusedPerson] += 1
    incomingPerson[edgeIndex] = personIndex
    incomingNext[edgeIndex] = incomingHead[accusedPerson]
    incomingHead[accusedPerson] = edgeIndex
    edgeIndex += 1
  var peelQueue = newSeq[int](personCount)
  var peeled = newSeq[bool](personCount)
  var peelOrder = newSeq[int](personCount)
  var queueFront = 0
  var queueBack = 0
  var peeledCount = 0
  for personIndex in 0 .. personCount - 1:
    if incomingCount[personIndex] == 0:
      peelQueue[queueBack] = personIndex
      queueBack += 1
  while queueFront < queueBack:
    let currentPerson = peelQueue[queueFront]
    queueFront += 1
    peelOrder[peeledCount] = currentPerson
    peeledCount += 1
    peeled[currentPerson] = true
    let accusedPerson = accusedBy[currentPerson]
    incomingCount[accusedPerson] -= 1
    if incomingCount[accusedPerson] == 0:
      peelQueue[queueBack] = accusedPerson
      queueBack += 1
```

`incomingHead` starts at -1 for every vertex before any edge is added.
`peelOrder` records vertices from leaves toward cycles.
`peeled` separates tree vertices from cycle vertices.

**Tree costs and cycle close.** Branch costs feed a two-state pass around each cycle.

```nim
  var coverWhenFree = newSeq[int](personCount)
  var coverWhenGuilty = newSeq[int](personCount)
  for orderIndex in 0 .. peeledCount - 1:
    let currentPerson = peelOrder[orderIndex]
    var freeCost = 0
    var guiltyCost = 1
    var edgeCursor = incomingHead[currentPerson]
    while edgeCursor != -1:
      let childPerson = incomingPerson[edgeCursor]
      freeCost += coverWhenGuilty[childPerson]
      guiltyCost += min(coverWhenFree[childPerson], coverWhenGuilty[childPerson])
      edgeCursor = incomingNext[edgeCursor]
    coverWhenFree[currentPerson] = freeCost
    coverWhenGuilty[currentPerson] = guiltyCost
  var cycleFreeCost = newSeq[int](personCount)
  var cycleGuiltyCost = newSeq[int](personCount)
  var onCycle = newSeq[bool](personCount)
  for personIndex in 0 .. personCount - 1:
    if not peeled[personIndex]:
      var freeCost = 0
      var guiltyCost = 1
      var edgeCursor = incomingHead[personIndex]
      while edgeCursor != -1:
        let childPerson = incomingPerson[edgeCursor]
        if peeled[childPerson]:
          freeCost += coverWhenGuilty[childPerson]
          guiltyCost += min(coverWhenFree[childPerson], coverWhenGuilty[childPerson])
        edgeCursor = incomingNext[edgeCursor]
      cycleFreeCost[personIndex] = freeCost
      cycleGuiltyCost[personIndex] = guiltyCost
      onCycle[personIndex] = true
  var totalGuilty = 0
  for startPerson in 0 .. personCount - 1:
    if not onCycle[startPerson]:
      continue
    var cyclePeople: seq[int] = @[]
    var currentPerson = startPerson
    while true:
      cyclePeople.add currentPerson
      onCycle[currentPerson] = false
      currentPerson = accusedBy[currentPerson]
      if currentPerson == startPerson:
        break
    var bestCycleCost = infiniteCost
    for firstState in 0 .. 1:
      var previousFree = infiniteCost
      var previousGuilty = infiniteCost
      let firstPerson = cyclePeople[0]
      if firstState == 0:
        previousFree = cycleFreeCost[firstPerson]
      else:
        previousGuilty = cycleGuiltyCost[firstPerson]
      for cycleIndex in 1 .. cyclePeople.len - 1:
        let currentCyclePerson = cyclePeople[cycleIndex]
        let nextFree = cycleFreeCost[currentCyclePerson] + previousGuilty
        let nextGuilty = cycleGuiltyCost[currentCyclePerson] + min(previousFree, previousGuilty)
        previousFree = nextFree
        previousGuilty = nextGuilty
      if firstState == 0:
        bestCycleCost = min(bestCycleCost, previousGuilty)
      else:
        bestCycleCost = min(bestCycleCost, min(previousFree, previousGuilty))
    totalGuilty += bestCycleCost
  appendOutput($totalGuilty)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each peeled vertex contributes one of two costs based on its parent's state.
Cycle results add up because components are disjoint.
`appendOutput` writes `stdout` only after the block fills.

## Complexity

Each vertex enters the queue once and each edge is scanned a constant number of times.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over N testimonies | one input string |
| Arrow sweep | one queue pass per test case | arrays of size N |
| Tree and cycle costs | one scan per vertex and edge | arrays of size N |
| Output | one line per case | one block buffer |

| Measure | Big O |
|---|---|
| Time per case | O(N) |
| Space per case | O(N) |

Checking all groups of people would take O(2^N) time and cannot handle large cases.
The peel order turns each tree into one linear pass.
