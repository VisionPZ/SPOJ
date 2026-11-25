# TREE2 — Which is Next (SPOJ)

<https://www.spoj.com/problems/TREE2/>

## Problem

The input gives identifiers of binary trees coded as bitstrings. In the ordering of all trees with the same node count, find each tree's successor identifier.

Input starts with the test count `t`. Each of the next `t` lines holds one integer identifier `n` with `0 ≤ n ≤ 2^30`. Output one integer per line: the successor identifier in the same size class. The order wraps from the largest tree back to the smallest.

The judge applies these limits.

| Item | Bound |
| --- | --- |
| Identifier `n` | 0 to 2^30 |
| Bit length of an identifier | at most 31 |
| Test count `t` | given on the first line |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The bit-length bound keeps every case inside a fixed array.

The sample input and output follow verbatim.

```
1
20
```

```
24
```

## Idea

Treat each tree as a bitstring and flip the rightmost zero that still allows a valid ending. Like counting in binary, change the last position that can still increase.

The identifier is the tree's preorder bitstring, with `1` for an internal node and `0` for a leaf. All trees of one size have bitstrings of equal length, so dictionary order equals numeric order. The successor is therefore the next valid bitstring above the given one. The program scans at most 31 bits, computes open slots, flips one zero, and writes the smallest valid tail.

Listing every tree of that size costs Catalan growth, roughly 2.7 million trees at 31 bits. Testing each larger integer also loses, because gaps can span millions. The scan wins with a few dozen steps.

A fixed-size scan always beats rebuilding the whole family.

## Why It Works

Four facts prove the scan.

1. The formula `N(t1, t2) = 2^(|t1|+|t2|) + 2^(|t2|)·N(t1) + N(t2)` lays the tree out in bits. The leading bit marks the root, the next bits hold the left subtree, and the low bits hold the right subtree.
2. Tree order compares left subtrees before right subtrees, recursively. That is lexicographic order of the bitstrings, which equals numeric order when all strings share a length.
3. Read bits from the top with `slots` starting at one. A `1` adds a slot and a `0` removes one. Every prefix keeps a positive count, and the last bit leaves zero.
4. The scan flips bit `j` only when `j >= currentHeight` and `j - currentHeight` is even. Those conditions leave enough low bits to close every open slot. If no bit works, the answer wraps to the smallest tree.

The table names the values used in the scan.

| Term | Meaning |
| --- | --- |
| `identifier` | preorder bitstring of the tree |
| `nodeCount` | bit length of the identifier |
| `slotHeights[j]` | open slots after reading bit `j` |
| `currentHeight` | open slots after flipping bit `j` to one |
| `remainingDownSteps` | down steps still needed to close the slots |
| `smallestCode` | identifier of the smallest tree of this size |

Every scan step is an integer test, so it never allocates memory.

A trace of the sample identifier `20` shows the arithmetic.

| Step | Value |
| --- | --- |
| Identifier in binary | `10100`, so `nodeCount = 5` |
| Slot heights, top to bottom | 2, 1, 2, 1, 0 |
| Flip bit 0 | height 2, no low bits, rejected |
| Flip bit 1 | height 3, no low bits, rejected |
| Flip bit 3 | height 3, two low bits, accepted |
| Assemble the result | `(20 shr 4) shl 4` gives 16, then set bit 3 to get 24 |
| Successor | `24`, matching the sample output |

The wrap branch writes ones at even positions 2, 4, and so on. That pattern is the smallest valid tree.

## Code

**Successor routine.** The successor routine performs the height pass, the flip scan, and the wrap construction.

```nim
proc nextIdentifier(identifier: int64): int64 =
  if identifier == 0:
    return 0
  var nodeCount = 0
  var probe = identifier
  while probe > 0:
    nodeCount = nodeCount + 1
    probe = probe shr 1
  var slotHeights: array[0 .. maxBitPosition, int]
  var slots = 1
  for i in countdown(nodeCount - 1, 0):
    if ((identifier shr i) and 1) == 1:
      slots = slots + 1
    else:
      slots = slots - 1
    slotHeights[i] = slots
  for j in 0 .. nodeCount - 2:
    if ((identifier shr j) and 1) == 0:
      let currentHeight = slotHeights[j + 1] + 1
      if j >= currentHeight and (j - currentHeight) mod 2 == 0:
        var resultCode = (identifier shr (j + 1)) shl (j + 1)
        resultCode = resultCode or (int64(1) shl j)
        var height = currentHeight
        var remainingDownSteps = (j + currentHeight - 2) div 2
        for i in countdown(j - 1, 1):
          if height >= 2 and remainingDownSteps > 0:
            height = height - 1
            remainingDownSteps = remainingDownSteps - 1
          else:
            resultCode = resultCode or (int64(1) shl i)
            height = height + 1
        return resultCode
  var smallestCode: int64 = 0
  var powerOfTwo: int64 = 4
  var exponent = 2
  while exponent <= nodeCount - 1:
    smallestCode = smallestCode or powerOfTwo
    powerOfTwo = powerOfTwo shl 2
    exponent = exponent + 2
  return smallestCode
```

The first loop reads `nodeCount` bits, the position of the highest one plus one. Starting `slots` at one avoids counting the root twice. The scan visits at most `nodeCount - 1` bits, so the routine costs `O(m)`.

**Digit scanner.** The digit scanner turns the single input buffer into integers.

```nim
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The loop stops at the first non-digit, so it never reads past one number. Character arithmetic with 48 converts a digit without a parsing library. Each call costs time proportional to the digit count.

**Input and driver.** The driver reads all input at once and flushes output in blocks.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer: string
for _ in 1 .. caseCount:
  let identifier = int64(nextInt(inputData, i))
  let successorCode = nextIdentifier(identifier)
  outputBuffer.add $successorCode
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The loop runs exactly `caseCount` times, since the first integer gives the count. Block flushing keeps write calls rare and caps the buffer. One read pass costs `O(input bytes)`.

## Complexity

Each phase has a fixed bound per case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(input bytes) | one input string |
| Successor scan | O(m), with m at most 31 | 61 integers |
| Output | O(output bytes) | one flush block |

The height table never grows, so space stays constant per case.

The overall bounds depend on the test count.

| Measure | Big O |
| --- | --- |
| Time | O(input bytes + t · 31) |
| Space | O(input bytes + flush block) |

Building and sorting all trees of a size takes about 2.7 million steps at 31 bits. The bit scan needs a few dozen.
