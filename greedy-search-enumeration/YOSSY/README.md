# YOSSY — Yossy, The King of IRYUDAT (SPOJ)

<https://www.spoj.com/problems/YOSSY/>

## Problem

Each soldier has a power and a food portion. An army is any subset of soldiers whose total food fits the supply, and its power is the sum of their powers. Different subsets count separately even when powers match. List the army powers from strongest to weakest, keeping k entries and writing zero when fewer armies exist.

Input gives n, n power-food pairs, the food supply s, and the list length k. Output k lines.

| item | bound |
|---|---|
| soldiers n | 1 to 2000 |
| power and food per soldier | 0 to 9999 |
| food supply s | 0 to 999999 |
| list length k | 1 to 40 |
| judge limit | 100 ms, 1536 MB |

For n above 15, power and food are generated without correlation.

Sample input:

```
4
45 3
30 5
45 9
10 5
15
4
```

Sample output:

```
90
85
75
75
```

## Idea

Sort soldiers by power per food, like packing the most valuable items first. Depth-first search decides include or exclude for each soldier and keeps the best k complete powers in a small heap. A fractional bound asks how much power split soldiers could still gain. When that bound cannot beat the heap's smallest entry, the branch is cut. Trying every subset costs exponential time, while pruning removes most branches on the random large cases. The heap preserves duplicates because two different subsets can reach the same power.

## Why It Works

1. Sorting by power per food makes a greedy fractional solution an upper bound.
2. Prefix sums of food and power give the bound in logarithmic time by binary search.
3. The whole soldiers that fit are counted, and the next soldier contributes a fraction.
4. A branch is cut only when current power plus that bound cannot beat the heap minimum.
5. Cutting on equality is safe because another equal power cannot change the top k values.
6. Every complete subset reaches a leaf and enters the heap if it qualifies.

| term | meaning |
|---|---|
| `soldierOrder` | soldier indices sorted by power per food |
| `fractionalBound` | optimistic remaining power from fractional packing |
| `topPowers` | min-heap holding the best k powers found |
| `currentPower` | power collected on the current search path |
| `usedFood` | food consumed on the current search path |

The bound is optimistic, so pruning never removes a better army.

A script trace over the sample soldiers gives these top armies:

```
subset soldiers   power  food
1 3               90     12
1 2 4             85     13
1 2               75     8
2 3               75     14
```

The two subsets with power 75 appear twice, matching the sample output.

Food supply 15 excludes subsets such as soldiers 1, 2, and 3, whose food totals 17.

## Code

