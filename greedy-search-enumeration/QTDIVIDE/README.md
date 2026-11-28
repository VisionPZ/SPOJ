# QTDIVIDE — One piece (SPOJ)

<https://www.spoj.com/problems/QTDIVIDE/>

## Problem

Two players split even many coins in pairs. One player values each coin by `tnValues`, the other by `dbValues`. In every pair the first player keeps the coin with the larger `tnValues` value, and the second player keeps the other coin. Choose all pairs so the second player's total `dbValues` value is largest.

The input gives `coinCount`, then `coinCount` values for the first player, then `coinCount` values for the second player. Print the best total on one line. Then print `coinCount / 2` lines, each with the two one-based coin indexes of one pair. Any optimal pairing is accepted.

| item | bound |
|---|---|
| `coinCount` | 2 to 500000, even |
| `tnValues` value | 1 to 1000000000, all distinct |
| `dbValues` value | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The coin count drives the design, so each step must cost at most logarithmic time.

Sample input:

```
6
6 10 11 18 5 14
1 7 6 12 15 1
```

Sample output:

```
28
5 1
2 6
3 4
```

## Idea

Think of each pair as a larger-value coin for the first player and a smaller-value coin for the second. Like seating guests so every earlier guest has a later partner, each chosen second-player coin needs a first-player coin with higher value. Sort coins by `tnValues` descending, then keep the best `dbValues` candidates seen so far. A min-heap drops the weakest candidate whenever the balance turns against the second player. A naive search over pairings explodes, while this sweep costs O(n log n).

## Why It Works

1. In a valid pair the second-player coin has a smaller `tnValues` value than its partner.
2. Sort by `tnValues` descending. Every first-player coin must appear before its partner.
3. While sweeping, let `dbCount` count kept candidates and `tnCount` count rejected ones. Keep the invariant `dbCount` ≤ `tnCount` after each coin.
4. When a new coin breaks the invariant, dropping the smallest `dbValues` candidate loses the least possible value.
5. After all coins, `dbCount` equals `tnCount`, and every rejected coin has a larger `tnValues` value than its chosen partner.

| term | meaning |
|---|---|
| `sortedCoins` | coin indexes in descending `tnValues` order |
| `heapValues` | `dbValues` values of kept candidates |
| `heapCoins` | coin indexes stored beside each heap value |
| `keepsDb` | flag marking coins kept for the second player |
| `dbTotal` | sum of `dbValues` over kept coins |

A worked trace for the sample follows.

```
coin by tnValues  4(18,12) 6(14,1) 3(11,6) 2(10,7) 1(6,1) 5(5,15)
step 1  add 4, drop 4 -> total 0
step 2  add 6, keep   -> total 1
step 3  add 3, drop 6 -> total 6
step 4  add 2, keep   -> total 13
step 5  add 1, drop 1 -> total 13
step 6  add 5, keep   -> total 28
kept coins in ascending tnValues order: 5 2 3
rejected coins in ascending order:       1 6 4
```

The kept coins sum to `15 + 7 + 6 = 28`, and the pairs match the sample output.

## Code

**Input and hand scanner.** All integers are parsed from one input string.

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
```

`dbValues` is int64 because the total can reach 5e14.
`nextInt` skips whitespace without creating token strings.
The first array holds `tnValues` for sorting.

**Buffered output.** Answers go through one block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Pair lines are appended one field at a time.
A write occurs only after `flushBlockBytes` is reached.
The final flush happens after the pair loop.

**Coin order and heap helpers.** The heap keeps the weakest kept candidate at its root.

```nim
let coinCount = nextInt(inputData, scanPos)
var tnValues = newSeq[int](coinCount)
var dbValues = newSeq[int64](coinCount)
for coinIndex in 0 .. coinCount - 1:
  tnValues[coinIndex] = nextInt(inputData, scanPos)
for coinIndex in 0 .. coinCount - 1:
  dbValues[coinIndex] = int64(nextInt(inputData, scanPos))

var sortedCoins = newSeq[int](coinCount)
for coinIndex in 0 .. coinCount - 1:
  sortedCoins[coinIndex] = coinIndex
