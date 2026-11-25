# HASHIT — Hash it! (SPOJ)
<https://www.spoj.com/problems/HASHIT/>

## Problem

The input gives insert and delete operations on a hash table with 101 slots.
Apply the given hash and probing rules, then print the stored key count and every occupied slot in index order.

The first line holds a test count t of at most 100. Each series starts with an operation count of at most 1000, then one operation per line: `ADD:string` or `DEL:string`. Keys use at most 15 letters from ASCII 'A' through 'z'. Print the stored key count, then one `index:key` line per occupied slot in index order.

The judge limits are:

| Item | Value |
| --- | --- |
| Series per file | at most 100 |
| Operations per series | at most 1000 |
| Key length | at most 15 characters |
| Time limit | 3 s |
| Memory limit | 1536 MB |

Each series starts from an empty table.

The sample input reads:

```text
1
11
ADD:marsz
ADD:marsz
ADD:Dabrowski
ADD:z
ADD:ziemii
ADD:wloskiej
ADD:do
ADD:Polski
DEL:od
DEL:do
DEL:wloskiej
```

The sample output reads:

```text
5
34:Dabrowski
46:Polski
63:marsz
76:ziemii
96:z
```

## Idea

Treat the table as 101 numbered slots. Place each key by computing its hash, then probing forward until a slot is free. A hash table (a fixed array indexed by a computed key) stores the string plus an occupancy flag. Quadratic probing (trying slots at square-growing offsets) walks at most twenty candidates. Each operation costs O(20 + key length). A language dictionary would hide the required probe order and the slot-by-slot dump. Takeaway: model the table exactly, then print it in slot order.

## Why It Works

1. The hash is `19 * sum(ASCII(ai) * i) mod 101`, counting positions from one.
2. Probe step j tests slot `(hash + j*j + 23*j) mod 101`, for steps 0 through 19.
3. Step 0 is the initial hash slot, so twenty entries get examined in total.
4. Insertion stops at the first empty slot and ignores a key already present.
5. Deletion marks a slot empty without moving other keys.
6. Lookup scans all twenty slots, so a gap left by deletion cannot hide a key.
7. The output loop walks slots from 0 upward, so the lines are already sorted.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| `tableKeys` | string stored in each slot |
| `tableUsed` | occupancy flag for each slot |
| `hashKey` | weighted address computed from the key |
| `probeIndex` | slot reached after a given probe step |

These four terms describe the table and its probes.

A script computed the sample hashes. The first probe slot equals the hash for each key.

| Key | Weighted sum | Hash | First slot |
| --- | --- | --- | --- |
| marsz | 1715 | 63 | 63 |
| Dabrowski | 1794 | 34 | 34 |
| z | 122 | 96 | 96 |
| ziemii | 1506 | 76 | 76 |
| Polski | 1146 | 46 | 46 |

The duplicate `marsz` is ignored, and three deletions remove `do`, `wloskiej`, and the absent `od`. Five keys remain, which matches the sample.

## Code

**Reader and line scanner.** The code reads all input once, then parses integers and operation lines.

```nim
import std/strutils

const firstDigitValue = 48
const tableSize = 101
const probeCount = 20
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc nextLine(data: string, i: var int): string =
  let j = i
  while i < data.len and data[i] != '\n':
    i += 1
  let result = data[j ..< i]
  if i < data.len:
    i += 1
  return result
```

`nextInt` leaves the cursor on the newline, so the driver consumes that newline before reading operations. Parsing one line visits its characters once. One input buffer holds the whole file.

**Hash and lookup.** The hash and probe functions are pure arithmetic on small integers.

```nim
proc hashKey(keyText: string): int =
  var weighted = 0
  for i in 0..<keyText.len:
    weighted += int(keyText[i]) * (i + 1)
  return (19 * weighted) mod tableSize

proc probeIndex(i: int, probeStep: int): int =
  return (i + probeStep * probeStep + 23 * probeStep) mod tableSize

var tableKeys = newSeq[string](tableSize)
var tableUsed = newSeq[bool](tableSize)

proc findKey(keyText: string): int =
  let i = hashKey(keyText)
  for probeStep in 0..<probeCount:
    let k = probeIndex(i, probeStep)
    if tableUsed[k] and tableKeys[k] == keyText:
      return k
  return -1
```

The weighted sum counts from one, as the statement defines. All twenty probe slots are examined, which keeps deleted gaps from hiding a key. The two flat arrays reuse their capacity across series.

**Add and delete.** Both operations use the same probe sequence.

```nim
proc insertKey(keyText: string) =
  if findKey(keyText) >= 0:
    return
  let i = hashKey(keyText)
  for probeStep in 0..<probeCount:
    let k = probeIndex(i, probeStep)
    if not tableUsed[k]:
      tableUsed[k] = true
      tableKeys[k] = keyText
      return

proc deleteKey(keyText: string) =
  let i = findKey(keyText)
  if i >= 0:
    tableUsed[i] = false
    tableKeys[i] = ""
```

Insertion stops at the first free slot and ignores a key already present. A full probe sequence leaves the key out. Deletion only changes the two arrays at the found slot. Each call costs at most twenty probes.

**Driver and output.** The table resets per series, then prints occupied slots in order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, i)
for j in 0..<testCount:
  for k in 0..<tableSize:
    tableUsed[k] = false
    tableKeys[k] = ""
  let operationCount = nextInt(inputData, i)
  if i < inputData.len and inputData[i] == '\n':
    i += 1
  for l in 0..<operationCount:
    let operation = nextLine(inputData, i)
    if operation.len < 4:
      continue
    let keyText = operation.substr(4)
    if operation.startsWith("ADD:"):
      insertKey(keyText)
    elif operation.startsWith("DEL:"):
      deleteKey(keyText)
  var keyCount = 0
  for k in 0..<tableSize:
    if tableUsed[k]:
      keyCount += 1
  appendOutput($keyCount)
  outputBuffer.add '\n'
  for k in 0..<tableSize:
    if tableUsed[k]:
      appendOutput($k)
      outputBuffer.add ':'
      appendOutput(tableKeys[k])
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The reset loop clears both arrays in 101 steps. `substr(4)` drops the four-character operation prefix. The output loop visits slots in increasing order, so no extra sort is needed. The buffer flushes in blocks, not once per line.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Hash one key | O(L) for length L | O(1) |
| One add, find, or delete | O(L + 20) | O(1) |
| Print one series | O(101 + K) for K stored keys | O(101) |

Each edit stays short in practice.

The probe count is a fixed twenty, so each edit stays constant apart from the key length.

| Measure | Bound |
| --- | --- |
| Total time | O(total input characters + output lines) |
| Total space | O(101) for the table plus input |
| Reset per series | O(101) |

A dictionary could answer membership faster, but it would not reproduce the required probe slots or the ordered table dump.
