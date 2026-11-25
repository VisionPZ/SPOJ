# KOPC12A — K12 - Building Construction (SPOJ)

<https://www.spoj.com/problems/KOPC12A/>

## Problem

Each building has a height and a per-brick price. Change every building to one common height `k` by adding or removing bricks, and pay that price per moved brick. Find the least total cost.

Input starts with the test count `T`. Each test gives the building count `n`, then `n` heights, then `n` prices. Output one total cost per test.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 15 |
| Buildings `n` | 1 to 10000 |
| Height per building | 0 to 10000 |
| Price per brick | 0 to 10000 |
| Judge limit | 1000 ms, 1536 MB |

Notation: `k` is the common height, and the price for each building applies to both adding and removing bricks.

Here is the sample input:

```
1
3
1 2 3
10 100 1000
```

Here is the sample output:

```
120
```

## Idea

The best common height is a weighted median, like picking a meeting point that minimises weighted travel distance. Bucket the prices by height, then sweep heights upward until the accumulated price reaches half the total. That height minimises the sum of weighted distances. Evaluating one height costs O(n), while the sweep costs O(n plus the height range). A naive search tries every height and rescans every building; the sweep needs one pass.

## Why It Works

1. The cost at target `k` is the sum over buildings of price times the height gap.
2. Raising `k` by one changes the cost by twice the price below `k`, minus the total price.
3. The cost stops falling when twice the accumulated price reaches the total price.
4. That crossing height is a weighted median and gives the minimum cost.
5. Heights and prices are bounded, so one upward scan over 10001 buckets finds it.

| Term | Meaning |
|---|---|
| `costAtHeight` | total price of buildings at one height |
| `totalWeight` | sum of all building prices |
| `cumulativeWeight` | price of buildings with height at most the current height |
| `bestHeight` | first height where twice the accumulated price reaches the total |
| `heightGap` | distance from one building to the chosen height |
| `totalCost` | final sum of weighted distances |

The table shows the values used by the sweep and the final sum.

A worked trace of the sample follows.

```
heights 1 2 3, prices 10 100 1000, total price 1110
k=1: 10*0 + 100*1 + 1000*2 = 2100
k=2: 10*1 + 100*0 + 1000*1 = 1010
k=3: 10*2 + 100*1 + 1000*0 = 120
cumulative price reaches 555 at height 3, so answer 120
```

The trace matches the sample output. Each product fits in 64 bits because the largest total stays near 10 to the 12.

## Code

**Input and buffer setup.** The reader loads stdin once and defines the buffered writer.

```nim
const flushBlockBytes = 1 shl 17
const maxBuildingHeight = 10000

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

The scanner reads decimal values across lines without caring about spacing. The writer collects answers and flushes only after a large block. Both helpers are shared by all test cases.

**Bucket sweep and cost total.** The code groups prices by height and finds the weighted median.

```nim
var costAtHeight = newSeq[int](maxBuildingHeight + 1)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let buildingCount = nextInt(inputData, scanPos)
  var heights = newSeq[int](buildingCount)
  var costs = newSeq[int](buildingCount)
  for index in 0 .. buildingCount - 1:
    heights[index] = nextInt(inputData, scanPos)
  var totalWeight: int64 = 0
  for index in 0 .. buildingCount - 1:
    costs[index] = nextInt(inputData, scanPos)
    totalWeight += int64(costs[index])
  for heightIndex in 0 .. maxBuildingHeight:
    costAtHeight[heightIndex] = 0
  for index in 0 .. buildingCount - 1:
    costAtHeight[heights[index]] += costs[index]
  var bestHeight = 0
  var cumulativeWeight: int64 = 0
  for heightIndex in 0 .. maxBuildingHeight:
    cumulativeWeight += int64(costAtHeight[heightIndex])
    if 2 * cumulativeWeight >= totalWeight:
      bestHeight = heightIndex
      break
  var totalCost: int64 = 0
  for index in 0 .. buildingCount - 1:
    let heightGap = abs(heights[index] - bestHeight)
    totalCost += int64(costs[index]) * int64(heightGap)
  appendOutput($totalCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The bucket array is cleared before each case. The scan stops at the first median crossing, and the final loop prices every move in 64 bits.

## Complexity

Each test reads its buildings once and sweeps a fixed height range.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input text | one input string |
| Bucket fill | O(n) | 10001 price buckets |
| Median sweep | at most 10001 steps | two scalar counters |
| Cost total | O(n) | building arrays |
| Output | one line per test | block buffer |

The height range is fixed, so the sweep does not grow with the building count.

| Measure | Big O |
|---|---|
| Time per test | O(n plus 10001) |
| Space per test | O(n plus 10001) |

Trying every height and every building would cost O(n times 10001); the weighted median sweep replaces that with one scan.