sortedCoins.sort(proc(leftCoin, rightCoin: int): int =
  if tnValues[leftCoin] > tnValues[rightCoin]: return -1
  if tnValues[leftCoin] < tnValues[rightCoin]: return 1
  return 0)
```

The comparator orders coins by `tnValues` descending.
`dbValues` uses int64 to avoid overflow in the final sum.
Sorting coin indexes keeps the two arrays untouched.

```nim
var heapValues = newSeq[int64](coinCount + 1)
var heapCoins = newSeq[int](coinCount + 1)
var heapSize = 0

proc heapPush(value: int64, coinIndex: int) =
  heapSize += 1
  heapValues[heapSize] = value
  heapCoins[heapSize] = coinIndex
  var childIndex = heapSize
  while childIndex > 1:
    let parentIndex = childIndex div 2
    if heapValues[parentIndex] <= heapValues[childIndex]:
      break
    swap heapValues[parentIndex], heapValues[childIndex]
    swap heapCoins[parentIndex], heapCoins[childIndex]
    childIndex = parentIndex

proc heapPop(): int =
  let poppedCoin = heapCoins[1]
  heapValues[1] = heapValues[heapSize]
  heapCoins[1] = heapCoins[heapSize]
  heapSize -= 1
  var parentIndex = 1
  while true:
    let leftChild = parentIndex * 2
    if leftChild > heapSize:
      break
    let rightChild = leftChild + 1
    var smallerChild = leftChild
    if rightChild <= heapSize and heapValues[rightChild] < heapValues[leftChild]:
      smallerChild = rightChild
    if heapValues[parentIndex] <= heapValues[smallerChild]:
      break
    swap heapValues[parentIndex], heapValues[smallerChild]
    swap heapCoins[parentIndex], heapCoins[smallerChild]
    parentIndex = smallerChild
  return poppedCoin
```

Both heaps store values and coin indexes together.
Sift up and sift down keep the smallest value at the root.
Each heap operation costs O(log n).

**Greedy sweep and pairing.** One pass over `sortedCoins` fixes the optimal kept set.

```nim
var keepsDb = newSeq[bool](coinCount)
var dbTotal: int64 = 0
var dbCount = 0
var tnCount = 0
for orderIndex in 0 .. coinCount - 1:
  let currentCoin = sortedCoins[orderIndex]
  heapPush(dbValues[currentCoin], currentCoin)
  dbTotal = dbTotal + dbValues[currentCoin]
  dbCount += 1
  keepsDb[currentCoin] = true
  if dbCount > tnCount:
    let droppedCoin = heapPop()
    keepsDb[droppedCoin] = false
    dbTotal = dbTotal - dbValues[droppedCoin]
    dbCount -= 1
    tnCount += 1

var dbCoins = newSeq[int](dbCount)
var tnCoins = newSeq[int](tnCount)
var dbCursor = 0
var tnCursor = 0
var reverseIndex = coinCount - 1
while reverseIndex >= 0:
  let currentCoin = sortedCoins[reverseIndex]
  if keepsDb[currentCoin]:
    dbCoins[dbCursor] = currentCoin
    dbCursor += 1
  else:
    tnCoins[tnCursor] = currentCoin
    tnCursor += 1
  reverseIndex -= 1

appendOutput($dbTotal)
outputBuffer.add '\n'
for pairIndex in 0 .. dbCount - 1:
  appendOutput($(dbCoins[pairIndex] + 1))
  outputBuffer.add ' '
  appendOutput($(tnCoins[pairIndex] + 1))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A dropped coin becomes a first-player coin and loses its value.
The reverse scan lists both groups in ascending `tnValues` order.
Matching equal positions pairs each kept coin with a larger-valued partner.

## Complexity

Sorting and the heap operations set the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over integers | one input string |
| sort | one sort over coin indexes | index array |
| greedy sweep | one heap step per coin | two heap arrays |
| pairing and output | one line per pair | block buffer |

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Trying every pairing costs factorial time, while the heap sweep keeps only one candidate per coin. The pairing pass adds only linear work after the optimal kept set is known.
