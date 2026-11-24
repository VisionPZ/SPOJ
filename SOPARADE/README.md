## Problem

Each province has n soldiers in a row at positions 1 to n. Each soldier has rank 1, 2, 3, or 4. Neighboring soldiers differ by at least two ranks. Each rule names positions that must all have different ranks. Print "approved" when an assignment satisfies every rule, and "rejected" otherwise.

| Quantity | Bound |
| --- | --- |
| Provinces | t ≤ 10 |
| Soldiers per province | n ≤ 100000 |
| Rules per province | p ≤ 100000 |
| Time limit | 9000 ms |
| Memory limit | 1536 MB |

Both bounds drive the implication graph, so the check stays linear in n and in the total rule size.

## Idea

Reduce the assignment to 2-SAT, clauses of the form "a or b" over true or false variables. Relabel ranks 3, 1, 4, 2 as vertices 0, 1, 2, 3 of a path. Neighboring soldiers take neighboring path vertices, so vertex parity flips at every step. Each position then has two possible ranks; call its binary choice v. Adjacency forbids one pair: v = 0 on an odd position next to v = 1 on an even position. A rule adds an "unequal" clause for each pair of same-parity positions it holds. Cost: O(n + total rule size) clauses, solved by strongly connected components in linear time.

## Why It Works

The allowed rank pairs are (1,3), (1,4), and (2,4). They form the path 3 - 1 - 4 - 2. A step along the row moves one edge along that path, so parity alternates with position. Odd positions use one pair of ranks, and even positions use the other pair. A rule with three positions of one parity fails because only two ranks fit that parity. Two positions of one parity differ exactly when their v values differ.

The adjacency clause is (v_odd or not v_even). It gives two implications: odd = 0 forces even = 0, and even = 1 forces odd = 1. Flipping every v turns this clause into the other parity case, so one check covers both cases. Each node has index 2 * position + value, and its negated node flips the last bit.

A script in gen.py checks all 32 binary choices for the second sample case and finds zero valid assignments. For the first case, v = (0, 0) gives ranks 3 and 1, which differ by two and are distinct.

## Code

```nim
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
```

The read loop appends one line at a time into one buffer. Blank lines between cases become harmless extra characters. The scanner skips them and parses each integer once. Cost is one pass over the input.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc addImplication(fromList: var seq[int], toList: var seq[int], source: int, target: int) =
  fromList.add source
  toList.add target

proc addClause(fromList: var seq[int], toList: var seq[int], leftVar: int, leftVal: int, rightVar: int, rightVal: int) =
  let leftNode = leftVar * 2 + leftVal
  let rightNode = rightVar * 2 + rightVal
  addImplication(fromList, toList, leftNode xor 1, rightNode)
  addImplication(fromList, toList, rightNode xor 1, leftNode)
```

One output buffer flushes at 256 KiB and is reused after each flush. `addClause` stores both implications of a clause. Each clause adds two edges to the graph.

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
```

Counts become offsets in `outStart` and `inStart`. The loops fill the forward and reverse edge arrays once. Cost is linear in nodes plus edges.

```nim
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

Two iterative depth-first passes label components without recursion. The final loop rejects a variable whose two nodes share a component. Cost is linear in nodes plus edges.

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

The first loop adds one clause per neighboring pair, so it runs n - 1 times. Each rule stores two positions per parity and rejects a third. The solver runs once per case, and the final write flushes the buffer.

## Complexity

Reading scans I integers once, where I counts all rule positions. Each case builds O(n + total rule size) clauses and twice as many implication edges. Kosaraju visits each node and edge once, so solving costs O(n + edges). Total time is O(I + sum of n and rule sizes over cases). Space is O(n + edges) per case for the graph and its reverse. Trying all 4^n rank assignments takes exponential time.
