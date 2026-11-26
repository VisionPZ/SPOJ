# MATHEXAM — Finishing Your Math Exam (SPOJ)

<https://www.spoj.com/problems/MATHEXAM/>

## Problem

N exam questions fall into types. Similar questions share a type, and the listed pairs are exactly the similar pairs. The first question of a type costs x seconds, every later one of that type costs y seconds. With T seconds left, can you finish all N questions?

The first line holds N, x, y, T. The second line holds M, the number of pairs, followed by M lines of two question labels.

| item | bound |
|---|---|
| questions N | 1 ≤ N ≤ 10,000 |
| costs x, y | 1 ≤ x, y ≤ 100,000 |
| time left T | 1 ≤ T ≤ 10^9 |
| pairs M | 1 ≤ M ≤ 100,000 |
| judge limit | 1000 ms, 1536 MB |

The answer depends only on the number of types, so the pairs just group questions.

Sample input:

```
6 3 1 10
4
1 2
1 3
4 3
5 6
```

Sample output:

```
YES
```

## Idea

Friends of friends form one club. Union-Find merges questions into type-clubs as pairs arrive, and one extra question of an existing club costs only the copy time.

If there are c clubs, the cheapest plan pays x once per club and y for each of the N-c copied questions. Compare that total with T.

Takeaway: only the club count matters, not who is in which club.

## Why It Works

1. Similarity is transitive, so types are exactly the connected components of the pair graph.
2. Union-Find merges components as each pair is read.
3. Each component needs one paid method, costing x.
4. Every other question copies that method, costing y.
5. The minimum total is c·x + (N-c)·y, and finishing is possible exactly when it is at most T.

For the sample, the pairs join questions 1-2-3-4 into one club and 5-6 into another, so c = 2. The total is 2·3 + 4·1 = 10, which fits in T = 10, so the answer is `YES`.

When y ≥ x the formula still holds: paying x per club is never worse than the alternative reading of the rules, because each club must pay its first-time cost once.

## Code

**Input and scanning.** The hand reader loads the file and parses 64-bit values.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

let questionCount = int(nextInt(inputData, scanPos))
let firstCost = nextInt(inputData, scanPos)
let copyCost = nextInt(inputData, scanPos)
let timeLimit = nextInt(inputData, scanPos)
let pairCount = int(nextInt(inputData, scanPos))
```

The scanner skips spaces and newlines.
Costs are read as 64-bit to keep the total exact.

**Union-Find.** Parent links and sizes merge components.

```nim
var parentNodes = newSeq[int](questionCount + 1)
var componentSizes = newSeq[int](questionCount + 1)
for nodeIndex in 0 .. questionCount:
  parentNodes[nodeIndex] = nodeIndex
  componentSizes[nodeIndex] = 1

proc findRoot(nodeIndex: int): int =
  var current = nodeIndex
  while parentNodes[current] != current:
    parentNodes[current] = parentNodes[parentNodes[current]]
    current = parentNodes[current]
  return current

proc joinNodes(firstNode, secondNode: int) =
  var firstRoot = findRoot(firstNode)
  var secondRoot = findRoot(secondNode)
  if firstRoot == secondRoot:
    return
  if componentSizes[firstRoot] < componentSizes[secondRoot]:
    swap(firstRoot, secondRoot)
  parentNodes[secondRoot] = firstRoot
  componentSizes[firstRoot] = componentSizes[firstRoot] + componentSizes[secondRoot]
```

Each node starts as its own club.
Path halving keeps finds short.
The bigger root absorbs the smaller one.

**Counting clubs and deciding.** Roots are counted once each.

```nim
var componentCount = 0
for nodeIndex in 1 .. questionCount:
  if findRoot(nodeIndex) == nodeIndex:
    componentCount += 1

let totalTime = int64(componentCount) * firstCost +
                int64(questionCount - componentCount) * copyCost
if totalTime <= timeLimit:
  appendOutput("YES\n")
else:
  appendOutput("NO\n")
```

A node that is its own root heads one club.
The total uses the cheapest legal plan.
The comparison with T gives the answer.

## Complexity

All pairs are merged, then one pass counts roots.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| unions | near-constant per pair | parent and size arrays |
| count | one pass over questions | none |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O((N + M) α(N)) |
| space | O(N) |

Building the full graph and running search would use more memory for the same answer.

Takeaway: components decide the cost, so union and count.
