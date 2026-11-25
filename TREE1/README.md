# TREE1 — Tree (SPOJ)

<https://www.spoj.com/problems/TREE1/>

## Problem

A teacher builds a binary search tree by inserting numbers one at a time. Given the finished tree shape, count how many insertion orders could have produced it.

Input: `d` data sets. Each set gives `n`, then the `n` keys in preorder.

Output: one line per set, the count of consistent permutations. The count can exceed any machine integer.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Data sets `d` | at most 10 |
| Keys `n` | 1 to 30 |
| Key order | preorder of the tree |
| Judge limit | 5000 ms, 1536 MB |

Thirty factorial has 33 digits, so the answer needs custom big-integer storage.

The sample input and output:

```
5 
3 
2 1 3 
3 
1 2 3 
1 
1 
4 
2 1 3 4 
4 
1 4 2 3 
```

```
2
1
1
3
1
```

## Idea

Treat the two subtrees as queues of guests that may interleave, while each queue keeps its own internal order. Count the interleavings at every node and multiply them.

The program walks the preorder keys recursively and collects binomial (choose) factors. It then multiplies those small factors into a big number stored in base one billion limbs. Collecting factors costs `O(n²)`, and printing the answer costs one pass over its limbs.

Enumerating all `n!` permutations and rebuilding the tree each time cannot reach `n = 30`. The factor product counts every valid order at once.

Node-by-node interleaving captures the whole tree in one multiplication chain.

## Why It Works

Five facts justify the factor product.

1. The first inserted key of any subtree becomes that subtree's root. So the root key must precede all other keys in its subtree.
2. Any order respecting that rule at every node builds the same tree. Left and right subtree insertions may interleave freely.
3. For a subtree with `L` left keys and `R` right keys, there are `C(L + R, L)` ways to interleave the two subtrees.
4. Multiplying that factor over every node gives `n!` divided by the product of subtree sizes. The recursion reads key ranges from the preorder list: left keys run from `lowKey` to `pivotKey - 1`.
5. Each limb stores nine decimal digits, so a factor times a limb plus carry stays inside a 64-bit integer.

The helpers used by the program:

| Term | Meaning |
| --- | --- |
| `collectInterleaveFactors` | walks nodes and collects one choose factor each |
| `binomialCoefficient` | computes `C(L + R, L)` by small steps |
| `multiplyBySmall` | multiplies the big value by one factor with carry |
| `baseValue` | one billion, the radix of each limb |
| `appendBigAnswer` | prints the top limb, then nine-digit padded limbs |

The most significant limb prints without padding, so no leading zeros appear.

A script trace of the sample keys:

```
keys [2, 1, 3]: factors [1, 1, 2], product 2
keys [1, 2, 3]: factors [1, 1, 1], product 1
keys [1]: factors [1], product 1
keys [2, 1, 3, 4]: factors [1, 1, 1, 3], product 3
keys [1, 4, 2, 3]: factors [1, 1, 1, 1], product 1
```

The first tree has a root with one left and one right child, giving two interleavings.

## Code

**Constants and scanner.** The reader collects one flat string of digits.

```nim
const baseValue = 1000000000
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const limbDigitCount = 9

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var numberValue = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    numberValue = numberValue * 10 + int(inputData[i]) - firstDigitValue
    i += 1
  return numberValue
```

`limbDigitCount = 9` matches `baseValue = 1,000,000,000`.
`nextInt` skips non-digits, so trailing spaces in the sample cause no trouble.
All tree keys are positive.

**Choose factor.** One binomial coefficient needs at most thirty small steps.

```nim
proc binomialCoefficient(groupSize: int, chooseCount: int): int =
  var coefficient = 1
  for j in 1 .. chooseCount:
    coefficient = coefficient * (groupSize - chooseCount + j) div j
  return coefficient
```

The loop divides at each step, so the intermediate product stays integral.
`chooseCount` never exceeds `n`, and `n` is at most 30.

**Preorder walk.** The recursion splits key ranges around each pivot.

