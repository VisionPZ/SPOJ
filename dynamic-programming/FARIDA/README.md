# FARIDA — Princess Farida (SPOJ)

<https://www.spoj.com/problems/FARIDA/>

## Problem

Given a row of `N` monsters, each holding a non-negative number of gold coins, choose a subset with no two adjacent monsters to maximize the total coins collected.

Input starts with `T`, the number of test cases. Each test case gives `N`, followed by `N` space-separated coin counts (or an empty line when `N = 0`). Output `Case C: X` on its own line for each test case, where `C` is 1-based and `X` is the maximum total coins.

This table lists the constraints and judge limits.

| item | bound |
|---|---|
| monster count `N` | 0 <= N <= 10 000 |
| coins per monster | 0 <= coins <= 10^9 |
| max total coins | 5 * 10^12 (fits in 64-bit integer) |
| judge limit | 1237 ms, 1536 MB, 50000 B |

Sums can exceed 32-bit integers, and `N = 0` must output `0`.

Sample input:

```
2
5
1 2 3 4 5
1
10
```

Sample output:

```
Case 1: 9
Case 2: 10
```

## Idea

Walking past the monsters is like picking houses along a street where you cannot visit two neighbors in a row. Rolling dynamic programming keeps only two numbers as it reads each monster. Those are `prevTwoBest` two steps back and `prevOneBest` one step back. Each monster updates both in `O(1)` time, so the whole test case finishes in `O(N)` time and `O(1)` extra space.

Trying every valid subset costs `O(2^N)` time, which explodes past `N = 30`.

## Why It Works

1. At monster `idx`, either you take its coins and add `prevTwoBest`, or you skip it and keep `prevOneBest`.
2. Both choices depend only on the previous two prefix optima, so no DP array is needed.
3. Initializing `prevTwoBest = 0` and `prevOneBest = 0` handles `N = 0` and `N = 1` without special branches.
4. Coin counts are non-negative, so `prevOneBest` never decreases.

This table maps the rolling variables to their roles.

| term | meaning |
|---|---|
| `prevTwoBest` | best coin total from monsters `0 .. idx - 2` |
| `prevOneBest` | best coin total from monsters `0 .. idx - 1` |
| `takeCurrent` | total if taking monster `idx` (`prevTwoBest + coins`) |
| `currentBest` | `max(takeCurrent, prevOneBest)` |

Updating two 64-bit integers per monster avoids both recursion and heap memory.

Worked example for `[1, 2, 3, 4, 5]`:

```
start : prevTwoBest=0, prevOneBest=0
c = 1 : take=1, best=1 -> prevTwoBest=0, prevOneBest=1
c = 2 : take=2, best=2 -> prevTwoBest=1, prevOneBest=2
c = 3 : take=4, best=4 -> prevTwoBest=2, prevOneBest=4
c = 4 : take=6, best=6 -> prevTwoBest=4, prevOneBest=6
c = 5 : take=9, best=9 -> prevTwoBest=6, prevOneBest=9
result: 9
```

Taking monsters with coins 1, 3, and 5 gives 9.

## Code

**Bulk input, 64-bit scanner, and output buffer.** Reads stdin once, scans unsigned 64-bit integers directly from `inputData`, and flushes output in 128 KiB blocks.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Because `nextInt64` skips blank lines, an empty line after `N = 0` never desynchronizes the scanner.

**Rolling DP loop.** Reads `monsterCount` coin values on the fly, advances the two-variable recurrence, and emits `Case C: X`.

```nim
let caseCount = int(nextInt64(inputData, scanPos))
for caseNumber in 1 .. caseCount:
  let monsterCount = int(nextInt64(inputData, scanPos))
  var prevTwoBest: int64 = 0
  var prevOneBest: int64 = 0
  for idx in 0 .. monsterCount - 1:
    let coins = nextInt64(inputData, scanPos)
    let takeCurrent = prevTwoBest + coins
    let currentBest = if takeCurrent > prevOneBest: takeCurrent else: prevOneBest
    prevTwoBest = prevOneBest
    prevOneBest = currentBest
  appendOutput("Case ")
  appendOutput($caseNumber)
  appendOutput(": ")
  appendOutput($prevOneBest)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

When `monsterCount` is 0, the inner loop does zero iterations and prints `0`. Using `int64` throughout prevents overflow up to `5 * 10^12`.

## Complexity

This table summarizes time and space per test case of `N` monsters.

| phase | time | space |
|---|---|---|
| rolling DP pass | O(N) | O(1) |
| emit answer | O(1) | O(1) |

No array is allocated for the monsters or DP states.

This table states the overall Big O bounds per test case.

| measure | big O |
|---|---|
| time | O(N) |
| space | O(1) |

Brute-force subset search costs `O(2^N)`, whereas the rolling recurrence finishes `N = 10 000` in microseconds.
