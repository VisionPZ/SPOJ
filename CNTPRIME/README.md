# CNTPRIME — Counting Primes (SPOJ)

<https://www.spoj.com/problems/CNTPRIME/>

## Problem

Maintain an array of integers under "set a whole range to one value" commands and "count primes in a range" queries. Print a case header, then one answer per query.

Input starts with `T`, the number of cases. Each case gives `n` and `q`, then `n` array values, then `q` commands. A command `0 x y v` assigns value `v` to positions `x` through `y`; a command `1 x y` asks for the prime count in that range. Positions start at one.

| item | bound |
|---|---|
| cases T | at most 10 |
| array size n | 1 to 10000 |
| commands q | 1 to 20000 |
| values | 2 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

The sample from the statement:

```
1
5 3
78 2 13 12 3
1 1 2
0 4 4 5
1 1 5
```

```
Case 1:
1
4
```

## Idea

Turn each value into a zero-or-one prime flag, like painting fence posts either marked or plain. A whole-range assignment paints one stretch a single color, so its prime count becomes either the stretch length or zero. A lazy segment tree stores that count and postpones work on children until a later command needs them.

The algorithm sieves primes once, builds the tree from the initial flags, then applies commands in `O(log n)` each. Rechecking every position for every query would cost `O(nq)` and fail on the largest case. The tree keeps both commands cheap.

## Why It Works

1. A sieve marks every composite up to 1000000, so a table lookup decides primality in constant time.
2. Each tree node stores the number of prime labels in its interval.
3. Assigning value `v` sets a node count to its interval length when `v` is prime, and to zero otherwise.
4. A pending value records an assignment until a child node is visited, which keeps updates logarithmic.
5. A query adds the stored counts of the covered nodes, giving the exact prime total.

| term | meaning |
|---|---|
| `isPrimeValue` | sieve table of primality for every value up to 1000000 |
| `primeCounts` | prime count stored at each segment tree node |
| `pendingValues` | deferred assignment for each node, or `noPendingValue` |
| `updateRange` | applies one range assignment |
| `queryRange` | sums prime counts over one range |

The table names the sieve table and the three tree operations.

A script trace of the sample follows.

| step | prime flags | query result |
|---|---|---|
| initial values | 0 1 1 0 1 | query 1 to 2 gives 1 |
| assign position 4 to 5 | 0 1 1 1 1 | query 1 to 5 gives 4 |

The two query results match the sample output exactly.

## Code

**Input, sieve, and tree helpers.** The scanner reads all cases; the sieve and helpers prepare the tree.

```nim
const flushBlockBytes = 1 shl 17
const maxNumber = 1000000
const sieveRoot = 1000
const noPendingValue = -1

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isPrimeValue = newSeq[bool](maxNumber + 1)
var initialValues: seq[int] = @[]
var primeCounts: seq[int] = @[]
var pendingValues: seq[int] = @[]

var sieveFactor = 2
while sieveFactor <= maxNumber:
  isPrimeValue[sieveFactor] = true
  sieveFactor += 1
sieveFactor = 2
while sieveFactor <= sieveRoot:
  if isPrimeValue[sieveFactor]:
    var multiple = sieveFactor * sieveFactor
    while multiple <= maxNumber:
      isPrimeValue[multiple] = false
      multiple += sieveFactor
  sieveFactor += 1

proc applyValue(nodeIndex: int, leftBound: int, rightBound: int, assignedValue: int) =
  if isPrimeValue[assignedValue]:
    primeCounts[nodeIndex] = rightBound - leftBound + 1
  else:
    primeCounts[nodeIndex] = 0
  pendingValues[nodeIndex] = assignedValue

proc pushPending(nodeIndex: int, leftBound: int, rightBound: int) =
  if pendingValues[nodeIndex] != noPendingValue and leftBound != rightBound:
    let middle = (leftBound + rightBound) div 2
    applyValue(nodeIndex * 2, leftBound, middle, pendingValues[nodeIndex])
    applyValue(nodeIndex * 2 + 1, middle + 1, rightBound, pendingValues[nodeIndex])
    pendingValues[nodeIndex] = noPendingValue

proc pullCounts(nodeIndex: int) =
  primeCounts[nodeIndex] = primeCounts[nodeIndex * 2] + primeCounts[nodeIndex * 2 + 1]
```

