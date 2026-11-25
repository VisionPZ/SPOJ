# TFRIENDS — True Friends (SPOJ)

<https://www.spoj.com/problems/TFRIENDS/>

## Problem

Given an `N × N` table of who knows whom, count the groups where every member is a true friend of every other member. A friend of B is anyone B knows, or anyone known by a friend of B.

Input: `t`, then for each case `N` and `N` strings of `Y` and `N`. Output: one group count per case.

| item | bound |
|---|---|
| test cases `t` | 1 to 1000 |
| people `N` | 1 to 100 |
| table entries | `Y` or `N`, diagonal `N` |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
3
3
NYN
NNY
YNN
7
NNYNNNN
NNNYYYN
NNNNNNN
YNNNNNN
NNNYNNN
NNNNNNN
NNNNNYN
7
NNNNYYN
NNNNNNN
NNNNNYN
NYNNNYY
NNNYNNN
NNYNNNY
NNNNYNN
```

Sample output:

```
1
7
3
```

## Idea

Read the friendship rule backwards, like tracing a rumour to its source. "A is a friend of B" means a chain of knows links leads from B to A. Two people are true friends when each can reach the other through such links.

Those mutual pairs are exactly the strongly connected components of the knows graph. Counting groups becomes counting components. Tarjan's algorithm finds each component with one depth-first search and a stack of active nodes.

A closure table would test every ordered pair against every middle person, costing `N^3` work per case. Tarjan scans the table rows once per node, so it costs `N^2` per case.

The takeaway: translate the friendship rule into reachability, then count components.

## Why It Works

1. If B knows A, there is a path from B to A, so A is a friend of B.
2. If B has a friend C who knows A, then paths B to C and C to A join into a path B to A.
3. By induction, A is a friend of B exactly when a path from B to A exists.
4. True friendship needs a path both ways, which is mutual reachability.
5. Mutual reachability is an equivalence relation, so its classes are the unique groups.
6. Those classes are the strongly connected components of the knows graph.

| term | meaning |
|---|---|
| `discoveryValue` | when a person was first visited |
| `lowValue` | earliest node still reachable from the current subtree |
| `stackNodes` | active nodes not yet assigned to a component |
| `groupCount` | number of components found |

When a node's low value equals its discovery value, the nodes above it on the stack form one component. The search pops them and increments the count.

Worked example from sample case 3, with edges read from the seven rows:

| person | knows | reaches | true friends with |
|---|---|---|---|
| 0 | 4, 5 | 4, 5 | 0 |
| 1 | none | none | 1 |
| 2 | 6 | 6 | 2 |
| 3 | 1, 5, 6 | 1, 5, 6 | 2, 3, 4, 5, 6 |
| 4 | 3 | 3, 5, 6, 1 | 2, 3, 4, 5, 6 |
| 5 | none | none | 2, 3, 4, 5, 6 |
| 6 | 4 | 4, 3, 5, 6, 1 | 2, 3, 4, 5, 6 |

Rows for people 2, 3, 4, and 6 form one cycle through 6, 4, 3, and back to 6. Person 1 has no outgoing link and person 0 never gets a link back. The groups are `{0}`, `{1}`, and `{2, 3, 4, 5, 6}`, so the answer is 3.

The table is stored as strings, so each neighbour test is one character read.

## Code

**Input and scanner.** Numbers come from the digit scanner, rows come from the character reader.

```nim
import sequtils

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

proc nextRow(data: string, pos: var int, rowLength: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  for columnIndex in 0 .. rowLength - 1:
    result.add data[pos]
    pos += 1
```

The row reader skips the line break and copies exactly `N` symbols.

**Buffered output.** One buffer serves all cases.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The final write flushes any remaining bytes.

**Tarjan state.** These variables are shared by the recursive search.

```nim
var knownRows: seq[string]
var personCount = 0
var visited: seq[bool]
var lowValue: seq[int]
var discoveryValue: seq[int]
var stackNodes: seq[int]
var onStack: seq[bool]
var timerValue = 0
var groupCount = 0
```

The arrays are rebuilt for each case, so no state leaks between cases.

**Strong connectivity search.** Each finished root produces one group.

```nim
proc strongConnect(node: int) =
  visited[node] = true
  lowValue[node] = timerValue
  discoveryValue[node] = timerValue
  timerValue += 1
  stackNodes.add node
  onStack[node] = true
  for neighbor in 0 .. personCount - 1:
    if knownRows[node][neighbor] == 'Y':
      if not visited[neighbor]:
        strongConnect(neighbor)
        if lowValue[neighbor] < lowValue[node]:
          lowValue[node] = lowValue[neighbor]
      elif onStack[neighbor]:
        if discoveryValue[neighbor] < lowValue[node]:
          lowValue[node] = discoveryValue[neighbor]
  if lowValue[node] == discoveryValue[node]:
    groupCount += 1
    while true:
      let topNode = stackNodes.pop()
      onStack[topNode] = false
      if topNode == node: break
```

A back edge to an active node lowers the root's low value. That merge is what binds a cycle into one group.

**Driver.** One search pass covers all people in a case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  personCount = nextInt(inputData, scanPos)
  knownRows = newSeq[string](personCount)
  for rowIndex in 0 .. personCount - 1:
    knownRows[rowIndex] = nextRow(inputData, scanPos, personCount)
  visited = repeat(false, personCount)
  lowValue = newSeq[int](personCount)
  discoveryValue = newSeq[int](personCount)
  onStack = repeat(false, personCount)
  stackNodes = newSeq[int](0)
  timerValue = 0
  groupCount = 0
  for personIndex in 0 .. personCount - 1:
    if not visited[personIndex]:
      strongConnect(personIndex)
  appendOutput($groupCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Recursion depth never exceeds `N`, which is at most 100.

## Complexity

| phase | time per case | space |
|---|---|---|
| input read | one pass over all bytes | one input string |
| table build | `N` row copies | `N` strings |
| Tarjan search | `N` rows scanned once each | `N` integers and booleans |
| output | one buffered line | 128 KiB buffer |

| measure | Big O |
|---|---|
| time per case | O(N^2) |
| total time | O(t N^2) |
| space | O(N^2) for the table |

Transitive closure costs O(N^3) per case and still needs a second pass to extract groups. Tarjan needs one pass over the rows and no reachability matrix.
