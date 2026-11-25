# TREASURY — Royal Treasury (SPOJ)

<https://www.spoj.com/problems/TREASURY/>

## Problem

Pair each clerk with a direct subordinate so that no clerk appears in two pairs.
Find the largest possible number of pairs and the number of ways to achieve that maximum.

Each test case starts with `N`, the number of clerks, from 1 to 1000.
Then come `N` lines, each holding a clerk ID, a subordinate count, and those subordinate IDs.
Clerk 1 leads the office, and a supervisor's line always appears before any subordinate's line.
Input ends at EOF.

| Item | Bound |
|---|---|
| Clerks N | 1 to 1000 |
| Subordinates per clerk | 0 to 999 |
| Output line 1 | maximum pair count |
| Output line 2 | number of maximum pairings, as a big integer |
| Judge limit | 1000 ms, 1536 MB |

A clerk may stay unpaired.
The count of ways can exceed standard integer types.

Sample input:

```
7
1 3 2 4 7
2 1 3
4 1 6
3 0
7 1 5
5 0
6 0
```

Sample output:

```
3
4
```

## Idea

Treat pairing like assigning dance partners at a party: each person may join one pair at most.
Process the office tree from the lowest subordinates upward, like closing branches before the root.
Two states describe each clerk: free toward the supervisor, or already paired with that supervisor.
The larger state chooses the best child to pair with and adds all tied choices.
Counts use base-one-billion limbs so the number of ways stays exact.

## Why It Works

1. A clerk paired upward cannot pair with any child, so all children stay free toward their parent.
2. A clerk free toward its supervisor either stays free from children or pairs with exactly one child.
3. Leaving all children free gives a base pair count and one product of child way counts.
4. Pairing with one child replaces that child's free value by its upward-paired value and adds one pair.
5. Prefix and suffix products give the way count for every child without division.
6. Ties add way counts, and a strictly better pair count replaces the stored count.
7. Processing clerks in reverse presentation order ensures each child is ready before its supervisor.

| Term | Meaning |
|---|---|
| `pairCount` | most pairs below a clerk that stays free toward its supervisor |
| `matchedCount` | most pairs below a clerk already paired with its supervisor |
| `waysFree` | number of optimal pairings for the free state |
| `waysMatched` | number of optimal pairings for the matched state |
| `prefixProducts` | product of child way counts before a given child |
| `suffixProducts` | product of child way counts after a given child |

In the sample, clerks 2, 4, and 7 each reach one pair inside their own branch.
Clerk 1 can keep all three branches free, giving three pairs in one way.
Pairing clerk 1 with any one of those three children also gives three pairs.
Those three choices plus the free choice give four ways, matching the sample.

A limb holds up to nine decimal digits, and `bigToDecimal` pads inner limbs with leading zeros.

## Code

**Input and hand scanner.** The reader loads all text once and parses integers without library calls.

```nim
const flushBlockBytes = 1 shl 17
const bigBase = 1000000000

type BigNumber = seq[int]

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

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false
```

`hasDigits` detects the end of input.
`bigBase` sets the limb width for all big counts.
The input string stays available for all test cases.

**Big integer helpers.** Counts are stored as little-endian limbs and printed by repeated division.

```nim
proc bigFromSmall(value: int): BigNumber =
  if value == 0:
    return @[0]
  return @[value]

proc bigAdd(left: BigNumber, right: BigNumber): BigNumber =
  result = newSeq[int](max(left.len, right.len))
  var carry = 0
  for chunkIndex in 0 ..< result.len:
    var total = carry
    if chunkIndex < left.len:
      total += left[chunkIndex]
    if chunkIndex < right.len:
      total += right[chunkIndex]
    result[chunkIndex] = total mod bigBase
    carry = total div bigBase
  if carry > 0:
    result.add carry
  return result

proc bigMultiply(left: BigNumber, right: BigNumber): BigNumber =
  result = newSeq[int](left.len + right.len)
  for leftIndex in 0 ..< left.len:
    var carry = 0
    for rightIndex in 0 ..< right.len:
      let cellIndex = leftIndex + rightIndex
      let current = result[cellIndex] + left[leftIndex] * right[rightIndex] + carry
      result[cellIndex] = current mod bigBase
      carry = current div bigBase
    var carryIndex = leftIndex + right.len
    while carry > 0:
      let current = result[carryIndex] + carry
      result[carryIndex] = current mod bigBase
      carry = current div bigBase
      carryIndex += 1
  while result.len > 0 and result[result.len - 1] == 0:
    result.setLen(result.len - 1)
  return result

proc bigToDecimal(value: BigNumber): string =
  var work = value
  var chunks: seq[int] = @[]
  while work.len > 0:
    var remainder = 0
    var quotient = newSeq[int](work.len)
    for chunkIndex in countdown(work.len - 1, 0):
      let current = remainder * bigBase + work[chunkIndex]
      quotient[chunkIndex] = current div bigBase
      remainder = current mod bigBase
    chunks.add remainder
    while quotient.len > 0 and quotient[quotient.len - 1] == 0:
      quotient.setLen(quotient.len - 1)
    work = quotient
  result = ""
  for chunkIndex in countdown(chunks.len - 1, 0):
    if chunkIndex == chunks.len - 1:
      result.add $(chunks[chunkIndex])
    else:
      var part = $(chunks[chunkIndex])
      while part.len < 9:
        part = "0" & part
      result.add part
  return result
```

