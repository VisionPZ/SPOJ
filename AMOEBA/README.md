# AMOEBA — Amoeba (SPOJ)

<https://www.spoj.com/problems/AMOEBA/>

## Problem

A colony starts with one amoeba. Each amoeba produces six new amoebae every day and survives, so the population on day d is 7 to the power d minus one. Given only the last K digits of that population, find the earliest day with those digits.

Each input line holds one K-digit string, possibly with leading zeros. Print the earliest day on its own line. Print -1 when no day produces the string.

| item | bound |
|---|---|
| digit count K | 1 to 9 |
| input lines | until end of file |
| judge limit | 301 ms, 1536 MB |

Leading zeros are part of the query, so the scanner keeps whole tokens instead of parsing integers.

Sample input:

```
01
143
743
600
```

Sample output:

```
1
20
12
-1
```

## Idea

Powers of 7 modulo a power of ten repeat in a fixed cycle, like a clock hand returning to the same mark. Store the first day for each value in that cycle. Look up each query in the stored table, like finding a name in a phone book. Scanning powers again for every query would repeat the same multiplication work, so one table per digit count serves all lines.

## Why It Works

1. Day d holds 7 to the power d minus one amoebae.
2. The last K digits are the population modulo 10 to the power K.
3. Seven is coprime with ten, so its powers cycle back to one.
4. Values inside one shortest cycle are distinct.
5. The first exponent giving a value also gives the earliest day.

| term | meaning |
|---|---|
| `modulus` | 10 to the power K, the size of the digit window |
| `period` | number of powers before the cycle restarts |
| `keys` | residue values stored in the hash table |
| `days` | first day for each stored residue |
| `targetValue` | value read from one input line |

The table stores each residue exactly once.

Script-generated trace for the query `743`:

```
quantity | value
modulus | 1000
7^1 mod 1000 | 7
7^2 mod 1000 | 49
7^3 mod 1000 | 343
7^4 mod 1000 | 401
7^11 mod 1000 | 743
first day | 11 + 1 = 12
```

The trace reproduces the third sample line.

## Code

**Bulk input and buffered output.** Token scanning keeps leading zeros; output is written in large blocks.

```nim
const flushBlockBytes = 1 shl 17
const digitBase = 10
const growthFactor = 7
const tableKinds = 10

type
  AnswerTable = object
    modulus: int64
    period: int
    tableSize: int
    keys: seq[int64]
    days: seq[int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The table type holds residues and their first days.
The scanner walks one shared input string.
The buffer flushes after 128 KiB of text.

**Table construction and lookup.** Each digit count gets one hash table built on first use.

```nim
proc buildTable(table: var AnswerTable, digitCount: int) =
  table.modulus = 1
  for digitIndex in 0 .. digitCount - 1:
    table.modulus = table.modulus * digitBase
  var powerValues = newSeq[int64]()
  var powerValue: int64 = 1
  powerValues.add powerValue
  while true:
    powerValue = (powerValue * growthFactor) mod table.modulus
    if powerValue == 1:
      break
    powerValues.add powerValue
  table.period = powerValues.len
  table.tableSize = 1
  while table.tableSize <= table.period:
    table.tableSize = table.tableSize shl 1
  table.keys = newSeq[int64](table.tableSize)
  table.days = newSeq[int](table.tableSize)
  for slotIndex in 0 .. table.tableSize - 1:
    table.keys[slotIndex] = -1
  for exponent in 0 .. table.period - 1:
    let storedValue = powerValues[exponent]
    var slotIndex = int(storedValue mod int64(table.tableSize))
    while table.keys[slotIndex] != -1:
      slotIndex = (slotIndex + 1) mod table.tableSize
    table.keys[slotIndex] = storedValue
    table.days[slotIndex] = exponent + 1

proc findDay(table: AnswerTable, target: int64): int =
  var slotIndex = int(target mod int64(table.tableSize))
  while table.keys[slotIndex] != -1:
    if table.keys[slotIndex] == target:
      return table.days[slotIndex]
    slotIndex = (slotIndex + 1) mod table.tableSize
  return -1
```

The power loop stops when the residue returns to one.
Linear probing resolves collisions inside the open table.
A missing residue returns -1.

**Query loop.** Each line selects its table and writes one answer.

```nim
var answerTables = newSeq[AnswerTable](tableKinds)
var tableReady = newSeq[bool](tableKinds)
for tableIndex in 0 .. tableKinds - 1:
  tableReady[tableIndex] = false

while true:
  let queryToken = nextToken(inputData, scanPos)
  if queryToken.len == 0:
    break
  if queryToken.len < 1 or queryToken.len >= tableKinds:
    continue
  let digitCount = queryToken.len
  if not tableReady[digitCount]:
    buildTable(answerTables[digitCount], digitCount)
    tableReady[digitCount] = true
  var targetValue: int64 = 0
  for charIndex in 0 .. queryToken.len - 1:
    targetValue = targetValue * digitBase + int64(int(queryToken[charIndex]) - 48)
  let answerDay = findDay(answerTables[digitCount], targetValue)
  appendOutput($answerDay)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The token length is the digit count K.
Tables are built once and reused for later lines.
The final write flushes any remaining text.

## Complexity

Table building touches each power in one cycle once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table build | up to 5 million powers per digit count | two arrays per table |
| lookup | one hash probe series per line | block buffer |

The longest cycle occurs at nine digits.

| measure | Big O |
|---|---|
| time per table | O(period) |
| time per query | O(1) average |
| space | O(period) |

Rescanning powers for every line would cost O(period) per query instead of one lookup.

A single table per digit count keeps repeated queries cheap.
