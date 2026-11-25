# PG10181 — Beca Grado 10 (SPOJ)
<https://www.spoj.com/problems/PG10181/>

## Problem

Two lines list students who passed two exams. Print the codes appearing on both lines, in ascending order.

Each line starts with its code count, followed by that many codes. Codes lie from 1 to 10000 and never repeat within a line.

| Item | Value |
|---|---|
| Input | two lines: count and codes per line |
| Output | shared codes, ascending, on one line |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The small code range allows a direct scan instead of sorting.

The statement sample follows verbatim.

```
4 101 309 499 333
3 499 66 101
```

```
101 499
```

A second statement sample uses the same format.

```
3 6 999 12
3 12 123 9
```

```
12
```

## Idea

Think of two guest lists laid side by side; a name earns a place only when both lists contain it.
The program marks each list in a boolean table indexed by code.
It then walks codes from 1 to 10000 and writes the marked ones.
Hash set intersection would also work but needs extra storage and a sort.

The index walk already produces ascending order.

## Why It Works

1. A boolean table records membership for one exam line.
2. A code is shared only when both tables hold true.
3. Walking codes in increasing order emits sorted output.
4. Duplicate codes are impossible by the statement, so one mark suffices.
5. Codes outside 1 to 10000 are ignored by the bounds check.

| Term | Meaning |
|---|---|
| mark | a true entry in a membership table |
| shared code | a code marked in both tables |
| index walk | visiting codes from 1 up to 10000 |

The table explains the direct route to sorted output.

A script trace of the first sample compares the two lists.

```
knowledge exam: [101, 309, 333, 499]
english exam: [66, 101, 499]
shared codes: [101, 499]
```

The shared codes match the first sample output.

## Code

**Membership marking.**
```nim
let knowledgeCount = nextInt(inputData, scanPos)
for index in 0..<knowledgeCount:
  let code = nextInt(inputData, scanPos)
  if code >= 1 and code <= maxCode:
    seenInKnowledge[code] = true

let englishCount = nextInt(inputData, scanPos)
for index in 0..<englishCount:
  let code = nextInt(inputData, scanPos)
  if code >= 1 and code <= maxCode:
    seenInEnglish[code] = true
```

Counts are read before their codes. Invalid codes are skipped by the bounds check.

**Table setup.**
```nim
var seenInKnowledge = newSeq[bool](maxCode + 1)
var seenInEnglish = newSeq[bool](maxCode + 1)
```

Two tables start with all false entries. Each line fills its own table.

**Ordered output.**
```nim
var firstCodeWritten = true
for code in 1..maxCode:
  if seenInKnowledge[code] and seenInEnglish[code]:
    if not firstCodeWritten:
      outputBuffer.add ' '
    firstCodeWritten = false
    appendOutput($(code))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The walk emits each shared code once. Spaces separate codes, and a newline ends the line.

## Complexity

Marking and the final walk dominate the work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Marking | O(codes on each line) | two boolean tables |
| Index walk | O(10000) | constant |
| Output | one write per block | buffer block |

Both phases are linear in their own input size.

| Measure | Big O |
|---|---|
| Time | O(input bytes + 10000) |
| Space | O(10000) |

Sorting a set intersection would cost O(n log n), so the bounded walk wins.
