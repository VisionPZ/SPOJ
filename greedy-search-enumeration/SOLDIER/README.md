# SOLDIER — Help the soldier (SPOJ)

<https://www.spoj.com/problems/SOLDIER/>

## Problem

A soldier buys one item of each of six equipment types and pays from a fixed budget. The value of the purchase is the lowest quality among the six items, so the task is to make that lowest quality as large as possible.

The first input line holds the item count `N` and the budget `T`. Each of the next `N` lines holds a type from 1 to 6, a price, and a quality. The output is one integer: the largest achievable lowest quality. Output 0 when no complete set fits the budget.

The bounds from the statement:

| item | bound |
|---|---|
| items N | 7 to 100 |
| budget T | 1 to 1000 |
| price and quality | 1 to T minus 1 |
| judge limit | 109 ms, 1536 MB |

The budget caps both price and quality, and six types must all be present.

Sample input:

```
7 53
5 8 2
2 4 8
6 8 13
1 13 12
4 5 1
3 2 7
3 13 5
```

Sample output:

```
1
```

## Idea

Treat a candidate quality as a bar that every chosen item must clear, like six friends each needing a ticket above the same height. For each bar, keep the cheapest qualifying item of each type and add the six prices.

The algorithm is a descending threshold scan with a per-type minimum-price pass. Each item costs one comparison, so one threshold costs O(N). Trying every threshold costs O(N times T), which stays small because both bounds are under 1000.

Enumerating every combination of six items costs the product of the six type counts, which grows quickly. The threshold scan replaces that product with a linear pass.

Testing bars from high to low returns the first feasible one, which is the optimum.

## Why It Works

1. If a set has lowest quality `candidateQuality`, every item in it has quality at least that value.
2. For a fixed bar, the cheapest qualifying item of each type gives the cheapest possible complete set.
3. That cheapest set fits whenever any complete set at that bar fits.
4. A bar that fails cannot be the answer, and every higher bar fails too.
5. The first feasible bar found while descending is therefore the maximum lowest quality.

The main terms and formulas:

| term | meaning |
|---|---|
| `candidateQuality` | current quality bar under test |
| `minimumPrices` | cheapest price per type at that bar |
| `totalPrice` | sum of the six cheapest prices |
| `bestQuality` | highest feasible bar found so far |

The table names the only values the scan needs to keep.

The gen.py oracle adds one item per type in turn and keeps the best minimum quality per spent price. For the sample it yields these two decisive bars:

```
bar 2: type 4 has only quality 1 -> no complete set
bar 1: prices 13 + 4 + 2 + 5 + 8 + 8 = 40 <= 53 -> feasible
```

The trace shows why the sample answer is 1 and not 2.

## Code

**Input and scanner.** One read loads stdin, and the hand parser skips separators.

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
```

The loop reads whole lines until stdin ends.
The scanner builds each value one digit at a time.
No test case count appears, because the statement supplies one case.

**Threshold scan.** Each bar selects the cheapest item of every type.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let itemCount = nextInt(inputData, scanPos)
let budgetLimit = nextInt(inputData, scanPos)
var itemTypes = newSeq[int](itemCount)
var itemPrices = newSeq[int](itemCount)
var itemQualities = newSeq[int](itemCount)
for itemIndex in 0 .. itemCount - 1:
  itemTypes[itemIndex] = nextInt(inputData, scanPos)
  itemPrices[itemIndex] = nextInt(inputData, scanPos)
  itemQualities[itemIndex] = nextInt(inputData, scanPos)

var bestQuality = 0
var candidateQuality = budgetLimit - 1
while candidateQuality >= 1 and bestQuality == 0:
  var minimumPrices = newSeq[int](7)
  for typeIndex in 0 .. 6:
    minimumPrices[typeIndex] = high(int)
  for itemIndex in 0 .. itemCount - 1:
    let equipmentType = itemTypes[itemIndex]
    if itemQualities[itemIndex] >= candidateQuality and equipmentType >= 1 and equipmentType <= 6:
      if itemPrices[itemIndex] < minimumPrices[equipmentType]:
        minimumPrices[equipmentType] = itemPrices[itemIndex]
  var totalPrice = 0
  var allTypesAvailable = true
  for equipmentType in 1 .. 6:
    if minimumPrices[equipmentType] == high(int):
      allTypesAvailable = false
    else:
      totalPrice += minimumPrices[equipmentType]
  if allTypesAvailable and totalPrice <= budgetLimit:
    bestQuality = candidateQuality
  candidateQuality -= 1

appendOutput($bestQuality)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan stops at the first feasible bar.
Types outside 1 to 6 are ignored, which covers incomplete input.
One buffered write emits the single answer line.

## Complexity

The scan repeats a short pass for each quality bar.

| phase | time | space |
|---|---|---|
| input read | one pass over N item lines | three arrays of N integers |
| threshold scan | up to T bars times N items | seven price slots |
| output | one line | block buffer |

The arrays dominate space, while the scan dominates time.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(N times T) |
| space | O(N) |

Enumerating all six-item combinations would cost the product of the type counts instead of a linear pass.

The threshold scan keeps the work bounded by two small input limits.
