# TRIP — Trip (SPOJ)

<https://www.spoj.com/problems/TRIP/>

## Problem

Alice and Bob want one shared holiday route. Each keeps a personal list of cities in visiting order, and neither will reorder or add cities. They delete cities until their lists match, aiming to visit as many cities as possible.

Input starts with `T ≤ 10`. Each case has two lines, one list per traveler, holding 1 to 80 lowercase letters. Cities may repeat, and letters `a` to `z` encode the 26 possible cities. Output every distinct longest common route, one per line in lexicographic order. Print one blank line between cases. The judge guarantees at least one shared city, with at most 1000 distinct answers.

The bounds are modest, but the answer count needs care.

| Constraint | Value |
| --- | --- |
| Test cases | at most 10 |
| List length | 1 to 80 letters |
| Distinct routes | 1 to 1000 |
| Time limit | 3 seconds |
| Memory limit | 1536 MB |

The 1000-answer cap keeps every printed route list small.

The sample input and output follow verbatim.

```
1
abcabcaa
acbacba
```

```
ababa
abaca
abcba
acaba
acaca
acbaa
acbca
```

## Idea

Keep one cache of all best routes for every pair of list positions. Think of two travelers standing at positions in their own lists, choosing together whether to move forward or match the current city.

The program fills a length table for every pair of suffixes. Then it walks from the start, following only moves that preserve the best length. Each state caches a sorted, deduplicated list of routes. A match prepends the shared city; a skip copies the child list unchanged.

Enumerating all subsequences takes exponential time. One cached answer per state, across at most 81 by 81 states, replaces that with a few list merges.

A cached answer per state turns enumeration into table lookup.

## Why It Works

Three facts drive the recursion.

1. A longest common subsequence either matches the two first cities, drops Alice's first city, or drops Bob's first city. Only those three moves exist.
2. The match move requires equal first cities and `bestLength == 1 + table.lengthTable[(i + 1)·rowWidth + j + 1]`. The skip moves require equality with the corresponding neighbor cell.
3. Each state sorts its collected routes and removes equal neighbors. Every kept route has the best length, and every distinct route appears once.

The table names the stored data.

| Term | Meaning |
| --- | --- |
| `lengthTable` | best route length for a state |
| `answerTable` | sorted distinct routes for a state |
| `isReady` | marks a state whose list is cached |
| `rowWidth` | offset to the next row, equal to `bobLength + 1` |
| state index | `i·rowWidth + j` |

The base case returns an empty route when either index reaches its list length.

For Alice `ab` and Bob `ba`, the states resolve as follows.

| State `(i, j)` | Longest length | Distinct routes |
| --- | --- | --- |
| `(0, 0)` | 1 | a, b |
| `(0, 1)` | 1 | a |
| `(0, 2)` | 0 | empty |
| `(1, 0)` | 1 | b |
| `(1, 1)` | 0 | empty |
| `(1, 2)` | 0 | empty |
| `(2, 0)` | 0 | empty |
| `(2, 1)` | 0 | empty |
| `(2, 2)` | 0 | empty |

The start state yields `a` and `b`, the two longest routes.

## Code

**State and comparator.** The state definition and comparator set up the flat table and lexicographic order.

```nim
type
  TripTable = ref object
    aliceRoute: string
    bobRoute: string
    aliceLength: int
    bobLength: int
    rowWidth: int
    lengthTable: seq[int]
    isReady: seq[bool]
    answerTable: seq[seq[string]]

proc compareText(leftText, rightText: string): int =
  if leftText < rightText:
    return -1
  if leftText > rightText:
    return 1
  return 0
```

The flat index is `i·rowWidth + j`. Each state owns one sorted route list. The comparator feeds `sort`.

**Route recorder.** The recorder follows every length-preserving move and caches the result.

