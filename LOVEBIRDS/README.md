# LOVEBIRDS — She was in Love with BST (SPOJ)
<https://www.spoj.com/problems/LOVEBIRDS/>

## Problem

Insert the numbers 1 to N in every possible order. Each order builds one binary search tree, and distinct orders can give the same shape. Count the distinct shapes and reduce the count modulo 1908.

Input starts with T, the number of test cases. Each of the next T lines holds one integer N. Output T lines, each holding one answer.

| quantity | bound |
|---|---|
| test cases T | 1 to 1000 |
| tree size N | 1 to 1000 |
| modulus | 1908 |
| judge limit | 1000 ms, 1536 MB |

Every N fits in one precomputed table, so no case needs its own search.

Sample input:

```
2
1
2
```

Sample output:

```
1
2
```

The two sample shapes are a single node and a two-node chain.

## Idea

Picking the root splits the remaining numbers into two piles, like dividing a deck into a left hand and a right hand. The count follows the Catalan recurrence, built once with dynamic programming.

For each size s, sum products of counts for every split of the other s minus one numbers. That costs O(N^2) once for the largest size, then one table read per case. Counting all insertion orders directly would walk through factorially many permutations.

Precomputing trades a small table for instant replies to every test case.

## Why It Works

1. A binary search tree shape is fixed by the root and the two subtree shapes.
2. Choosing root i leaves i minus one smaller keys and s minus i larger keys.
3. Those two groups form independent binary search trees.
4. Multiplying their shape counts gives the shapes for that root.
5. Adding over all roots gives the Catalan recurrence for size s.
6. Reducing after each addition keeps every table entry small.

| term | meaning |
|---|---|
| `catalanValues` | shape count for each tree size, modulo 1908 |
| `treeSize` | current size being filled in the table |
| `leftSize` | size of the left subtree in one split |
| `shapeTotal` | sum of products for one size |

The table index equals the tree size, so answers need no extra arithmetic.

For size four, the split products are 1 times 5, 1 times 2, 2 times 1, and 5 times 1. Their sum is 14, the fourth Catalan number. For size two, the sum is 1 plus 1, giving 2.

Products can reach about 1908 squared, so the sum uses `int64`. The modulo comes after the sum, which keeps the stored entry inside the intended range.

## Code

**Input and scanner.** The reader loads all lines and parses integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1908
const maxTreeSize = 1000

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
```

Spacing and line breaks do not affect the scan.
The scanner stops at the first non digit after each number.

**Table and replies.** One dynamic program fills every size up to the maximum.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var catalanValues = newSeq[int](maxTreeSize + 1)
catalanValues[0] = 1
for treeSize in 1 .. maxTreeSize:
  var shapeTotal: int64 = 0
  for leftSize in 0 .. treeSize - 1:
    shapeTotal = shapeTotal + int64(catalanValues[leftSize]) * int64(catalanValues[treeSize - 1 - leftSize])
  catalanValues[treeSize] = int(shapeTotal mod int64(answerModulus))

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let treeCount = nextInt(inputData, scanPos)
  appendOutput($catalanValues[treeCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The empty tree seeds the table with one shape.
`appendOutput` writes in blocks, never once per case.
A final flush emits any remaining bytes.

## Complexity

The table is filled before any case is read.

| phase | time | space |
|---|---|---|
| input read | one pass over the input text | one input string |
| table fill | sum of sizes up to N products | N plus one integers |
| output | one line per test case | block buffer |

The table size sets the whole running time.

| measure | Big O |
|---|---|
| preprocessing | O(N^2) |
| each case | O(1) |
| space | O(N) |

Counting all permutations would take factorial time for each case.

The precomputed table answers every case with one lookup.