The sieve starts marking at each prime square.
An assignment replaces a node count without visiting leaves.
A pending value moves down only when a child is needed.

**Tree operations.** Building, updating, and querying all recurse over half-open work.

```nim
proc buildTree(nodeIndex: int, leftBound: int, rightBound: int) =
  if leftBound == rightBound:
    if isPrimeValue[initialValues[leftBound]]:
      primeCounts[nodeIndex] = 1
    else:
      primeCounts[nodeIndex] = 0
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  pullCounts(nodeIndex)

proc updateRange(nodeIndex: int, leftBound: int, rightBound: int,
                 queryLeft: int, queryRight: int, assignedValue: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    applyValue(nodeIndex, leftBound, rightBound, assignedValue)
    return
  pushPending(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    updateRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, assignedValue)
  if queryRight > middle:
    updateRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, assignedValue)
  pullCounts(nodeIndex)

proc queryRange(nodeIndex: int, leftBound: int, rightBound: int,
                queryLeft: int, queryRight: int): int =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return primeCounts[nodeIndex]
  pushPending(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  var total = 0
  if queryLeft <= middle:
    total += queryRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight)
  if queryRight > middle:
    total += queryRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight)
  return total
```

A leaf stores one prime flag.
Both commands split at the midpoint and visit only intersecting children.
Pulling counts after a child change keeps every node correct.

**Case driver.** Each case rebuilds the tree and writes its answers.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let elementCount = nextInt(inputData, scanPos)
  let commandCount = nextInt(inputData, scanPos)
  initialValues = newSeq[int](elementCount + 1)
  for elementIndex in 1 .. elementCount:
    initialValues[elementIndex] = nextInt(inputData, scanPos)
  let treeSize = 4 * elementCount + 5
  primeCounts = newSeq[int](treeSize)
  pendingValues = newSeq[int](treeSize)
  for nodeIndex in 0 .. treeSize - 1:
    pendingValues[nodeIndex] = noPendingValue
  buildTree(1, 1, elementCount)
  appendOutput("Case " & $caseIndex & ":\n")
  for commandIndex in 1 .. commandCount:
    let commandType = nextInt(inputData, scanPos)
    if commandType == 0:
      let rangeLeft = nextInt(inputData, scanPos)
      let rangeRight = nextInt(inputData, scanPos)
      let assignedValue = nextInt(inputData, scanPos)
      updateRange(1, 1, elementCount, rangeLeft, rangeRight, assignedValue)
    else:
      let rangeLeft = nextInt(inputData, scanPos)
      let rangeRight = nextInt(inputData, scanPos)
      appendOutput($queryRange(1, 1, elementCount, rangeLeft, rangeRight))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Pending values are reset to `noPendingValue` for each case.
The case header is written before any answer line.
All answers share one block-buffered output stream.

## Complexity

The sieve runs once; each case pays for its tree and commands.

| phase | time | space |
|---|---|---|
| sieve | one pass up to 1000000 | one boolean table |
| tree build | one node per interval | four nodes per element |
| each command | one logarithmic walk | recursion stack |
| output | one block flush per `flushBlockBytes` bytes | block buffer |

The command count drives total runtime after the fixed sieve.

| measure | Big O |
|---|---|
| time | `O(1000000 log log 1000000)` once, then `O((n + q) log n)` per case |
| space | `O(1000000 + n)` |

Scanning the array for each query would take `O(nq)` and lose on wide ranges. Lazy propagation keeps every command logarithmic.
