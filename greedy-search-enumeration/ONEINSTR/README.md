# ONEINSTR — One Instruction Computer Simulator (SPOJ)

<https://www.spoj.com/problems/ONEINSTR/>

## Problem

Translate each postfix arithmetic expression into machine code for a computer that has only `SUBLEQ A B C`. Print the instruction count and the program, one triple per line.

`SUBLEQ A B C` computes M[B] = M[B] - M[A] and jumps to `C` when the result is non-positive. A negative `A` makes the machine subtract that negative constant, which adds its magnitude. Memory cells 0 through 8 hold input and output, and the result belongs in `M0`. Input has one expression per line until end of input, with constants, `M0` through `M8`, and the operators + - * /.

| item | bound |
|---|---|
| arithmetic terms | at most 100 |
| operators | at most 99 |
| constants | 0 to 10000 |
| program limit | finish within 10 to the power of 7 cycles |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
100
M1 M2 -
```

Sample output:

```
3
0 0 12
-100 0 0
19 19 10000
4
0 0 12
1 2 15
2 0 18
21 21 10000
```

## Idea

Treat each stack entry as a memory address that holds either a value or its negative. One `SUBLEQ` then combines two operands, because subtracting one address from another leaves the negative of the desired result. A final negation stores the answer in `M0`. Multiplication and division use short loops that repeatedly subtract a constant, as a person counting by repeated subtraction would. A direct interpreter of the expression would not produce machine code, while the stack translation emits each instruction once.

The table gives the cost of one expression.

| item | bound |
|---|---|
| stack operations | one per token |
| loop body | constant instructions per cycle |

This cost shape keeps each emitted program short.

## Why It Works

1. `SUBLEQ A B C` reads `A` as an address when `A` is non-negative.
2. A negative `A` is an immediate constant, so -100 adds 100 to `M[B]`.
3. Clearing a cell uses the same address twice, since M[X] - M[X] is zero.
4. For operands `A` and `B`, one SUBLEQ A B leaves B - A, the negative of A - B.
5. Carrying negation through the stack lets addition and subtraction avoid extra copies.
6. Negating twice into a fresh cell restores a positive value when an operator needs one.
7. Multiplication repeats subtraction of the right operand with a counter initialized to the left operand plus one.
8. Division counts subtractions of the divisor from a working copy of the dividend.
9. The halt instruction clears a spare cell and jumps past the program to `10000`.

The table names the values used in the code.

| term | meaning |
|---|---|
| `instructions` | emitted triples in program order |
| `ValueSlot` | a constant or a memory address with a parity flag |
| `holdsNegation` | true when the addressed cell stores the negative |
| `counterCell` | loop counter for multiplication |
| `accumulatorCell` | running negative sum for multiplication |
| `quotientCell` | running negative quotient |
| `haltCell` | spare cell used by the final instruction |

Each emitted triple occupies three consecutive memory cells.

The worked example uses the second sample line, M1 M2 -, with M1 = 9 and M2 = 4. The simulator script reports the emitted program and the final output.

```
3: 0 0 12      clears M0
4: 1 2 15      M2 = 4 - 9 = -5
5: 2 0 18      M0 = 0 - (-5) = 5
6: 21 21 10000 clears a spare cell and halts
M0 = 5
```

The first sample line emits a clear and an immediate load of 100, giving the three instructions shown in the statement.

## Code

**Machine layout and emitters.** Constants describe the memory map, and small procedures append triples with forward jumps.

```nim
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
```

Program memory starts at cell 9 and data cells start at 9000. The flow emitter sets the jump target to the following instruction. A constant is stored in its own cell before subtraction.

**Value slots and stack operators.** A slot records whether its cell holds a negation, and the two simple operators emit a few instructions each.

```nim
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
```

A negated slot is flipped into a fresh cell when an operator needs a positive operand. Two address operands for subtraction need one instruction. Constants are folded into fresh cells when no input variable supplies them.

**Loop operators.** Multiplication counts down; division counts successful subtractions.

```nim
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
```

The counter starts one above the multiplier, so the loop body runs the right number of times. A zero dividend skips the division loop and returns zero. Loop targets are patched after the body is emitted.

**Finalization and driver.** The top stack value moves into `M0`, and a halt triple closes the program.

```nim
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
```

An immediate load writes a constant straight into `M0`. A negated address is flipped once to restore the positive result. The compiler state resets for each input line.

**Expression driver.** The driver splits one line into tokens, applies operators, and writes the program.

```nim
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
```

Token lengths are measured before parsing, so constants and variable names share one scanner.

```nim
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
```

`M0` is saved before the clear when the expression uses it as an input. The halt triple uses a spare address beyond the program. All instructions leave through the block writer.

## Complexity

Each token emits a bounded number of triples, and multiplication and division add one loop body.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| token translation | constant work per token | one stack and cell map |
| output | one write per block | block buffer |

The emitted instruction list is the largest working structure.

| measure | Big O |
|---|---|
| time | O(T) emitted instructions per expression |
| space | O(T) for the instruction list |

Simulating all possible programs would be unbounded, while translation emits one program per line.
