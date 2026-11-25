# VOL — Volunteers (SPOJ)

<https://www.spoj.com/problems/VOL/>

## Problem

Cover each contest day with at least the required number of volunteers. A volunteer type works on one interval of days, costs a fixed amount, and can be hired any number of times. Minimize total hiring cost.

| item | bound |
|---|---|
| days N | 1 to 1000 |
| volunteer types M | 1 to 10000 |
| daily need Ai | nonnegative integer |
| test cases | ten, one after another |
| judge limit | 3000 ms, 1536 MB |

The first case in the statement is shown below; nine more follow in the judge input.

Sample input:

```
3 3
2 3 4
1 2 2
2 3 5
3 3 2
```

Sample output:

```
14
```

## Idea

Send flow through a line of days, like routing trucks along a road where each toll booth sells a shortcut at a fixed price. Free edges carry unused volunteer coverage from one day to the next. A volunteer edge jumps from its start day to the day after its end day at cost Ci. Sending one unit through such a shortcut buys one volunteer. Minimum-cost flow finds the cheapest set of shortcuts that meets every day's need. A cost-sorted greedy fails because a cheap short interval can block a better combination of longer intervals.

| term | meaning |
|---|---|
| `dailyNeeds` | required volunteers for each day |
| `flowTarget` | flow amount larger than any achievable coverage |
| `addDirectedEdge` | adds one network edge and its residual reverse edge |
| `minCostFlow` | successive shortest augmenting paths |
| `minimumCost` | cheapest total hiring cost |

Each augmentation saturates a free edge or finishes the flow, so at most N + 1 augmentations run.

## Why It Works

1. Number the boundaries from 0 before day 1 to N after day N.
2. The free edge from boundary i to i + 1 has capacity flowTarget minus that day's need.
3. A volunteer for days s to t gets an edge from boundary s - 1 to boundary t with cost Ci.
4. Flow on the free edge into day i equals flowTarget minus coverage on day i.
5. The capacity on that edge therefore enforces coverage of at least Ai.
6. Sending flowTarget units from boundary 0 to boundary N minimizes total shortcut cost.
7. Successive shortest paths keep the residual graph optimal after each augmentation.

| term | meaning |
|---|---|
| residual edge | reverse edge carrying cancelable flow at negative cost |
| `augmentAmount` | largest flow increase along the current shortest path |
| `flowTarget` | (max need + 1) times (number of types + 1) |

The large target allows any valid coverage, including more than the peak daily need.

A worked example for needs 2, 3, 4 and types (1, 2, 2), (2, 3, 5), (3, 3, 2):

```
buy 3 of type (1,2,2): cost 6, day 1 and 2 covered
buy 4 of type (3,3,2): cost 8, day 3 and 4 boundary covered
day 2 coverage 3 meets its need of 3
total cost 14
```

The trace returns the sample answer.

## Code

**Input and scanner.** The reader loads one case at a time until end of input.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const infiniteCapacity = int64(1) shl 60
const unreachableCost = int64(1) shl 62

type
  FlowEdge = object
    targetNode: int
    reverseIndex: int
    capacity: int64
    unitCost: int64

  Volunteer = object
    startDay: int
    endDay: int
    dailyCost: int64

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
```

Costs and capacities use int64.
Each volunteer keeps its interval and price.
A zero day count does not appear, so EOF ends the loop.

**Network and flow.** Residual edges support cancellation during augmentation.

```nim
var adjacency: seq[seq[FlowEdge]]

proc addDirectedEdge(fromNode: int, toNode: int, capacityValue: int64, costValue: int64) =
  let forwardEdge = FlowEdge(targetNode: toNode, reverseIndex: adjacency[toNode].len,
                             capacity: capacityValue, unitCost: costValue)
  let backwardEdge = FlowEdge(targetNode: fromNode, reverseIndex: adjacency[fromNode].len,
                              capacity: 0, unitCost: -costValue)
  adjacency[fromNode].add forwardEdge
  adjacency[toNode].add backwardEdge

