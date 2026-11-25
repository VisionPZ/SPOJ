# CORNET — Corporative Network (SPOJ)

<https://www.spoj.com/problems/CORNET/>

## Problem

Each enterprise starts with its own center, and link commands merge clusters under a new center. Each query asks the total link length from an enterprise to its center.

Input: one integer for the test count, then an enterprise count per test. Commands follow: `I i j` links center i to enterprise j, `E i` asks for a distance, and `O` ends the test.

Output: one distance per `E` command.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Test cases T | 1 to 5 |
| Enterprises N | 5 to 20000 |
| Commands per test | at most 200000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The command count drives the design.

The sample input and output:

```
1
4
E 3
I 3 1
E 3
I 1 2
E 3
I 2 4
E 3
O
```

```
0
2
3
5
```

## Idea

Trace each link chain like an org chart, then write the final boss's name on every file you visited. That rewriting is path compression, and it keeps later traces short.

The program uses a disjoint set (a structure that groups nodes under one root). Each node stores its parent and the distance up to that parent. A link changes one parent and records one edge length. A query walks to the root, sums the edges, and compresses the path.

Each command costs effectively constant time, with an inverse Ackermann (extremely slow-growing) factor. Rebuilding the whole path for every query would cost O(N) each time.

Compression makes repeated queries cheap.

## Why It Works

Every enterprise starts as its own root with distance zero.

1. A link names a center i, so i is a root before the link. The program sets its parent to j and stores `|i - j| mod 1000`.
2. A query walks while a node differs from its parent and adds the parent's stored distance before moving.
3. After the walk, the queried node's stored distance equals the whole path length to its center.
4. Each visited node is redirected straight to the root, so later walks skip the middle of the chain.

The arrays and the command rules are as follows:

| Term | Meaning |
| --- | --- |
| `parentArr[node]` | node above this one in the chain |
| `distArr[node]` | edge length from this node up to its parent |
| `findRoot` | root walk with compression |
| link distance | `abs(i - j) mod 1000` |
| query distance | sum of raw edge lengths, never reduced |

Only a link uses modulo 1000. The printed sum adds raw edge lengths.

A script traces the sample commands:

| Step | Command | Action | Printed |
| --- | --- | --- | --- |
| 1 | `E 3` | node 3 is its own center | 0 |
| 2 | `I 3 1` | link edge length 2 | — |
| 3 | `E 3` | path 3 to 1 sums 2 | 2 |
| 4 | `I 1 2` | link edge length 1 | — |
| 5 | `E 3` | path 3 to 1 to 2 sums 3 | 3 |
| 6 | `I 2 4` | link edge length 2 | — |
| 7 | `E 3` | path 3 to 1 to 2 to 4 sums 5 | 5 |

The four printed values match the sample output.

## Code

**Constants and scanners.** One buffer holds the stream, and two scanners read numbers and command letters.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const lengthModulus = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc nextCommand(data: string, i: var int): char =
  while i < data.len and data[i] <= ' ':
    i += 1
  result = data[i]
  i += 1
```

The read loop runs once per input line. The integer scanner skips command letters. The command scanner skips whitespace and returns the next letter. One pass covers the input.

**Root walk.** Recursion stops at a node whose parent is itself.

```nim
var parentArr: seq[int]
var distArr: seq[int]

proc findRoot(nodeIdx: int): int =
  if parentArr[nodeIdx] != nodeIdx:
    let oldParent = parentArr[nodeIdx]
    let rootIdx = findRoot(oldParent)
    distArr[nodeIdx] += distArr[oldParent]
    parentArr[nodeIdx] = rootIdx
    return rootIdx
  return nodeIdx
```

The addition uses the parent's distance after that parent has been compressed. The assignment shortens the path for future walks. Each visited node pays one recursive call.

**Output helper.** One buffer collects answers and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer holds roughly 256 KiB before a write. This bounds memory and avoids a write per answer.

**Command driver.** Initialization sets every node to its own root, and the loop ends at `O`.

```nim
let caseCount = nextInt(inputData, i)
for caseIdx in 0..<caseCount:
  let enterpriseCount = nextInt(inputData, i)
  parentArr = newSeq[int](enterpriseCount + 1)
  distArr = newSeq[int](enterpriseCount + 1)
  for k in 0..enterpriseCount:
    parentArr[k] = k
    distArr[k] = 0
  while true:
    let commandChar = nextCommand(inputData, i)
    if commandChar == 'O':
      break
    if commandChar == 'E':
      let nodeIdx = nextInt(inputData, i)
      discard findRoot(nodeIdx)
      appendOutput($(distArr[nodeIdx]))
      outputBuffer.add '\n'
    elif commandChar == 'I':
      let centerIdx = nextInt(inputData, i)
      let linkedIdx = nextInt(inputData, i)
      parentArr[centerIdx] = linkedIdx
      var chainDiff = centerIdx - linkedIdx
      if chainDiff < 0:
        chainDiff = -chainDiff
      distArr[centerIdx] = chainDiff mod lengthModulus

stdout.write outputBuffer
outputBuffer.setLen 0
```

The initialization runs exactly `enterpriseCount + 1` times. The sign branch keeps the difference positive, and modulo applies only to a link. The final write emits any buffered bytes.

## Complexity

Each link takes constant time, and each query walks a compressed path.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Initialization | O(N) per test | O(N) arrays |
| Link command | O(1) | O(1) |
| Query command | O(α(N)) amortized | O(N) recursion |
| Output | one write per 256 KiB block | 256 KiB |
| Total | O(C α(N)) for C commands | O(N) plus buffers |

Here α is the inverse Ackermann function, which stays below 5 for any practical N.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(C α(N)) for C commands |
| Space | O(N) |

Rebuilding every path from scratch would cost O(N) per query and fail on large command counts.