`bigMultiply` keeps products below nine billion per limb.
`bigToDecimal` emits the most significant limb without padding.
Both operations work for arbitrarily many limbs.

**Buffered output and tree input.** Each clerk line contributes its children to an adjacency chain.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasDigits(inputData, scanPos):
  let clerkCount = nextInt(inputData, scanPos)
  var childrenHead = newSeq[int](clerkCount + 1)
  var childrenNext = newSeq[int](clerkCount + 1)
  var childClerk = newSeq[int](clerkCount + 1)
  var presentationOrder = newSeq[int](clerkCount)
  var edgeIndex = 0
  for clerkIndex in 0 .. clerkCount - 1:
    childrenHead[clerkIndex + 1] = -1
  for clerkIndex in 0 .. clerkCount - 1:
    let clerkId = nextInt(inputData, scanPos)
    let subordinateCount = nextInt(inputData, scanPos)
    presentationOrder[clerkIndex] = clerkId
    for subordinateIndex in 0 .. subordinateCount - 1:
      let subordinateId = nextInt(inputData, scanPos)
      childClerk[edgeIndex] = subordinateId
      childrenNext[edgeIndex] = childrenHead[clerkId]
      childrenHead[clerkId] = edgeIndex
      edgeIndex += 1
```

`presentationOrder` records the line order for the reverse pass.
`childrenHead` starts at -1 before any edge is added.
`appendOutput` flushes `stdout` only after the block fills.

**Bottom-up tree pass.** Each clerk combines child pair counts and big way counts.

```nim
  var pairCount = newSeq[int](clerkCount + 1)
  var matchedCount = newSeq[int](clerkCount + 1)
  var waysFree = newSeq[BigNumber](clerkCount + 1)
  var waysMatched = newSeq[BigNumber](clerkCount + 1)
  for orderIndex in countdown(clerkCount - 1, 0):
    let clerkId = presentationOrder[orderIndex]
    var childList: seq[int] = @[]
    var edgeCursor = childrenHead[clerkId]
    while edgeCursor != -1:
      childList.add childClerk[edgeCursor]
      edgeCursor = childrenNext[edgeCursor]
    let childTotal = childList.len
    var prefixProducts = newSeq[BigNumber](childTotal + 1)
    var suffixProducts = newSeq[BigNumber](childTotal + 1)
    prefixProducts[0] = bigFromSmall(1)
    suffixProducts[childTotal] = bigFromSmall(1)
    var basePairs = 0
    for childIndex in 0 .. childTotal - 1:
      let childId = childList[childIndex]
      basePairs += pairCount[childId]
      prefixProducts[childIndex + 1] = bigMultiply(prefixProducts[childIndex], waysFree[childId])
    for childIndex in countdown(childTotal - 1, 0):
      let childId = childList[childIndex]
      suffixProducts[childIndex] = bigMultiply(waysFree[childId], suffixProducts[childIndex + 1])
    matchedCount[clerkId] = basePairs
    waysMatched[clerkId] = prefixProducts[childTotal]
    var bestPairs = basePairs
    var bestWays = prefixProducts[childTotal]
    for childIndex in 0 .. childTotal - 1:
      let childId = childList[childIndex]
      let candidatePairs = 1 + matchedCount[childId] + basePairs - pairCount[childId]
      if candidatePairs < bestPairs:
        continue
      let candidateWays = bigMultiply(waysMatched[childId],
                                      bigMultiply(prefixProducts[childIndex],
                                                  suffixProducts[childIndex + 1]))
      if candidatePairs > bestPairs:
        bestPairs = candidatePairs
        bestWays = candidateWays
      else:
        bestWays = bigAdd(bestWays, candidateWays)
    pairCount[clerkId] = bestPairs
    waysFree[clerkId] = bestWays
  appendOutput($pairCount[1])
  outputBuffer.add '\n'
  appendOutput(bigToDecimal(waysFree[1]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`candidatePairs` compares pairing one child against leaving all children free.
Prefix and suffix products avoid big-integer division.
The root's free state supplies both output lines.

## Complexity

Each clerk contributes one tree node and one edge.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over clerk lines | one input string |
| Tree pass | one scan per clerk and child | arrays of size N |
| Big arithmetic | limb products per child | limbs per count |
| Output | two lines per case | one block buffer |

| Measure | Big O |
|---|---|
| Time per case | O(N times limbs squared) |
| Space per case | O(N times limbs) |

Enumerating all matchings would take exponential time in the number of clerks.
The tree pass keeps only two states per clerk and exact way counts.
