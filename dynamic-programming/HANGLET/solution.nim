import tables

const
  registerCount = 32
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  opAnd = 0
  opOr = 1
  opXor = 2
  opNot = 3
  opMov = 4
  opSet = 5
  opRandom = 6
  opJmp = 7
  opJz = 8
  opStop = 9
  falseNode = 0
  trueNode = 1
  topLevelSentinel = 64
  stateSlotBits = 16
  stateSlotCount = 1 shl stateSlotBits
  stateSlotMask = stateSlotCount - 1

type
  Program = object
    opCodes: seq[int]
    firstArgs: seq[int]
    secondArgs: seq[int]
  SearchState = object
    pc: int
    regs: array[registerCount, int]
    pathCond: int
    depth: int

var
  nodeVars: seq[int] = @[]
  nodeLows: seq[int] = @[]
  nodeHighs: seq[int] = @[]
  variableNodes: seq[int] = @[]
  negatedNodes: seq[int] = @[]
  nodeKeys: Table[int64, int]
  applyKeys: Table[int64, int]
  seenSlots: seq[int] = @[]
  seenHashes: seq[int64] = @[]
  seenEpochs: seq[int] = @[]
  currentEpoch = 0

proc wrappingMix(value: int64): int64 =
  var mixed = value
  mixed = mixed xor (mixed shr 33)
  mixed = mixed *% 1000003'i64
  mixed = mixed xor (mixed shr 29)
  mixed = mixed *% 0xbf58476d1ce4e5b9'i64
  mixed xor (mixed shr 32)

proc makeNode(i, lowNode, highNode: int): int =
  if lowNode == highNode:
    return lowNode
  let key = (int64(i) shl 42) or (int64(lowNode) shl 21) or int64(highNode)
  if nodeKeys.hasKey(key):
    return nodeKeys[key]
  result = nodeVars.len
  nodeVars.add i
  nodeLows.add lowNode
  nodeHighs.add highNode
  nodeKeys[key] = result

proc negateNode(i: int): int =
  if i == falseNode:
    return trueNode
  if i == trueNode:
    return falseNode
  if i < negatedNodes.len and negatedNodes[i] >= 0:
    return negatedNodes[i]
  while negatedNodes.len <= i:
    negatedNodes.add -1
  result = makeNode(nodeVars[i], negateNode(nodeLows[i]), negateNode(nodeHighs[i]))
  negatedNodes[i] = result

proc applyOp(operation, leftNode, rightNode: int): int =
  if operation == opAnd:
    if leftNode == falseNode or rightNode == falseNode:
      return falseNode
    if leftNode == trueNode:
      return rightNode
    if rightNode == trueNode:
      return leftNode
  elif operation == opOr:
    if leftNode == trueNode or rightNode == trueNode:
      return trueNode
    if leftNode == falseNode:
      return rightNode
    if rightNode == falseNode:
      return leftNode
  else:
    if leftNode == falseNode:
      return rightNode
    if rightNode == falseNode:
      return leftNode
    if leftNode == trueNode:
      return negateNode(rightNode)
    if rightNode == trueNode:
      return negateNode(leftNode)
    if leftNode == rightNode:
      return falseNode
  let key = (int64(operation) shl 46) or (int64(leftNode) shl 23) or int64(rightNode)
  if applyKeys.hasKey(key):
    return applyKeys[key]
  var topVar = topLevelSentinel
  if leftNode > trueNode:
    topVar = nodeVars[leftNode]
  if rightNode > trueNode:
    topVar = min(topVar, nodeVars[rightNode])
  var leftLow = leftNode
  var leftHigh = leftNode
  if leftNode > trueNode and nodeVars[leftNode] == topVar:
    leftLow = nodeLows[leftNode]
    leftHigh = nodeHighs[leftNode]
  var rightLow = rightNode
  var rightHigh = rightNode
  if rightNode > trueNode and nodeVars[rightNode] == topVar:
    rightLow = nodeLows[rightNode]
    rightHigh = nodeHighs[rightNode]
  result = makeNode(topVar, applyOp(operation, leftLow, rightLow), applyOp(operation, leftHigh, rightHigh))
  applyKeys[key] = result

proc andNodes(leftNode, rightNode: int): int =
  applyOp(opAnd, leftNode, rightNode)

proc orNodes(leftNode, rightNode: int): int =
  applyOp(opOr, leftNode, rightNode)

proc xorNodes(leftNode, rightNode: int): int =
  applyOp(opXor, leftNode, rightNode)

proc variableNode(i: int): int =
  while variableNodes.len <= i:
    variableNodes.add makeNode(variableNodes.len, falseNode, trueNode)
  variableNodes[i]

proc resetSolver() =
  inc currentEpoch
  nodeVars.setLen 2
  nodeVars[0] = 0
  nodeVars[1] = 0
  nodeLows.setLen 2
  nodeLows[0] = 0
  nodeLows[1] = 0
  nodeHighs.setLen 2
  nodeHighs[0] = 0
  nodeHighs[1] = 0
  variableNodes.setLen 0
  negatedNodes.setLen 0
  nodeKeys.clear()
  applyKeys.clear()
  if seenSlots.len == 0:
    seenSlots = newSeq[int](stateSlotCount)
    seenHashes = newSeq[int64](stateSlotCount)
    seenEpochs = newSeq[int](stateSlotCount)

proc hashState(state: SearchState): int64 =
  var hash = int64(state.pc) +% 17'i64
  for regValue in state.regs:
    hash = hash *% 1000003'i64 +% int64(regValue)
  hash = hash *% 1000003'i64 +% int64(state.pathCond)
  wrappingMix(hash)

