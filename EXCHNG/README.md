# EXCHNG — Exchanges (SPOJ)
<https://www.spoj.com/problems/EXCHNG/>

## Problem

A chip machine compares and swaps register values.
One broken instruction must not break the program that finds the minimum.

Read a compare-exchange program.
Instruction CE(a, b) with a < b puts the smaller of registers a and b into register a.
A program finds the minimum when register 1 always holds the smallest value.
It is reliable when deleting any single instruction still leaves a minimum-finding program.
Print the fewest appended instructions that make the program reliable.

Read `d` datasets. Each gives register count `n` and instruction count `m`, then `2m` register indices.
Print one answer per dataset.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Data sets `d` | 1 to 10 |
| Registers `n` | 2 to 10000 |
| Instructions `m` | 0 to 25000 |
| Time limit | 600 ms |
| Memory limit | 1536 MB |

The answer is at most 2(n - 1), so the output stays tiny.

The sample input and expected output follow verbatim.

```
1
3 3
1 2 2 3 1 2
```

```
2
```

The three-instruction sample needs two appended instructions.

## Idea

Track a token (a possible origin of the minimum) in each register, like marking every candidate ballot in a box.
Every register starts with its own token.
CE(a, b) moves all tokens from b into a and empties b.
The program finds the minimum when no token rests outside register 1.

A register holding a token after the original program needs two appended copies of CE(1, p).
A register holding a token only after deleting an original instruction needs one copy.
A forward pass counts the first kind, and a backward sweep counts the second.

Cost per instruction is constant work in each pass.
Searching every appended sequence and simulating every deletion takes exponential time.
Count stranded tokens forward, then trace deletion landings backward.

## Why It Works

Four facts prove the method.

1. Register a holds the smaller value after CE(a, b), so tokens move only from b to a.
2. Register 1 is never an upper operand, so its token never leaves.
3. Deleting CE(a, b) strands tokens that sat at b before that instruction.
   Those tokens then follow every later instruction from b.
4. The backward sweep keeps finalSlot[p], the final resting place of a token placed at p.
   Going backward past CE(a, b), finalSlot[b] becomes finalSlot[a].

The answer terms follow.

| Term | Meaning |
| --- | --- |
| `tokenCount[p]` | number of tokens currently in register p |
| `tokenBefore[l]` | whether the upper operand held a token before instruction l |
| `finalStranded` | registers with tokens after the original program |
| `extraCleanup` | extra registers stranded by one deletion |

The answer is `2 * finalStranded + extraCleanup`.

A script runs the forward pass and the backward sweep on the sample program.

```
| Instruction | Counts before | Token at upper | Counts after |
| --- | --- | --- | --- |
| CE(1,2) | [1, 1, 1] | yes | [2, 0, 1] |
| CE(2,3) | [2, 0, 1] | yes | [2, 1, 0] |
| CE(1,2) | [2, 1, 0] | yes | [3, 0, 0] |
no token rests outside register 1, so finalStranded = 0.

| Instruction | Landing slot | Adds cleanup | Slots after |
| --- | --- | --- | --- |
| CE(1,2) | 2 | yes | [1, 1, 3] |
| CE(2,3) | 3 | yes | [1, 1, 1] |
| CE(1,2) | 1 | no | [1, 1, 1] |
Both stranded registers get one cleanup copy, so answer = 0 + 2 = 2.
```

Two cleanup copies clear the two stranded registers.

## Code

**Integer scanner.**

```nim
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] < '0': inc i
  var value = 0
  while i < inputData.len and inputData[i] >= '0':
    value = value * 10 + (int(inputData[i]) - 48)
    inc i
  return value
```

The first loop stops at the next digit. The second loop consumes the digits. The scanner touches each input byte once.

**Bulk input.**

```nim
var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var i = 0
let dataSets = nextInt(inputData, i)
var outputBuffer = ""
```

Every input line is appended to one buffer. Parsing walks that buffer by index. The read cost is one pass over the bytes.

**Forward token pass.**

```nim
for j in 0 ..< dataSets:
  let registerCount = nextInt(inputData, i)
  let instructionCount = nextInt(inputData, i)

  var leftOperand = newSeq[int](instructionCount)
  var rightOperand = newSeq[int](instructionCount)
  var tokenBefore = newSeq[bool](instructionCount)
  var tokenCount = newSeq[int](registerCount + 1)
  for k in 1 .. registerCount: tokenCount[k] = 1

  for l in 0 ..< instructionCount:
    let lowerIndex = nextInt(inputData, i)
    let upperIndex = nextInt(inputData, i)
    leftOperand[l] = lowerIndex
    rightOperand[l] = upperIndex
    tokenBefore[l] = tokenCount[upperIndex] > 0
    tokenCount[lowerIndex] += tokenCount[upperIndex]
    tokenCount[upperIndex] = 0
```

The loop runs once per instruction. tokenBefore records the upper token count before the move. Tokens shift into the lower register, and the upper register empties. Each iteration costs O(1).

**Count and sweep backward.**

```nim
  var finalStranded = 0
  for k in 2 .. registerCount:
    if tokenCount[k] > 0: inc finalStranded

  var finalSlot = newSeq[int](registerCount + 1)
  for k in 0 .. registerCount: finalSlot[k] = k
  var needsCleanup = newSeq[bool](registerCount + 1)
  for k in 2 .. registerCount:
    if tokenCount[k] > 0: needsCleanup[k] = true

  var extraCleanup = 0
  var l = instructionCount - 1
  while l >= 0:
    let lowerIndex = leftOperand[l]
    let upperIndex = rightOperand[l]
    let landingSlot = finalSlot[upperIndex]
    if tokenBefore[l] and landingSlot > 1 and not needsCleanup[landingSlot]:
      needsCleanup[landingSlot] = true
      inc extraCleanup
    finalSlot[upperIndex] = finalSlot[lowerIndex]
    dec l
```

The first loop counts registers that still hold tokens. The backward pass reads landingSlot before overwriting finalSlot. Each new stranded landing adds one cleanup copy. Both loops cost O(m) or O(n).

**Answer and output.**

```nim
  let answer = 2 * finalStranded + extraCleanup
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each stranded final register needs two cleanup copies. Each deletion-only register needs one. One output buffer serves all datasets.

## Complexity

The phases and their costs for one dataset follow.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Forward pass | O(m) | O(n) tokens |
| Backward sweep | O(m) | O(n) slots |
| Output | O(1) | one output block |

Total time is O(m + n) per dataset.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(m + n) per dataset |
| Space | O(m + n) per dataset |

Searching every appended sequence and simulating deletions would take exponential time.
