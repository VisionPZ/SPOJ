# SPACESHIP — Spaceship (SPOJ)

<https://www.spoj.com/problems/SPACESHIP/>

## Problem

A flying disc must gather at least N monitors, keyboards, and processors from at most M shops and stop as soon as the sets are complete. Find the least squared-distance travel cost from the starting point to such a trip.

Input gives N, then the starting coordinates X Y Z, then M, then two lines per shop. The first shop line holds its coordinates, and the second holds its monitor, keyboard, and processor counts. One line holds the minimum cost.

| item | bound |
|---|---|
| required sets N | 1 to 20 |
| shops M | 1 to 10 |
| coordinates | 0 to 500 |
| parts per shop | 0 to 20 |
| judge limit | 3000 ms, 1536 MB |

Travel between two points costs the sum of squared coordinate differences, with no square root.

Sample input:

```
1
0 0 0
2
10 0 0
2 5 7
0 10 0
0 3 9
```

Sample output:

```
100
```

## Idea

Squared distance is not a true metric, so stopping at a shop on the way can cost less than flying straight. Compute shortest travel costs between all stops first, like planning the cheapest leg between every pair of stations. Then try every subset and order of shops, keeping the cheapest trip that supplies all sets.

The shop count is at most ten, so subset dynamic programming replaces factorial order enumeration. Legendre-style brute force over every full permutation would repeat many identical tails.

## Why It Works

1. Passing through a shop collects its parts, so a visit never needs repeating for parts.
2. All leg costs are positive, so a shortest leg uses any useful intermediate shop.
3. Repeated relaxation over all node pairs gives those shortest legs.
4. A subset state records which shops have supplied parts, and a last shop records the current position.
5. Extending a state by one unvisited shop adds the precomputed leg cost.
6. The cheapest finished state whose part totals reach N is the answer.

| term | meaning |
|---|---|
| `travelCosts` | shortest squared cost between any two nodes |
| `bestCosts` | cheapest trip reaching a subset and ending at one shop |
| `monitorTotals` | capped monitor count for each shop subset |

Capping totals at N keeps every state small.

The script example from the second statement sample has N = 5. The direct leg from the start to shop 2 costs 10858. The leg through shop 0 costs 7892 + 2650 = 10542. The oracle reports 10542.

The first sample needs one set, and shop 0 already supplies it for a cost of 100.

## Code

**Input and distance table.** The reader loads the start, the shops, and their parts.

```nim
let requiredSets = int64(nextInt(inputData, scanPos))
let startX = int64(nextInt(inputData, scanPos))
let startY = int64(nextInt(inputData, scanPos))
let startZ = int64(nextInt(inputData, scanPos))
let shopCount = nextInt(inputData, scanPos)

var shopX = newSeq[int64](shopCount)
var shopY = newSeq[int64](shopCount)
var shopZ = newSeq[int64](shopCount)
var monitorsAvailable = newSeq[int64](shopCount)
var keyboardsAvailable = newSeq[int64](shopCount)
var processorsAvailable = newSeq[int64](shopCount)
for shopIndex in 0 .. shopCount - 1:
  shopX[shopIndex] = int64(nextInt(inputData, scanPos))
  shopY[shopIndex] = int64(nextInt(inputData, scanPos))
  shopZ[shopIndex] = int64(nextInt(inputData, scanPos))
  monitorsAvailable[shopIndex] = int64(nextInt(inputData, scanPos))
  keyboardsAvailable[shopIndex] = int64(nextInt(inputData, scanPos))
  processorsAvailable[shopIndex] = int64(nextInt(inputData, scanPos))
```

Each shop occupies one token pair of lines.
Coordinates and costs use wide integers.
The start is node zero in the distance table.

**Shortest legs.** Repeated relaxation lets intermediate shops shorten every leg.

```nim
for viaNode in 0 .. nodeCount - 1:
  for firstNode in 0 .. nodeCount - 1:
    for secondNode in 0 .. nodeCount - 1:
      let candidateCost = travelCosts[firstNode][viaNode] + travelCosts[viaNode][secondNode]
      if candidateCost < travelCosts[firstNode][secondNode]:
        travelCosts[firstNode][secondNode] = candidateCost
```

At most eleven nodes take part.
The diagonal stays zero.
Every leg becomes the cheapest possible route.

**Subset search.** Each state extends to every shop not yet in its subset.

```nim
for mask in 1 .. maskCount - 1:
  for lastShop in 0 .. shopCount - 1:
    let currentCost = bestCosts[mask][lastShop]
    if currentCost >= unreachableCost:
      continue
    for nextShop in 0 .. shopCount - 1:
      if (mask and (1 shl nextShop)) != 0:
        continue
      let nextMask = mask or (1 shl nextShop)
      let candidateCost = currentCost + travelCosts[lastShop + 1][nextShop + 1]
      if candidateCost < bestCosts[nextMask][nextShop]:
        bestCosts[nextMask][nextShop] = candidateCost
```

Bit masks encode visited shops.
Unreachable states are skipped.
The final scan checks part totals and takes the least cost.

## Complexity

The cost table and the subset search are the two large phases.

| phase | time | space |
|---|---|---|
| input read | one pass over shop tokens | shop arrays |
| shortest legs | three loops over at most eleven nodes | node distance table |
| subset search | subsets times last shop times next shop | state table |
| answer scan | one pass over subsets | three subset total arrays |

The shop bound keeps the subset table tiny.

| measure | Big O |
|---|---|
| time | O(M^3 + 2^M M^2) |
| space | O(2^M M + M^2) |

Enumerating every shop permutation would take factorial time for the largest shop count. Subset dynamic search reuses each partial trip once.
