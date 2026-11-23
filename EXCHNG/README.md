## Problem

Read a compare-exchange program and report the fewest appended instructions that make it a reliable minimum-finding program.

An instruction CE(a, b) with a < b puts the smaller of r_a and r_b into r_a. A program finds the minimum when r1 always holds the smallest value. A program is reliable (tolerant of one deleted instruction) when removing any single instruction leaves a minimum-finding program. Print one answer per dataset.

The judge bounds keep each dataset inside one pass over the instructions.

| Quantity | Bound |
| --- | --- |
| Data sets d | 1 to 10 |
| Registers n | 2 to 10000 |
| Instructions m | 0 to 25000 |
| Time limit | 600 ms |
| Memory limit | 1536 MB |

The answer is at most 2(n - 1), so the output stays tiny.

## Idea

Track a token (a possible origin of the minimum) in each register. Every register starts with its own token. Instruction CE(a, b) moves all tokens from b into a and empties b. The program finds the minimum when no token rests outside register 1 at the end.

A register that holds a token after the original program needs two appended copies of CE(1, p). Deleting one copy must still clear that register. A register that holds a token only after deleting an original instruction needs one copy, since every original instruction then stays. A forward pass and a backward sweep count those registers.

Cost per instruction: O(1) work in each pass.

## Why It Works

Register a holds the smaller value after CE(a, b), so tokens move only from b to a. Register 1 is never an upper operand, so its token never leaves.

Deleting CE(a, b) strands the tokens that sat at b before that instruction. Those tokens stay at b and follow every later instruction from there.

The backward sweep keeps finalSlot[p], the final resting position of a token placed at p after the current instruction. Going backward past CE(a, b), a token at b moves to a first. Therefore finalSlot[b] becomes finalSlot[a].

The answer has two terms, one for each kind of stranded register.

| Term | Meaning |
| --- | --- |
| S | Registers p > 1 holding a token after the original program |
| E | Other registers holding a token after one original instruction is deleted |

Two copies of CE(1, p) clear a register in S even when one copy is deleted. One copy clears a register in E, because the deleted instruction is an original one and the appended copy survives.

The sample program CE(1, 2), CE(2, 3), CE(1, 2) produces this forward trace.

| Instruction | Counts before | Token at upper | Counts after |
| --- | --- | --- | --- |
| CE(1,2) | [1, 1, 1] | yes | [2, 0, 1] |
| CE(2,3) | [2, 0, 1] | yes | [2, 1, 0] |
| CE(1,2) | [2, 1, 0] | yes | [3, 0, 0] |

No token rests outside register 1, so S is empty.

The backward sweep visits the same instructions in reverse.

| Instruction | Landing slot | Adds cleanup | Slots after |
| --- | --- | --- | --- |
| CE(1,2) | 2 | yes | [1, 1, 3] |
| CE(2,3) | 3 | yes | [1, 1, 1] |
| CE(1,2) | 1 | no | [1, 1, 1] |

Both stranded registers get one cleanup copy, so the answer is two.

## Code

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] < '0': inc scanPos
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    value = value * 10 + (int(inputData[scanPos]) - 48)
    inc scanPos
  return value
```

The first loop stops at the first digit, and the second loop consumes the remaining digits. The character test uses `int(inputData[scanPos]) - 48`, which works on the judge compiler. The scanner touches each input byte once.

```nim
var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'
```

The loop runs once per input line, so it reads the whole stream before parsing. One buffer keeps the scanner independent of the stream layer. The loop copies O(total input bytes).

```nim
  for instrIndex in 0 ..< instructionCount:
    let lowerIndex = nextInt(inputData, scanPos)
    let upperIndex = nextInt(inputData, scanPos)
    leftOperand[instrIndex] = lowerIndex
    rightOperand[instrIndex] = upperIndex
    tokenBefore[instrIndex] = tokenCount[upperIndex] > 0
    tokenCount[lowerIndex] += tokenCount[upperIndex]
    tokenCount[upperIndex] = 0
```

The loop runs exactly m times, once per instruction. We record `tokenCount[upperIndex]` before clearing it, since the deletion question needs the old value. Each iteration costs O(1).

```nim
  var extraCleanup = 0
  var instrIndex = instructionCount - 1
  while instrIndex >= 0:
    let lowerIndex = leftOperand[instrIndex]
    let upperIndex = rightOperand[instrIndex]
    let landingSlot = finalSlot[upperIndex]
    if tokenBefore[instrIndex] and landingSlot > 1 and not needsCleanup[landingSlot]:
      needsCleanup[landingSlot] = true
      inc extraCleanup
    finalSlot[upperIndex] = finalSlot[lowerIndex]
    dec instrIndex
```

The loop runs exactly m times, from the last instruction down to the first. We read `landingSlot` before overwriting `finalSlot[upperIndex]`, so the landing value stays correct. Each iteration costs O(1).

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

The flush check runs once per dataset, so at most ten times. One buffer avoids a stream call for each answer. The final write emits any remaining bytes.

## Complexity

Reading and scanning take O(total input bytes). The forward pass and the backward sweep each take O(m) per dataset. Counting stranded registers takes O(n) per dataset. The total is O(m + n) per dataset.

Arrays for operands, token counts, and landing slots take O(m + n) space per dataset. The input buffer and the output buffer add O(input bytes) and O(1) space.

The big-O form is O(m + n) time and O(m + n) space per dataset. Searching every appended sequence and simulating every deleted instruction instead would take exponential time in the number of appended copies.
