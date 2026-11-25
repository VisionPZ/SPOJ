# SQDANCE — Square dance (SPOJ)

<https://www.spoj.com/problems/SQDANCE/>

## Problem

Given pairs of primes arriving one at a time, keep those whose product never forms a perfect square with earlier pairs. Count each arrival that would complete a square, and skip it.

Input: `T` test cases. Each case starts with `P` prime indices and `R` relations.

Each of the next `R` lines holds two indices `i j`. Output: one line per case with the number of squares formed.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Test cases `T` | at most 30 |
| Prime indices `P` | at most 100,000 |
| Relations `R` | at most 100,000 |
| Judge limit | 5000 ms, 1536 MB |

The relation count drives the work, since each arrival needs one check.

The sample input and output:

```
2
6 7
1 2
3 5
2 4
1 4
3 5
1 6
4 6
2 3
1 2
1 2
1 2
```

```
3
2
```

## Idea

A square appears when a new pair joins two primes already linked by earlier pairs. Think of relations as strings between numbered posts. A string inside one connected bunch closes a loop.

The program tracks those bunches with union-find (a structure that merges sets and finds each set's representative). Each relation costs `O(α(P))` amortized time, where α is the inverse Ackermann function. That function grows slower than any logarithm.

Testing every subset of relations would explore exponentially many products. The online check settles each arrival once.

Counting loops as they form turns an exponential search into one near-constant check per relation.

## Why It Works

Four facts justify the online count.

1. A product of relations is a square when every prime index appears an even number of times.
2. The stored relations never contain a loop, so each component is a tree.
3. A new relation inside one tree closes one loop. That loop is one square, and the relation stays out of the collection.
4. A new relation between two trees merges them. No square appears, so the program stores it.

The terms used by the program:

| Term | Meaning |
| --- | --- |
| `parent` | representative index of one set |
| `componentSize` | number of prime indices in that set |
| `leftRoot`, `rightRoot` | representatives of the two relation endpoints |
| `squareCount` | loops closed so far |
| `R - P + C` | closed form of the count, with `C` components |

Union by size keeps each tree shallow, so repeated lookups stay cheap.

A script trace of the first sample case, using representatives after path compression:

```
| relation | roots before | action | squares | roots after |
| --- | --- | --- | --- | --- |
| 1,2 | 1,2 | merge | 0 | 1,1 |
| 3,5 | 3,5 | merge | 0 | 3,3 |
| 2,4 | 1,4 | merge | 0 | 1,1 |
| 1,4 | 1,1 | count square | 1 | 1,1 |
| 3,5 | 3,3 | count square | 2 | 3,3 |
| 1,6 | 1,6 | merge | 2 | 1,1 |
| 4,6 | 1,1 | count square | 3 | 1,1 |
check R - P + C = 7 - 6 + 2 = 3
```

The third and fifth rows show repeated pairs. Both close a loop and raise the count.

## Code

**Bulk input and scanner.** The reader grows one buffer, and the scanner walks it by index.

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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The buffer doubles only when full, so the read loop runs once per chunk.
The scanner skips non-digits and needs no sign branch.
Parsing one integer visits each digit once.

**Set representative.** Two walks find the root and then compress the path to it.

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

The first walk stops at the root.
The second walk rewires every node on the path to that root.
Both walks visit at most the tree height, which stays small under union by size.

**Buffered output.** One buffer collects answers and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`flushBlockBytes` fixes the block size at 256 KiB.
`setLen 0` reuses the same allocation for the next block.
A case writes one line, never one write per digit.

**Driver.** Each relation either closes a loop or merges two sets.

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

The initialization loop runs `primeCount + 1` times, one slot per index plus index zero.
`findRoot` returns both roots before any merge, so a loop is detected correctly.
The final write covers the tail of the buffer.

## Complexity

Each phase does one pass over the input or over one small set of arrays.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Set initialization | O(P) | O(P) for two arrays |
| One relation | O(α(P)) amortized | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O((P + R) α(P)) | O(P) |

The inverse Ackermann factor stays below five for any realistic input.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O((P + R) α(P)) per case |
| Space | O(P) per case, plus buffers |

Trying every subproduct takes exponential time and cannot handle `R = 100,000`. The union-find scan handles each relation once.
