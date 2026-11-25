# CADYDIST — Candy Distribution (SPOJ)
<https://www.spoj.com/problems/CADYDIST/>

## Problem

Each class needs one distinct candy type, and the cost of a type is its price times the class size. Choose the pairing with the least total cost.

Input is a sequence of cases. Each case has `classCount`, then that many class sizes, then that many candy prices.

A line holding 0 ends the input. Print one line per case with the least cost.

The table lists the input and judge limits.

| item | bound |
|---|---|
| classes N | 1 to 100000 |
| class size Ci | 1 to 100000 |
| candy price Pi | 1 to 100000 |
| judge limit | 301 ms, 1536 MB |

A product of two bounds can reach 10 to the 10th power.

The sample below is verbatim from the statement.

```
4
1 1 1 1
2 2 2 2
5
10 80 37 22 109
6 8 8 20 15
0
```

```
8
2120
```

The second case pairs 109 students with the price of 6.

## Idea

Give the cheapest candy to the largest class, like fitting the biggest box into the smallest slot.

The algorithm sorts class sizes upward and candy prices downward, then sums aligned products. Sorting costs O(N log N) and the sum costs O(N).

Trying every assignment would cost N factorial pairings. The rearrangement inequality proves that the sorted pairing is optimal.

One pair of sorts settles the case.

## Why It Works

1. Take two classes with sizes a and b, where a is at least b.
2. Take two prices p and q, where p is at least q.
3. The crossed cost a times q plus b times p exceeds the sorted cost by (a - b) times (p - q).
4. Swapping any inverted pair never raises the cost.
5. Repeating the swaps ends at sizes rising and prices falling.

The table names the arrays and the total.

| term | meaning |
|---|---|
| `classSizes` | student counts, sorted upward |
| `candyPrices` | candy prices, sorted downward |
| `totalCost` | accumulated product sum |

The accumulator uses `int64` because a single product reaches 10 to the 10th power.

In the second sample case, sizes become 10, 22, 37, 80, 109. Prices become 20, 15, 8, 8, 6.

The sum is 200 plus 330 plus 296 plus 640 plus 654, which is 2120.

The comparator returns -1, 0, or 1 explicitly. Nim 0.19.4 needs an explicit comparator for a sequence sort.

## Code

**Input and comparators.** The reader takes the case size and both arrays.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

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

proc compareAscending(leftValue: int64, rightValue: int64): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc compareDescending(leftValue: int64, rightValue: int64): int =
  return compareAscending(rightValue, leftValue)

```

The zero case ends the loop. One comparator sorts upward and the other downward.

Both use `int64` values.

**Sorted pairing.** Two sorts align the largest class with the cheapest candy.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let classCount = nextInt(inputData, scanPos)
  if classCount == 0:
    break
  var classSizes = newSeq[int64](classCount)
  var candyPrices = newSeq[int64](classCount)
  for indexValue in 0 .. classCount - 1:
    classSizes[indexValue] = int64(nextInt(inputData, scanPos))
  for indexValue in 0 .. classCount - 1:
    candyPrices[indexValue] = int64(nextInt(inputData, scanPos))
  classSizes.sort(compareAscending)
  candyPrices.sort(compareDescending)
  var totalCost: int64 = 0
  for indexValue in 0 .. classCount - 1:
    totalCost = totalCost + classSizes[indexValue] * candyPrices[indexValue]
  appendOutput($totalCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case reads sizes before prices. The product sum stays in `int64`.

The buffer writes one line per case.

## Complexity

The table shows the work in each phase.

| phase | time | space |
|---|---|---|
| input read | 2N numbers per case | one input string |
| sort | two sorts of N values | two arrays |
| sum | N products | one accumulator |
| output | one line per case | block buffer |

N is the case size.

| measure | Big O |
|---|---|
| time | O(N log N) per case |
| space | O(N) per case |

Enumerating assignments would cost N factorial pairings. The sorted pairing gives the optimum in two sorts.
