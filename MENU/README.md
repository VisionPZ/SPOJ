# MENU — Menu (SPOJ)

<https://www.spoj.com/problems/MENU/>

## Problem

Alfred cooks one dish each day. A dish costs money and carries a benefit. Cooking it again the next day earns half that benefit. A third day in a row earns nothing. He wants the largest benefit that fits his budget.

Let k be the days, n the dishes, and m the budget. Let c be a dish cost, v its benefit, and cMax the largest cost. Each case gives k, n, m, then n lines of c and v. A case of 0 0 0 ends the input.

Print the benefit with one decimal digit, then the k dish numbers. Follow each dish number with a space. Print only `0.0` when no menu fits the budget. Among menus with the largest benefit, print one with the smallest cost.

The bounds from the statement and judge page:

| Item | Bound |
|---|---|
| Days k | 1 to 21 |
| Dishes n | 1 to 50 |
| Budget m | 0 to 100 |
| Dish cost c | 1 to 50 |
| Dish benefit v | 1 to 10000 |
| Judge limit | 702 ms, 1536 MB |

The small budget and day count let one table hold the whole search.

The sample input and output, byte for byte:

```
2 1 5
3 5
3 5 20
2 5
18 6
1 1
3 3
2 3
0 0 0
```

```
0.0

13.0
1 5 1 

```

The first case has no affordable two-day menu, so it prints only `0.0`.

## Idea

Picture a scorecard with one row per day. Writing a dish name earns full points, writing it again earns half, and a third time earns none. Keep the best score for every last dish, repeat count, and money spent.

The program uses dynamic programming over states of day, dish, run length, and cost. Each state reads the best and second-best source dishes, so a transition costs constant time. Trying all n^k menus is slower, since n reaches 50 and k reaches 21.

A fixed sweep over the table replaces an exponential search.

## Why It Works

1. A run of one dish earns full benefit on day one, half on day two, and nothing later. Three run lengths describe every possible history.
2. A state records the last dish, its run length, and the exact money spent. Future choices depend only on those three values.
3. A new dish resets the run, so only its identity matters. The best and second-best source scores at one cost give that answer in constant time.
4. The table keeps the largest benefit at each exact cost. The final scan then picks the smallest cost among the largest benefits.

The terms that drive each transition:

| Term | Meaning |
|---|---|
| `2 * dishValue[dish]` | doubled benefit on a fresh day |
| `dishValue[dish]` | extra doubled benefit on a second day in a row |
| `deepValue` | extra doubled benefit on a third or later day, always zero |
| `costLimit` | largest cost any reachable state can carry |
| `secondValue` | best source score from a dish other than `topDish` |

Doubling every benefit keeps all arithmetic in whole numbers and preserves the .5 endings.

A script traces the second sample case, which has three days and a budget of 20:

```
day dish run spent doubled
  1    1   1     2      10
  2    5   1     4      16
  3    1   1     6      26
benefit = 26/2 = 13.0, total cost = 6
dish 1 twice then dish 5: 21 doubled = 10.5
```

The chain spends 6 and reaches 26 doubled, which prints as 13.0.

## Code

**Constants.** Three fixed values reused by every case.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unreachable = -1000000000
```

`firstDigitValue` turns a digit byte into its value. `flushBlockBytes` sets the 256 KiB write block. `unreachable` marks a state no menu can reach.

**Digit scanner.** One integer is read without building a token string.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scanner skips spaces and newlines before each number. It builds the value one digit at a time, with no token object. Inputs are non-negative, so no sign branch is needed.

**Bulk input and block output.** The stream is read once, then written in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each line joins `inputData`, so blank lines cannot desync the scanner. `appendOutput` writes only when the buffer reaches `flushBlockBytes`. `setLen 0` reuses the same allocation for the next block.

**State layout and day one.** One flat array holds every day, run, dish, and cost.

```nim
  var dishCost = newSeq[int](dishCount + 1)
  var dishValue = newSeq[int](dishCount + 1)
  var largestCost = 0
  for dish in 1 .. dishCount:
    dishCost[dish] = nextInt(inputData, scanPos)
    dishValue[dish] = nextInt(inputData, scanPos)
    if dishCost[dish] > largestCost: largestCost = dishCost[dish]

  let costLimit = min(budget, dayCount * largestCost)
  let stride = costLimit + 1
  let layerSize = (dishCount + 1) * stride
  var allStates = newSeq[int]((dayCount + 1) * 3 * layerSize)

  let firstLayer = 3 * layerSize
  for pos in firstLayer .. firstLayer + 3 * layerSize - 1:
    allStates[pos] = unreachable
  for dish in 1 .. dishCount:
    let price = dishCost[dish]
    if price <= costLimit:
      allStates[firstLayer + dish * stride + price] = 2 * dishValue[dish]
