# CWC2015 — CWC-2015 (SPOJ)

<https://www.spoj.com/problems/CWC2015/>

## Problem

Decide whether players can be split into two groups of equal size with equal total experience. Each test gives the player count and the experience list; the answer is a yes or no decision.

Input starts with the test count. Each test gives N, then N experience values on the next line.

Output one line per test: `Case ` plus the case number, a colon, and `Yes` or `No`.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| players N | 1 to 40 |
| experience per player | 1 to 1000000 |
| judge limit | 5000 ms, 1536 MB |

A split needs an even player count and an even total, plus one subset of half the players with half the total.

Sample input:

```
2
6
1 2 3 4 5 6
4
2 3 4 5
```

Sample output:

```
Case 1: No
Case 2: Yes
```

## Idea

Split the player list into two halves of about twenty, like dealing cards into two piles. Check which sums each half can make with each possible number of cards. A subset from the first half pairs with a subset from the second when their counts and sums complete the target. Enumerating all forty-player subsets would take two to the forty tries; each half takes two to the twenty. A hash index turns the pairing step into one lookup per first-half subset.

## Why It Works

1. Equal groups need N even and a target sum equal to half the total.
2. The target group takes exactly N/2 players, so both count and sum matter.
3. Every subset of a half is one Gray code step away from the previous one.
4. Gray code changes one bit, so the running sum and count update in constant time.
5. A hash key packs count and sum, so a complement is found by one lookup.

| term | meaning |
|---|---|
| `targetCount` | half of the player count |
| `targetSum` | half of the total experience |
| `hashKeys` | packed count and sum pairs from the second half |
| `hashStamps` | test index marking keys that belong to the current test |

The table names the values shared by both halves of the search.

A worked example from the generator:

```
values 2 3 4 5, total 14, target count 2, target sum 7
second-half sums with count 1: 3, 5
first half picks 4 -> needs count 1 and sum 3 -> found
another pick: 2 -> needs count 1 and sum 5 -> found
answer Yes
```

The trace matches case 2 in the sample output.

## Code

**Input and hash helpers.** The table is sized once and reused with a stamp per test.

```nim
const flushBlockBytes = 1 shl 17
const hashTableSize = 1 shl 22
const countMultiplier = 41
const hashFactor = 2654435761

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

var bitPositions = newSeq[int](1 shl 20)
for bitIndex in 0 .. 19:
  bitPositions[1 shl bitIndex] = bitIndex

var hashKeys = newSeq[int](hashTableSize)
var hashStamps = newSeq[int](hashTableSize)
var currentStamp = 0

proc hashSlot(keyValue: int): int =
  return int((int64(keyValue) * hashFactor) and int64(hashTableSize - 1))

proc insertKey(keyValue: int) =
  var slot = hashSlot(keyValue)
  while hashStamps[slot] == currentStamp and hashKeys[slot] != keyValue:
    slot = (slot + 1) and (hashTableSize - 1)
  if hashStamps[slot] != currentStamp:
    hashStamps[slot] = currentStamp
    hashKeys[slot] = keyValue

proc containsKey(keyValue: int): bool =
  var slot = hashSlot(keyValue)
  while hashStamps[slot] == currentStamp:
    if hashKeys[slot] == keyValue:
      return true
    slot = (slot + 1) and (hashTableSize - 1)
  return false
```

Linear probing stops at the first empty slot.
Stamps avoid clearing millions of entries for every test.
The multiplier keeps count and sum in one integer key.

**Subset enumeration.** Gray code flips one player at a time.

```nim
proc buildSubsetData(values: seq[int], sums: var seq[int], counts: var seq[int8]) =
  let subsetTotal = 1 shl values.len
  sums = newSeq[int](subsetTotal)
  counts = newSeq[int8](subsetTotal)
  var previousGray = 0
  var currentSum = 0
  var currentCount: int8 = 0
  for subsetIndex in 0 .. subsetTotal - 1:
    let grayCode = subsetIndex xor (subsetIndex shr 1)
    if subsetIndex > 0:
      let changedBit = grayCode xor previousGray
      let changedIndex = bitPositions[changedBit]
      if (grayCode and changedBit) != 0:
        currentSum += values[changedIndex]
        currentCount += 1
      else:
        currentSum -= values[changedIndex]
        currentCount -= 1
    sums[subsetIndex] = currentSum
    counts[subsetIndex] = currentCount
    previousGray = grayCode
```

Each mask costs one array write and one flipped value.
The changed bit is a power of two, so the lookup table is direct.
Counts fit in a signed byte because a half holds at most twenty players.

**Test loop.** One half fills the table and the other half searches it.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let playerCount = nextInt(inputData, scanPos)
  var experiences = newSeq[int](playerCount)
  var totalExperience: int64 = 0
  for playerIndex in 0 .. playerCount - 1:
    experiences[playerIndex] = nextInt(inputData, scanPos)
    totalExperience += int64(experiences[playerIndex])

  var canSplit = false
  if playerCount mod 2 == 0 and (totalExperience and 1) == 0:
    let targetCount = playerCount div 2
    let targetSum = int(totalExperience div 2)
    let firstCount = playerCount div 2
    let secondCount = playerCount - firstCount
    var firstHalf = newSeq[int](firstCount)
    var secondHalf = newSeq[int](secondCount)
    for firstIndex in 0 .. firstCount - 1:
      firstHalf[firstIndex] = experiences[firstIndex]
    for secondIndex in 0 .. secondCount - 1:
      secondHalf[secondIndex] = experiences[firstCount + secondIndex]

    var secondSums: seq[int] = @[]
    var secondCounts: seq[int8] = @[]
    buildSubsetData(secondHalf, secondSums, secondCounts)
    currentStamp += 1
    for subsetIndex in 0 .. (1 shl secondCount) - 1:
      insertKey(secondSums[subsetIndex] * countMultiplier + int(secondCounts[subsetIndex]))

    var firstSums: seq[int] = @[]
    var firstCounts: seq[int8] = @[]
    buildSubsetData(firstHalf, firstSums, firstCounts)
    for subsetIndex in 0 .. (1 shl firstCount) - 1:
      let neededCount = targetCount - int(firstCounts[subsetIndex])
      let neededSum = targetSum - firstSums[subsetIndex]
      if neededCount >= 0 and neededCount <= secondCount and neededSum >= 0:
        if containsKey(neededSum * countMultiplier + neededCount):
          canSplit = true
          break

  appendOutput("Case " & $caseIndex & ": " & (if canSplit: "Yes" else: "No"))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Odd counts and odd totals skip the search entirely.
The first matching pair ends the current test.
Each answer line is buffered and written in blocks.

## Complexity

Both halves enumerate their subsets once per test.

| phase | time | space |
|---|---|---|
| input read | one pass over the experience lists | one input string |
| subset enumeration | one step per subset in each half | two sum and count arrays |
| hash build | one insert per second-half subset | open addressing table |
| hash search | one lookup per first-half subset | constant |
| output | one line per test | block buffer |

A half of twenty players yields about one million subsets.

| measure | Big O |
|---|---|
| time | O(2 to the N/2) per test |
| space | O(2 to the N/2) for subset arrays and the table |

Checking all forty-player subsets would cost O(2 to the N), which is a million times larger.
The split halves trade that cost for two short enumerations and one hash table.
