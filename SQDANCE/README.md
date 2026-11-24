## Problem

Read T test cases. Each case gives P prime indices and R relations. Each relation names two indices. Relations arrive in order. Keep a relation when it adds no square subproduct. Count the squares that appear and print one count per case.

| Quantity | Bound |
| --- | --- |
| Test cases | 30 |
| Prime indices per case | 100000 |
| Relations per case | 100000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The relation total drives the work because each arrival needs one check.

## Idea

Treat each relation as an edge between two prime indices. A product of relations is a square when every index appears an even number of times. That happens exactly when the new edge closes a cycle among the stored edges.

Union-find holds the components of the stored edges in one array. It tests each arrival and merges two components when needed. Nothing gets rebuilt between arrivals.

Each relation costs O(α(P)) amortized time and O(1) extra space.

## Why It Works

A subproduct is a square exactly when each prime index has even total degree. Stored edges never contain a cycle, so each component is a tree. A new edge inside one tree creates one even-degree cycle, hence one square. A new edge between two trees joins them and creates no square.

The union steps number P - C, where C is the final component count. The counted squares therefore number R - (P - C).

The table traces the first sample case. Roots use the final parent array after path compression.

| Step | Pair | Roots | Action | Squares |
| --- | --- | --- | --- | --- |
| 1 | 1,2 | 1,2 | store | 0 |
| 2 | 3,5 | 3,5 | store | 0 |
| 3 | 2,4 | 2,4 | store | 0 |
| 4 | 1,4 | 4,4 | count | 1 |
| 5 | 3,5 | 5,5 | count | 2 |
| 6 | 1,6 | 4,6 | store | 2 |
| 7 | 4,6 | 6,6 | count | 3 |

Step 7 closes the last cycle and gives the answer 3.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const initialBufferBytes = 1 shl 20

var inputData = ""
inputData.setLen(initialBufferBytes)
var totalRead = 0
while true:
  if totalRead == inputData.len:
    inputData.setLen(inputData.len * 2)
  let bytesRead = stdin.readBuffer(addr inputData[totalRead], inputData.len - totalRead)
  if bytesRead == 0: break
  totalRead += bytesRead
inputData.setLen(totalRead)
```

The loop ends at the first empty read. The buffer doubles only when full, so one bulk copy holds the whole stream. `setLen` trims the string to the bytes read.

```nim
proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The scanner skips separators and reads digits into an integer. It allocates no token objects. It assumes non-negative input, which the statement guarantees.

```nim
proc findRoot(parent: var seq[int], i: int): int =
  var j = i
  while parent[j] != j:
    j = parent[j]
  var k = i
  while parent[k] != k:
    let l = parent[k]
    parent[k] = j
    k = l
  return j
```

The first walk finds the root. The second walk compresses the path in place. Both walks stop at a root, so the loop bound is the tree height, kept short by size merging.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let primeCount = nextInt(inputData, i)
  let relationCount = nextInt(inputData, i)
  var parent = newSeq[int](primeCount + 1)
  var componentSize = newSeq[int](primeCount + 1)
  for j in 0..primeCount:
    parent[j] = j
    componentSize[j] = 1
  var squareCount = 0
  for j in 0..<relationCount:
    let leftPrime = nextInt(inputData, i)
    let rightPrime = nextInt(inputData, i)
    let leftRoot = findRoot(parent, leftPrime)
    let rightRoot = findRoot(parent, rightPrime)
    if leftRoot == rightRoot:
      squareCount += 1
    elif componentSize[leftRoot] < componentSize[rightRoot]:
      parent[leftRoot] = rightRoot
      componentSize[rightRoot] += componentSize[leftRoot]
    else:
      parent[rightRoot] = leftRoot
      componentSize[leftRoot] += componentSize[rightRoot]
  appendOutput($(squareCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per case and the inner loop once per relation. The `parent` array uses index 0 as unused space. Merging the smaller tree into the larger one keeps lookups fast. The output buffer flushes in blocks through `appendOutput`.

## Complexity

Bulk input takes O(B) time and O(B) space for B input bytes. Each case spends O(P) time initializing two arrays and O(R α(P)) time on relations. The arrays use O(P) space.

Total time is O(T(P + R) α(P)) and peak space is O(B + P). A subset-enumeration approach would take O(2^R) time per case.
