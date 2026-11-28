# MENUTOUR — Menu Tour (SPOJ)
<https://www.spoj.com/problems/MENUTOUR/>

## Problem

Rachid must eat C courses in order, choosing one restaurant per course.
Restaurants sit on a grid, and walking costs the Manhattan distance between crossings.
Each chosen dish has a price, and the total must stay within budget B.
Find the least walking time, or print -1 when no tour fits.

| Item | Value |
|---|---|
| Courses C | 1 to 20 |
| Restaurants R | 1 to 1000 |
| Budget B | 0 to 100 |
| Grid coordinates | 1 to 1000 |
| Dish price | 0 to 40, where 0 means not offered |
| Time limit | 4000 ms |

The product of courses, budget, and restaurants drives the design.

The statement sample input follows verbatim.

```
3 5 9
1 1 1 0 0
3 1 0 9 7
6 2 0 0 3
3 5 0 2 0
6 5 8 0 9
```

```
12
```

## Idea

Imagine a shadow cast from each of the four corners of the city grid.
The cheapest walk to a crossing appears in the shadow of one corner.
The program keeps one DP layer per spent budget and advances it one course at a time.
A Fenwick tree tracks the best reduced cost while each shadow sweeps all restaurants.
Checking every restaurant pair per course would cost far more.

The final minimum over budgets is the answer.

## Why It Works

1. Manhattan distance equals the largest signed difference over four sign choices.
2. For one sign choice, valid predecessors satisfy u_p ≤ u_k and v_p ≤ v_k.
3. Sweeping by increasing u keeps all valid predecessors in the tree.
4. The tree stores A[p] minus u_p minus v_p, so a prefix minimum gives the best cost.
5. Adding u_k plus v_k turns the reduced cost back into walking time.
6. Dish prices move the DP state forward and never exceed the budget.

| Term | Meaning |
|---|---|
| layer | best times for one course and every budget |
| shadow | one of four sign choices for the coordinates |
| reduced cost | best time minus transformed row and column |
| Fenwick tree | structure for prefix minima over columns |

These facts let one sweep replace every predecessor pair.

A script trace of the sample shows the chosen tour.

```
budget 9: restaurants 1 -> 4 -> 3
price sum: 1 + 0 + 5 = 6
walk: (1,1) to (6,2) = 6, (6,2) to (3,5) = 6
total travel: 12
```

The traced travel of 12 minutes is the sample answer.

## Code

**Prefix-minimum tree.**
```nim
proc fenwickUpdate(tree: var seq[int64], index: int, value: int64) =
  var cursor = index
  while cursor < tree.len:
    if value < tree[cursor]:
      tree[cursor] = value
    cursor += (cursor and (-cursor))

proc fenwickQuery(tree: seq[int64], index: int): int64 =
  var cursor = index
  var best = infinity
  while cursor > 0:
    if tree[cursor] < best:
      best = tree[cursor]
    cursor -= (cursor and (-cursor))
  return best
```

Updates walk upward and queries walk downward. Both operations cost logarithmic time.

**Four-shadow transform.**
```nim
    for combo in 0..<4:
      for index in 0..<columnTree.len:
        columnTree[index] = infinity
      for restaurant in sweepOrders[combo]:
        let rowValue = transformedRow(combo, restaurant)
        let columnValue = transformedColumn(combo, restaurant)
        let previousCost = previousLayer[spent * restaurantCount + restaurant]
        let columnIndex = columnValue + verticalShift
        if previousCost < infinity div 2:
          let reduced = previousCost - int64(rowValue) - int64(columnValue)
          fenwickUpdate(columnTree, columnIndex, reduced)
        let candidate = fenwickQuery(columnTree, columnIndex) + int64(rowValue) + int64(columnValue)
        if candidate < distanceToRestaurant[restaurant]:
          distanceToRestaurant[restaurant] = candidate
```

Each shadow uses its own coordinate signs. The tree holds reduced predecessor costs.

**Course transition.**
```nim
    for restaurant in 0..<restaurantCount:
      let dishPrice = priceTable[restaurant * courseCount + course]
      let newCost = spent + dishPrice
      if dishPrice > 0 and newCost <= budgetLimit:
        let travelTime = distanceToRestaurant[restaurant]
        let target = newCost * restaurantCount + restaurant
        if travelTime < currentLayer[target]:
          currentLayer[target] = travelTime
```

The dish price selects the next budget cell. Zero prices are skipped as unoffered dishes.

**Opening layer.**
```nim
for index in 0..<previousLayer.len:
  previousLayer[index] = infinity
for restaurant in 0..<restaurantCount:
  let openingPrice = priceTable[restaurant * courseCount]
  if openingPrice > 0 and openingPrice <= budgetLimit:
    previousLayer[openingPrice * restaurantCount + restaurant] = 0'i64
```

Course one sets zero travel at each restaurant serving it. All other states start unreachable.

**Final answer.**
```nim
var bestTravel = infinity
for index in 0..<previousLayer.len:
  if previousLayer[index] < bestTravel:
    bestTravel = previousLayer[index]

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if bestTravel >= infinity div 2:
  appendOutput("-1")
else:
  appendOutput($(bestTravel))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The minimum over all budgets is printed. An unreachable state prints -1.

## Complexity

The course and budget loops multiply the transform work.

| Phase | Time | Space |
|---|---|---|
| Input read | O(R C) | input bytes |
| Order setup | O(R log R) | four orders |
| One budget transform | O(R log 1000) | tree and one row |
| All courses and budgets | O(C B R log 1000) | two DP layers |
| Output | one buffered write | buffer block |

Coordinates stay within 1000, so tree depth is bounded by ten.

| Measure | Big O |
|---|---|
| Time | O(C B R log 1000) |
| Space | O(B R + R) |

A naive transition checks every restaurant pair and costs O(C B R squared), so the sweeps win.
