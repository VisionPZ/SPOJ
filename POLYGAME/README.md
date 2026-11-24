## Problem

Read a triangulated convex polygon and decide who wins its cutting game. The first triangle is black. Each turn cuts away one ear, and the player who cuts the black triangle wins. Print YES when the first player has a winning strategy, otherwise print NO.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded by the statement |
| Vertices per polygon | 4 to 50000 |
| Triangles per test case | n - 2 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The input can hold millions of integers, so one bulk read and one buffered write drive the design.

## Idea

The dual graph of a triangulation is a tree, and cutting an ear deletes a leaf. Root that tree at the black triangle and count its branches. The outcome then depends only on the black degree and the parity of n, so the program never builds the tree.

Cost per triangle: three comparisons while scanning its three vertices.

## Why It Works

Two triangles that share two vertices share a diagonal. Those pairs form the dual tree. A triangle can be cut only when it is an ear, which means one diagonal and one leaf in that tree.

The black triangle can be cut when at most one branch remains. Each branch is a rooted tree with a game value.

- black degree = count of triangles sharing two vertices with the first triangle
- branch value = 1 xor (xor of child branch values) = branch size mod 2
- combined value = xor of branch values = (n - 3) mod 2
- win = black degree <= 1 or n mod 2 == 0

The leading 1 counts the branch root. Each child term adds that child branch value. XOR of bits equals addition mod 2, so expansion collapses to the subtree size mod 2. XOR across branches equals the parity of all non-black triangles, which is (n - 3) mod 2. An odd value gives the next player a winning move.

The generator prints the sample's deciding values:

| Sample value | Result |
| --- | --- |
| black neighbours | 1 |
| non-black triangles | 3 |
| answer | YES |

One neighbour makes the black triangle an ear, so the first player cuts it at once.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The line loop ends at EOF, and the scanner skips blank separators between cases. One bulk read avoids a syscall per token. This phase costs time linear in the input bytes.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let triangleCount = vertexCount - 2
  let blackFirst = nextInt(inputData, scanPos)
  let blackSecond = nextInt(inputData, scanPos)
  let blackThird = nextInt(inputData, scanPos)
  var blackDegree = 0
  for j in 1..<triangleCount:
    var sharedCount = 0
    for k in 0..<3:
      let vertex = nextInt(inputData, scanPos)
      if vertex == blackFirst or vertex == blackSecond or vertex == blackThird:
        sharedCount += 1
    if sharedCount >= 2:
      blackDegree += 1
  if blackDegree <= 1 or vertexCount mod 2 == 0:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The case loop runs caseCount times and the triangle loop runs n - 3 times. The bound 0..<3 reads exactly three vertices; reading four would steal the next token. Each case costs O(n) and adds four output bytes.

## Complexity

Reading the input takes time linear in its byte size and uses one buffer of that size. Each case scans n - 3 triangles with three comparisons each, so the case cost is O(n) and the extra space is constant. The output buffer flushes every 262144 bytes, which caps write memory at one block.

Total time is O(input bytes + output bytes), and total space is O(input bytes + 262144). A search over the dual game tree would take exponential time and grow memory with each triangle.
