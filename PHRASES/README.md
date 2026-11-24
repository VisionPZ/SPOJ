## Problem

Read several test cases. Each case gives n messages made of lowercase letters. Print the length of the longest string that appears disjointly at least twice in every message. Two occurrences are disjoint when their character ranges do not overlap.

The judge gives these bounds.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 10 |
| Messages per case | at most 10 |
| Message length | 2 to 10000 characters |
| Time limit | 9000 ms |
| Memory limit | 1536 MB |

The message length sets the search bound, since two disjoint copies need twice the answer.

## Idea

Binary search the answer length. For one candidate length, hash every substring of that length in each message. Keep a hash only when two occurrences start far enough apart to be disjoint. Intersect the kept sets across all messages. A shared hash means some string of that length qualifies everywhere.

Cost per substring: one constant-time hash and one hash-table probe.

## Why It Works

Prefix hashes turn any substring hash into two array reads and one subtraction. The program builds two independent 64-bit hashes, so a collision needs two unlikely matches.

For a candidate length, one table stores the smallest and largest start of each substring hash. The gap test `workMax[slot] - workMin[slot] >= length` marks a substring that occurs twice without overlap.

The largest start and the smallest start give two occurrences. Their distance is at least the length, so they do not overlap. Any qualifying pair implies this inequality, so the test loses no answer.

Feasibility is monotone. A qualifying string of length L has a prefix of length L - 1 that also qualifies at the same starts. Binary search therefore finds the largest feasible length.

The sample script checks each two-letter string in every message.

| Message | Substrings with two disjoint copies |
| --- | --- |
| abbabba | ab, ba, bb |
| dabddkababa | ab, ba |
| bacaba | ba |
| baba | ba |

Only `ba` survives every row. Length 3 fails the same check, so the answer is 2.

## Code

**Constants and bulk input.**

```nim
{.push checks: off.}
const firstDigitValue = 48
const firstLetterValue = 97
const flushBlockBytes = 1 shl 18
const tableBits = 15
const tableSize = 1 shl tableBits
const tableMask = uint64(tableSize - 1)
const baseA: uint64 = 1000003
const baseB: uint64 = 1000033
const maxMessageLength = 10000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The read loop runs to end of file, so all bytes land in one string. The pragma removes runtime checks from the hot loops. The table holds 32768 slots, which keeps the load below one half.

**Scanners and output helper.**

```nim
var i = 0

proc nextInt(): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i += 1
  return value

