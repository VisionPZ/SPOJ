# MATHEXAM — Finishing Your Math Exam (SPOJ)
<https://www.spoj.com/problems/MATHEXAM/>

## Problem

Decide whether all exam questions can be solved within the time limit after grouping similar questions by type.

Each similarity pair means the two questions share one type.
The first question of a type costs x seconds, and each later question of that type costs y seconds.
The input gives N, x, y and T on the first line, M on the second line, then M pairs.
Output YES when the total time is at most T, otherwise NO.

| item | bound |
|---|---|
| questions N | 1 to 10000 |
| first cost x | 1 to 100000 |
| copy cost y | 1 to 100000 |
| time limit T | 1 to 1000000000 |
| pairs M | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Questions with no listed pair still form a type of their own.

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

Similar questions form circles of friends, like circles that merge when any two members know each other.

Every similarity pair joins two circles into one type.
When all pairs are read, each circle is one type.
A circle of size s costs x plus s minus one times y.
Adding those costs gives the total time.
Checking every pair against every other pair would waste work, so union-find joins circles directly.

The circle count is the only quantity needed.

## Why It Works

1. Similarity is transitive, so a connected component of the pair graph is exactly one question type.
2. Union-find keeps one root per component and merges two roots for each pair.
3. A component of size s contributes x once and y for the other s minus one questions.
4. The sum over all components is the component count times x plus N minus that count times y.

| term | meaning |
|---|---|
| `parentNodes` | the parent of each question in union-find |
| `componentSizes` | the size stored at each root |
| `joinNodes` | the merge step for one similarity pair |
| `componentCount` | the number of distinct question types |

For the sample the pairs form two components of sizes 4 and 2.
The cost is 3 plus 3 times 1, then 3 plus 1 times 1, giving 10.
That meets the limit of 10 seconds, so the answer is YES.

## Code

**Input, union-find structures and merge operations.** The reader loads the header and prepares one root per question.

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

Path halving flattens parent chains during each find.
The smaller tree is attached to the larger tree to keep chains short.

**Pair processing and decision.** After all merges, the roots give the number of types.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var pairIndex = 0
while pairIndex < pairCount:
  let leftQuestion = int(nextInt(inputData, scanPos))
  let rightQuestion = int(nextInt(inputData, scanPos))
  joinNodes(leftQuestion, rightQuestion)
  pairIndex += 1

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
stdout.write outputBuffer
outputBuffer.setLen 0
```

The total is computed in int64 before it is compared with the limit.
One buffered line carries the decision.

## Complexity

Union-find keeps each merge almost constant in cost.

| phase | time | space |
|---|---|---|
| input read | one pass over pairs | one input string |
| merges and finds | almost constant per pair | two arrays of N entries |
| decision | one pass over questions | a few integers |

| measure | Big O |
|---|---|
| time | O((N + M) alpha(N)) |
| space | O(N) |

Rebuilding component lists for every pair would cost far more than union-find.

The merge rule gives the exact type count for the stated limits.
