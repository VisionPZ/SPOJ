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

proc addImplication(fromList: var seq[int], toList: var seq[int], source: int, target: int) =
  fromList.add source
  toList.add target

proc addClause(fromList: var seq[int], toList: var seq[int], leftVar: int, leftVal: int, rightVar: int, rightVal: int) =
  let leftNode = leftVar * 2 + leftVal
  let rightNode = rightVar * 2 + rightVal
  addImplication(fromList, toList, leftNode xor 1, rightNode)
  addImplication(fromList, toList, rightNode xor 1, leftNode)

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
