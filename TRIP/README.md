## Problem

Read the number of test cases. Each case gives one city list for Alice and one for Bob. Each list holds 1 to 80 lowercase letters, and cities may repeat. Print every longest common subsequence once per line in lexicographic order. Separate cases with one blank line.

| Constraint | Value |
| --- | --- |
| Test cases | at most 10 |
| List length | 1 to 80 letters |
| Distinct trips | 1 to 1000 |
| Time limit | 3 seconds |
| Memory limit | 1536 MB |

The judge always provides at least one shared city.

## Idea

The program computes longest common subsequence lengths for every pair of suffixes and caches the sorted distinct trips for each pair. From one pair it follows at most three moves: match the first cities, skip Alice's city, or skip Bob's city. Enumerating all subsequences is exponential, while one cached solution per pair costs one lookup and three list merges at most.

## Why It Works

A longest common subsequence either matches the two first cities, drops Alice's first city, or drops Bob's first city. The length table tells which moves can still reach the best length. A matching pair extends every trip from the smaller pair by that city.

The state index is `i * table.rowWidth + j`. The term `rowWidth` equals `bobLength + 1`. The table `lengthTable` holds the best length for the state. The table `answerTable` holds the sorted distinct trips. The table `isReady` marks solved states.

The match move needs equal first cities and `bestLength == 1 + table.lengthTable[(i + 1) * table.rowWidth + j + 1]`. The skip-Alice move needs `bestLength == table.lengthTable[(i + 1) * table.rowWidth + j]`. The skip-Bob move needs `bestLength == table.lengthTable[i * table.rowWidth + j + 1]`.

Only moves that preserve `bestLength` are kept, so every collected trip is longest. Sorting and removing equal neighbors leaves each trip once in order.

For Alice "ab" and Bob "ba", the states resolve as follows.

| State (i, j) | Longest length | Distinct trips |
| --- | --- | --- |
| (0, 0) | 1 | a, b |
| (0, 1) | 1 | a |
| (0, 2) | 0 | empty trip |
| (1, 0) | 1 | b |
| (1, 1) | 0 | empty trip |
| (1, 2) | 0 | empty trip |
| (2, 0) | 0 | empty trip |
| (2, 1) | 0 | empty trip |
| (2, 2) | 0 | empty trip |

The start state yields a and b, the two longest trips.

## Code

The program is a single file. Every block below comes from that file.

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

The flat index is `i * table.rowWidth + j`. Each state owns one sorted list of trips. The comparison gives lexicographic order to `sort`.

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

The recursion stops at `aliceLength` or `bobLength`, where the only trip is empty. Each accepted move merges one smaller list into `collected`. Sorting and deduplicating costs O(k log k) for k collected trips.

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

The loops cover every state except the two empty borders, whose length stays zero. The value `rowWidth` gives the offset to the next row. Filling the table costs `(table.aliceLength + 1) * table.rowWidth` cells.

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

The scanner skips whitespace and reads one token. The integer routine reuses it for the case count. Parsing touches each input byte once.

```nim
const flushBlockBytes = 1 shl 18

proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after `flushBlockBytes` bytes. The call `setLen 0` reuses the same storage. Output memory stays near one block.

```nim
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

The loop runs `testCount` times. A blank line goes before each case except the first. The final `stdout.write` flushes the remaining bytes.

## Complexity

Let n be the Alice list length, m be the Bob list length, and k be the largest trip list at any state.

Building lengths takes O(nm) time and O(nm) space. Collecting trips visits each state once and sorts at most k strings there. The collection phase takes O(nm k log k) time and O(nm k) space.

Total time is O(nm k log k) and total space is O(nm k). Enumerating all subsequences instead would take exponential time.
