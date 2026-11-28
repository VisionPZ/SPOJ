# SUPPER — Supernumbers in a permutation (SPOJ)

<https://www.spoj.com/problems/SUPPER/>

## Problem

The input gives several permutations, each a sequence of distinct numbers from 1 to n. For each, report every number that belongs to at least one longest increasing subsequence.

Input: ten test cases one after another. Each case gives `n`, then a permutation of `1..n`. Output: two lines per case, first the count of supernumbers, then the numbers in increasing order.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Test cases | exactly 10 |
| Permutation size `n` | 1 to 100,000 |
| Values | a permutation of `1..n` |
| Judge limit | 2250 ms, 1536 MB |

Large input and output call for one buffered read and batched writes.

The sample input and output:

```
5
2 1 4 5 3
```

```
4
1 2 4 5
```

## Idea

Check which numbers lie on a longest increasing run, like marking the cards that fit a longest rising row. Compute the best run ending at each number and the best run starting there.

The program uses patience sorting with binary search in both directions. Forward passes give the longest increasing subsequence ending at each position.

A reverse pass with negated values gives the one starting there. Each element costs `O(log n)`, so a case costs `O(n log n)`.

Enumerating all longest subsequences can take exponential time. Two length arrays decide membership with one addition per position.

A value is a supernumber when the two lengths through it reach the global maximum.

## Why It Works

Four facts justify the membership test.

1. Patience sorting keeps `tailValues[v]` as the smallest possible tail of a rising subsequence of length `v`.
2. `lowerBound` finds the first tail at least as large as the current value. That index plus one is the longest rising subsequence ending here.
3. Scanning right to left with negated values gives the longest rising subsequence starting here.
4. A longest subsequence through position `j` has length `endingLength[j] + startingLength[j] - 1`. It is a supernumber when that value equals `longestLength`.

The arrays and helpers used by the driver:

| Term | Meaning |
| --- | --- |
| `endingLength[j]` | longest rising subsequence ending at position `j` |
| `startingLength[j]` | longest rising subsequence starting at position `j` |
| `tailValues` | smallest tail for each subsequence length |
| `lowerBound` | binary search for the first tail not below a value |
| `isSupernumber[value]` | membership flag, indexed by value |

Scanning values from 1 to `n` prints the supernumbers in sorted order.

A script trace of the sample permutation:

```
permutation [2, 1, 4, 5, 3], longest length 3
| position | value | ending | starting | end+start-1 | supernumber |
| 1 | 2 | 1 | 3 | 3 | True |
| 2 | 1 | 1 | 3 | 3 | True |
| 3 | 4 | 2 | 2 | 3 | True |
| 4 | 5 | 3 | 1 | 3 | True |
| 5 | 3 | 2 | 1 | 2 | False |
supernumbers: [1, 2, 4, 5]
```

Value 3 reaches only length 2 through its position. It is absent from every longest subsequence.

## Code

**Scanner and binary search.** The scanner reads positive integers, and `lowerBound` scans the tail array.

```nim
const maxPermutationSize = 100000
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc lowerBound(tailValues: seq[int], tailCount: int, value: int): int =
  var i = 0
  var j = tailCount
  while i < j:
    let k = (i + j) div 2
    if tailValues[k] < value:
      i = k + 1
    else:
      j = k
  return i
```

The scanner skips non-digits and needs no sign branch.
`lowerBound` runs in `O(log n)` because it halves the index range each step.
It returns the first tail not smaller than `value`.

**Stored arrays and input.** Fixed arrays cover the largest permitted permutation.

```nim
var permutation = newSeq[int](maxPermutationSize + 1)
var endingLength = newSeq[int](maxPermutationSize + 1)
var startingLength = newSeq[int](maxPermutationSize + 1)
var tailValues = newSeq[int](maxPermutationSize + 1)
var isSupernumber = newSeq[bool](maxPermutationSize + 1)

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var outputBuffer: string
```

All arrays have `maxPermutationSize + 1` slots, so no case allocates memory.
The reader appends lines to one input string.
The loop stops when the parsed size falls below one.

**Two passes and output.** Forward, reverse, and membership scans share the same tail array.

```nim
while i < inputData.len:
  let size = nextInt(inputData, i)
  if size < 1: break
  for j in 0 ..< size:
    permutation[j] = nextInt(inputData, i)
  var tailCount = 0
  for j in 0 ..< size:
    let value = permutation[j]
    let k = lowerBound(tailValues, tailCount, value)
    endingLength[j] = k + 1
    tailValues[k] = value
    if k == tailCount: tailCount = tailCount + 1
  let longestLength = tailCount
  tailCount = 0
  for j in 0 ..< size:
    let k = size - 1 - j
    let value = -permutation[k]
    let l = lowerBound(tailValues, tailCount, value)
    startingLength[k] = l + 1
    tailValues[l] = value
    if l == tailCount: tailCount = tailCount + 1
  for value in 1 .. size:
    isSupernumber[value] = false
  var supernumberCount = 0
  for j in 0 ..< size:
    if endingLength[j] + startingLength[j] - 1 == longestLength:
      isSupernumber[permutation[j]] = true
  for value in 1 .. size:
    if isSupernumber[value]: supernumberCount = supernumberCount + 1
  outputBuffer.add $supernumberCount
  outputBuffer.add "\n"
  var written = 0
  for value in 1 .. size:
    if isSupernumber[value]:
      if written > 0: outputBuffer.add " "
      outputBuffer.add $value
      written = written + 1
      if outputBuffer.len >= flushBlockBytes:
        stdout.write outputBuffer
        outputBuffer.setLen 0
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The forward loop fills `endingLength` and records the maximum.
The reverse loop negates each value, which turns a falling tail into a rising one.
The membership loop marks values, and the final loop prints them in sorted order.

## Complexity

Each case performs two linear passes with a binary search per element.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Forward pass | O(n log n) | O(n) for two arrays |
| Reverse pass | O(n log n) | O(n) for two arrays |
| Membership and output | O(n) | O(n) for flags |
| Total per case | O(n log n) | O(n) |

At `n = 100,000` each pass performs about 1.7 million comparison steps.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n log n) per case, O(10 × n log n) overall |
| Space | O(n) per case, plus buffers |

Listing all longest subsequences can be exponential. Two patience-sorting passes decide membership in near-linear time.
