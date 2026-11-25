# ORDERS — Ordering the Soldiers (SPOJ)
<https://www.spoj.com/problems/ORDERS/>

## Problem

Soldiers stand in an unknown line, and each one remembers how many superiors he passed. The sergeant must rebuild the original rank order.

The input starts with the case count. Each case gives a soldier count and one walk distance per soldier. Print the ranks from left to right.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Cases | at most 50 |
| Soldiers `n` | 1 to 200000 |
| Walk distance | 0 to `n - 1` |
| Judge time | 13000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

Large input and output need buffered IO.

Sample input and output:

Input:

```
2
3
0 1 0
5
0 1 2 0 1
```

Output:

```
2 1 3
3 2 1 5 4
```

## Idea

Fill the ranks from right to left, taking the next free rank that fits. Think of dealing numbered cards backward, skipping the cards already spoken for.

The program uses a Fenwick tree (an indexed tree of partial counts) over free ranks. Binary lifting (jumping by powers of two) finds the k-th free rank in logarithmic steps. Each soldier costs O(log n). Rebuilding the sorted free list after every soldier would cost O(n^2).

Takeaway: a count tree turns rank selection into a short jump.

## Why It Works

Walk distances determine ranks uniquely.

1. A soldier with `wi` superiors to his left has `wi` higher ranks among positions `0..i`.
2. When filling right to left, exactly `i + 1` ranks remain free.
3. The target rank is the `(i + 1 - wi)`-th smallest free rank.
4. `bitTree` stores subtree counts, so binary lifting locates that rank.
5. Removing the used rank subtracts one from its tree path.

The terms are:

| Term | Meaning |
| --- | --- |
| `walkCounts[i]` | Superiors passed by soldier `i` |
| `bitTree` | Fenwick tree of available ranks |
| `highestStep` | Largest power of two at most `n` |
| `targetRank` | Order statistic of the chosen rank |

Binary lifting never scans the whole tree.

A script traced the first sample case:

| Soldier | Free ranks before | Walk distance | Target order | Chosen rank |
| --- | --- | --- | --- | --- |
| 2 | 1, 2, 3 | 0 | 3rd | 3 |
| 1 | 1, 2 | 1 | 1st | 1 |
| 0 | 2 | 0 | 1st | 2 |

The ranks read left to right as `2 1 3`.

## Code

**Header and scanner.**

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

Checks are disabled for speed. The scanner reads all numbers from one input buffer. Separators are skipped in place.

**Output helper.**

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Answers collect in one string. A flush starts after `flushBlockBytes` bytes. This avoids a write per rank.

**Fenwick selection.**

```nim
let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let soldierCount = nextInt(inputData, scanPos)
  var walkCounts = newSeq[int](soldierCount)
  for i in 0..<soldierCount:
    walkCounts[i] = nextInt(inputData, scanPos)

  var bitTree = newSeq[int](soldierCount + 1)
  for i in 1..soldierCount:
    bitTree[i] = i and (-i)

  var highestStep = 1
  while highestStep shl 1 <= soldierCount:
    highestStep = highestStep shl 1

  var answer = newSeq[int](soldierCount)
  for i in countdown(soldierCount - 1, 0):
    var targetRank = i + 1 - walkCounts[i]
    var treePos = 0
    var l = highestStep
    while l > 0:
      let nextPos = treePos + l
      if nextPos <= soldierCount and bitTree[nextPos] < targetRank:
        treePos = nextPos
        targetRank -= bitTree[nextPos]
      l = l shr 1
    let rankValue = treePos + 1
    answer[i] = rankValue
    var k = rankValue
    while k <= soldierCount:
      bitTree[k] -= 1
      k += k and (-k)

  for i in 0..<soldierCount:
    if i > 0:
      outputBuffer.add ' '
    appendOutput($(answer[i]))
  outputBuffer.add '\n'
```

The tree starts with one free rank per position. `highestStep` sets the lifting range. Each chosen rank is removed before the next soldier.

**Final flush.**

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

One write emits the last buffered ranks. The tree work ends once the answer line is built.

## Complexity

Each soldier performs one tree search and one update.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total numbers) | O(Input size) |
| Tree build | O(n) | O(n) |
| Rank selection | O(n log n) | O(n) |
| Output | O(n) | O(1) |

The tree is rebuilt for each case.

| Measure | Bound |
| --- | --- |
| Time | O(n log n) per case |
| Space | O(n) per case |

Two hundred thousand soldiers take about eighteen steps each.

Rescanning the free ranks for every soldier would cost O(n^2).
