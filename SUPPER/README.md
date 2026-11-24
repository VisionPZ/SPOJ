## Problem

Read ten permutations, one per test case. Each permutation holds every value from 1 to n once. A supernumber is a value that appears in at least one longest increasing subsequence. Print the count of supernumbers, then print their values in ascending order.

The judge fixes the size of one case and the budget for all ten.

| Limit | Value |
| --- | --- |
| Permutation size n | at most 100000 |
| Test cases | 10 |
| Time | 2250 ms |
| Memory | 1536 MB |

All ten cases share the same 2250 ms budget.

## Idea

For each position, find the longest increasing subsequence that ends there and the one that starts there. The position belongs to some longest increasing subsequence exactly when those two lengths add up to the full length plus one. Compute both lengths with a tails array, an array where `tailValues` holds the smallest last value for each subsequence length. A binary search places each value in O(log n) steps. A boolean array indexed by value then emits the supernumbers in ascending order with no sort.

Cost per element: O(log n) for the forward pass and O(log n) for the backward pass.

## Why It Works

Take any longest increasing subsequence and a position inside it. The values before that position form an increasing subsequence ending there, so their count is at most `endingLength[j]`. The values after it form an increasing subsequence starting there, so their count is at most `startingLength[j]`. Those two parts share the position, so their combined length is `endingLength[j] + startingLength[j] - 1`. This combined sequence is increasing, so it cannot exceed `longestLength`.

Now suppose the equality holds. The prefix subsequence ends at the position, and the suffix subsequence starts there. Every value in the first part is smaller than the value at the position, and every value in the second part is larger. Concatenating them gives an increasing subsequence of length `longestLength` that contains the position. Therefore the equality is both necessary and sufficient.

The position is `j`. The binary search returns the insertion slot `k` or `l`. The test for one position uses four terms.

```
    if endingLength[j] + startingLength[j] - 1 == longestLength:
```

- `endingLength[j]`: longest increasing subsequence ending at this position.
- `startingLength[j]`: longest increasing subsequence starting at this position.
- `- 1`: the value at this position appears in both lengths.
- `longestLength`: length of the longest increasing subsequence of the case.

For the sample permutation 2 1 4 5 3, the two passes give these lengths.

| Position | Value | endingLength | startingLength | Sum | Supernumber |
| --- | --- | --- | --- | --- | --- |
| 0 | 2 | 1 | 3 | 3 | yes |
| 1 | 1 | 1 | 3 | 3 | yes |
| 2 | 4 | 2 | 2 | 3 | yes |
| 3 | 5 | 3 | 1 | 3 | yes |
| 4 | 3 | 2 | 1 | 2 | no |

Only the value at position 4 fails the test, so the answer is 1 2 4 5.

## Code

```
const maxPermutationSize = 100000
const flushBlockBytes = 1 shl 17
```

The first constant fixes the largest legal array and the second sets the flush threshold. All work arrays are allocated once, so no case pays an allocation cost. The closed bound comes from the judge limit of 100000.

```
proc nextInt(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The loop advances until a digit appears, so spaces and newlines need no special handling. Each value has at most six digits. The scanner allocates nothing and costs O(1) per value.

```
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

The search halves the live prefix on each step, so it takes O(log n) comparisons. Lower bound keeps the strictly increasing rule intact. The live prefix always has `tailCount` entries.

```
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
while i < inputData.len:
  let size = nextInt(inputData, i)
  if size < 1: break
  for j in 0 ..< size:
    permutation[j] = nextInt(inputData, i)
```

The five arrays are sized once from the maximum legal permutation, so no case allocates. The input loop gathers every line into one string before parsing starts. The guard stops the empty case created by the trailing newline. Filling one case costs O(n).

```
  var tailCount = 0
  for j in 0 ..< size:
    let value = permutation[j]
    let k = lowerBound(tailValues, tailCount, value)
    endingLength[j] = k + 1
    tailValues[k] = value
    if k == tailCount: tailCount = tailCount + 1
  let longestLength = tailCount
```

The loop visits positions from 0 to size-1 in index order. A smaller tail always wins, so `tailValues` holds the best tail for each length. The guard extends the live prefix only for a longer subsequence. Cost is O(n log n).

```
  tailCount = 0
  for j in 0 ..< size:
    let k = size - 1 - j
    let value = -permutation[k]
    let l = lowerBound(tailValues, tailCount, value)
    startingLength[k] = l + 1
    tailValues[l] = value
    if l == tailCount: tailCount = tailCount + 1
```

The loop visits positions from size-1 down to 0. Negating the value turns a decreasing run in reverse order into an increasing run for the same binary search. This avoids a second comparison routine. Cost is O(n log n).

```
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

The first loop resets only values that this case can emit. Marking by value makes the second loop emit values in ascending order without a sort. The buffer flushes every 128 KiB, so output cost stays linear in bytes written.

## Complexity

Reading takes O(total numbers) time and one input buffer. The forward pass takes O(n log n) time for one case and uses one array of n integers. The backward pass takes O(n log n) time and reuses the tail array. Marking and printing take O(n) time and use one boolean array of n entries. For ten cases of size n, total time is O(10 n log n) and peak space is O(n) beyond the two buffers.

A naive method tries every subsequence, which costs O(2^n) time per case. Testing each pair of positions with dynamic programming costs O(n^2) time and O(n) space, still too slow at n = 100000. The tails method reduces each pass to O(log n) per element.
