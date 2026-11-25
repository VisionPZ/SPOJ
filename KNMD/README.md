# KNMD — Subsequences with modulo (SPOJ)
<https://www.spoj.com/problems/KNMD/>

## Problem

For every residue i modulo k, find the largest sum of a nonempty subsequence whose sum leaves remainder i. Print minus one when no such subsequence exists.

Input starts with n and k, followed by n positive integers. Output one line with k values, one for each residue from 0 to k minus one.

| quantity | bound |
|---|---|
| element count n | 1 to 1000000 |
| modulus k | 1 to 200 |
| each value Ai | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Keeping a small set per residue makes the large input manageable.

Sample input:

```
6 5
2 8 10 44 15 32
```

Sample output:

```
65 111 77 103 109
```

The first answer comes from dropping 2 and 44 from the total 111.

## Idea

Paying a bill is a good picture: keep as much as possible and set aside the smallest handful of coins that fixes the change. Since every number is positive, the best subsequence drops the cheapest group with the right remainder.

Keep the k smallest numbers for each remainder in a small max heap. A zero one dynamic program over those heaps finds the cheapest removable sum for every remainder. Each case costs O(n log k plus k cubed), far less than a pass over all n numbers for each residue.

Trying all subsequences would cost O(2 to the n), and a full dynamic program would cost O(n times k).

Find the cheapest group to drop, then subtract it from the total.

## Why It Works

1. All values are positive, so dropping less leaves a larger sum.
2. For residue i, the dropped group must have sum congruent to total minus i.
3. A cheapest dropped group has at most k minus one elements.
4. If it had k or more, two prefix sums would share a residue, and the middle part could be removed.
5. Keeping the k smallest values per remainder therefore preserves every cheapest group.
6. A zero one dynamic program over the kept values computes the cheapest sum for each residue.

| term | meaning |
|---|---|
| `totalSum` | sum of all input values |
| `perRemainderHeaps` | k smallest values kept for each remainder |
| `bestDistances` | cheapest removable sum for each residue |
| `removalRemainder` | residue that the dropped group must have |
| `answer` | total minus the cheapest removable sum |

The heap root holds the largest kept value for its remainder, so it leaves first.

In the sample the total is 111, which has remainder 1 modulo 5. For residue 0, the dropped group needs remainder 1. The cheapest such group is 2 plus 44, or 46, so the answer is 111 minus 46, which is 65. For residue 2, the dropped group needs remainder 4. The cheapest choice is 2 plus 32, or 34, so the answer is 77.

A result of zero means the empty subsequence, so the program prints minus one. An unreachable remainder also prints minus one. Sums use `int64` because n values can total one quadrillion.

## Code

**Input and buffer.** The reader loads all numbers and prepares output.

```nim
const flushBlockBytes = 1 shl 17
const infinityValue = high(int64) div 4

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
```

The scanner skips spaces and line breaks.
`appendOutput` writes bytes in blocks.

**Small heaps.** Each remainder keeps only its k smallest values.

```nim
let numberCount = nextInt(inputData, scanPos)
let modulus = nextInt(inputData, scanPos)
var perRemainderHeaps = newSeq[int64](modulus * (modulus + 1))
var heapSizes = newSeq[int](modulus)
var totalSum: int64 = 0

for numberIndex in 0 .. numberCount - 1:
  let value = int64(nextInt(inputData, scanPos))
  totalSum = totalSum + value
  let remainder = int(value mod int64(modulus))
  let base = remainder * (modulus + 1)
  let size = heapSizes[remainder]
  if size < modulus:
    perRemainderHeaps[base + size] = value
    var childIndex = size
    while childIndex > 0:
      let parentIndex = (childIndex - 1) div 2
      if perRemainderHeaps[base + parentIndex] >= perRemainderHeaps[base + childIndex]:
        break
      swap perRemainderHeaps[base + parentIndex], perRemainderHeaps[base + childIndex]
      childIndex = parentIndex
    heapSizes[remainder] = size + 1
  elif value < perRemainderHeaps[base]:
    perRemainderHeaps[base] = value
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      let rightChild = leftChild + 1
      var largestIndex = parentIndex
      if leftChild < modulus and perRemainderHeaps[base + leftChild] > perRemainderHeaps[base + largestIndex]:
        largestIndex = leftChild
      if rightChild < modulus and perRemainderHeaps[base + rightChild] > perRemainderHeaps[base + largestIndex]:
        largestIndex = rightChild
      if largestIndex == parentIndex:
        break
      swap perRemainderHeaps[base + parentIndex], perRemainderHeaps[base + largestIndex]
      parentIndex = largestIndex
```

The total accumulates in `int64`.
A new value enters its heap in logarithmic time.
Only values smaller than the heap root replace it.

**Residue table.** The sweep uses each kept value once.

```nim
var bestDistances = newSeq[int64](modulus)
var nextDistances = newSeq[int64](modulus)
for residue in 0 .. modulus - 1:
  bestDistances[residue] = infinityValue
bestDistances[0] = 0

for remainder in 0 .. modulus - 1:
  let base = remainder * (modulus + 1)
  for heapIndex in 0 .. heapSizes[remainder] - 1:
    let value = perRemainderHeaps[base + heapIndex]
    for residue in 0 .. modulus - 1:
      nextDistances[residue] = bestDistances[residue]
    for residue in 0 .. modulus - 1:
      if bestDistances[residue] < infinityValue:
        let target = (residue + remainder) mod modulus
        let candidate = bestDistances[residue] + value
        if candidate < nextDistances[target]:
          nextDistances[target] = candidate
    swap bestDistances, nextDistances

let totalRemainder = int(totalSum mod int64(modulus))
var firstValue = true
for residue in 0 .. modulus - 1:
  let removalRemainder = (totalRemainder - residue + modulus) mod modulus
  var answer: int64 = -1
  if bestDistances[removalRemainder] < infinityValue:
    let candidateAnswer = totalSum - bestDistances[removalRemainder]
    if candidateAnswer > 0:
      answer = candidateAnswer
  if not firstValue:
    appendOutput(" ")
  appendOutput($answer)
  firstValue = false
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A fresh copy enforces one use per value.
The empty group seeds residue zero with sum zero.
The last loop prints one value per residue.

## Complexity

Heap insertion is cheap, and the reduced table is small.

| phase | time | space |
|---|---|---|
| input read | one pass over n values | one input string |
| heap build | O(log k) per value | k heaps of k slots |
| residue table | O(k cubed) updates | two rows of k values |
| output | one line with k values | block buffer |

At the limits, the residue table holds at most 40000 kept values.

| measure | Big O |
|---|---|
| time | O(n log k + k^3) |
| extra space | O(k^2) |

A full dynamic program over all values would cost O(n times k).

The heap reduction keeps the residue table small enough for every case.
