# EMTY2 — Can You Make It Empty 2 (SPOJ)

<https://www.spoj.com/problems/EMTY2/>

## Problem

Decide whether repeated deletion of the substring "100" can remove a binary string completely. Each deletion removes one 1 together with the two zeros that directly follow it.

Input starts with T, the number of cases. Each case is one string of characters 0 and 1. For each case print "Case k: yes" or "Case k: no", where k is the case number starting at one.

| item | bound |
|---|---|
| test cases T | at most 100 |
| string length | at most 120000 |
| judge limit | 1000 ms, 1536 MB |

Deletion joins the remaining parts, so a later deletion can use characters that were far apart earlier.

Sample input:

```
2
101000
1010001
```

Sample output:

```
Case 1: yes
Case 2: no
```

## Idea

Treat each 1 as an order for two zeros, like a queue of tickets that must be punched twice. A stack records how many punches each waiting 1 has received. Two zeros close one waiting 1 and pop it. The reduced string has a unique final form because two "100" blocks cannot overlap. A left-to-right scan finds that form in one pass. Repeated search and replace would rescan the string many times.

## Why It Works

1. The block "100" has no proper suffix equal to a proper prefix of itself.
2. Two occurrences of "100" in the same string are therefore disjoint.
3. Deleting one occurrence leaves the other unchanged, so the final form is unique.
4. A 1 adds a new stack entry that waits for its first zero.
5. The first zero changes that entry to wait for a second zero, and the second zero removes it.
6. A zero with no waiting 1 below it can never be removed and stays on the stack.
7. The string reduces to empty exactly when the stack ends empty.

| term | meaning |
|---|---|
| `stackStates` | state of each waiting character in the reduced prefix |
| `awaitingFirstZero` | a 1 that still needs two zeros |
| `awaitingSecondZero` | a 1 that has one zero and needs another |
| `unmatchedZero` | a zero that no earlier 1 can consume |
| `stackSize` | number of entries left in the reduced prefix |

For S = 101000, the scan reads 1, then 0, so the top waits for a second zero. The next 1 pushes a new entry. The next two zeros close that entry. The last zero closes the older entry, and `stackSize` reaches zero. For S = 1010001, one 1 remains and the answer is no.

The count of zeros equals twice the count of ones is necessary but not sufficient. The stack check gives the exact answer.

## Code

**Input and output scaffolding.** Tokens are read once, and answers leave the buffer in blocks.

```nim
const flushBlockBytes = 1 shl 17
const awaitingFirstZero = 0'i8
const awaitingSecondZero = 1'i8
const unmatchedZero = 2'i8

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The integer scanner reads the case count.
The token scanner returns each binary string as a slice of the input.
Both scanners share one cursor into `inputData`.

**Stack scan and report.** Each character updates the top entry or pushes a new one.

```nim
let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  let binaryText = nextToken(inputData, scanPos)
  var stackStates = newSeq[int8](binaryText.len)
  var stackSize = 0
  for characterIndex in 0 .. binaryText.len - 1:
    if binaryText[characterIndex] == '1':
      stackStates[stackSize] = awaitingFirstZero
      stackSize += 1
    elif stackSize > 0 and stackStates[stackSize - 1] == awaitingFirstZero:
      stackStates[stackSize - 1] = awaitingSecondZero
    elif stackSize > 0 and stackStates[stackSize - 1] == awaitingSecondZero:
      stackSize -= 1
    else:
      stackStates[stackSize] = unmatchedZero
      stackSize += 1
  appendOutput("Case " & $caseNumber & ": ")
  if stackSize == 0:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The stack array is allocated once per case at full string length.
A pop only lowers `stackSize`, so no shifting is needed.
One final flush writes all case lines.

## Complexity

Every character is read once and does constant work.

| phase | time | space |
|---|---|---|
| input read | one pass over all strings | one input string |
| stack scan | one step per character | one byte per character |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(total string length) |
| space | O(maximum string length) |

Repeated search and replace can rescan a long string thousands of times. The stack scan finishes in one pass.
