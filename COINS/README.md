# COINS — Bytelandian gold coins (SPOJ)

<https://www.spoj.com/problems/COINS/>

## Problem

A coin showing the integer n can be sold for n dollars or split into three coins showing `n div 2`, `n div 3`, and `n div 4`, each rounded down. Find the most dollars obtainable from one coin.

Write best(n) for that answer. Then best(n) equals `max(n, best(n div 2) + best(n div 3) + best(n div 4))`. The bases are `best(0) = 0` and `best(1) = 1`, and for `n >= 2` all three parts are smaller than n.

Input: one test case per line, each a single integer n, with at most ten lines and no count line. Output: one line per test case with the maximum dollars for that n.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases | at most 10 |
| Coin value n | 0 ≤ n ≤ 1 000 000 000 |
| Answer size | fits in a signed 64-bit integer |
| Judge limit | 9 s, 1536 MB |

The 64-bit answer bound drives the choice of `int64`. The largest answer here is 4243218150 at n = 1000000000.

The sample from the statement:

```
12
2
```

```
13
2
```

The first coin pays 13 dollars and the second pays 2 dollars.

## Idea

Think of each coin as a choice between cashing it now and passing three smaller coins to the same rule. The trick is to solve each coin value once and remember the answer.

The analogy is a recipe that refers to smaller versions of itself. You cook each quantity once and write the result on a card. Here the cards live in a hash table, and `coinValue` reads a card before doing any work.

The algorithm is memoized recursion. Each distinct n costs three recursive calls and one table lookup. A plain recursion without memory recomputes the same small coins thousands of times, because every branch reaches values like 2 and 1 again and again.

For n = 1000000000, only about 240 distinct values appear. The table stays small and each later lookup takes constant time.

Takeaway: compute once, store the value, and reuse it on every later visit.

## Why It Works

Four facts prove the rule.

1. For `n >= 2`, each of `n div 2`, `n div 3`, and `n div 4` is smaller than n. The recursion reaches the bases 0 and 1 and always stops.
2. `best(0) = 0` and `best(1) = 1`, because splitting these coins cannot pay more than selling them.
3. The exchange pays `best(n div 2) + best(n div 3) + best(n div 4)`, and selling pays n. The larger of the two is best(n).
4. The memo table stores best(n) on the first computation, so a later request returns one stored value.

The terms of the rule:

| Term | Meaning |
|---|---|
| `best(n)` | most dollars from a coin showing n |
| `n div 2`, `n div 3`, `n div 4` | the three smaller coins, rounded down |
| `max(n, best(n div 2) + best(n div 3) + best(n div 4))` | sell now or exchange, whichever pays more |
| memo table | stored answers, one per distinct n |

One line summarizes the rule: `best(n) = max(n, best(n div 2) + best(n div 3) + best(n div 4))`.

A script-generated trace for 12:

```
coin   halves   exchange value   keep
   3   1+1+0=2    3     3
   2   1+0+0=1    2     2
   6   3+2+1=6    6     6
   4   2+1+1=4    4     4
  12   6+4+3=13   12    13
answer: 13
```

The last line matches the sample: 12 becomes 6 + 4 + 3 = 13, which beats selling for 12.

## Code

**Constants and tables.** Sizes and the three memo arrays.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashBitCount = 18
const hashSize = 1 shl hashBitCount
const hashMask = hashSize - 1

var memoKeys = newSeq[int64](hashSize)
var memoUsed = newSeq[bool](hashSize)
var memoValues = newSeq[int64](hashSize)
```

`hashSize` is a power of two, so `hashMask` replaces a division. `memoUsed` separates an empty slot from a stored key. `newSeq` allocates all three tables once at startup.

**Hash lookup.** `slotFor` finds the slot for one coin value.

```nim
proc slotFor(coinNumber: int64): int =
  var mixed = cast[uint64](coinNumber) * 1099511628211'u64
  mixed = mixed xor (mixed shr 29)
  var tableSlot = int(mixed and uint64(hashMask))
  while memoUsed[tableSlot] and memoKeys[tableSlot] != coinNumber:
    tableSlot = (tableSlot + 1) and hashMask
  return tableSlot
```

The mixer spreads similar coin values over the table. `and hashMask` wraps the index without a modulo. Linear probing walks past slots holding other keys.

**Core rule.** `coinValue` returns the maximum dollars for one value.

```nim
proc coinValue(coinNumber: int64): int64 =
  if coinNumber <= 1:
    return coinNumber
  var tableSlot = slotFor(coinNumber)
  if memoUsed[tableSlot] and memoKeys[tableSlot] == coinNumber:
    return memoValues[tableSlot]
  var candidate = coinValue(coinNumber div 2) + coinValue(coinNumber div 3) + coinValue(coinNumber div 4)
  if candidate < coinNumber:
    candidate = coinNumber
  tableSlot = slotFor(coinNumber)
  memoKeys[tableSlot] = coinNumber
  memoUsed[tableSlot] = true
  memoValues[tableSlot] = candidate
  return candidate
```

Values 0 and 1 return before any recursion, which stops the tree. The `if candidate < coinNumber` line keeps the sell-now option. The slot is found again after recursion, because recursive calls may fill the first slot.

**Token reader.** `nextInt` scans digits by index and allocates no string objects.

```nim
proc hasNext(inputData: string, scanPos: int): bool =
  var checkPos = scanPos
  while checkPos < inputData.len and (inputData[checkPos] < '0' or inputData[checkPos] > '9'):
    checkPos += 1
  return checkPos < inputData.len

proc nextInt(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value: int64 = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return value
```

`hasNext` checks for another digit before each parse, so the trailing newline never becomes a phantom case. `scanPos` is a `var` parameter, so the position survives across calls. Values stay non-negative, so no sign branch is needed.

**Driver.** One read of the whole input, and writes in blocks.

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

while hasNext(inputData, scanPos):
  let coinNumber = nextInt(inputData, scanPos)
  appendOutput($(coinValue(coinNumber)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each line is appended to one buffer, so blank lines cannot desync the reader. `appendOutput` flushes a full block and `setLen 0` reuses the allocation. The final write covers the tail.

## Complexity

The program reads once, computes each distinct coin value once, and writes in blocks.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass per line, then one digit pass | input bytes |
| Memo table | one allocation at startup | 3 × 262 144 entries |
| One coin value | three recursive calls, one lookup | constant per value |
| All cases | one pass per distinct value | at most about 240 values |
| Output | one write per 262 144-byte block | one block |

Distinct values stay few, so all ten cases finish in a few milliseconds.

The overall bounds use D, the number of distinct reachable coin values.

| Measure | Big O |
|---|---|
| Time | O(D), with D about 240 at n = 10^9 |
| Space | O(D) for answers, plus a fixed table of 2^18 slots |

A plain recursion with no memo recomputes the same small coins on every branch. Its work grows with the whole recursion tree, not the number of distinct values.
