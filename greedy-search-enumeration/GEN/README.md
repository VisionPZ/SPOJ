# GEN — Text Generator (SPOJ)

<https://www.spoj.com/problems/GEN/>

## Problem

Count strings of length `L` over the 26 uppercase letters that contain at least one known word.
Print the count modulo 10007 for each test case.

Each test case starts with `N L`, where `N` is between 1 and 10 and `L` is between 1 and 1000000.
The next `N` lines each hold one uppercase word of length at most 6.
Input ends at EOF, and a word may appear more than once in the list.

| Item | Bound |
|---|---|
| Known words N | 1 to 10 |
| Article length L | 1 to 1000000 |
| Word length | 1 to 6 uppercase letters |
| Output modulus | 10007 |
| Judge limit | 1386 ms, 1536 MB |

A string is readable when at least one known word occurs as a substring anywhere inside it.

Sample input:

```
2 2
A
B
2 10000
ABC
B
```

Sample output:

```
100
5960
```

## Idea

Treat matching as a museum turnstile: once a visitor sees an exhibit, they join the counted crowd forever.
Build an Aho-Corasick automaton whose states remember the current matching prefix.
Make any state that completes a word jump to one absorbing state, then count paths of length `L`.
Fast exponentiation applies the transition matrix in O(log L) matrix products.
Listing all strings would take 26 to the power of `L` steps, which cannot work.

## Why It Works

1. A state records the longest suffix of the text that is also a prefix of a known word.
2. Failure links send a state to the next shorter matching prefix after a letter.
3. A state that completes a word moves to the absorbing state for every later letter.
4. Each matrix entry counts how many letters lead from one state to another state.
5. Raising the matrix to the power `L` counts all paths of exactly `L` letters.
6. The absorbing column after that power is the number of readable strings, modulo 10007.
7. There are at most 61 trie states plus the absorbing state, so each product is small.

| Term | Meaning |
|---|---|
| `transitionTable` | trie edges and completed failure transitions |
| `wordEnds` | marks states where a known word finishes |
| `transitionMatrix` | letter counts between automaton states |
| `stateVector` | path counts after the processed number of letters |
| `stateCount` | number of trie states before the absorbing state |

With words A and B and length 2, there are 676 strings in total.
Unreadable strings use the other 24 letters twice, giving 576 strings.
The difference is 100, matching the first sample answer.
With words ABC and B, an unreadable string cannot contain B at all, leaving 25 choices per letter.
The difference 26 to the power of 10000 minus 25 to the power of 10000 is 5960 modulo 10007.

Products use `int64` accumulation before reduction by `moduloBase`.
The absorbing row keeps all 26 letters so readable paths stay counted.

## Code

**Input and hand scanners.** The reader loads all text once and parses integers and uppercase words.

```nim
import sequtils

const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const moduloBase = 10007

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  result = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    result.add data[pos]
    pos += 1

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false
```

`nextWord` skips separators and collects uppercase letters.
`hasDigits` detects the end of input.
`moduloBase` is the required modulus.

**Buffered output and matrix helpers.** Block writes reduce system calls, and flat arrays store matrices.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyMatrices(left: seq[int], size: int): seq[int] =
  result = newSeq[int](size * size)
  for rowIndex in 0 .. size - 1:
    for middleIndex in 0 .. size - 1:
      let leftValue = left[rowIndex * size + middleIndex]
      if leftValue == 0:
        continue
      for columnIndex in 0 .. size - 1:
        let rightValue = left[middleIndex * size + columnIndex]
        if rightValue == 0:
          continue
        let cellIndex = rowIndex * size + columnIndex
        result[cellIndex] = (result[cellIndex] + leftValue * rightValue) mod moduloBase
  return result

proc multiplyVectorMatrix(stateVector: seq[int], matrix: seq[int], size: int): seq[int] =
  result = newSeq[int](size)
  for columnIndex in 0 .. size - 1:
    var total: int64 = 0
    for rowIndex in 0 .. size - 1:
      total += int64(stateVector[rowIndex]) * int64(matrix[rowIndex * size + columnIndex])
    result[columnIndex] = int(total mod int64(moduloBase))
  return result
