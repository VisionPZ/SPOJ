## Problem

Each test starts with N enterprises, each served by its own center. Commands link a center I to an enterprise J, or ask for the total line length from an enterprise to its current center. A link costs the absolute difference of I and J, reduced modulo 1000. Print one answer line for each E command across all tests.

The bounds set the size of the data and the output:

| Quantity | Bound |
| --- | --- |
| Test cases T | 1 to 5 |
| Enterprises N | 5 to 20000 |
| Commands per test | at most 200000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The command count drives the design.

## Idea

Use a disjoint set (a structure that groups nodes under one root) and store the distance from each node up to its root. Each link sets the parent of the center I to J and records the edge length. Each query walks to the root, adds the edge lengths, and redirects visited nodes straight to the root. This redirection, called path compression, keeps later walks short. The cost is effectively constant per command.

## Why It Works

Every enterprise begins as its own root with distance zero. A link names a center I, so the parent of I is I before the link. The program sets the parent of I to J and stores the absolute difference of I and J, reduced modulo 1000.

The query walks up while a node differs from its parent. Before moving to the parent, it adds the parent's stored distance to the node's distance. It then points the node at the root. After this walk, the stored distance of the queried node equals the whole path length to its center.

Only a link uses modulo 1000. The printed sum adds raw edge lengths and never reduces them. The trace below uses the sample input and matches the sample output.

| Step | Command | Action | Printed |
| --- | --- | --- | --- |
| 1 | E 3 | node 3 is its own center | 0 |
| 2 | I 3 1 | link edge length 2 | — |
| 3 | E 3 | path 3 to 1 sums 2 | 2 |
| 4 | I 1 2 | link edge length 1 | — |
| 5 | E 3 | path 3 to 1 to 2 sums 3 | 3 |
| 6 | I 2 4 | link edge length 2 | — |
| 7 | E 3 | path 3 to 1 to 2 to 4 sums 5 | 5 |

The four printed values match the sample output exactly.

## Code

The constants and the single input buffer appear first.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const lengthModulus = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The read loop runs once per input line and ends at end of file. It keeps all input in one string. This avoids a stream call per number.

The scanners read integers and command letters from that one string.

```nim
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

The index i only moves forward, so the whole input is scanned in one pass. The digit scanner skips letters and separators. The command scanner skips whitespace and returns the next letter.

The parent and distance arrays back the root walk.

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

Recursion stops at a node whose parent is itself. The addition uses the parent's distance after that parent has been compressed. The assignment then shortens the path for future walks.

One output buffer collects answers and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer holds roughly one quarter megabyte before a write. This bounds memory and avoids a write per answer.

The main loop drives the commands for every test.

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
```

The initialization loop runs exactly enterpriseCount plus one times. The command loop ends when it reads the letter O. The sign branch keeps the difference positive, and the modulo applies only to a link.

The final write emits any buffered bytes left over.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

This runs once after all tests. No answer can be lost at the end of the stream.

## Complexity

Reading input takes time linear in the input size and uses one string. Each link takes constant time. Each query walks a compressed path and takes effectively constant time. The total time is O(C alpha(N)) for C commands, where alpha is the inverse Ackermann function. Space is O(N) for the two arrays and O(C) for the input and output buffers. A naive approach that rebuilds every path from scratch costs O(N) per query and fails on large command counts.