```nim
proc collectTrips(table: TripTable, i, j: int): seq[string] =
  if i == table.aliceLength or j == table.bobLength:
    return @[""]
  let k = i * table.rowWidth + j
  if table.isReady[k]:
    return table.answerTable[k]
  let bestLength = table.lengthTable[k]
  var collected: seq[string] = @[]
  if table.aliceRoute[i] == table.bobRoute[j] and
      bestLength == 1 + table.lengthTable[(i + 1) * table.rowWidth + j + 1]:
    let lastCity = table.aliceRoute[i]
    let tailList = collectTrips(table, i + 1, j + 1)
    for tailText in tailList:
      collected.add lastCity & tailText
  if bestLength == table.lengthTable[(i + 1) * table.rowWidth + j]:
    let tailList = collectTrips(table, i + 1, j)
    for tailText in tailList:
      collected.add tailText
  if bestLength == table.lengthTable[i * table.rowWidth + j + 1]:
    let tailList = collectTrips(table, i, j + 1)
    for tailText in tailList:
      collected.add tailText
  sort(collected, compareText)
  var uniqueCount = 0
  for l in 0 .. collected.len - 1:
    if l == 0 or collected[l] != collected[l - 1]:
      collected[uniqueCount] = collected[l]
      uniqueCount += 1
  collected.setLen(uniqueCount)
  table.isReady[k] = true
  table.answerTable[k] = collected
  return collected
```

Recursion stops at either list end, where the only route is empty. Each accepted move merges one smaller list. Sorting and deduplication cost `O(k log k)` for `k` collected routes.

**Length table.** The builder fills lengths from the bottom right, so each child is ready first.

```nim
proc buildTripTable(aliceRoute, bobRoute: string): TripTable =
  let table = new(TripTable)
  table.aliceRoute = aliceRoute
  table.bobRoute = bobRoute
  table.aliceLength = aliceRoute.len
  table.bobLength = bobRoute.len
  table.rowWidth = table.bobLength + 1
  let stateCount = (table.aliceLength + 1) * table.rowWidth
  table.lengthTable = newSeq[int](stateCount)
  table.isReady = newSeq[bool](stateCount)
  table.answerTable = newSeq[seq[string]](stateCount)
  for i in countdown(table.aliceLength - 1, 0):
    for j in countdown(table.bobLength - 1, 0):
      let k = i * table.rowWidth + j
      if table.aliceRoute[i] == table.bobRoute[j]:
        table.lengthTable[k] =
          1 + table.lengthTable[(i + 1) * table.rowWidth + j + 1]
      else:
        let skipAlice = table.lengthTable[(i + 1) * table.rowWidth + j]
        let skipBob = table.lengthTable[i * table.rowWidth + j + 1]
        table.lengthTable[k] = max(skipAlice, skipBob)
  return table
```

The loops cover every non-border state. The two empty borders keep length zero. Filling the table touches each cell once.

**Token scanner.** The scanner reads tokens from the single input buffer.

```nim
proc nextToken(inputData: string, i: var int): string =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] <= ' ':
    i += 1
  let j = i
  while i < dataLength and inputData[i] > ' ':
    i += 1
  result = inputData[j .. i - 1]

proc nextInteger(inputData: string, i: var int): int =
  let numberText = nextToken(inputData, i)
  var numberValue = 0
  for digitChar in numberText:
    numberValue = numberValue * 10 + (int(digitChar) - 48)
  return numberValue
```

`nextToken` skips whitespace and returns one word. `nextInteger` reuses it for the case count. Parsing touches each input byte once.

**Writer and driver.** The writer flushes in blocks and the driver runs all cases.

```nim
const flushBlockBytes = 1 shl 18

proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
var i = 0
let testCount = nextInteger(inputData, i)
var outputBuffer = ""
for j in 0 .. testCount - 1:
  let aliceRoute = nextToken(inputData, i)
  let bobRoute = nextToken(inputData, i)
  let tripTable = buildTripTable(aliceRoute, bobRoute)
  let tripList = collectTrips(tripTable, 0, 0)
  if j > 0:
    appendOutput(outputBuffer, "\n")
  for tripText in tripList:
    appendOutput(outputBuffer, tripText)
    appendOutput(outputBuffer, "\n")
stdout.write outputBuffer
```

A blank line precedes each case except the first. The final write flushes the remaining bytes. Each case builds one table from scratch.

## Complexity

The two phases split cleanly by work.

| Phase | Time | Space |
| --- | --- | --- |
| Build lengths | O(nm) | O(nm) integers |
| Collect routes | O(nm·k log k) | O(nm·k) strings |
| Input and output | O(input + output bytes) | one flush block |

The largest cached list bounds `k`, and the statement caps printed routes at 1000.

The totals use the two list lengths.

| Measure | Big O |
| --- | --- |
| Time | O(nm·k log k) |
| Space | O(nm·k) |

Enumerating every subsequence instead grows exponentially with the list lengths.
