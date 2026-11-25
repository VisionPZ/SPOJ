# SOPARADE — Soldiers on Parade (SPOJ)
<https://www.spoj.com/problems/SOPARADE/>

## Problem

Soldiers stand in one row with ranks 1 to 4. Neighbors must differ by at least two ranks. Extra rules say that certain sets of positions must all have different ranks. Detect provinces whose rules cannot be satisfied.

Input: an integer t, then t rule sets separated by blank lines. Each set starts with n and p, then p rules. A rule gives a count b and b positions. Output: `approved` when some arrangement exists, and `rejected` otherwise.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases t | at most 10 |
| Soldiers n | at most 100000 |
| Rules p | at most 100000 |
| Ranks | 1 to 4 |
| Judge time limit | 9000 ms |
| Judge memory limit | 1536 MB |

Only four ranks exist, so a rule with more than four positions fails at once.

The sample input:

```
2

2 1
2 1 2

5 2
3 1 3 2
4 2 3 4 5
```

The sample output:

```
approved
rejected
```

## Idea

Turn the parade into yes-or-no questions, like deciding which side of a fence each soldier sits on. Rank choices collapse to one bit per soldier after the neighbor rule. Each extra rule becomes a small clause about two bits.

The program builds a 2-SAT (yes-or-no constraint) implication graph and finds strongly connected components. A variable and its negation in the same component means a contradiction. Reading rules costs O(total positions), and the graph pass costs O(n + p). Brute-force rank assignment would cost 4 to the n, which is impossible for 100000 soldiers.

A bit and a graph replace an exponential assignment search.

## Why It Works

Four facts carry the program.

1. Neighbors differ by at least two ranks exactly when their rank halves differ. Ranks 1 and 2 form the low half, and ranks 3 and 4 form the high half.
2. The alternating neighbor constraint forces the half bit to alternate along the row. One free bit therefore fixes every soldier's half.
3. Same-parity positions share a half, so they must differ in the low bit of the rank. Only two low bits exist, so a rule may name at most two odd positions and two even positions.
4. Two such same-parity positions give an exclusive-or (different bits) clause. The implication graph encodes it with two opposite implications, and a component check detects any contradiction.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `fromList`, `toList` | edge endpoint arrays of the implication graph |
| `addClause` | adds the two implications of an exclusive-or |
| `finishOrder` | vertex order from the first depth-first pass |
| `component` | strongly connected component id per vertex |

The scanner skips blanks, so blank lines between sets need no special case.

A script reduces the second sample case.

```text
rule 1 positions 1,3,2 -> odd pair (1,3), even position 2
rule 2 positions 2,3,4,5 -> odd pair (3,5), even pair (2,4)
neighbor constraints alternate half bits along the row
the odd-pair and even-pair clauses force a contradiction
output rejected
```

The first case has no same-parity pair, so it is approved.

## Code

**Input and output plumbing.** One buffer and one scanner serve all sets.

```nim
{.push checks: off.}
when not defined(release):
  {.passC: "-O2".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextInt` skips every non-digit, so blank lines between sets vanish. One output buffer flushes in blocks.

**Clause construction.** Two helpers add one implication each.

```nim
proc addImplication(fromList: var seq[int], toList: var seq[int], source: int, target: int) =
  fromList.add source
  toList.add target

proc addClause(fromList: var seq[int], toList: var seq[int], leftVar: int, leftVal: int, rightVar: int, rightVal: int) =
  let leftNode = leftVar * 2 + leftVal
  let rightNode = rightVar * 2 + rightVal
  addImplication(fromList, toList, leftNode xor 1, rightNode)
  addImplication(fromList, toList, rightNode xor 1, leftNode)
```

Node index is variable times two plus the literal value. The `xor 1` flips a literal, which gives the contrapositive implication.

**Component search.** Two passes find strongly connected components.