```

`multiplyMatrices` composes two transition powers.
`multiplyVectorMatrix` advances the path counts by one power.
Zero entries are skipped to save work.

**Automaton construction.** Known words form a trie, and a queue fills failure transitions.

```nim
while hasDigits(inputData, scanPos):
  let wordCount = nextInt(inputData, scanPos)
  let articleLength = nextInt(inputData, scanPos)
  var transitionTable: seq[seq[int]] = @[]
  var failLinks: seq[int] = @[]
  var wordEnds: seq[bool] = @[]
  transitionTable.add repeat(-1, alphabetSize)
  failLinks.add 0
  wordEnds.add false
  for wordIndex in 0 .. wordCount - 1:
    let knownWord = nextWord(inputData, scanPos)
    var nodeIndex = 0
    for character in knownWord:
      let letterIndex = int(character) - 65
      if transitionTable[nodeIndex][letterIndex] == -1:
        transitionTable[nodeIndex][letterIndex] = transitionTable.len
        transitionTable.add repeat(-1, alphabetSize)
        failLinks.add 0
        wordEnds.add false
      nodeIndex = transitionTable[nodeIndex][letterIndex]
    wordEnds[nodeIndex] = true
  var automatonQueue: seq[int] = @[]
  for letterIndex in 0 .. alphabetSize - 1:
    let childNode = transitionTable[0][letterIndex]
    if childNode == -1:
      transitionTable[0][letterIndex] = 0
    else:
      failLinks[childNode] = 0
      automatonQueue.add childNode
  var queueFront = 0
  while queueFront < automatonQueue.len:
    let nodeIndex = automatonQueue[queueFront]
    queueFront += 1
    if wordEnds[failLinks[nodeIndex]]:
      wordEnds[nodeIndex] = true
    for letterIndex in 0 .. alphabetSize - 1:
      let childNode = transitionTable[nodeIndex][letterIndex]
      if childNode == -1:
        transitionTable[nodeIndex][letterIndex] = transitionTable[failLinks[nodeIndex]][letterIndex]
      else:
        failLinks[childNode] = transitionTable[failLinks[nodeIndex]][letterIndex]
        automatonQueue.add childNode
```

`wordEnds` propagates from a failure target to its children.
Every missing trie edge gets a valid destination during the queue pass.
The automaton then has exactly one edge per state and letter.

**Power and answer.** The transition matrix counts paths, and binary exponentiation reaches length `L`.

```nim
  let stateCount = transitionTable.len
  let matrixSize = stateCount + 1
  var transitionMatrix = newSeq[int](matrixSize * matrixSize)
  for stateIndex in 0 .. stateCount - 1:
    if wordEnds[stateIndex]:
      continue
    for letterIndex in 0 .. alphabetSize - 1:
      let destination = transitionTable[stateIndex][letterIndex]
      if wordEnds[destination]:
        transitionMatrix[stateIndex * matrixSize + stateCount] += 1
      else:
        transitionMatrix[stateIndex * matrixSize + destination] += 1
  transitionMatrix[stateCount * matrixSize + stateCount] = alphabetSize
  var stateVector = newSeq[int](matrixSize)
  stateVector[0] = 1
  var remainingLength = articleLength
  while remainingLength > 0:
    if (remainingLength and 1) != 0:
      stateVector = multiplyVectorMatrix(stateVector, transitionMatrix, matrixSize)
    remainingLength = remainingLength shr 1
    if remainingLength > 0:
      transitionMatrix = multiplyMatrices(transitionMatrix, matrixSize)
  appendOutput($stateVector[stateCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last matrix row keeps readable strings inside the absorbing state.
`stateVector` starts at the root with count one.
The final entry is the readable count, written through `appendOutput`.

## Complexity

Each test case builds one automaton and raises one small matrix to the article length.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over words | one input string |
| Automaton build | letters times alphabet size | states times alphabet size |
| Matrix power | logarithm of L products | one square matrix |
| Output | one line per case | one block buffer |

| Measure | Big O |
|---|---|
| Time per case | O(S cubed times log L) |
| Space per case | O(S squared) |

Enumerating all articles takes exponential time in `L`.
The matrix power replaces that enumeration with a few products of a matrix of size at most 62.
