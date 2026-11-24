## Problem

Read a program of assignments over 26 registers and four binary operations. Each instruction gives an operation, two source registers, and a destination register. Print the fewest gates in an acyclic circuit that produces every final register value from the initial values.

| Quantity | Bound |
| --- | --- |
| Registers | 26 |
| Operations | 4 |
| Instructions per case | 1000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Every final value is a function of the 26 initial values, so the circuit needs no state.

## Idea

The program names each value by the operation and the two earlier values that made it. Store that triple in a hash table so equal triples share one node. Dead instructions then cost no gates, and repeated work costs one gate. A naive circuit gives each instruction its own gate and keeps values that no final register uses.

Cost: one hash probe per instruction and one visit per reachable node.

## Why It Works

A gate reads initial register values or earlier gate outputs. Each gate output is therefore an expression over the initial registers. Two expressions with the same operation and the same operand value IDs compute the same function. One gate can drive both uses. A value that no final register reaches needs no gate.

`packed` holds the four fields in base 26.

- `destination = packed mod registerCount` gives the written register.
- `sourceTwo = (packed div registerCount) mod registerCount` gives the second input.
- `sourceOne = (packed div (registerCount * registerCount)) mod registerCount` gives the first input.
- `operation = packed div (registerCount * registerCount * registerCount)` gives the operation.

The generator prints this trace for the sample.

```
Afbc  A(v5,v1) -> v26  new
Bfbd  B(v5,v1) -> v27  new
Cddd  C(v27,v27) -> v28  new
Bcbc  B(v26,v1) -> v29  new
Afcc  A(v5,v29) -> v30  new
Afbf  A(v5,v1) -> v26  reuse
Cfbb  C(v26,v1) -> v32  new
Dfdb  D(v26,v28) -> v33  new
final: b=v33 c=v30 d=v28 f=v26
gates: 6
```

The sixth instruction reuses v26, and the missing v31 shows that a repeated triple creates no node.

## Code

```nim
const firstDigitValue = 48
const firstUpperValue = 65
const firstLowerValue = 97
const registerCount = 26
const leaveCount = 26
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextInstruction(data: string, position: var int): int =
  while position < data.len and (data[position] < 'A' or data[position] > 'D'):
    position += 1
  var packed = int(data[position]) - firstUpperValue
  position += 1
  for l in 0..2:
    while position < data.len and (data[position] < 'a' or data[position] > 'z'):
      position += 1
    packed = packed * registerCount + (int(data[position]) - firstLowerValue)
    position += 1
  return packed

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop runs once per input line. The scanners skip blank lines between cases. The output buffer flushes at 256 KiB. Cost: one pass over the input bytes.

```nim
let caseCount = nextInt(inputData, scanPos)
var registerValue = newSeq[int](registerCount)
var nodeOperation = newSeq[int](0)
var nodeLeft = newSeq[int](0)
var nodeRight = newSeq[int](0)
var hashSlots = newSeq[int](0)
var visited = newSeq[bool](0)
var pending = newSeq[int](0)

for i in 0..<caseCount:
  let instructionCount = nextInt(inputData, scanPos)

  for k in 0..<registerCount:
    registerValue[k] = k

  nodeOperation.setLen(0)
  nodeLeft.setLen(0)
  nodeRight.setLen(0)
  for k in 0..<leaveCount:
    nodeOperation.add(-1)
    nodeLeft.add(-1)
    nodeRight.add(-1)

  var hashSize = 1
  while hashSize < (instructionCount + leaveCount) * 4:
    hashSize = hashSize shl 1
  let hashMask = hashSize - 1
  hashSlots.setLen(hashSize)
  for k in 0..<hashSize:
    hashSlots[k] = 0

  for j in 0..<instructionCount:
    let packed = nextInstruction(inputData, scanPos)
    let destination = packed mod registerCount
    let sourceTwo = (packed div registerCount) mod registerCount
    let sourceOne = (packed div (registerCount * registerCount)) mod registerCount
    let operation = packed div (registerCount * registerCount * registerCount)
    let leftValue = registerValue[sourceOne]
    let rightValue = registerValue[sourceTwo]

    var slot = ((operation * 73856093) xor (leftValue * 19349663) xor (rightValue * 83492791)) and hashMask
    var found = -1
    while hashSlots[slot] != 0:
      let candidate = hashSlots[slot] - 1
      if nodeOperation[candidate] == operation and nodeLeft[candidate] == leftValue and nodeRight[candidate] == rightValue:
        found = candidate
        break
      slot = (slot + 1) and hashMask
    if found < 0:
      found = nodeOperation.len
      nodeOperation.add operation
      nodeLeft.add leftValue
      nodeRight.add rightValue
      hashSlots[slot] = found + 1
    registerValue[destination] = found
```

The instruction loop runs instructionCount times. Slot zero means empty, so stored IDs start above zero. The table stays at least a quarter empty, which bounds each probe. Cost: constant time per instruction.

```nim
  visited.setLen(nodeOperation.len)
  for k in 0..<visited.len:
    visited[k] = false
  pending.setLen(0)
  for k in 0..<registerCount:
    let valueId = registerValue[k]
    if not visited[valueId]:
      visited[valueId] = true
      pending.add valueId
  var gateCount = 0
  while pending.len > 0:
    let currentNode = pending[pending.len - 1]
    pending.setLen(pending.len - 1)
    if currentNode >= leaveCount:
      gateCount += 1
      let leftChild = nodeLeft[currentNode]
      let rightChild = nodeRight[currentNode]
      if not visited[leftChild]:
        visited[leftChild] = true
        pending.add leftChild
      if not visited[rightChild]:
        visited[rightChild] = true
        pending.add rightChild

  appendOutput($(gateCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The walk visits each reachable node once. Leaf IDs below 26 are circuit inputs and add no gate. The final write flushes the remaining bytes. Cost: one visit per node.

## Complexity

Input reading stores the stream once, using time and space linear in the input size. Hash consing uses O(n) time and O(n) space per case, where n is the instruction count. The final walk uses O(n) time and O(n) space. The total is O(n) per case plus the shared input buffer.

A naive circuit builds one gate per instruction, so it uses O(n) gates and keeps values that no final register needs.
