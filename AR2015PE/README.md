# AR2015PE — Queue of Soldiers (SPOJ)

<https://www.spoj.com/problems/AR2015PE/>

## Problem

Soldiers pass through a valley in some order of their heights. A soldier dies when an earlier soldier is strictly shorter. Count the orderings of the given heights that kill exactly K soldiers, modulo 1000000007.

The first line holds the test count. Each case gives N and K, then N heights. At most 100 distinct heights occur, and at most 1000 soldiers share one height. Print `Case x: y` for each case.

| item | bound |
|---|---|
| test cases | 1 to 20 |
| soldiers N | 1 to 50000 |
| deaths K | 0 to 1000 |
| distinct heights | at most 100 |
| judge limit | 1000 ms, 1536 MB |

The product of distinct heights and K drives the dynamic program design.

Sample input:

```
3
3 1
1 2 3
3 1
1 2 2
3 2
1 2 3
```

Sample output:

```
Case 1: 3
Case 2: 1
Case 3: 2
```

## Idea

Think of inserting each height group into a row that already contains shorter soldiers, like adding taller books to a shelf. A new soldier survives only at the front; elsewhere an earlier shorter soldier kills it. Dynamic programming counts arrangements by deaths after each height group.

A grouped insertion formula replaces enumerating every ordering of the multiset. Precompute the binomial factors once per group and stop once deaths exceed K.

## Why It Works

1. A soldier dies exactly when some earlier soldier is shorter.
2. Soldiers of the shortest height never die, since no shorter height exists.
3. Process heights from shortest to tallest to keep earlier soldiers shorter.
4. When a group of size c is inserted into a row of length L, only front copies survive.
5. The remaining u copies die, and they distribute across L gaps in C(u+L-1, L-1) ways.
6. The dynamic state counts arrangements by deaths, so only K plus one states are kept.

| term | meaning |
|---|---|
| `deleteWays` | arrangements by death count after processed heights |
| `lengthSoFar` | soldiers placed before the current height group |
| `groupSize` | number of soldiers sharing the current height |
| `kernelValues` | binomial factors for adding u dying soldiers |

Every insertion preserves a unique final ordering of the multiset.

A script-generated trace for heights 1, 2, 3:

```
ordering: 123 132 213 231 312 321
deaths:     2   2   1   1   1   0
```

Three orderings have one death, which matches sample case 1.

## Code

**Input and scanner.** All tokens are read, then integers are extracted by hand.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

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
It builds values digit by digit.
The modulus constant supports the counting formulas.

**Buffered output.** Results accumulate in one string and flush in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after a large block fills.
No write happens for one answer.
A final write drains the leftover text.

**Height grouping and counting.** The DP inserts each equal-height group in turn.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let soldierCount = nextInt(inputData, scanPos)
  let deathLimit = nextInt(inputData, scanPos)
  var heightValues = newSeq[int](0)
  var heightCounts = newSeq[int](0)
  for soldierIndex in 0 .. soldierCount - 1:
    let soldierHeight = nextInt(inputData, scanPos)
    var foundIndex = -1
    for heightIndex in 0 .. heightValues.len - 1:
      if heightValues[heightIndex] == soldierHeight:
        foundIndex = heightIndex
        break
    if foundIndex < 0:
      heightValues.add soldierHeight
      heightCounts.add 1
    else:
      heightCounts[foundIndex] = heightCounts[foundIndex] + 1

  var heightOrder = newSeq[int](heightValues.len)
  for heightIndex in 0 .. heightValues.len - 1:
    heightOrder[heightIndex] = heightIndex
  for firstIndex in 1 .. heightOrder.len - 1:
    let currentOrder = heightOrder[firstIndex]
    var compareIndex = firstIndex - 1
    while compareIndex >= 0 and heightValues[heightOrder[compareIndex]] > heightValues[currentOrder]:
      heightOrder[compareIndex + 1] = heightOrder[compareIndex]
      compareIndex -= 1
    heightOrder[compareIndex + 1] = currentOrder

  var modularInverse = newSeq[int64](deathLimit + 2)
  if deathLimit + 1 >= 1:
    modularInverse[1] = 1
  for inverseIndex in 2 .. deathLimit + 1:
    modularInverse[inverseIndex] = modulusValue - (modulusValue div inverseIndex) * modularInverse[modulusValue mod inverseIndex] mod modulusValue

  var deleteWays = newSeq[int64](deathLimit + 1)
  deleteWays[0] = 1
  var lengthSoFar = 0
  var reachableDeaths = 0
  for orderIndex in 0 .. heightOrder.len - 1:
    let groupSize = heightCounts[heightOrder[orderIndex]]
    var nextWays = newSeq[int64](deathLimit + 1)
    if lengthSoFar == 0:
      for deathCount in 0 .. reachableDeaths:
        nextWays[deathCount] = deleteWays[deathCount]
    else:
      var kernelValues = newSeq[int64](deathLimit + 1)
      kernelValues[0] = 1
      for deathAdd in 1 .. deathLimit:
        kernelValues[deathAdd] = kernelValues[deathAdd - 1] * int64(lengthSoFar + deathAdd - 1) mod modulusValue
        kernelValues[deathAdd] = kernelValues[deathAdd] * modularInverse[deathAdd] mod modulusValue
      for deathCount in 0 .. reachableDeaths:
        let currentWays = deleteWays[deathCount]
        if currentWays == 0:
          continue
        let maxAdd = groupSize
        let limitAdd = deathLimit - deathCount
        for deathAdd in 0 .. min(maxAdd, limitAdd):
          nextWays[deathCount + deathAdd] = (nextWays[deathCount + deathAdd] + currentWays * kernelValues[deathAdd]) mod modulusValue
    deleteWays = nextWays
    lengthSoFar = lengthSoFar + groupSize
    reachableDeaths = min(deathLimit, lengthSoFar)

  appendOutput("Case " & $caseIndex & ": " & $deleteWays[deathLimit])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Heights are sorted with a small insertion pass.
Binomial factors use modular inverses and one sweep.
States beyond K deaths are never stored.

## Complexity

The DP processes one height group at a time and keeps K plus one states.

| phase | time | space |
|---|---|---|
| input read | one pass over N heights | one input string |
| height grouping | linear scan over at most 100 distinct heights | height and count arrays |
| counting DP | O(K) factors per group and bounded transitions | K plus one states |
| output | one line per case | block buffer |

Grouping keeps the number of DP rounds at most 100.

| measure | Big O |
|---|---|
| time | O(N + D K^2), D is the number of distinct heights |
| space | O(N + K) |

Enumerating all N factorial orderings would be impossible for the large cases. The grouped DP counts them with a compact state space.
