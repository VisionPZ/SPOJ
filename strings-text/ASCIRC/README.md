# ASCIRC — Assembler Circuits (SPOJ)
<https://www.spoj.com/problems/ASCIRC/>

## Problem

Each case gives a sequence of register assignments using four elementary operations.
Find the fewest gates in an acyclic circuit that produces the same final register values.

The first line gives the case count. Each case gives n, then n four-letter instructions with an operation A, B, C, or D and three register letters. Print the minimal gate count.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Instructions n | 1 to 1000 |
| Registers | up to 26 |
| Operations | A, B, C, D |
| Judge time | 1 s |
| Judge memory | 1536 MB |

The small register set keeps each instruction lookup constant.

The sample input and its expected output follow byte for byte.

```
1
8
Afbc
Bfbd
Cddd
Bcbc
Afcc
Afbf
Cfbb
Dfdb
```

```
6
```


## Idea

Build one expression tree per register and share identical subtrees, like reusing the same prebuilt brick wherever a pattern repeats.
The program starts with 26 leaf nodes (plain register inputs) for the input registers. Each instruction becomes a node keyed by its operation and the two source node ids. A hash table finds an existing equal node, so duplicate work maps to one gate.
A depth-first walk from the final 26 register values counts reachable non-leaf nodes. Counting instructions directly would miss this sharing and overstate the cost.
Hash-consing turns a program into a compact shared circuit in linear expected time.

## Why It Works

1. Each register holds a node id, so an instruction either creates one node or reuses a matching one.
2. `nextInstruction` packs the operation and three register letters into a single integer.
3. The hash key combines the operation with the two source node ids, so equal work shares one gate.
4. A stack walk from all 26 final register values visits exactly the nodes the circuit needs.
5. Leaf nodes are plain register inputs and never add to the gate count.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| leaf | register input node with no gate |
| node | one operation applied to two source nodes |
| hash key | packed operation and node pair |
| reachable | needed by some final register value |

They explain how repeated expressions collapse to one gate.

A script check of the sample reads 8 instructions and 26 leaves.
The first instruction `Afbc` builds node (A, node f, node b) and stores it in register c.
The reachability walk ends at 6 gate nodes, which is the printed answer.

## Code

**Instruction packer.**
```nim
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
```

The packer scans for the next uppercase operation. Three lowercase letters are folded into the same integer. One packed value carries the whole instruction.

**Per-case setup.**
```nim
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
```

The code seeds 26 leaf nodes and clears the hash slots. The table size grows to a power of two. Each register starts as its own leaf id.

**Node hash-consing.**
```nim
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

The code decodes the destination, sources, and operation. A linear probe finds an equal node or inserts a new one. Equal subexpressions therefore share one gate.

**Reachability count.**
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
```

The walk starts from all 26 final register values. Leaves are skipped, and each new gate adds one to the count. Visited flags stop a node from being counted twice.


## Complexity

Every instruction does one expected-constant hash lookup and one stack step.

| Phase | Time | Space |
| --- | --- | --- |
| input parse | O(n) | one buffer |
| node hash-consing | O(n) expected | node arrays plus hash |
| reachability walk | O(n) | visited flags and stack |

All arrays grow once per case and are reused on later cases.

Big O uses instruction count n.

| Measure | Big O |
| --- | --- |
| time | O(n) expected per case |
| space | O(n) |

Counting instructions without sharing would report more gates than the circuit needs.