proc minCostFlow(sourceNode: int, sinkNode: int, requiredFlow: int64, nodeCount: int): int64 =
  var remainingFlow = requiredFlow
  var totalCost: int64 = 0
  while remainingFlow > 0:
    var shortestCost = newSeq[int64](nodeCount)
    var previousNode = newSeq[int](nodeCount)
    var previousEdge = newSeq[int](nodeCount)
    var queued = newSeq[bool](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      shortestCost[nodeIndex] = unreachableCost
    var queue = newSeq[int]()
    shortestCost[sourceNode] = 0
    queue.add sourceNode
    queued[sourceNode] = true
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      queued[currentNode] = false
      for edgeIndex in 0 .. adjacency[currentNode].len - 1:
        let candidateEdge = adjacency[currentNode][edgeIndex]
        let candidateCost = shortestCost[currentNode] + candidateEdge.unitCost
        if candidateEdge.capacity > 0 and candidateCost < shortestCost[candidateEdge.targetNode]:
          shortestCost[candidateEdge.targetNode] = candidateCost
          previousNode[candidateEdge.targetNode] = currentNode
          previousEdge[candidateEdge.targetNode] = edgeIndex
          if not queued[candidateEdge.targetNode]:
            queued[candidateEdge.targetNode] = true
            queue.add candidateEdge.targetNode
    if shortestCost[sinkNode] == unreachableCost:
      break
    var augmentAmount = remainingFlow
    var walkNode = sinkNode
    while walkNode != sourceNode:
      let flowEdge = adjacency[previousNode[walkNode]][previousEdge[walkNode]]
      augmentAmount = min(augmentAmount, flowEdge.capacity)
      walkNode = previousNode[walkNode]
    walkNode = sinkNode
    while walkNode != sourceNode:
      let fromNode = previousNode[walkNode]
      let edgeIndex = previousEdge[walkNode]
      var flowEdge = adjacency[fromNode][edgeIndex]
      flowEdge.capacity -= augmentAmount
      adjacency[fromNode][edgeIndex] = flowEdge
      adjacency[walkNode][flowEdge.reverseIndex].capacity += augmentAmount
      totalCost += augmentAmount * flowEdge.unitCost
      walkNode = fromNode
    remainingFlow -= augmentAmount
  return totalCost
```

SPFA finds a shortest path with negative residual costs.
The bottleneck walk limits each augmentation.
Reverse capacities allow later rerouting.

**Graph build and output.** The free edges encode the daily needs.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let dayCount = nextInt(inputData, scanPos)
  if dayCount == 0:
    break
  let volunteerCount = nextInt(inputData, scanPos)
  var dailyNeeds = newSeq[int](dayCount)
  var largestNeed = 0
  for dayIndex in 0 .. dayCount - 1:
    dailyNeeds[dayIndex] = nextInt(inputData, scanPos)
    if dailyNeeds[dayIndex] > largestNeed:
      largestNeed = dailyNeeds[dayIndex]
  var volunteers = newSeq[Volunteer](volunteerCount)
  for volunteerIndex in 0 .. volunteerCount - 1:
    volunteers[volunteerIndex].startDay = nextInt(inputData, scanPos)
    volunteers[volunteerIndex].endDay = nextInt(inputData, scanPos)
    volunteers[volunteerIndex].dailyCost = int64(nextInt(inputData, scanPos))
  let flowTarget = int64(largestNeed + 1) * int64(volunteerCount + 1)
  adjacency = newSeq[seq[FlowEdge]](dayCount + 1)
  for dayIndex in 0 .. dayCount - 1:
    addDirectedEdge(dayIndex, dayIndex + 1, flowTarget - int64(dailyNeeds[dayIndex]), 0)
  for volunteerIndex in 0 .. volunteerCount - 1:
    let currentVolunteer = volunteers[volunteerIndex]
    addDirectedEdge(currentVolunteer.startDay - 1, currentVolunteer.endDay,
                    infiniteCapacity, currentVolunteer.dailyCost)
  let minimumCost = minCostFlow(0, dayCount, flowTarget, dayCount + 1)
  appendOutput($minimumCost)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The target exceeds any possible coverage.
One edge per volunteer type represents unlimited hiring.
Buffered output writes one line per case.

## Complexity

The flow graph has N free edges and M volunteer edges.

| phase | time | space |
|---|---|---|
| input read | one pass over needs and types | one input string |
| one shortest path | O(M + N) with SPFA | arrays of N values |
| all augmentations | at most N + 1 paths | residual graph |
| output | one line per case | block buffer |

The residual graph stores two edges per network edge.

| measure | Big O |
|---|---|
| time | O(N * (N + M)) per case |
| space | O(N + M) |

A cost-sorted greedy can miss cheaper interval combinations, so the flow model is needed.

The flow network turns interval covering into a shortest-path problem.