proc statesEqual(left, right: SearchState): bool =
  if left.pc != right.pc or left.pathCond != right.pathCond:
    return false
  for i in 0 ..< registerCount:
    if left.regs[i] != right.regs[i]:
      return false
  return true

proc rememberState(states: seq[SearchState], state: SearchState): bool =
  let hash = hashState(state)
  var slot = int(hash) and stateSlotMask
  while seenEpochs[slot] == currentEpoch:
    let existing = seenSlots[slot] - 1
    if seenHashes[slot] == hash and statesEqual(states[existing], state):
      return true
    slot = (slot + 1) and stateSlotMask
  seenEpochs[slot] = currentEpoch
  seenSlots[slot] = states.len + 1
  seenHashes[slot] = hash
  return false

proc pushState(states: var seq[SearchState], nextPc, nextCond, nextDepth: int, nextRegs: array[registerCount, int]) =
  if nextCond == falseNode:
    return
  var candidate: SearchState
  candidate.pc = nextPc
  candidate.pathCond = nextCond
  candidate.depth = nextDepth
  candidate.regs = nextRegs
  if not rememberState(states, candidate):
    states.add candidate

proc scanToken(inputData: string, i: var int): string =
  let inputLength = inputData.len
  while i < inputLength and inputData[i] <= ' ':
    inc i
  let j = i
  while i < inputLength and inputData[i] > ' ':
    inc i
  inputData.substr(j, i - 1)

proc scanInt(inputData: string, i: var int): int =
  let inputLength = inputData.len
  while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  var value = 0
  while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (int(inputData[i]) - firstDigitValue)
    inc i
  value

proc opcodeOf(token: string): int =
  case token[0]
  of 'A':
    opAnd
  of 'O':
    opOr
  of 'X':
    opXor
  of 'N':
    opNot
  of 'M':
    opMov
  of 'R':
    opRandom
  of 'J':
    if token[1] == 'Z': opJz else: opJmp
  of 'S':
    if token[1] == 'E': opSet else: opStop
  else:
    opStop

proc readProgram(inputData: string, i: var int): Program =
  let instructionCount = scanInt(inputData, i)
  result.opCodes = newSeq[int](instructionCount)
  result.firstArgs = newSeq[int](instructionCount)
  result.secondArgs = newSeq[int](instructionCount)
  for j in 0 ..< instructionCount:
    let mnemonic = scanToken(inputData, i)
    result.opCodes[j] = opcodeOf(mnemonic)
    case result.opCodes[j]
    of opAnd, opOr, opXor, opMov:
      result.firstArgs[j] = scanInt(inputData, i)
      result.secondArgs[j] = scanInt(inputData, i)
    of opNot, opRandom, opSet:
      result.firstArgs[j] = scanInt(inputData, i)
      if result.opCodes[j] == opSet:
        result.secondArgs[j] = scanInt(inputData, i)
    of opJmp:
      result.firstArgs[j] = scanInt(inputData, i)
    of opJz:
      result.firstArgs[j] = scanInt(inputData, i)
      result.secondArgs[j] = scanInt(inputData, i)
    else:
      discard

proc shortestRunningTime(program: Program): string =
  resetSolver()
  var states: seq[SearchState] = @[]
  var startState: SearchState
  startState.pc = 0
  startState.pathCond = trueNode
  startState.depth = 0
  for i in 0 ..< registerCount:
    startState.regs[i] = variableNode(i)
  discard rememberState(states, startState)
  states.add startState
  var j = 0
  while j < states.len:
    let current = states[j]
    let opcode = program.opCodes[current.pc]
    if opcode == opStop:
      return $(current.depth + 1)
    let firstArg = program.firstArgs[current.pc]
    let secondArg = program.secondArgs[current.pc]
    let nextDepth = current.depth + 1
    case opcode
    of opJz:
      let tested = current.regs[secondArg]
      pushState(states, firstArg, andNodes(current.pathCond, negateNode(tested)), nextDepth, current.regs)
      pushState(states, current.pc + 1, andNodes(current.pathCond, tested), nextDepth, current.regs)
    of opRandom:
      var zeroRegs = current.regs
      zeroRegs[firstArg] = falseNode
      pushState(states, current.pc + 1, current.pathCond, nextDepth, zeroRegs)
      var oneRegs = current.regs
      oneRegs[firstArg] = trueNode
      pushState(states, current.pc + 1, current.pathCond, nextDepth, oneRegs)
    of opJmp:
      pushState(states, firstArg, current.pathCond, nextDepth, current.regs)
    else:
      var nextRegs = current.regs
      case opcode
      of opAnd:
        nextRegs[firstArg] = andNodes(current.regs[firstArg], current.regs[secondArg])
      of opOr:
        nextRegs[firstArg] = orNodes(current.regs[firstArg], current.regs[secondArg])
      of opXor:
        nextRegs[firstArg] = xorNodes(current.regs[firstArg], current.regs[secondArg])
      of opNot:
        nextRegs[firstArg] = negateNode(current.regs[firstArg])
      of opMov:
        nextRegs[firstArg] = current.regs[secondArg]
      of opSet:
        nextRegs[firstArg] = secondArg
      else:
        discard
      pushState(states, current.pc + 1, current.pathCond, nextDepth, nextRegs)
    inc j
  "HANGS"

when isMainModule:
  var inputData = ""
  var line = ""
  while stdin.readLine(line):
    inputData.add line
    inputData.add '\n'
  nodeKeys = initTable[int64, int]()
  applyKeys = initTable[int64, int]()
  var i = 0
  let testCount = scanInt(inputData, i)
  var outputBuffer = ""
  for j in 0 ..< testCount:
    let program = readProgram(inputData, i)
    let answer = shortestRunningTime(program)
    outputBuffer.add answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
  stdout.write outputBuffer
  outputBuffer.setLen 0