```nim
proc collectInterleaveFactors(prefixKeys: seq[int], i: int, lowKey: int, highKey: int, factors: var seq[int]) =
  let pivotKey = prefixKeys[i]
  let leftKeyCount = pivotKey - lowKey
  let rightKeyCount = highKey - pivotKey
  if leftKeyCount > 0:
    collectInterleaveFactors(prefixKeys, i + 1, lowKey, pivotKey - 1, factors)
  if rightKeyCount > 0:
    collectInterleaveFactors(prefixKeys, i + 1 + leftKeyCount, pivotKey + 1, highKey, factors)
  factors.add binomialCoefficient(leftKeyCount + rightKeyCount, leftKeyCount)
```

`leftKeyCount` is `pivotKey - lowKey`, since keys form a consecutive range.
The left subtree starts at the next preorder slot, and the right starts after all left keys.
The factor is appended after both children, so children are ready first.

**Big multiplication.** One factor updates every limb with a carry.

```nim
proc multiplyBySmall(bigValue: var seq[int], factor: int) =
  var carry = 0
  for j in 0 .. bigValue.high:
    let product = bigValue[j] * factor + carry
    bigValue[j] = product mod baseValue
    carry = product div baseValue
  while carry > 0:
    bigValue.add(carry mod baseValue)
    carry = carry div baseValue
```

The loop visits limbs from least to most significant.
A carry beyond the top limb appends a new limb.
Each step stays below nine billion, well within a 64-bit integer.

**Big output.** Each limb prints as nine decimal digits.

```nim
proc appendPaddedLimb(outputBuffer: var string, limbValue: int) =
  var placeValue = 1
  for j in 1 .. limbDigitCount:
    placeValue = placeValue * 10
  var remaining = limbValue
  for j in 1 .. limbDigitCount:
    placeValue = placeValue div 10
    let digitValue = remaining div placeValue
    outputBuffer.add char(firstDigitValue + digitValue)
    remaining = remaining mod placeValue

proc appendBigAnswer(outputBuffer: var string, bigValue: seq[int]) =
  outputBuffer.add $bigValue[bigValue.high]
  for j in countdown(bigValue.high - 1, 0):
    appendPaddedLimb(outputBuffer, bigValue[j])
  outputBuffer.add '\n'
```

`appendPaddedLimb` divides by decreasing powers of ten and writes one digit at a time.
The top limb prints as a plain decimal.
The answer ends with one newline.

**Driver.** One loop handles all data sets and flushes the output buffer.

```nim
var inputData = ""
var oneLine = ""
while readLine(stdin, oneLine):
  inputData.add oneLine
  inputData.add '\n'

var i = 0
let dataSetCount = nextInt(inputData, i)
var outputBuffer = ""
for j in 0 .. dataSetCount - 1:
  let treeSize = nextInt(inputData, i)
  var prefixKeys = newSeq[int](treeSize)
  for k in 0 .. treeSize - 1:
    prefixKeys[k] = nextInt(inputData, i)
  var interleaveFactors: seq[int] = @[]
  collectInterleaveFactors(prefixKeys, 0, 1, treeSize, interleaveFactors)
  var bigAnswer = @[1]
  for factor in interleaveFactors:
    multiplyBySmall(bigAnswer, factor)
  appendBigAnswer(outputBuffer, bigAnswer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

`collectInterleaveFactors` fills a temporary factor list for each tree.
`bigAnswer` starts at one, and each factor multiplies into it.
The final conditional write covers the tail.

## Complexity

Each tree contributes a small factor list and one big multiplication.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Preorder walk | O(n) nodes | O(n) for factors and stack |
| Big multiplication | O(n × D) limb steps | O(D) for the answer |
| Answer output | O(D) digits | 256 KiB block |
| Total per data set | O(n × D) | O(n + D) |

At `n = 30` the answer occupies four limbs.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n × D) per data set, with D answer limbs |
| Space | O(n + D) per data set, plus buffers |

Enumerating `n!` insertion orders is impossible at `n = 30`. The interleave product counts them all in a few dozen steps.
