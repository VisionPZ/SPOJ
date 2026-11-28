# EXPRESS — Expressions (SPOJ)

<https://www.spoj.com/problems/EXPRESS/>

## Problem

Rewrite each postfix expression so a FIFO queue evaluator builds the same expression tree as the original stack evaluator. Operators and numbers stay single letters; only their order changes.

Input: a first line with T, then T lines, each one postfix expression. Output: one rewritten expression per line. Uppercase letters are operators; lowercase letters are numbers.

| item | bound |
|---|---|
| test cases T | at most 200 |
| expression length | under 10000 characters |
| judge limit | 3108 ms, 1536 MB |

Expression length drives the design, since each token is handled once.

Sample input:

```
2
xyPzwIM
abcABdefgCDEF
```

Sample output:

```
wzyxIPM
gfCecbDdAaEBF
```

The first input expression builds `(xPy)M(zIw)` with a stack.

## Idea

Reading a queue is like dealing cards from the top of a pile, so a new operation must consume older items first. Walk the expression tree from the root and prepend each pair of children before the tokens already collected. Record tokens on the way out, then reverse the record once at the end.

The algorithm parses child ranges in one forward pass with a stack of start positions. Each expansion step costs one token. A naive rewrite tries every permutation of the letters and takes factorial time.

Prepending child ranges keeps the queue order correct without rebuilding trees.

## Why It Works

1. A stack evaluator pops the right child first, then the left child, and writes `b O a`.
2. A queue evaluator pops the front item first, so the two children must appear in the opposite order.
3. The last token of the rewritten expression is always the root operator.
4. Before that token, the queue holds the right subtree ahead of the left subtree.
5. Expanding the root, then the pending items, produces every token in reverse order.
6. Reversing the record gives the unique valid rewrite.

| term | meaning |
|---|---|
| `leftBound` | start index of the left child of an operator |
| `rightBound` | start index of the right child of an operator |
| `pendingFront` | front index of the pending item list |
| `recorded` | tokens collected in processing order |

The four terms describe one parse pass and one expansion pass.

Here is the trace for `xyPzwIM` from `gen.py`:

| step | recorded token | pending items |
|---|---|---|
| root | M | zwI, xyP |
| left child | P | w, z, xyP |
| right child | I | w, z, x, y |
| leaves | w, z, y, x | none |

The reversed record is w z y x I P M, the sample output.

## Code

**Input and token scanning.** The reader loads stdin once and scans numbers and letter words by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not ((data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= 'A' and data[pos] <= 'Z')):
    pos += 1
  var word = ""
  while pos < data.len and ((data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= 'A' and data[pos] <= 'Z')):
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts only letters, so line breaks cannot merge expressions.
One buffer collects every output line.
Large output flushes in blocks.

**Range parse and token expansion.** The driver finds child ranges, then walks the pending list from its tail.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let expression = nextWord(inputData, scanPos)
  var leftBound = newSeq[int](expression.len)
  var rightBound = newSeq[int](expression.len)
  var parseStack = newSeq[int](expression.len)
  var parseTop = 0
  for charIndex in 0 .. expression.len - 1:
    if expression[charIndex] >= 'a':
      parseStack[parseTop] = charIndex
      parseTop += 1
    else:
      parseTop -= 1
      let rightStart = parseStack[parseTop]
      parseTop -= 1
      let leftStart = parseStack[parseTop]
      leftBound[charIndex] = leftStart
      rightBound[charIndex] = rightStart
      parseStack[parseTop] = leftStart
      parseTop += 1
  let capacity = 2 * expression.len + 10
  var pendingLeft = newSeq[int](capacity)
  var pendingRight = newSeq[int](capacity)
  var pendingFront = expression.len + 3
  var pendingBack = pendingFront
  pendingLeft[pendingFront] = 0
  pendingRight[pendingFront] = expression.len - 1
  pendingBack += 1
  var recorded = ""
  while pendingBack > pendingFront:
    pendingBack -= 1
    let pieceLeft = pendingLeft[pendingBack]
    let pieceRight = pendingRight[pendingBack]
    if pieceLeft == pieceRight:
      recorded.add expression[pieceLeft]
    else:
      let operatorIndex = pieceRight
      let rightStart = rightBound[operatorIndex]
      pendingFront -= 2
      pendingLeft[pendingFront] = rightStart
      pendingRight[pendingFront] = operatorIndex - 1
      pendingLeft[pendingFront + 1] = leftBound[operatorIndex]
      pendingRight[pendingFront + 1] = rightStart - 1
      recorded.add expression[operatorIndex]
  var rewritten = ""
  for tokenIndex in countdown(recorded.len - 1, 0):
    rewritten.add recorded[tokenIndex]
  appendOutput(rewritten)
  outputBuffer.add '\n'
```

The parse pass touches each token once.
New children go in front of older pending items.
The record reverses once, not per token.
The final flush writes the remaining buffer.

## Complexity

The work splits into one parse pass and one expansion pass per expression.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| child parse | one pass over tokens | two bound arrays |
| expansion | one step per token | two pending arrays |
| output | one write per block | block buffer |

Every phase grows linearly with expression length.

| measure | Big O |
|---|---|
| time | O(L) per expression |
| space | O(L) per expression |

Trying all token permutations would take factorial time, while this walk takes linear time.
The pending list and block buffer keep both passes fast for the longest expression.
