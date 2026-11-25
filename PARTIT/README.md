# PARTIT — Partition (SPOJ)
<https://www.spoj.com/problems/PARTIT/>

## Problem

A number m can be split into n sorted positive parts in many ways. Given m, n and a rank k, output the k-th split in lexicographic order.

A partition of m into n components is a sorted sequence a₁ ≤ a₂ ≤ … ≤ aₙ with sum m. Sort all such sequences lexicographically. Print the k-th one.

Input: the first integer is t, the number of cases. Each case gives m, n, and k on three separate lines. Output: the k components separated by spaces, one case per line.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | from the input |
| Parts n | 1 to 10 |
| Sum m | 1 to 220 |
| Rank k | at most the number of partitions |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The sample asks for the third partition of 9 into four parts:

```
1
9
4
3
```

```
1 1 3 4
```

The ordered partitions start 1 1 1 6, 1 1 2 5, then 1 1 3 4.

## Idea

Count whole blocks of answers, then skip blocks until the target rank fits. Think of looking up a word in a dictionary: you skip all words starting with A before reading the B section.

The program first fills a table `partitionWays`, where entry (i, j) counts partitions of i using parts no larger than j. During unranking, it tries each possible next part in increasing order. Each candidate owns a block of completions whose size comes from the table.

The count table costs O(220 × 10) once. Each case tests at most 220 candidates per part, so unranking costs O(n × m). Listing every partition before picking the k-th would be far slower, because the largest case has over 1.7 billion partitions.

Takeaway: a small count table turns unranking into a short walk over candidate values.

## Why It Works

Four facts make the unranking exact.

1. `partitionWays[i][j]` counts partitions of i using parts at most j. Such a partition either omits the part j, or removes one j and leaves a partition of i − j with parts at most j.
2. Fix the next part to candidate c and keep L parts left. Subtract c from every remaining part. The leftovers form a partition of `remainingSum − L × c` into at most L − 1 parts.
3. That leftover count is exactly `partitionWays[shiftedSum][partsLeft − 1]`. It is the number of answers starting with c, so it is one lexicographic block.
4. Blocks appear in increasing c. If rank exceeds a block size, subtract that size and move on. Otherwise the target lies inside, so keep c and recurse.

These are the quantities in one unranking step:

| Term | Meaning |
| --- | --- |
| `partitionWays[i][j]` | number of partitions of i with parts at most j |
| `rank` | 1-based position of the wanted partition |
| `remainingSum` | sum still to distribute |
| `candidate` | next part value being tested |
| `shiftedSum` | remainingSum − partsLeft × candidate |
| `blockSize` | number of completions that start with candidate |

A script traces the sample case from rank 3:

```
start remaining=9 partsLeft=4 minValue=1 rank=3
candidate 1: block 5, choose, rank 3 <= 5
candidate 1: block 3, choose, rank 3 <= 3
candidate 1: block 1, skip, rank 3 -> 2
candidate 2: block 1, skip, rank 2 -> 1
candidate 3: block 1, choose, rank 1 <= 1
last part = 4
```

The chosen parts are 1, 1, 3, and 4. Counts reach about 1.79 × 10⁹, so the table uses 64-bit integers.

## Code

**Input.** One buffer holds the stream, and the scanner returns 64-bit integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSum = 220
const maxParts = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

The scanner skips separators and stops at the buffer end. The 64-bit result avoids overflow on large counts. The cost is one pass over the input.

**Counts.** A filled table stores every block size the unranking needs.

```nim
var partitionWays: array[0..maxSum, array[0..maxParts, int64]]
for i in 0..maxSum:
  for j in 0..maxParts:
    if i == 0:
      partitionWays[i][j] = 1
    elif j == 0:
      partitionWays[i][j] = 0
    else:
      partitionWays[i][j] = partitionWays[i][j - 1]
      if i >= j:
        partitionWays[i][j] += partitionWays[i - j][j]
```

The base case gives one empty partition of zero. The `i >= j` guard skips a negative index. Filling the table costs O(maxSum × maxParts).

**Output.** One buffer collects answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush triggers every `flushBlockBytes` bytes. No write happens inside a case. The cost is one pass over the answer text.

**Driver.** Each case walks candidates and prints the chosen parts.

```nim
var chosenParts: array[0..maxParts - 1, int]

let caseCount = int(nextInt(inputData, i))
for j in 0..<caseCount:
  let totalSum = int(nextInt(inputData, i))
  let partCount = int(nextInt(inputData, i))
  var rank = nextInt(inputData, i)
  var remainingSum = totalSum
  var partsLeft = partCount
  var minValue = 1
  var k = 0
  while partsLeft > 0:
    if partsLeft == 1:
      chosenParts[k] = remainingSum
      k += 1
      partsLeft = 0
      break
    var candidate = minValue
    var picked = false
    while candidate * partsLeft <= remainingSum:
      let shiftedSum = remainingSum - partsLeft * candidate
      let blockSize = partitionWays[shiftedSum][partsLeft - 1]
      if rank > blockSize:
        rank -= blockSize
        candidate += 1
      else:
        chosenParts[k] = candidate
        k += 1
        remainingSum -= candidate
        partsLeft -= 1
        minValue = candidate
        picked = true
        break
    if not picked:
      chosenParts[k] = remainingSum
      k += 1
      partsLeft = 0
  for l in 0..<partCount:
    if l > 0:
      outputBuffer.add ' '
    appendOutput($(chosenParts[l]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The last part takes the whole remainder, so the loop stops early. The condition `candidate × partsLeft ≤ remainingSum` keeps parts sorted. The final write flushes the tail.

## Complexity

A one-time count table supports every case.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Count table | O(220 × 10) | O(220 × 10) |
| Unranking per case | O(n × m) | O(n) |
| Output | O(cases) | O(block size) |

The unranking dominates, with at most n × 220 candidate tests per case.

| Measure | Big O |
| --- | --- |
| Precomputation | O(m × n) |
| Time per case | O(n × m) |
| Working space | O(m × n) |

Generating partitions in order until rank k takes up to the full partition count, which reaches 1788625426 here.
