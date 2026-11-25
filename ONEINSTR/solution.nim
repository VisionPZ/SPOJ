const flushBlockBytes = 1 shl 17
const firstInstructionPc = 9
const haltJump = 10000
const firstDataCell = 9000
const cellsPerInstruction = 3

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

type ValueSlot = object
  isConstant: bool
  constantValue: int
  memoryAddress: int
  holdsNegation: bool

var instructions: seq[array[3, int]] = @[]
var nextDataCell = firstDataCell
var constantCount = 0
var oneCell = -1
var jumpCell = -1

proc emitInstruction(firstValue: int, secondValue: int, jumpTarget: int): int =
  instructions.add([firstValue, secondValue, jumpTarget])
  return firstInstructionPc + cellsPerInstruction * (instructions.len - 1)

proc nextPc(): int =
  return firstInstructionPc + cellsPerInstruction * instructions.len

proc emitFlow(firstValue: int, secondValue: int): int =
  return emitInstruction(firstValue, secondValue, nextPc() + cellsPerInstruction)

proc allocateCell(): int =
  result = nextDataCell
  nextDataCell += 1

proc clearCell(targetCell: int) =
  discard emitFlow(targetCell, targetCell)

proc addConstant(targetCell: int, amount: int) =
  if amount != 0:
    discard emitFlow(-amount, targetCell)

proc loadConstantCell(value: int): int =
  let targetCell = allocateCell()
  clearCell(targetCell)
  addConstant(targetCell, value)
  return targetCell

proc subtractConstant(targetCell: int, amount: int) =
  if amount != 0:
    let sourceCell = loadConstantCell(amount)
    discard emitFlow(sourceCell, targetCell)

proc ensureOneCell() =
  if oneCell < 0:
    oneCell = allocateCell()
    clearCell(oneCell)
    addConstant(oneCell, 1)

proc ensureJumpCell() =
  if jumpCell < 0:
    jumpCell = allocateCell()

proc negateInto(sourceCell: int, targetCell: int) =
  clearCell(targetCell)
  discard emitFlow(sourceCell, targetCell)

proc copyPositive(sourceCell: int, targetCell: int) =
  let holdingCell = allocateCell()
  negateInto(sourceCell, holdingCell)
  clearCell(targetCell)
  discard emitFlow(holdingCell, targetCell)

proc addressSlot(cellIndex: int, negated: bool): ValueSlot =
  result.isConstant = false
  result.constantValue = 0
  result.memoryAddress = cellIndex
  result.holdsNegation = negated

proc constantSlot(value: int): ValueSlot =
  result.isConstant = true
  result.constantValue = value
  result.memoryAddress = -1
  result.holdsNegation = false

proc makePositive(slot: ValueSlot): ValueSlot =
  if slot.isConstant:
    return slot
  if not slot.holdsNegation:
    return slot
  let targetCell = allocateCell()
  negateInto(slot.memoryAddress, targetCell)
  return addressSlot(targetCell, false)

proc compileSubtract(left: ValueSlot, right: ValueSlot): ValueSlot =
  let positiveLeft = makePositive(left)
  let positiveRight = makePositive(right)
  if positiveLeft.isConstant and positiveRight.isConstant:
    let targetCell = allocateCell()
    clearCell(targetCell)
    addConstant(targetCell, positiveRight.constantValue)
    subtractConstant(targetCell, positiveLeft.constantValue)
    return addressSlot(targetCell, true)
  if positiveLeft.isConstant:
    subtractConstant(positiveRight.memoryAddress, positiveLeft.constantValue)
    return addressSlot(positiveRight.memoryAddress, true)
  if positiveRight.isConstant:
    let targetCell = allocateCell()
    clearCell(targetCell)
    addConstant(targetCell, positiveRight.constantValue)
    discard emitFlow(positiveLeft.memoryAddress, targetCell)
    return addressSlot(targetCell, true)
  discard emitFlow(positiveLeft.memoryAddress, positiveRight.memoryAddress)
  return addressSlot(positiveRight.memoryAddress, true)

