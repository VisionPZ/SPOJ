# MINVEST — Investment Money (SPOJ)

<https://www.spoj.com/problems/MINVEST/>

## Problem

Grow an initial capital over a fixed number of years by buying and selling bonds with no transaction cost. Each bond pays its yearly interest at the end of every year, and the owner chooses any mix of bonds.

The input starts with the test count. Each test gives the starting capital and year count, then the bond count and one value and interest per bond. Output one line per test with the final capital.

| item | bound |
|---|---|
| starting capital | at most 1000000 |
| years | at most 40 |
| bonds per test | 1 to 10 |
| bond value | a multiple of 1000 |
| bond interest | at most ten percent of its value |
| judge limit | 1000 ms, 1536 MB |

Bond values are multiples of 1000, so dividing every value and the capital by 1000 keeps all relevant amounts as integers.

Sample input:

```
1
10000 4
2
4000 400
3000 250
```

Sample output:

```
14050
```

## Idea

Choosing bonds is like filling a backpack at each weight: keep the best interest for every exact load, then reuse that answer next year.

Divide by 1000 and treat bond values as item weights and interests as item values. An unbounded knapsack table stores the best interest for each invested amount in thousands.

Each year adds the table entry for the current amount to the capital. Listing every possible bond mix would take exponential time. Filling the table once per test takes linear time in its size.

Divide by 1000, fill one unbounded knapsack table, and advance the capital once per year.

## Why It Works

1. Every bond value is a multiple of 1000, so thousands become the natural unit.
2. `bestInterest` at u units is the largest yearly interest bought with at most u thousands.
3. The unbounded recurrence tries every bond as the last purchase and reuses smaller entries.
4. Each year invests all complete thousands and leaves the remainder idle.
5. Interest is at most ten percent, so 40 years multiply capital by less than 46.

| term | meaning |
|---|---|
| `bondValues` | bond prices measured in thousands |
| `bondInterests` | yearly interest of each bond |
| `bestInterest` | best interest for each invested amount in thousands |
| `unitCap` | largest table index the test can need |
| `investedUnits` | complete thousands available in one year |
| `capital` | current amount of money |

Every term in the table appears in the driver code.

For the sample, the table gives 900 at 10 units, 1050 at 11 units, and 1200 at 12 units. The capital moves from 10000 to 10900, then 11800, then 12850, and finally 14050.

The table cap uses the ten percent interest limit, so no year can index past it. Leftover money below 1000 stays idle and is never lost.

## Code

**Input and knapsack fill.** The reader converts values to thousands and builds the interest table.

```nim
const flushBlockBytes = 1 shl 17
const growthHeadroom = 46

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let startingCapital = nextInt(inputData, scanPos)
  let yearCount = nextInt(inputData, scanPos)
  let bondCount = nextInt(inputData, scanPos)
  var bondValues = newSeq[int](bondCount)
  var bondInterests = newSeq[int](bondCount)
  for bondIndex in 0 .. bondCount - 1:
    bondValues[bondIndex] = nextInt(inputData, scanPos) div 1000
    bondInterests[bondIndex] = nextInt(inputData, scanPos)
  let unitCap = (startingCapital div 1000) * growthHeadroom + 100
  var bestInterest = newSeq[int](unitCap + 1)
  for investedUnits in 1 .. unitCap:
    var largestInterest = 0
    for bondIndex in 0 .. bondCount - 1:
      if bondValues[bondIndex] <= investedUnits:
        let candidate = bestInterest[investedUnits - bondValues[bondIndex]] + bondInterests[bondIndex]
        if candidate > largestInterest:
          largestInterest = candidate
    bestInterest[investedUnits] = largestInterest
```

The divisor turns bond prices into unit weights.
The table is rebuilt for each test because its bonds differ.
Increasing units make every smaller sub-answer available.

**Year simulation and output.** Each year reads one table entry and advances the capital.

```nim
  var capital = startingCapital
  for yearIndex in 0 .. yearCount - 1:
    let investedUnits = capital div 1000
    if investedUnits <= unitCap:
      capital += bestInterest[investedUnits]
  appendOutput($capital)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Division drops the idle remainder below 1000.
The guard keeps the index inside the table.
One line is written per test case.

## Complexity

The knapsack fill dominates each test case.

| phase | time | space |
|---|---|---|
| input read | one pass over d bonds per test | two bond arrays |
| knapsack fill | U times d relaxations | one table of U entries |
| year simulation | one table lookup per year | no extra arrays |

U is the number of thousands in the largest capital the test can reach.

| measure | Big O |
|---|---|
| time per test | O(U times d) |
| space per test | O(U) |

At the given limits U stays near 50000 and d stays at most 10.
Enumerating bond mixes would grow far faster than the bounded table.
Reusing one table across all years keeps the whole test case short.
