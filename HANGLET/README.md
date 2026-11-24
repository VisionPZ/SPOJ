## Problem

Read a tiny assembly program that uses 32 one-bit registers. Registers start with arbitrary values, and RANDOM picks a free bit. Report the fewest cycles needed to reach STOP over every choice of starting values and random bits. Print HANGS when no run reaches STOP.

The judge bounds keep the program short but the state space large.

| Quantity | Bound |
| --- | --- |
| Registers | 32, one bit each |
| Instructions per program | 1 to 16 |
| Register index | 0 to 31 |
| Jump target | 0 to n - 1 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

No bound lets us list all 2^32 starting register settings.

## Idea

A state holds the program counter and 32 register values. We explore symbolic states instead of concrete ones. Each register holds a boolean formula over the 32 starting bits. We store formulas as reduced ordered binary decision diagrams, which merge equal subformulas. A path condition stores the tests taken so far. Breadth-first search visits symbolic states by cycle count. The first STOP gives the shortest time, and an exhausted queue gives HANGS.

Each symbolic state costs O(n) diagram operations, and n is at most 16.

## Why It Works

Each starting register becomes a free variable, so one symbolic step covers every concrete setting. Bitwise instructions map to diagram operations. NOT swaps the two children of every node. MOV copies a node. RANDOM picks a free constant, so we branch once with zero and once with one. A JZ adds the tested formula to one branch and its negation to the other. A branch with a false path condition is impossible, so we drop it. Diagrams keep correlations between repeated tests. For example, `x AND NOT x` reduces to false, which makes the second sample hang. An epoch hash table skips repeated states, so a cycle ends the search.

The branch condition uses this rule, with one term per line.

- jump branch: pathCond AND NOT tested
- fall branch: pathCond AND tested
- false result: skip the branch

A script generated the following trace from the first sample.

| Cycle | Instruction | Effect |
| --- | --- | --- |
| 1 | SET 0 1 | MEM[0] = 1 |
| 2 | JZ 4 0 | MEM[0] = 1, continue |
| 3 | RANDOM 0 | MEM[0] = 0, chosen branch |
| 4 | JMP 1 | jump to 1 |
| 5 | JZ 4 0 | MEM[0] = 0, jump to 4 |
| 6 | STOP | stop after 6 cycles |

The program reaches STOP at cycle 6.

## Code

The state record keeps the program counter, 32 formula nodes, the path condition, and the cycle count.

```
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
```

The loop bound is the fixed register count of 32. Storing nodes by index avoids a table lookup per register.

Negation reuses a cached answer per node. The recursion follows at most 32 levels, one per variable.

```
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
```

The cache lookup prevents repeated work on shared subformulas. A missing entry costs one node per level.

A JZ adds the negated test to the jump branch and the test itself to the fall branch. The push rejects a false path condition.

```
    of opJz:
      let tested = current.regs[secondArg]
      pushState(states, firstArg, andNodes(current.pathCond, negateNode(tested)), nextDepth, current.regs)
      pushState(states, current.pc + 1, andNodes(current.pathCond, tested), nextDepth, current.regs)
```

Each branch adds one diagram operation. The two pushes add at most two states for this instruction.

RANDOM branches on a free constant. One state stores zero in the target, and the other stores one.

```
    of opRandom:
      var zeroRegs = current.regs
      zeroRegs[firstArg] = falseNode
      pushState(states, current.pc + 1, current.pathCond, nextDepth, zeroRegs)
      var oneRegs = current.regs
      oneRegs[firstArg] = trueNode
      pushState(states, current.pc + 1, current.pathCond, nextDepth, oneRegs)
```

Copying the register array costs 32 assignments. Both branches share the current path condition.

The main loop reads all input once, scans tokens by hand, and flushes output in blocks.

```
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
```

The loop bound is the case count from the first token. Block flushing keeps write calls rare.

## Complexity

Parsing one program reads at most 16 instruction lines and costs O(n) work. BDD setup creates 32 variable nodes once per case. The search visits at most S symbolic states, and each state does O(n) diagram work. Random trials with n up to 16 stayed below 1000 states, so S stays small in practice. Total time per case is O(n * S), and total space is O(32 * S) plus the diagram node table.

A naive search would enumerate 2^32 starting register settings and simulate each one. That approach cannot finish within the limit.