proc compileAdd(left: ValueSlot, right: ValueSlot): ValueSlot =
  let positiveLeft = makePositive(left)
  let positiveRight = makePositive(right)
  let targetCell = allocateCell()
  clearCell(targetCell)
  if positiveLeft.isConstant:
    subtractConstant(targetCell, positiveLeft.constantValue)
  else:
    discard emitFlow(positiveLeft.memoryAddress, targetCell)
  if positiveRight.isConstant:
    subtractConstant(targetCell, positiveRight.constantValue)
  else:
    discard emitFlow(positiveRight.memoryAddress, targetCell)
  return addressSlot(targetCell, true)

proc compileMultiply(left: ValueSlot, right: ValueSlot): ValueSlot =
  let positiveLeft = makePositive(left)
  let positiveRight = makePositive(right)
  ensureOneCell()
  ensureJumpCell()
  let counterCell = allocateCell()
  let accumulatorCell = allocateCell()
  if positiveLeft.isConstant:
    clearCell(counterCell)
    addConstant(counterCell, positiveLeft.constantValue + 1)
  else:
    copyPositive(positiveLeft.memoryAddress, counterCell)
    addConstant(counterCell, 1)
  clearCell(accumulatorCell)
  let loopStart = nextPc()
  let decrementIndex = instructions.len
  discard emitInstruction(oneCell, counterCell, 0)
  if positiveRight.isConstant:
    subtractConstant(accumulatorCell, positiveRight.constantValue)
  else:
    discard emitFlow(positiveRight.memoryAddress, accumulatorCell)
  discard emitInstruction(jumpCell, jumpCell, loopStart)
  instructions[decrementIndex][2] = nextPc()
  return addressSlot(accumulatorCell, true)

proc compileDivide(left: ValueSlot, right: ValueSlot): ValueSlot =
  let positiveLeft = makePositive(left)
  let positiveRight = makePositive(right)
  if positiveLeft.isConstant and positiveLeft.constantValue == 0:
    return constantSlot(0)
  ensureOneCell()
  let workCell = allocateCell()
  let quotientCell = allocateCell()
  if positiveLeft.isConstant:
    clearCell(workCell)
    addConstant(workCell, positiveLeft.constantValue)
  else:
    copyPositive(positiveLeft.memoryAddress, workCell)
  clearCell(quotientCell)
  let checkCell = allocateCell()
  copyPositive(workCell, checkCell)
  addConstant(checkCell, 1)
  let emptyIndex = instructions.len
  discard emitInstruction(oneCell, checkCell, 0)
  discard emitFlow(oneCell, quotientCell)
  let divisorCell = if positiveRight.isConstant:
      loadConstantCell(positiveRight.constantValue)
    else:
      positiveRight.memoryAddress
  let loopStart = nextPc()
  let subtractIndex = instructions.len
  discard emitInstruction(divisorCell, workCell, 0)
  discard emitInstruction(oneCell, quotientCell, loopStart)
  let afterLoop = nextPc()
  instructions[emptyIndex][2] = afterLoop
  instructions[subtractIndex][2] = afterLoop
  return addressSlot(quotientCell, true)

proc finishExpression(resultSlot: ValueSlot) =
  if resultSlot.isConstant:
    if resultSlot.constantValue > 0:
      discard emitInstruction(-resultSlot.constantValue, 0, 0)
    return
  if resultSlot.holdsNegation:
    if resultSlot.memoryAddress == 0:
      let holdingCell = allocateCell()
      negateInto(0, holdingCell)
      discard emitFlow(holdingCell, 0)
    else:
      discard emitFlow(resultSlot.memoryAddress, 0)
    return
  if resultSlot.memoryAddress != 0:
    let holdingCell = allocateCell()
    negateInto(resultSlot.memoryAddress, holdingCell)
    discard emitFlow(holdingCell, 0)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc resetCompiler() =
  instructions = @[]
  nextDataCell = firstDataCell
  constantCount = 0
  oneCell = -1
  jumpCell = -1