```

`costLimit` never exceeds the most any menu can spend. Three layers of `layerSize` hold run lengths 1, 2, and 3. Day one starts every affordable dish at doubled benefit.

**Day sweep.** Each day reads the previous layer and fills the next one.

```nim
  for dayIndex in 1 ..< dayCount:
    let sourceLayer = dayIndex * 3 * layerSize
    let targetLayer = sourceLayer + 3 * layerSize
    for pos in targetLayer .. targetLayer + 3 * layerSize - 1:
      allStates[pos] = unreachable
    for spent in 0 .. costLimit:
      var topValue = unreachable
      var topDish = 0
      var secondValue = unreachable
      for dish in 1 .. dishCount:
        let base = sourceLayer + dish * stride + spent
        var dishBest = allStates[base]
        if allStates[base + layerSize] > dishBest: dishBest = allStates[base + layerSize]
        if allStates[base + 2 * layerSize] > dishBest: dishBest = allStates[base + 2 * layerSize]
        if dishBest > topValue:
          secondValue = topValue
          topValue = dishBest
          topDish = dish
        elif dishBest > secondValue and dish != topDish:
          secondValue = dishBest
      for dish in 1 .. dishCount:
        let newSpent = spent + dishCost[dish]
        if newSpent > costLimit: continue
        let targetBase = targetLayer + dish * stride + newSpent
        let switchSource = if dish == topDish: secondValue else: topValue
        if switchSource > unreachable div 2:
          let candidate = switchSource + 2 * dishValue[dish]
          if candidate > allStates[targetBase]: allStates[targetBase] = candidate
        let sourceBase = sourceLayer + dish * stride + spent
        let firstRunValue = allStates[sourceBase]
        if firstRunValue > unreachable div 2:
          let candidate = firstRunValue + dishValue[dish]
          if candidate > allStates[targetBase + layerSize]: allStates[targetBase + layerSize] = candidate
        let secondRunValue = allStates[sourceBase + layerSize]
        let thirdRunValue = allStates[sourceBase + 2 * layerSize]
        let deepValue = if secondRunValue > thirdRunValue: secondRunValue else: thirdRunValue
        if deepValue > unreachable div 2 and deepValue > allStates[targetBase + 2 * layerSize]:
          allStates[targetBase + 2 * layerSize] = deepValue
```

The loop visits each cost once, so the sweep costs O(n * costLimit) per day. `secondValue` lets a dish exclude itself without scanning all sources again. A third or later run adds nothing, so only the score moves forward.

**Winner scan.** The largest benefit wins; the smallest cost breaks ties.

```nim
  let finalLayer = dayCount * 3 * layerSize
  var bestBenefit = unreachable
  var bestCost = 0
  var bestRun = 0
  var bestDish = 0
  for runIndex in 0 .. 2:
    let runBase = finalLayer + runIndex * layerSize
    for dish in 1 .. dishCount:
      let dishBase = runBase + dish * stride
      for spent in 0 .. costLimit:
        let value = allStates[dishBase + spent]
        if value <= unreachable div 2: continue
        if value > bestBenefit or (value == bestBenefit and spent < bestCost):
          bestBenefit = value
          bestCost = spent
          bestRun = runIndex
          bestDish = dish

  if bestBenefit <= unreachable div 2:
    appendOutput("0.0\n\n")
    continue
```

The scan visits run, dish, and cost in a fixed order. A case with no reachable state prints only `0.0`.

**Backtracking.** Each chosen state points back to the state that produced it.

```nim
  var menu = newSeq[int](dayCount + 1)
  var currentDay = dayCount
  var currentRun = bestRun
  var currentDish = bestDish
  var currentCost = bestCost
  var currentValue = bestBenefit
  while currentDay >= 1:
    menu[currentDay] = currentDish
    if currentDay == 1: break
    let previousCost = currentCost - dishCost[currentDish]
    let previousLayer = (currentDay - 1) * 3 * layerSize
    if currentRun == 0:
      let wanted = currentValue - 2 * dishValue[currentDish]
      var found = false
      for runIndex in 0 .. 2:
        for previousDish in 1 .. dishCount:
          if previousDish == currentDish: continue
          let pos = previousLayer + runIndex * layerSize + previousDish * stride + previousCost
          if allStates[pos] == wanted:
            currentRun = runIndex
            currentDish = previousDish
            currentValue = wanted
            found = true
            break
        if found: break
    elif currentRun == 1:
      currentValue = currentValue - dishValue[currentDish]
      currentRun = 0
    else:
      let posTwo = previousLayer + layerSize + currentDish * stride + previousCost
      let posThree = previousLayer + 2 * layerSize + currentDish * stride + previousCost
      if allStates[posTwo] == currentValue:
        currentRun = 1
      elif allStates[posThree] == currentValue:
        currentRun = 2
    currentCost = previousCost
    currentDay -= 1
```

A fresh run looks for another dish with the required score. A second run subtracts half the benefit; a third run subtracts none. The chain reconstructs exactly k dish numbers.

**Emit.** The benefit and menu go to the one output buffer.

```nim
  appendOutput($(bestBenefit div 2))
  appendOutput(".")
  if bestBenefit mod 2 == 0: appendOutput("0") else: appendOutput("5")
  appendOutput("\n")
  for dayIndex in 1 .. dayCount:
    appendOutput($(menu[dayIndex]))
    appendOutput(" ")
  appendOutput("\n\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Doubling makes the decimal digit a simple parity test. Each dish number is followed by a space, as the sample shows. The last write flushes the remaining bytes.

## Complexity

The table dominates both time and space.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Dish parse | one pass over n dishes | two dish arrays |
| Day sweep | k times O(n * costLimit) | one flat table |
| Winner scan | O(3 * n * costLimit) | no new storage |
| Backtrack | O(k * n) | k dish numbers |
| Output | one write per block | block buffer |

The day sweep and winner scan both stay inside the table size.

The overall bounds for one case:

| Measure | Big O |
|---|---|
| Time | O(k * n * min(m, k * cMax)) |
| Space | O(k * n * min(m, k * cMax)) |

Trying all n^k menus takes exponential time, while this table stays polynomial.
