# ADAFRIEN — Ada and Friends (SPOJ)

<https://www.spoj.com/problems/ADAFRIEN/>

## Problem

Ada records one gift expense per line, often for the same friend. Find the largest total she can save by unfriending at most `K` friends, where unfriending removes every gift for that name.

Each test case starts with `Q` and `K`. The next `Q` lines each hold a lowercase name and a positive expense. Input ends at end of file. Print one 64-bit integer per case.

| item | bound |
|---|---|
| gift records Q per case | 1 to 100000 |
| unfriend limit K | 1 to 100000 |
| each expense | 1 to 1000000001 |
| judge limit | 2000 ms, 1536 MB |

The expense bound makes a 64-bit sum necessary.

Sample input:

```
6 1
uvuvwevwevweonyetenyevweugwemubwemossas 10
ryuk 11
uvuvwevwevweonyetenyevweugwemubwemossas 5
fegla 3
tenshikanade 7
fegla 2
```

Sample output:

```
15
```

## Idea

Adding up each friend's tab before cutting the biggest tabs is the whole trick. The algorithm sorts records by name to aggregate totals, then sorts those totals from largest to smallest. Both sorts cost O(Q log Q) per case. Testing every subset of friends would cost far more when Q reaches 100000. Take the largest totals, up to `K`, and print their sum.

## Why It Works

1. Every gift belongs to exactly one friend, so per-friend totals partition the total spending.
2. Unfriending a friend removes their whole total, not a single gift.
3. The largest savings come from the largest friend totals.
4. `min` caps the choice when `K` exceeds the number of distinct friends.
5. `sparedMoney` uses `int64` because 100000 gifts above 10^9 exceed 32 bits.

| term | meaning |
|---|---|
| `spendingRecords` | one name and expense from each input line |
| `friendTotals` | one summed record per distinct friend |
| `compareByName` | sort key that groups equal names together |
| `compareByExpense` | sort key that puts the largest total first |
| `sparedMoney` | sum of the chosen friend totals |

For the sample, the long name totals `10 + 5 = 15`, `ryuk` totals `11`, `fegla` totals `5`, and `tenshikanade` totals `7`. With `K = 1`, the largest total is `15`, matching the sample output.

## Code

**Input and sort keys.** The reader loads each case, and the comparators group names then rank totals.

```nim
import algorithm

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc hasMoreData(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and data[scanIndex] <= ' ':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type SpendingRecord = object
  friendName: string
  totalExpense: int64

proc compareByName(leftRecord: SpendingRecord, rightRecord: SpendingRecord): int =
  cmp(leftRecord.friendName, rightRecord.friendName)

proc compareByExpense(leftRecord: SpendingRecord, rightRecord: SpendingRecord): int =
  if leftRecord.totalExpense > rightRecord.totalExpense:
    return -1
  if leftRecord.totalExpense < rightRecord.totalExpense:
    return 1
  return 0
```

The token reader handles names that contain no spaces.
The name sort places equal names in adjacent slots.
The expense sort avoids subtraction to keep `int64` values safe.

**Aggregate and answer.** Each case sums adjacent names, ranks them, and prints the top totals.

```nim
while hasMoreData(inputData, scanPos):
  let giftCount = nextInt(inputData, scanPos)
  let unfriendLimit = nextInt(inputData, scanPos)
  var spendingRecords = newSeq[SpendingRecord](giftCount)
  for recordIndex in 0 .. giftCount - 1:
    spendingRecords[recordIndex].friendName = nextToken(inputData, scanPos)
    spendingRecords[recordIndex].totalExpense = int64(nextInt(inputData, scanPos))
  spendingRecords.sort(compareByName)
  var friendTotals = newSeq[SpendingRecord]()
  for record in spendingRecords:
    if friendTotals.len > 0 and friendTotals[friendTotals.len - 1].friendName == record.friendName:
      friendTotals[friendTotals.len - 1].totalExpense += record.totalExpense
    else:
      friendTotals.add record
  friendTotals.sort(compareByExpense)
  let takeCount = min(unfriendLimit, friendTotals.len)
  var sparedMoney: int64 = 0
  for recordIndex in 0 .. takeCount - 1:
    sparedMoney += friendTotals[recordIndex].totalExpense
  appendOutput($sparedMoney)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Adjacent equal names merge into one total in one pass.
The limit is capped by the distinct friend count.
The buffer holds all answers until the final flush.

## Complexity

Two sorts per test case dominate the running time.

| phase | time | space |
|---|---|---|
| input read | one pass over gift lines | one input string |
| name sort and merge | `O(Q log Q)` | `Q` records |
| expense sort | `O(F log F)` for `F` friends | `F` records |
| output | one line per case | block buffer |

The name sort is the largest single step at the stated bound.

| measure | Big O |
|---|---|
| time | `O(Q log Q)` per test case |
| space | `O(Q)` |

Checking every subset of friends would cost exponential time, so ranking the totals is the deciding gain. Grouping first also handles repeated names without extra passes.