```nim
proc graphSatisfiable(nodeCount: int, fromList: seq[int], toList: seq[int]): bool =
  if nodeCount == 0: return true
  var outStart = newSeq[int](nodeCount + 1)
  var inStart = newSeq[int](nodeCount + 1)
  for k in 0..<fromList.len:
    outStart[fromList[k] + 1] += 1
    inStart[toList[k] + 1] += 1
  for k in 1..nodeCount:
    outStart[k] += outStart[k - 1]
    inStart[k] += inStart[k - 1]
  var outEdge = newSeq[int](fromList.len)
  var inEdge = newSeq[int](fromList.len)
  var outCursor = newSeq[int](nodeCount)
  var inCursor = newSeq[int](nodeCount)
  for k in 0..<nodeCount:
    outCursor[k] = outStart[k]
    inCursor[k] = inStart[k]
  for k in 0..<fromList.len:
    let sourceNode = fromList[k]
    let targetNode = toList[k]
    outEdge[outCursor[sourceNode]] = targetNode
    outCursor[sourceNode] += 1
    inEdge[inCursor[targetNode]] = sourceNode
    inCursor[targetNode] += 1
  var visited = newSeq[bool](nodeCount)
  var finishOrder = newSeq[int](nodeCount)
  var orderCount = 0
  var stackNode = newSeq[int]()
  var stackEdge = newSeq[int]()
  for startNode in 0..<nodeCount:
    if visited[startNode]: continue
    visited[startNode] = true
    stackNode.add startNode
    stackEdge.add outStart[startNode]
    while stackNode.len > 0:
      let nodeTop = stackNode[^1]
      let edgeAt = stackEdge[^1]
      if edgeAt < outStart[nodeTop + 1]:
        stackEdge[^1] = edgeAt + 1
        let nextNode = outEdge[edgeAt]
        if not visited[nextNode]:
          visited[nextNode] = true
          stackNode.add nextNode
          stackEdge.add outStart[nextNode]
      else:
        finishOrder[orderCount] = nodeTop
        orderCount += 1
        stackNode.setLen(stackNode.len - 1)
        stackEdge.setLen(stackEdge.len - 1)
  var component = newSeq[int](nodeCount)
  for k in 0..<nodeCount: component[k] = -1
  var stack = newSeq[int]()
  var componentCount = 0
  for orderIndex in countdown(orderCount - 1, 0):
    let startNode = finishOrder[orderIndex]
    if component[startNode] != -1: continue
    component[startNode] = componentCount
    stack.add startNode
    while stack.len > 0:
      let nodeTop = stack[^1]
      stack.setLen(stack.len - 1)
      for edgeAt in inStart[nodeTop]..<inStart[nodeTop + 1]:
        let nextNode = inEdge[edgeAt]
        if component[nextNode] == -1:
          component[nextNode] = componentCount
          stack.add nextNode
    componentCount += 1
  for varIndex in 0..<(nodeCount div 2):
    if component[varIndex * 2] == component[varIndex * 2 + 1]: return false
  return true
```

An iterative depth-first pass avoids deep recursion at 200000 nodes. The second pass uses the reverse graph. The final loop rejects a variable sharing a component with its negation.

**Driver.** Neighbor clauses come first, then rule clauses.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let soldierCount = nextInt(inputData, scanPos)
  let ruleCount = nextInt(inputData, scanPos)
  var possible = true
  var fromList = newSeq[int]()
  var toList = newSeq[int]()
  for positionIndex in 0..<(soldierCount - 1):
    if (positionIndex + 1) mod 2 == 1:
      addClause(fromList, toList, positionIndex, 1, positionIndex + 1, 0)
    else:
      addClause(fromList, toList, positionIndex + 1, 1, positionIndex, 0)
  var firstOdd = -1
  var secondOdd = -1
  var firstEven = -1
  var secondEven = -1
  var oddCount = 0
  var evenCount = 0
  var xorLeft = newSeq[int]()
  var xorRight = newSeq[int]()
  for ruleIndex in 0..<ruleCount:
    let bound = nextInt(inputData, scanPos)
    if bound > 4: possible = false
    firstOdd = -1
    secondOdd = -1
    firstEven = -1
    secondEven = -1
    oddCount = 0
    evenCount = 0
    for k in 0..<bound:
      let pos = nextInt(inputData, scanPos) - 1
      if pos < 0 or pos >= soldierCount:
        possible = false
      elif pos mod 2 == 0:
        oddCount += 1
        if oddCount == 1: firstOdd = pos
        elif oddCount == 2: secondOdd = pos
        else: possible = false
      else:
        evenCount += 1
        if evenCount == 1: firstEven = pos
        elif evenCount == 2: secondEven = pos
        else: possible = false
    if secondOdd >= 0:
      xorLeft.add firstOdd
      xorRight.add secondOdd
    if secondEven >= 0:
      xorLeft.add firstEven
      xorRight.add secondEven
  if possible:
    for k in 0..<xorLeft.len:
      addClause(fromList, toList, xorLeft[k], 1, xorRight[k], 1)
      addClause(fromList, toList, xorLeft[k], 0, xorRight[k], 0)
  if possible and graphSatisfiable(soldierCount * 2, fromList, toList):
    appendOutput "approved"
  else:
    appendOutput "rejected"
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each rule keeps at most two odd and two even positions. A third position of either parity fails the case. Only satisfiable cases add the extra clauses.

## Complexity

Reading and the component pass dominate each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Neighbor clauses | O(n) | O(n) edges |
| Rule reading | O(total positions) | O(p) edges |
| Component search | O(n + p) | O(n + p) |
| Output | O(t) lines | one block |

The graph has 2n vertices, one true and one false vertex per soldier.

| Measure | Big O |
| --- | --- |
| Time | O(n + p + total positions) per case |
| Space | O(n + p) per case |

Assigning ranks to every soldier would cost O(4 to the n) time.
