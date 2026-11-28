# DYZIO — Dyzio (SPOJ)

<https://www.spoj.com/problems/DYZIO/>

## Problem

The input encodes a rope-cutting procedure as a word of `0` and `1`, where a `1` cuts a piece in half.
For each word, count the cuts made before the first shortest piece is cut off.

Input holds ten cases, one after another. Each case gives a length `n` and a word of `n` symbols.

A `1` cuts a piece in half, then describes the left half and the right half. A `0` leaves a piece whole. Print the number of cuts before the first shortest piece is cut off.

| item | bound |
|---|---|
| test cases | 10 |
| word length `n` | 1 ≤ n ≤ 20000 |
| symbols | `0` and `1` only |
| answer | at most `n` |
| judge limits | 1903 ms, 1536 MB |

The bounds let one pass handle each case.

Sample input:

```
9
110011000
```

Sample output:

```
4
```

## Idea

Parse the word into a cut tree, and give each subtree three numbers: total cuts, deepest leaf, and cuts to the first deepest leaf. Each node costs constant work, since the two child reports combine in one step. The naive way cuts pieces one at a time and cannot know which leaf is shortest until every cut is done.

## Why It Works

A `0` consumes one symbol and adds no cut. A `1` consumes itself and the whole left subtree, then the whole right subtree. So each child owns a prefix of the word, and parsing left to right needs no search.

A leaf at depth `d` has length `L / 2^d`. The shortest leaf has the largest depth. Cutting visits the left child before the right child, so a right subtree waits until the left subtree is fully cut.

A subtree combines its two child reports with these lines:

| term | meaning |
|---|---|
| `totalCuts` | one for this cut, plus both child totals |
| `maxDepth` | one plus the larger child depth |
| `1 + leftInfo.firstCuts` | the deepest leaf is in the left child |
| `1 + leftInfo.totalCuts + rightInfo.firstCuts` | the deepest leaf is in the right child, after the left child is cut |

A tie goes to the left child, since the left child is cut first.

The word `110011000` shows the order:

```text
pos:  0 1 2 3 4 5 6 7 8
word: 1 1 0 0 1 1 0 0 0
action   pos  depth  cuts done
cut       0      0          1
cut       1      1          2
leaf      2      2          2
leaf      3      2          2
cut       4      1          3
cut       5      2          4
leaf      6      3          4
leaf      7      3          4
leaf      8      2          4
deepest leaves are at depth 3 and the first one is cut off after 4 cuts
```

The deepest leaves sit at positions 6 and 7, and the first one is cut off after 4 cuts.

## Code

`flushBlockBytes` is the 128 KiB write block. `TreeInfo` is the three-number report from one subtree. The block costs nothing at run time.

```nim
const flushBlockBytes = 1 shl 17

type
  TreeInfo = object
    totalCuts: int
    maxDepth: int
    firstCuts: int
```

The first loop ends at the first non-digit or at the buffer end. `i` is a `var` parameter, so the position survives the call. A digit byte minus 48 gives its value. The cost is one pass over the digits.

```nim
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

`i` ends at the first symbol outside the word. The word is a slice of `inputData`, so no copy is made. The cost is one pass over the word.

```nim
proc nextBitWordStart(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  let wordStart = i
  while i < inputData.len and (inputData[i] == '0' or inputData[i] == '1'):
    i = i + 1
  return wordStart
```

The `>=` sends a tie to the left child, which is cut first. `wordEnd` keeps a missing child from reading the next case. One node costs one call plus two child reports.

```nim
proc parseSubtree(inputData: string, wordEnd: int, i: var int): TreeInfo =
  if i >= wordEnd or inputData[i] == '0':
    if i < wordEnd: i = i + 1
    return TreeInfo(totalCuts: 0, maxDepth: 0, firstCuts: 0)
  i = i + 1
  let leftInfo = parseSubtree(inputData, wordEnd, i)
  let rightInfo = parseSubtree(inputData, wordEnd, i)
  result.totalCuts = 1 + leftInfo.totalCuts + rightInfo.totalCuts
  result.maxDepth = 1 + max(leftInfo.maxDepth, rightInfo.maxDepth)
  if leftInfo.maxDepth >= rightInfo.maxDepth:
    result.firstCuts = 1 + leftInfo.firstCuts
  else:
    result.firstCuts = 1 + leftInfo.totalCuts + rightInfo.firstCuts
```

The read loop ends at end of input. A zero length ends the case loop, since lengths are at least one. `setLen 0` reuses the same output allocation. The final write covers the tail.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var outputBuffer: string
while true:
  let declaredLength = nextInt(inputData, i)
  if declaredLength == 0: break
  let wordStart = nextBitWordStart(inputData, i)
  var j = wordStart
  let wordEnd = i
  let subtreeInfo = parseSubtree(inputData, wordEnd, j)
  outputBuffer.add $subtreeInfo.firstCuts
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

## Complexity

The work splits into input, one recursive pass per case, and output:

| phase | time | space |
|---|---|---|
| input read | one pass over each line, then one pass over each token | input bytes |
| one case | one call per `1`, constant work per call | depth at most `n` |
| output write | one `write` per 128 KiB block | 128 KiB |
| ten cases of length 20000 | 200000 calls | 200000 input bytes plus 128 KiB |

The recursion depth equals the longest chain of cuts, which is at most `n`.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(n) worst-case depth |

A literal simulation stores every leaf and scans them to find the deepest one, using two passes and O(n) extra space. The recursion returns all three numbers in one pass and stores none of the leaves.