**Input and ratio sort.** Soldiers are ordered by power per food with cross multiplication.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let soldierCount = nextInt(inputData, scanPos)
var powerOf = newSeq[int](soldierCount)
var foodOf = newSeq[int](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  powerOf[soldierIndex] = nextInt(inputData, scanPos)
  foodOf[soldierIndex] = nextInt(inputData, scanPos)
let foodSupply = nextInt(inputData, scanPos)
let listLength = nextInt(inputData, scanPos)

proc ratioBefore(firstIndex: int, secondIndex: int): bool =
  let leftProduct = int64(powerOf[firstIndex]) * int64(foodOf[secondIndex])
  let rightProduct = int64(powerOf[secondIndex]) * int64(foodOf[firstIndex])
  if leftProduct != rightProduct:
    return leftProduct > rightProduct
  return powerOf[firstIndex] > powerOf[secondIndex]
```

Cross multiplication avoids floating point comparisons.
Zero-food soldiers sort first because they give free power.
Insertion sort handles the small fixed list of soldier indices.

```nim
var soldierOrder = newSeq[int](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  soldierOrder[soldierIndex] = soldierIndex
for soldierIndex in 1 .. soldierCount - 1:
  let currentIndex = soldierOrder[soldierIndex]
  var insertionIndex = soldierIndex
  while insertionIndex > 0 and ratioBefore(currentIndex, soldierOrder[insertionIndex - 1]):
    insertionIndex = insertionIndex - 1
  var shiftIndex = soldierIndex
  while shiftIndex > insertionIndex:
    soldierOrder[shiftIndex] = soldierOrder[shiftIndex - 1]
    shiftIndex = shiftIndex - 1
  soldierOrder[insertionIndex] = currentIndex

var sortedPowers = newSeq[int](soldierCount)
var sortedFoods = newSeq[int](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  sortedPowers[soldierIndex] = powerOf[soldierOrder[soldierIndex]]
  sortedFoods[soldierIndex] = foodOf[soldierOrder[soldierIndex]]
powerOf = sortedPowers
foodOf = sortedFoods
```

The order array keeps indices stable during sorting.
Sorted arrays feed both prefix sums and the search.
Ties break by larger power for a deterministic order.

**Prefix sums and heap.** Prefix sums make bounds cheap, and the heap keeps the best k powers.

```nim
var foodPrefix = newSeq[int64](soldierCount + 1)
var powerPrefix = newSeq[int64](soldierCount + 1)
for soldierIndex in 0 .. soldierCount - 1:
  foodPrefix[soldierIndex + 1] = foodPrefix[soldierIndex] + int64(foodOf[soldierIndex])
  powerPrefix[soldierIndex + 1] = powerPrefix[soldierIndex] + int64(powerOf[soldierIndex])

var topPowers = newSeq[int64]()

proc pushPower(candidate: int64) =
  if topPowers.len < listLength:
    topPowers.add candidate
    var childIndex = topPowers.len - 1
    while childIndex > 0:
      let parentIndex = (childIndex - 1) div 2
      if topPowers[parentIndex] <= topPowers[childIndex]:
        break
      let swapValue = topPowers[parentIndex]
      topPowers[parentIndex] = topPowers[childIndex]
      topPowers[childIndex] = swapValue
      childIndex = parentIndex
  elif candidate > topPowers[0]:
    topPowers[0] = candidate
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= topPowers.len:
        break
      let rightChild = leftChild + 1
      var smallestChild = leftChild
      if rightChild < topPowers.len and topPowers[rightChild] < topPowers[leftChild]:
        smallestChild = rightChild
      if topPowers[parentIndex] <= topPowers[smallestChild]:
        break
      let swapValue = topPowers[parentIndex]
      topPowers[parentIndex] = topPowers[smallestChild]
      topPowers[smallestChild] = swapValue
      parentIndex = smallestChild
```

Prefix indexes start at zero and end after the last soldier.
The heap root always holds the smallest stored power.
Equal powers from different subsets are kept by replacement.

**Bound and search.** The fractional bound cuts branches that cannot improve the heap.

```nim
proc fractionalBound(startIndex: int, capacity: int64): int64 =
  var lowIndex = startIndex
  var highIndex = soldierCount
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex + 1) div 2
    if foodPrefix[middleIndex] - foodPrefix[startIndex] <= capacity:
      lowIndex = middleIndex
    else:
      highIndex = middleIndex - 1
  let wholeCount = lowIndex
  var bound = powerPrefix[wholeCount] - powerPrefix[startIndex]
  if wholeCount < soldierCount:
    let usedFood = foodPrefix[wholeCount] - foodPrefix[startIndex]
    let remainingFood = capacity - usedFood
    let nextFood = int64(foodOf[wholeCount])
    if nextFood > 0:
      bound = bound + int64(powerOf[wholeCount]) * remainingFood div nextFood
  return bound

proc searchArmies(startIndex: int, usedFood: int64, currentPower: int64) =
  if topPowers.len == listLength and currentPower + fractionalBound(startIndex, int64(foodSupply) - usedFood) <= topPowers[0]:
    return
  if startIndex == soldierCount:
    pushPower(currentPower)
    return
  let soldierFood = int64(foodOf[startIndex])
  let soldierPower = int64(powerOf[startIndex])
  if usedFood + soldierFood <= int64(foodSupply):
    searchArmies(startIndex + 1, usedFood + soldierFood, currentPower + soldierPower)
  searchArmies(startIndex + 1, usedFood, currentPower)
```

The binary search finds the most whole soldiers that fit.
The next soldier contributes a fractional share of its power.
Current power is added before comparing with the heap minimum.

**Output.** Powers are sorted descending and missing slots become zero.

```nim
searchArmies(0, 0, 0)

for powerIndex in 1 .. topPowers.len - 1:
  let currentPower = topPowers[powerIndex]
  var insertionIndex = powerIndex
  while insertionIndex > 0 and topPowers[insertionIndex - 1] < currentPower:
    topPowers[insertionIndex] = topPowers[insertionIndex - 1]
    insertionIndex = insertionIndex - 1
  topPowers[insertionIndex] = currentPower

for powerIndex in 0 .. topPowers.len - 1:
  appendOutput($(topPowers[powerIndex]))
  outputBuffer.add '\n'
for missingIndex in topPowers.len .. listLength - 1:
  appendOutput("0")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Insertion sort orders at most k stored powers.
Zero lines fill the list when fewer armies exist.
One buffer flush writes the whole answer.

## Complexity

The search visits branches until the fractional bound rules them out.

| phase | time | space |
|---|---|---|
| ratio sort | insertion sort over n indices | index and value arrays |
| bound setup | one prefix pass | two prefix arrays |
| search | pruned binary tree | recursion stack |
| output | sort and write k powers | block buffer |

Random large instances prune quickly because the bound is tight.

| measure | Big O |
|---|---|
| time | O(n log n + V), V is visited search nodes |
| space | O(n + k) |

Enumerating every subset would cost O(2^n) time, which is slower.
Branch and bound keeps only promising subsets, which is the takeaway.
