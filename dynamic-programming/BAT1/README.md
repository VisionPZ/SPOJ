# BAT1 — BATMAN1 (SPOJ)

<https://www.spoj.com/problems/BAT1/>

## Problem

Choose which weapon batches to open and buy weapons to maximise total power within a fixed budget. Opening a batch costs money once, and each batch then offers unlimited copies of its weapon types. Output the largest power rating affordable.

Input starts with the number of test cases. Each case gives batch count, weapon types per batch, and budget. Then come the opening costs, all weapon costs, and all weapon ratings. Output one maximum rating per case.

The statement gives these bounds.

| item | bound |
|---|---|
| batches n | 1 to 20 |
| weapon types per batch m | 1 to 20 |
| budget k | up to 1000 |
| weapon cost | up to 20 |
| weapon rating | up to 100 |
| judge limit | 1000 ms, 1536 MB |

The budget sets the size of the DP table.

Sample input:

```
1
2 4 20
3 4
3 2 3 2
3 2 3 5
3 2 3 2
4 5 6 5
```

Sample output:

```
40
```

## Idea

Treat opening a batch as paying a toll before its weapons become available, then run unlimited knapsack as you pass each batch.

The algorithm keeps one value per amount spent and updates it batch by batch. Opening a batch shifts the reachable amounts by its toll, and complete knapsack adds its weapons. Each batch costs O(m k) work. Trying every subset of batches would need 2^n trials, which is far larger.

## Why It Works

1. Every opened batch adds its opening cost once to the total spent.
2. Weapons from a batch are unlimited, so a complete knapsack handles that batch.
3. Purchases commute, so all weapons from a batch can be bought at its step.
4. Keeping the best rating for each total spent merges all opening choices.
5. Taking the maximum over amounts up to the budget gives the answer.

The main terms are listed below.

| term | meaning |
|---|---|
| `openCosts` | the toll for opening each batch |
| `weaponCosts` | the price of each weapon type |
| `weaponRatings` | the power of each weapon type |
| `bestBySpent` | best rating for each total amount spent |
| `openedBatch` | values after paying one opening toll |

The toll shift and the knapsack step together model every opened batch.

A script trace shows the DP after each batch on two cases.

```
counterexample n=3 m=1 k=14 open=[1,1,1] costs=[5,3,7] ratings=[6,3,20]
after batch 1: best=12 dp14=-1
after batch 2: best=12 dp14=12
after batch 3: best=26 dp14=26
sample n=2 m=4 k=20
after batch 1: best=17 dp14=17
after batch 2: best=40 dp14=40
```

Opening batches 1 and 3 reaches rating 26, and the sample reaches 40.

A batch with zero budget left cannot be opened, so that shift is skipped.

## Code

**Input and helpers.** The reader loads the cases and the output buffer collects answers.

```nim
const flushBlockBytes = 1 shl 17
const unreachableValue = -1

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

All numbers, including ratings, come from the same scanner.
The buffer writes once per block instead of once per case.

**Reading one case.** The code loads opening costs, then costs, then ratings.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let batchCount = nextInt(inputData, scanPos)
  let weaponKinds = nextInt(inputData, scanPos)
  let budget = nextInt(inputData, scanPos)
  let totalWeaponKinds = batchCount * weaponKinds
  var openCosts = newSeq[int](batchCount)
  for batchIndex in 0 ..< batchCount:
    openCosts[batchIndex] = nextInt(inputData, scanPos)
  var weaponCosts = newSeq[int](totalWeaponKinds)
  for weaponIndex in 0 ..< totalWeaponKinds:
    weaponCosts[weaponIndex] = nextInt(inputData, scanPos)
  var weaponRatings = newSeq[int](totalWeaponKinds)
  for weaponIndex in 0 ..< totalWeaponKinds:
    weaponRatings[weaponIndex] = nextInt(inputData, scanPos)
```

The flat arrays use batch times types plus type as the index.
Reading all three blocks in order matches the statement layout.

**Batch DP.** Each batch shifts the table by its toll, then adds its weapons.

```nim
  var bestBySpent = newSeq[int](budget + 1)
  for spent in 0 .. budget:
    bestBySpent[spent] = unreachableValue
  bestBySpent[0] = 0
  for batchIndex in 0 ..< batchCount:
    var openedBatch = newSeq[int](budget + 1)
    for spent in 0 .. budget:
      openedBatch[spent] = unreachableValue
    let openingPrice = openCosts[batchIndex]
    if openingPrice <= budget:
      for spent in 0 .. budget - openingPrice:
        if bestBySpent[spent] >= 0:
          let targetSpent = spent + openingPrice
          if openedBatch[targetSpent] < bestBySpent[spent]:
            openedBatch[targetSpent] = bestBySpent[spent]
    for weaponIndex in 0 ..< weaponKinds:
      let flatIndex = batchIndex * weaponKinds + weaponIndex
      let weaponPrice = weaponCosts[flatIndex]
      let weaponPower = weaponRatings[flatIndex]
      if weaponPrice <= 0 or weaponPrice > budget:
        continue
      for spent in weaponPrice .. budget:
        if openedBatch[spent - weaponPrice] >= 0:
          let candidate = openedBatch[spent - weaponPrice] + weaponPower
          if openedBatch[spent] < candidate:
            openedBatch[spent] = candidate
    for spent in 0 .. budget:
      if openedBatch[spent] > bestBySpent[spent]:
        bestBySpent[spent] = openedBatch[spent]
  var bestRating = 0
  for spent in 0 .. budget:
    if bestBySpent[spent] > bestRating:
      bestRating = bestBySpent[spent]
  appendOutput($bestRating)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The toll shift runs before any weapon from that batch is bought.
The forward loop over amounts allows unlimited copies of each weapon.
Taking the maximum at the end covers any amount up to the budget.

## Complexity

Each batch scans the budget once per weapon type.

| phase | time | space |
|---|---|---|
| input read | one pass over the case numbers | one input string |
| toll shift | one pass over the budget | one table of budget entries |
| knapsack | m passes over the budget | one table of budget entries |
| output | one line per case | block buffer |

The knapsack passes dominate the work per batch.

| measure | Big O |
|---|---|
| time | O(n m k) per case |
| space | O(k) per case |

Enumerating all 2^n opening sets would grow far faster than the linear-in-batches DP.

Shifting once and knapsacking once per batch keeps every case small.
