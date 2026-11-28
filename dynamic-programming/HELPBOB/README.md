# HELPBOB — Help Bob (SPOJ)

<https://www.spoj.com/problems/HELPBOB/>

## Problem

Bob buys pizzas at most once each, in any order, and wants the lowest price per total area. Coupons from earlier pizzas multiply the price of later pizzas, so the order changes the answer.

Input holds several cases. Each starts with `m`, followed by `m` lines of price, area, and coupon count.

Each pizza line then holds target index and discount percent pairs. A line with zero ends the input.

Output holds one price per area per case, rounded to four decimals.

The bounds from the statement:

| item | bound |
|---|---|
| pizzas per case | 1 to 15 |
| price and area | 1 to 10000 |
| coupons per pizza | 0 to m - 1 |
| discount percent | 1 to 50 |
| judge limit | 1783 ms, 1536 MB |

Coupons multiply, so two 50% coupons on one pizza leave a quarter of its price.

Sample input:

```
1
80 30 0
2
200 100 1 2 50
200 100 0
5
100 100 2 3 50 2 50
100 100 1 4 50
100 100 1 2 40
600 600 1 5 10
1000 10 1 1 50
0
```

This figure is the sample input copied from the statement.

Sample output:

```
2.6667
1.5000
0.5333
```

This figure is the sample output, one value per case.

## Idea

Think of coupons as stamps collected while walking through a set of pizzas; a later pizza gets every stamp gathered so far.

Try every subset and every order inside it, but share work with a bitmask DP that stores the cheapest cost for each bought set.

Each transition costs one multiplication, so a case costs O(m * 2^m). Enumerating all orders costs well over m! steps. The DP turns the order choice into a table over subsets.

## Why It Works

1. A coupon earned by pizza `j` applies only when pizza `j` was bought earlier.
2. For a fixed bought set, only the cheapest reachable cost can improve any ratio.
3. The last pizza in an order contributes its price times the product of coupons from the earlier pizzas.
4. Removing that last pizza leaves a smaller bought set, which the DP has already solved.
5. Dividing each set's cheapest cost by its total area and taking the minimum gives the answer.

The main terms:

| term | meaning |
|---|---|
| `discountFactors` | price multiplier earned by each pizza toward each other pizza |
| `factorTable` | multiplier for every pizza under every bought set |
| `minimumCosts` | cheapest cost to buy exactly the pizzas in a mask |
| `areaTotals` | total area of the pizzas in a mask |

The table names the arrays built before and during the DP.

A script traced both orders in the second sample case:

```
order 1,2: cost 200 + 200*1.00 = 400, area 200, ratio 2.0000
order 2,1: cost 200 + 200*0.50 = 300, area 200, ratio 1.5000
```

Buying the coupon pizza first gives the reported 1.5000.

The multiplier table uses the recurrence over the lowest set bit, so each mask needs one previous mask.

Float prices keep enough precision for four decimals. `appendRounded` scales by `decimalPlaces` and pads the fractional digits.

## Code

**Input and scanner.** The reader loads the whole case list and the scanner walks integer tokens.

```nim
const flushBlockBytes = 1 shl 17
const decimalPlaces = 10000
const impossibleCost = 1e100

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
```

The scanner ignores spaces and line breaks.
Coupon targets are converted to zero-based indexes while reading.
One output buffer serves all cases.

**Rounded writer.** A single helper writes one fixed-point answer line.

```nim
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendRounded(value: float) =
  let scaledValue = int64(value * float(decimalPlaces) + 0.5)
  var fractionDigits = $(scaledValue mod decimalPlaces)
  while fractionDigits.len < 4:
    fractionDigits = "0" & fractionDigits
  appendOutput($(scaledValue div decimalPlaces) & "." & fractionDigits)
  outputBuffer.add '\n'
```

Scaling rounds to four decimals without a format library.
Padding keeps trailing zeros in answers such as 1.5000.
The buffer flushes only after reaching `flushBlockBytes`.

**Coupon factors and DP.** The first loop builds multipliers, the second finds cheapest costs.

```nim
while true:
  let pizzaCount = nextInt(inputData, scanPos)
  if pizzaCount == 0:
    break
  var prices = newSeq[int](pizzaCount)
  var areas = newSeq[int](pizzaCount)
  var discountFactors = newSeq[seq[float]](pizzaCount)
  for pizzaIndex in 0 .. pizzaCount - 1:
    prices[pizzaIndex] = nextInt(inputData, scanPos)
    areas[pizzaIndex] = nextInt(inputData, scanPos)
    let couponCount = nextInt(inputData, scanPos)
    discountFactors[pizzaIndex] = newSeq[float](pizzaCount)
    for targetIndex in 0 .. pizzaCount - 1:
      discountFactors[pizzaIndex][targetIndex] = 1.0
    for couponIndex in 0 .. couponCount - 1:
      let couponTarget = nextInt(inputData, scanPos) - 1
      let discountPercent = nextInt(inputData, scanPos)
      discountFactors[pizzaIndex][couponTarget] = discountFactors[pizzaIndex][couponTarget] *
        (100.0 - float(discountPercent)) / 100.0

  let maskCount = 1 shl pizzaCount
  var factorTable = newSeq[seq[float]](maskCount)
  var areaTotals = newSeq[int](maskCount)
  for mask in 0 .. maskCount - 1:
    factorTable[mask] = newSeq[float](pizzaCount)
    if mask == 0:
      for pizzaIndex in 0 .. pizzaCount - 1:
        factorTable[mask][pizzaIndex] = 1.0
    else:
      var lowestIndex = 0
      while ((mask shr lowestIndex) and 1) == 0:
        lowestIndex += 1
      let previousMask = mask xor (1 shl lowestIndex)
      for pizzaIndex in 0 .. pizzaCount - 1:
        factorTable[mask][pizzaIndex] = factorTable[previousMask][pizzaIndex] *
          discountFactors[lowestIndex][pizzaIndex]
      areaTotals[mask] = areaTotals[previousMask] + areas[lowestIndex]

  var minimumCosts = newSeq[float](maskCount)
  for mask in 0 .. maskCount - 1:
    minimumCosts[mask] = impossibleCost
  minimumCosts[0] = 0.0
  for mask in 0 .. maskCount - 1:
    if minimumCosts[mask] >= impossibleCost:
      continue
    for pizzaIndex in 0 .. pizzaCount - 1:
      let pizzaBit = 1 shl pizzaIndex
      if (mask and pizzaBit) != 0:
        continue
      let nextMask = mask or pizzaBit
      let nextCost = minimumCosts[mask] + float(prices[pizzaIndex]) * factorTable[mask][pizzaIndex]
      if nextCost < minimumCosts[nextMask]:
        minimumCosts[nextMask] = nextCost

  var bestRatio = impossibleCost
  for mask in 1 .. maskCount - 1:
    let currentRatio = minimumCosts[mask] / float(areaTotals[mask])
    if currentRatio < bestRatio:
      bestRatio = currentRatio
  appendRounded(bestRatio)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The lowest set bit gives a previously computed mask.
Each transition adds one pizza as the last item in its order.
The final loop compares ratios over all nonempty masks.

## Complexity

Each case builds a multiplier table, then fills a cost table over all masks.

The cost breakdown by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over coupon pairs | one input string |
| factor table | O(m * 2^m) | m values per mask |
| cost DP | O(m * 2^m) | one cost per mask |
| output | one line per case | block buffer |

The two table phases dominate the read and write work.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(m * 2^m) per case |
| space | O(m * 2^m) |

Enumerating every ordering of every subset grows far faster than one transition per pizza and mask. The DP shares all orders that end with the same bought set.
