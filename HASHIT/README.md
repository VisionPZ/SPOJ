## Problem

Read several series of operations on a hash table of 101 slots. Each operation adds or deletes a string key. Two keys can collide, so the table uses quadratic probing with twenty candidate slots. After each series, print the number of stored keys, then one `index:key` line for every occupied slot, ordered by index.

| Quantity | Bound |
| --- | --- |
| Series per file | at most 100 |
| Operations per series | at most 1000 |
| Key length | at most 15 characters |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

A new empty table is used for every series.

## Idea

Store the table as two flat arrays: one for keys and one for occupancy flags. For each operation, compute the start slot from the key and try the twenty probe slots in order. Add the first empty slot, delete a matching key, and ignore keys that are absent or already present.

Each operation examines at most twenty slots, so the cost per operation is constant. Rebuilding the table with a dictionary would hide the required probing order.

## Why It Works

The hash value is `19 · Σ ASCII(aᵢ)·i mod 101`, counting positions from one. Probe step `j` tests slot `(hash + j² + 23j) mod 101`. The program uses steps zero through nineteen, which matches the twenty examined entries in the statement.

Deletion marks a slot as empty without moving other keys. A lookup therefore scans the whole probe sequence instead of stopping at the first empty slot, so it still finds a key stored behind a gap. Keys print in index order because the output loop walks the table from slot zero.

## Code

Input is read once and split into lines by a small scanner.

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

The integer scanner leaves the cursor on the newline, so the driver consumes that newline once before reading operation lines. Parsing one line visits its characters once.

Hashing and probing are pure arithmetic on small integers.

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

The weighted sum counts from one, as the statement defines. All twenty probe slots are examined on lookup, which keeps deleted gaps from hiding a key.

The add and delete operations use the same probe sequence.

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

An insertion stops at the first free slot and ignores a key already present. A full probe sequence leaves the key out. Deletion only changes the two arrays at the found slot.

The driver resets the table per series and emits the sorted contents.

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

The reset loop clears both arrays in 101 steps. The output loop visits slots in increasing order, so the lines are already sorted. The buffer flushes in blocks, not once per line.

## Complexity

Hashing a key costs O(L) for length L. Each operation probes at most twenty slots, so it costs O(L) time. Printing one series costs O(101 + K) for K stored keys. Total time is O(total input characters + output lines) and space is O(101) for the table plus the input buffer.
