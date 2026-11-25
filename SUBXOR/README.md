# SUBXOR — SubXor (SPOJ)

<https://www.spoj.com/problems/SUBXOR/>

## Problem

Count subarrays whose XOR is strictly less than K. A subarray is a contiguous slice, and its XOR combines every element in that slice.

Input starts with the test count. Each test gives N and K, then N values. Print one count per test.

| item | bound |
|---|---|
| test count T | 1 to 10 |
| array length N | 1 to 100000 |
| array value | 1 to 100000 |
| threshold K | 1 to 1000000 |
| sum of N | at most 100000 |
| judge limit | 1000 ms, 1536 MB |

The XOR of a subarray equals the XOR of two prefix XOR values.

Sample input:

```
1
5 2
4 1 3 2 7
```

Sample output:

```
3
```

## Idea

Think of a library shelf where each book is filed by its prefix XOR barcode. For the current barcode, a binary trie counts earlier barcodes whose XOR falls below K. One bit walk handles each element, while testing every subarray would cost O(N^2) and cannot handle N = 100000.

## Why It Works

1. Let prefix value P[i] be the XOR of values 0 through i.
2. The XOR of the slice from i+1 to j equals P[j] XOR P[i].
3. Therefore a subarray ending at j is valid when some earlier prefix p satisfies p XOR P[j] less than K.
4. A binary trie stores earlier prefixes with counts at each node.
5. The query walks bits from high to low, matching K's bits.
6. When a bit of K is 1, the branch whose XOR bit is 0 gives a complete valid group and is added.
7. The walk continues into the branch whose XOR bit is 1, so equality with K is never counted.
8. The empty prefix zero is inserted before reading values, allowing subarrays that start at index zero.

| term | meaning |
|---|---|
| `prefixXor` | XOR of all values up to the current index |
| `zeroChild` | trie child for a zero bit |
| `oneChild` | trie child for a one bit |
| `nodeCountAt` | number of prefixes ending at a trie node |
| `subarrayCount` | running answer for one test case |

The trie counts prefixes, not subarrays, so each query adds many answers at once.

A worked trace from `gen.py`:

```
values 4 1 3 2 7, K = 2
prefixes inserted: 0, 4, 5, 6, 4, 3
ending at value 1: prefix 5, valid earlier prefixes are 4 -> 1 match
ending at value 3: prefix 6, valid earlier prefixes are 4, 5 -> 2 matches
ending at value 7: prefix 3, no earlier prefix gives XOR below 2
total = 3
```

The three matches are the subarrays listed in the statement.

## Code

**Input and scanner.** The whole input is read once and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const highestBit = 20
const missingChild = -1

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
```

Bit 20 covers K up to 1000000.
The missing-child sentinel is minus one because the root is zero.
The scanner skips all spacing between tokens.

**Buffered output.** Answers collect in one string and flush in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One line is appended per test.
The buffer avoids a write per answer.
A final write clears any remaining text.

**Trie insertion.** Each prefix adds one path through the trie.

```nim
var zeroChild = newSeq[int]()
var oneChild = newSeq[int]()
var nodeCountAt = newSeq[int]()

proc resetTrie() =
  zeroChild = newSeq[int](1)
  oneChild = newSeq[int](1)
  nodeCountAt = newSeq[int](1)
  zeroChild[0] = missingChild
  oneChild[0] = missingChild
  nodeCountAt[0] = 0

proc insertPrefix(prefixValue: int) =
  var nodeIndex = 0
  nodeCountAt[nodeIndex] += 1
  for bitIndex in countdown(highestBit, 0):
    let bitValue = (prefixValue shr bitIndex) and 1
    if bitValue == 0:
      if zeroChild[nodeIndex] == missingChild:
        zeroChild[nodeIndex] = zeroChild.len
        zeroChild.add missingChild
        oneChild.add missingChild
        nodeCountAt.add 0
      nodeIndex = zeroChild[nodeIndex]
    else:
      if oneChild[nodeIndex] == missingChild:
        oneChild[nodeIndex] = oneChild.len
        zeroChild.add missingChild
        oneChild.add missingChild
        nodeCountAt.add 0
      nodeIndex = oneChild[nodeIndex]
    nodeCountAt[nodeIndex] += 1
```

Each test starts with a fresh root node.
Missing children are created on demand.
Every visited node increments its prefix count.

**Trie query.** One bit walk counts all prefixes below the limit.

```nim
proc countBelowLimit(prefixValue, limitValue: int): int =
  var nodeIndex = 0
  var totalCount = 0
  for bitIndex in countdown(highestBit, 0):
    if nodeIndex == missingChild:
      break
    let prefixBit = (prefixValue shr bitIndex) and 1
    let limitBit = (limitValue shr bitIndex) and 1
    if limitBit == 1:
      var equalBranch: int
      var greaterBranch: int
      if prefixBit == 0:
        equalBranch = zeroChild[nodeIndex]
        greaterBranch = oneChild[nodeIndex]
      else:
        equalBranch = oneChild[nodeIndex]
        greaterBranch = zeroChild[nodeIndex]
      if equalBranch != missingChild:
        totalCount += nodeCountAt[equalBranch]
      nodeIndex = greaterBranch
    else:
      if prefixBit == 0:
        nodeIndex = zeroChild[nodeIndex]
      else:
        nodeIndex = oneChild[nodeIndex]
  return totalCount
```

A limit bit of one adds the lower XOR branch.
The walk never adds an XOR equal to K.
A missing branch ends the query early.

**Main loop.** Prefixes are updated and queried as each value arrives.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let limitValue = nextInt(inputData, scanPos)
  resetTrie()
  insertPrefix(0)
  var prefixXor = 0
  var subarrayCount: int64 = 0
  for elementIndex in 0 .. elementCount - 1:
    prefixXor = prefixXor xor nextInt(inputData, scanPos)
    subarrayCount += int64(countBelowLimit(prefixXor, limitValue))
    insertPrefix(prefixXor)
  appendOutput($subarrayCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The empty prefix is present before the first value.
The query runs before inserting the current prefix.
The answer uses int64 because subarray counts can exceed 2^32.

## Complexity

Each value causes one trie query and one trie insert.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| trie work | 21 steps per value | one node per added prefix |
| output | one line per test | block buffer |

The trie size grows with the number of distinct prefixes.

| measure | Big O |
|---|---|
| time | O(N bits) per test |
| space | O(N bits) worst case |

Trying every subarray would cost O(N^2) per test.
The prefix trie returns the same count in one bit walk per element.
