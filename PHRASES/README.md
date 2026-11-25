# PHRASES — Relevant Phrases of Annihilation (SPOJ)
<https://www.spoj.com/problems/PHRASES/>

## Problem

Your agents intercept several encrypted messages. The cryptographer will read only the fragment that the enemy emphasized most: a phrase appearing twice without overlap in every message.

Find the length of the longest such phrase. A phrase must occur at least twice disjointly in each message, and the same phrase must work across all messages.

Input: the first integer is t, the number of cases. Each case gives n messages, then n lowercase lines. Output: one integer per case, the maximum length.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | at most 10 |
| Messages per case n | at most 10 |
| Characters per message | 2 to 10000 |
| Alphabet | lowercase a–z |
| Time limit | 9000 ms |
| Memory limit | 1536 MB |

The sample has four messages:

```
1
4
abbabba
dabddkababa
bacaba
baba
```

```
2
```

The phrase `ba` appears twice without overlap in all four messages.

## Idea

Guess a length, fingerprint every substring of that length, then keep the fingerprints that qualify everywhere. Picture comparing four intercepted letters by underlining every two-letter pair and keeping only pairs underlined twice, far apart, in all of them.

The program binary searches the answer. For a tested length L, rolling hashes (numbers computed from a string so equal strings give equal numbers) turn each substring into a key. Two 64-bit bases make collisions unlikely.

Each message contributes the smallest and largest start position for every key. A key qualifies when `workMax − workMin ≥ L`, meaning two non-overlapping copies exist. Keys surviving all messages prove L feasible.

One feasibility check costs O(n × messageLength) with O(1) table work; binary search multiplies that by log(messageLength). Comparing all substring pairs costs O(n × messageLength²).

Takeaway: hashing plus binary search turns a repeated-substring hunt into a handful of linear scans.

## Why It Works

Four facts justify the check.

1. Two occurrences of a length-L substring are disjoint exactly when their start positions differ by at least L. Tracking only the smallest and largest start is enough to detect that.
2. The rolling hash of a substring comes from two prefix-hash arrays in O(1). Using two independent bases keeps accidental collisions negligible.
3. `prepareWork` stores a min and max start per key in an open-addressed table. A key passes a message when its spread reaches L.
4. `feasible` removes any key that fails in a later message. If keys remain, one phrase appears disjointly twice everywhere. Feasibility decreases with L, so binary search finds the maximum.

These are the parts of one feasibility test:

| Term | Meaning |
| --- | --- |
| `HashKey` | pair of 64-bit rolling hashes for one substring |
| `prefixA`, `prefixB` | running hashes used to extract substring hashes |
| `powerA`, `powerB` | precomputed base powers for the two hashes |
| `workMin`, `workMax` | smallest and largest start offset of a key in one message |
| `commonUsed` | marks keys still valid in every processed message |
| `tableMask` | bit mask that maps a hash to a table slot |

A script checks length 2 on the sample messages:

```
abbabba     -> ['ab', 'ba', 'bb']
dabddkababa -> ['ab', 'ba']
bacaba      -> ['ba']
baba        -> ['ba']
```

The intersection keeps only `ba`. The search therefore accepts length 2 and rejects length 3. The upper bound is half the shortest message, since two disjoint copies must fit.

## Code

**Input.** The whole stream goes into one buffer, and words are read by offset.

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
```

`nextWord` copies one message, so trailing whitespace never enters a hash. The power arrays are shared across cases. Setup costs O(maxMessageLength).

**Output.** One buffer collects the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush happens every `flushBlockBytes` bytes. No write occurs during a feasibility check. The cost is one pass over the answer text.

**Tables.** Three open-addressed tables hold working and common keys.

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

The power tables let any substring hash come from two prefix differences. Arrays are allocated once at maximum size, so no case reallocates them. Space is O(tableSize + messageLength).

**Table operations.** Linear probing stores keys and merges start positions.

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

`slotOf` masks the first hash into the table. Probing wraps with `and (tableSize − 1)` because the size is a power of two. Each operation costs O(1) expected time.

**Feasibility.** One length is tested across all messages.

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

Clearing `workMin` to −1 resets the table in one pass, which is cheaper than freeing it. The spread test `workMax − workMin ≥ length` enforces disjointness. One check costs O(n × messageLength).

**Driver.** Binary search finds the longest feasible length.

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

The upper bound `shortest div 2` follows from needing two disjoint copies. The `+ 1` in the middle avoids an infinite loop when two values remain. Each case uses about log(shortest) checks.

## Complexity

Binary search repeats linear hash scans.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total characters) | O(input size) |
| Power tables | O(maxMessageLength) | O(maxMessageLength) |
| One feasibility check | O(n × messageLength) | O(messageLength) |
| Binary search | O(log shortest) checks | O(tableSize) |
| Output | O(cases) | O(block size) |

Feasibility dominates, with about log(10000) × n × 10000 hash operations per case.

| Measure | Big O |
| --- | --- |
| Time per case | O(n × Lmax × log Lmax) |
| Total time | O(sum over cases of n × Lmax × log Lmax) |
| Working space | O(tableSize + Lmax) |

Comparing every substring pair across messages takes O(n × Lmax²) time, far more than hashing.