proc nextWord(): string =
  while i < inputData.len and (inputData[i] < 'a' or inputData[i] > 'z'):
    i += 1
  var startPos = i
  while i < inputData.len and inputData[i] >= 'a' and inputData[i] <= 'z':
    i += 1
  return inputData[startPos .. i - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner walks the shared index, so no token object is built. `nextWord` skips trailing whitespace and returns only letters. The output flushes once per 256 KiB block.

**Powers and tables.**

```nim
type HashKey = tuple[firstHash: uint64; secondHash: uint64]

var powerA = newSeq[uint64](maxMessageLength + 1)
var powerB = newSeq[uint64](maxMessageLength + 1)
powerA[0] = 1
powerB[0] = 1
for k in 1 .. maxMessageLength:
  powerA[k] = powerA[k - 1] * baseA
  powerB[k] = powerB[k - 1] * baseB

var prefixA: seq[uint64]
var prefixB: seq[uint64]
var messages: seq[string]
var workKey: array[tableSize, HashKey]
var workMin: array[tableSize, int]
var workMax: array[tableSize, int]
var commonKey: array[tableSize, HashKey]
var commonUsed: array[tableSize, bool]
var commonCount = 0
```

Both power arrays are built once before any test case. The work table is rebuilt per message. The common table holds hashes still shared by every message seen so far.

**Open-addressing probes.**

```nim
proc slotOf(key: HashKey): int =
  return int(key.firstHash and tableMask)

proc putWork(key: HashKey, startPos: int) =
  var slot = slotOf(key)
  while workMin[slot] != -1:
    if workKey[slot].firstHash == key.firstHash and workKey[slot].secondHash == key.secondHash:
      if startPos < workMin[slot]: workMin[slot] = startPos
      if startPos > workMax[slot]: workMax[slot] = startPos
      return
    slot = (slot + 1) and (tableSize - 1)
  workKey[slot] = key
  workMin[slot] = startPos
  workMax[slot] = startPos

proc findWork(key: HashKey): int =
  var slot = slotOf(key)
  while workMin[slot] != -1:
    if workKey[slot].firstHash == key.firstHash and workKey[slot].secondHash == key.secondHash:
      return slot
    slot = (slot + 1) and (tableSize - 1)
  return -1

proc putCommon(key: HashKey) =
  var slot = slotOf(key)
  while commonUsed[slot]:
    if commonKey[slot].firstHash == key.firstHash and commonKey[slot].secondHash == key.secondHash:
      return
    slot = (slot + 1) and (tableSize - 1)
  commonKey[slot] = key
  commonUsed[slot] = true
  commonCount += 1
```

Linear probing stops at an empty slot or a matching key. A start of -1 marks an empty work slot, which avoids a second occupancy array. Each probe touches one cache-friendly flat array.

**Hash the substrings of one message.**

```nim
proc prepareWork(message: string, length: int) =
  for slot in 0 .. (tableSize - 1): workMin[slot] = -1
  let messageLen = message.len
  prefixA.setLen(messageLen + 1)
  prefixB.setLen(messageLen + 1)
  prefixA[0] = 0
  prefixB[0] = 0
  for k in 0 .. (messageLen - 1):
    let letter = uint64(ord(message[k]) - firstLetterValue)
    prefixA[k + 1] = prefixA[k] * baseA + letter
    prefixB[k + 1] = prefixB[k] * baseB + letter
  for k in 0 .. (messageLen - length):
    let key: HashKey = (prefixA[k + length] - prefixA[k] * powerA[length],
                        prefixB[k + length] - prefixB[k] * powerB[length])
    putWork(key, k)
```

The loop runs once per start, from 0 to messageLen - length. Prefix hashes make each substring hash constant time. Stale keys from an earlier call stay harmless because the cleared start marks those slots empty.

**Test one length.**

```nim
proc feasible(length: int): bool =
  prepareWork(messages[0], length)
  for slot in 0 .. (tableSize - 1): commonUsed[slot] = false
  commonCount = 0
  for slot in 0 .. (tableSize - 1):
    if workMin[slot] != -1 and workMax[slot] - workMin[slot] >= length:
      putCommon(workKey[slot])
  if commonCount == 0: return false
  for messageIndex in 1 .. (messages.len - 1):
    prepareWork(messages[messageIndex], length)
    for slot in 0 .. (tableSize - 1):
      if commonUsed[slot]:
        let found = findWork(commonKey[slot])
        if found == -1 or workMax[found] - workMin[found] < length:
          commonUsed[slot] = false
          commonCount -= 1
    if commonCount == 0: return false
  return commonCount > 0
```

The first message seeds the common set. Each later message removes hashes that no longer qualify. The scan stops early when the set becomes empty. Cost is one pass over the table per message.

**Binary search and output.**

```nim
let caseCount = nextInt()
for j in 0 .. (caseCount - 1):
  let messageCount = nextInt()
  messages = newSeq[string](messageCount)
  var shortest = maxMessageLength
  for k in 0 .. (messageCount - 1):
    messages[k] = nextWord()
    if messages[k].len < shortest: shortest = messages[k].len
  var low = 0
  var high = shortest div 2
  while low < high:
    let middle = (low + high + 1) div 2
    if feasible(middle):
      low = middle
    else:
      high = middle - 1
  appendOutput($low)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

The upper bound is half the shortest message, since two copies need that much space. Each loop tests the middle length and narrows the range. The final write flushes the remaining answer lines.

## Complexity

Costs by phase, with S as the total input characters and L as a tested length:

| Phase | Time | Space |
| --- | --- | --- |
| power setup | O(10000) | O(10000) |
| hash one message | O(L) per start | message length |
| test one length | O(S + n * 32768) | table size |
| binary search | O(log 10000) tests | table size |
| output | one write per block | block size |

The largest table scans dominate, yet they stay fixed at 32768 slots.

Big O form:

| Measure | Form |
| --- | --- |
| Time | O(log M * (S + n * T)) for shortest message M and table size T |
| Space | O(S + n * 10000 + T) |

Enumerating every substring and searching it in every message costs far more than one hash pass per start.
