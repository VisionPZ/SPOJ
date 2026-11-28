# MJOURNEY — Journey with Pigs (SPOJ)

<https://www.spoj.com/problems/MJOURNEY/>

## Problem

Assign one pig to each village so the total sale money is largest. Sale money for pig i in village j is its weight times the local price minus the fuel spend on the trip.

The input holds one case. Line one gives the pig count n and fuel cost per kilogram per kilometre t.

Line two lists n pig weights w_i. Line three lists n village distances d_j. Line four lists n pork prices p_j.

Output n pig numbers, one per village in input order, numbered from one.

| item | bound |
|---|---|
| pigs and villages n | 1 to 1000 |
| fuel cost t | 1 to 1000000000 |
| weights w_i | 1 to 1000000000 |
| distances d_j | 1 to 1000000000 |
| prices p_j | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Fuel cost for one pig in village j is t times d_j per kilogram, so the net rate is p_j minus t times d_j.

Sample input:

```
3 1
10 20 15
10 20 30
50 70 60
```

Sample output:

```
3 2 1
```

## Idea

Pairing heavy pigs with high rates is like pairing the heaviest boxes with the strongest movers: each sorted match beats every crossed match.

The net rate of a village is p_j minus t times d_j. Profit is the product of a pig weight and that rate, so the rearrangement inequality applies.

Sort weights and rates in the same order, then pair equal ranks. An insertion sort costs O(n squared) here. Trying every assignment costs O(n factorial) and cannot finish.

Take the net rate from prices and distances, sort both lists with their original numbers, and read off the pairs.

## Why It Works

1. Profit for pig i in village j equals w_i times (p_j minus t times d_j).
2. Call the bracket term the net rate of village j.
3. Swapping two crossed pairs of weights and rates raises profit by the product of their differences.
4. Repeating every beneficial swap ends with both lists in the same order.
5. That sorted pairing is therefore optimal.

| term | meaning |
|---|---|
| `fuelCost` | cost per kilogram per kilometre |
| `villageValues` | net rate of each village |
| `pigWeights` | weights paired with their input numbers |
| `villageNumbers` | input numbers paired with net rates |
| `chosenPigNumbers` | selected pig number for each village |

Each table row names an array that the driver fills before sorting.

In the sample the net rates are 50 minus 10 = 40, 70 minus 20 = 50, and 60 minus 30 = 30.

Sorted weights are 10 (pig 1), 15 (pig 3), 20 (pig 2). Sorted rates are 30 (village 3), 40 (village 1), 50 (village 2).

Pairing equal ranks sends pig 3 to village 1, pig 2 to village 2, and pig 1 to village 3. The answer is 3 2 1.

Rates use 64-bit integers because t times d_j reaches 1e18. Profit itself is never computed, so weight times rate cannot overflow.

## Code

**Input and rate computation.** The reader stores weights, distances, and prices, then derives each net rate.

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pigCount = nextInt(inputData, scanPos)
let fuelCost = int64(nextInt(inputData, scanPos))
var pigWeights = newSeq[int](pigCount)
var pigNumbers = newSeq[int](pigCount)
for pigIndex in 0 .. pigCount - 1:
  pigWeights[pigIndex] = nextInt(inputData, scanPos)
  pigNumbers[pigIndex] = pigIndex + 1
var villageDistances = newSeq[int64](pigCount)
for villageIndex in 0 .. pigCount - 1:
  villageDistances[villageIndex] = int64(nextInt(inputData, scanPos))
var villagePrices = newSeq[int64](pigCount)
for villageIndex in 0 .. pigCount - 1:
  villagePrices[villageIndex] = int64(nextInt(inputData, scanPos))
var villageValues = newSeq[int64](pigCount)
var villageNumbers = newSeq[int](pigCount)
for villageIndex in 0 .. pigCount - 1:
  villageValues[villageIndex] = villagePrices[villageIndex] - fuelCost * villageDistances[villageIndex]
  villageNumbers[villageIndex] = villageIndex + 1
```

Pig numbers start at one in input order.
Village numbers follow the order of the rate lines.
Each rate is stored as a 64-bit value.

**Rank sorting.** Two insertion sorts keep each number attached to its sort key.

```nim
for sortIndex in 1 .. pigCount - 1:
  var insertionIndex = sortIndex
  while insertionIndex > 0 and pigWeights[insertionIndex - 1] > pigWeights[insertionIndex]:
    let weightSwap = pigWeights[insertionIndex - 1]
    pigWeights[insertionIndex - 1] = pigWeights[insertionIndex]
    pigWeights[insertionIndex] = weightSwap
    let numberSwap = pigNumbers[insertionIndex - 1]
    pigNumbers[insertionIndex - 1] = pigNumbers[insertionIndex]
    pigNumbers[insertionIndex] = numberSwap
    insertionIndex -= 1

for sortIndex in 1 .. pigCount - 1:
  var insertionIndex = sortIndex
  while insertionIndex > 0 and villageValues[insertionIndex - 1] > villageValues[insertionIndex]:
    let valueSwap = villageValues[insertionIndex - 1]
    villageValues[insertionIndex - 1] = villageValues[insertionIndex]
    villageValues[insertionIndex] = valueSwap
    let numberSwap = villageNumbers[insertionIndex - 1]
    villageNumbers[insertionIndex - 1] = villageNumbers[insertionIndex]
    villageNumbers[insertionIndex] = numberSwap
    insertionIndex -= 1
```

Weights move with pig numbers.
Rates move with village numbers.
Strict comparisons keep the sort stable on ties.

**Pairing and output.** Ranks meet, and the answer returns to village order.

```nim
var chosenPigNumbers = newSeq[int](pigCount)
for pairIndex in 0 .. pigCount - 1:
  chosenPigNumbers[villageNumbers[pairIndex] - 1] = pigNumbers[pairIndex]
for villageIndex in 0 .. pigCount - 1:
  if villageIndex > 0:
    outputBuffer.add ' '
  appendOutput($chosenPigNumbers[villageIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The pair index is the shared rank in both sorted lists.
Spaces separate the numbers on one line.
The single final flush writes all numbers.

## Complexity

Sorting dominates the work after input parsing.

| phase | time | space |
|---|---|---|
| input read | one pass over three lines | four arrays of n values |
| insertion sort | two quadratic passes | no extra arrays |
| pairing and output | one pass over n ranks | one answer array |

The table shows that both sorts share the same cost shape.

| measure | Big O |
|---|---|
| time | O(n squared) |
| space | O(n) |

At n = 1000 the sort performs about one million shifts per list.
Checking all n factorial assignments would take far longer than the judge limit.
Sorted pairing gives the optimum with two short sorts and one output line.