proc tokenLength(data: string, startPos: int, endPos: int): int =
  var cursor = startPos
  while cursor < endPos and data[cursor] != ' ':
    cursor += 1
  return cursor - startPos

proc parseConstant(data: string, startPos: int, length: int): int =
  var value = 0
  for offset in 0 .. length - 1:
    value = value * 10 + int(data[startPos + offset]) - 48
  return value

proc compileLine(data: string, startPos: int, endPos: int) =
  resetCompiler()
  var tokenStarts: seq[int] = @[]
  var tokenEnds: seq[int] = @[]
  var tokenCursor = startPos
  while tokenCursor < endPos:
    while tokenCursor < endPos and inputData[tokenCursor] == ' ':
      tokenCursor += 1
    if tokenCursor >= endPos:
      break
    let tokenStart = tokenCursor
    tokenStarts.add tokenStart
    while tokenCursor < endPos and inputData[tokenCursor] != ' ':
      tokenCursor += 1
    tokenEnds.add tokenCursor
  let loneZeroVariable = tokenStarts.len == 1 and
      tokenEnds[0] - tokenStarts[0] == 2 and
      inputData[tokenStarts[0]] == 'M' and inputData[tokenStarts[0] + 1] == '0'
  var usesZeroInput = false
  for tokenIndex in 0 .. tokenStarts.len - 1:
    if tokenEnds[tokenIndex] - tokenStarts[tokenIndex] == 2 and
       inputData[tokenStarts[tokenIndex]] == 'M' and
       inputData[tokenStarts[tokenIndex] + 1] == '0':
      usesZeroInput = true
  var savedZeroCell = -1
  if usesZeroInput and not loneZeroVariable:
    savedZeroCell = allocateCell()
    copyPositive(0, savedZeroCell)
  if not loneZeroVariable:
    clearCell(0)
  var stack: seq[ValueSlot] = @[]
  var cursor = startPos
  while cursor < endPos:
    while cursor < endPos and data[cursor] == ' ':
      cursor += 1
    if cursor >= endPos:
      break
    let length = tokenLength(data, cursor, endPos)
    let tokenStart = cursor
    cursor += length
    if length == 1 and (data[tokenStart] == '+' or data[tokenStart] == '-' or
                        data[tokenStart] == '*' or data[tokenStart] == '/'):
      let rightSlot = stack[stack.len - 1]
      stack.setLen(stack.len - 1)
      let leftSlot = stack[stack.len - 1]
      stack.setLen(stack.len - 1)
      case data[tokenStart]
      of '+':
        stack.add compileAdd(leftSlot, rightSlot)
      of '-':
        stack.add compileSubtract(leftSlot, rightSlot)
      of '*':
        stack.add compileMultiply(leftSlot, rightSlot)
      of '/':
        stack.add compileDivide(leftSlot, rightSlot)
      else:
        discard
    elif data[tokenStart] == 'M':
      let variableIndex = int(data[tokenStart + 1]) - 48
      if variableIndex == 0 and savedZeroCell >= 0:
        stack.add addressSlot(savedZeroCell, false)
      else:
        stack.add addressSlot(variableIndex, false)
    else:
      constantCount += 1
      stack.add constantSlot(parseConstant(data, tokenStart, length))
  finishExpression(stack[stack.len - 1])
  let haltIndex = instructions.len
  discard emitInstruction(0, 0, haltJump)
  let haltCell = firstInstructionPc + cellsPerInstruction * instructions.len + constantCount
  instructions[haltIndex][0] = haltCell
  instructions[haltIndex][1] = haltCell
  appendOutput($instructions.len)
  outputBuffer.add '\n'
  for instruction in instructions:
    appendOutput($(instruction[0]) & " " & $(instruction[1]) & " " & $(instruction[2]))
    outputBuffer.add '\n'

var lineStart = 0
while lineStart < inputData.len:
  var lineEnd = lineStart
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  if lineEnd > lineStart:
    compileLine(inputData, lineStart, lineEnd)
  lineStart = lineEnd + 1
stdout.write outputBuffer
outputBuffer.setLen 0
