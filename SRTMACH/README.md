# SRTMACH — Sorting Machine (SPOJ)

<https://www.spoj.com/problems/SRTMACH/>

## Problem

Two permutations reorder a list of length `N`. Apply them any number of times in any order, then keep the lexicographically smallest reordering. Count the distinct kept lists over all `M^N` input lists, modulo `MOD` = 98765431.

Input starts with the test count `T`. Each test has `N` and `M`, then two lines of `N` integers describing the permutations. Output one answer per test.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 10 |
| List length `N` | 2 to 10 |
| Value range `M` | 1 to 10 |
| Modulo `MOD` | 98765431 |
| Judge limit | 1000 ms, 1536 MB |

Permutation entries lie in 1 to `N` and are distinct. The two permutations generate a subgroup `G` of the symmetric group on `N` positions. Notation: `N!` counts all permutations, |G| is the group size, and `M^cycles` counts the lists fixed by one permutation.

Here is the sample input:

```
2
2 2
1 2
2 1
3 3
2 1 3
3 1 2
```

Here is the sample output:

```
3
10
```

## Idea

Counting distinct smallest reorderings is the same as counting orbits of `G`, like counting distinct necklaces formed by rotation. Burnside's lemma gives the orbit count as the average number of fixed lists over the group. A fixed list is constant on each cycle of a permutation, so its count is `M` raised to the cycle count. A breadth-first search over generated permutations visits every group element once. Store each permutation as one packed 64-bit key in an open-addressing table, so duplicate detection stays constant time. The naive way enumerates every input list and every reordering; Burnside turns that into one sweep over the group. Each group element costs O(N) work.

## Why It Works

1. The two permutations and all their products form a finite group `G`.
2. Every input list has one orbit, the set of lists reachable by reordering.
3. All lists in one orbit share the same lexicographically smallest member, so distinct outputs equal distinct orbits.
4. A permutation fixes a list exactly when each cycle holds one repeated value, giving `M^cycles` fixed lists.
5. Burnside's lemma states that the orbit count is the sum of fixed counts divided by |G|.
6. Packing a permutation into four-bit nibbles gives one key, and a hash table with low load rejects repeats quickly.
7. The sum and group size are exact integers, so integer division is safe before the final modulo.

| Term | Meaning |
|---|---|
| `visited` | open-addressing table of packed permutation keys |
| `queue` | holds permutation keys still to expand |
| `packPermutation` | packs entries into one 64-bit key |
| `unpackPermutation` | restores entries from a key |
| `tryInsert` | adds an unseen key and reports whether it was new |
| `cycleCount` | number of cycles of the current permutation |
| `fixedSum` | sum of `M^cycles` over the group |
| `groupSize` | number of generated permutations |

The table names the values that feed the Burnside average and the group search.

A worked trace of the sample follows.

```
case 1: N=2 M=2, group size 2
  identity    cycles=2  fixed=2^2=4
  swap        cycles=1  fixed=2^1=2
  sum=6  answer=6/2=3
case 2: N=3 M=3, group size 6
  identity    cycles=3  fixed=27
  3 swaps     cycles=2  fixed=9 each -> 27
  2 rotations cycles=1  fixed=3 each -> 6
  sum=60 answer=60/6=10
```

The trace reproduces the sample outputs 3 and 10. The sums stay below 4 times 10 to the 16, so int64 holds them without overflow.

## Code

**Input and buffer setup.** The reader loads stdin once and defines the buffered writer.

```nim
const flushBlockBytes = 1 shl 17
const modValue = 98765431
const maxPermutationSize = 10
const bitsPerEntry = 4
const entryMask = 15

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and reads one decimal value at a time. The writer flushes only after a large block fills. Both helpers run once per program execution.

**Packing and hash helpers.** A permutation becomes one key, and insertion reports duplicate keys.

```nim
var factorials = newSeq[int](maxPermutationSize + 1)
factorials[0] = 1
for sizeIndex in 1 .. maxPermutationSize:
  factorials[sizeIndex] = factorials[sizeIndex - 1] * sizeIndex

proc packPermutation(values: seq[int], count: int): uint64 =
  result = 0'u64
  for position in 0 .. count - 1:
    result = result or uint64((values[position] + 1) shl (bitsPerEntry * position))

proc unpackPermutation(key: uint64, count: int, target: var seq[int]) =
  var packedValue = int64(key)
  for position in 0 .. count - 1:
    target[position] = int(packedValue and int64(entryMask)) - 1
    packedValue = packedValue shr bitsPerEntry

proc tryInsert(table: var seq[uint64], capacityMask: int, key: uint64): bool =
  var hashed = key * 11400714819323198485'u64
  hashed = hashed xor (hashed shr 30)
  hashed = hashed * 13829222197050239205'u64
  hashed = hashed xor (hashed shr 27)
  var slot = int(hashed and uint64(capacityMask))
  while table[slot] != 0'u64:
    if table[slot] == key:
      return false
    slot = (slot + 1) and capacityMask
  table[slot] = key
  return true
```

Adding one to each entry keeps the packed key non-zero, which marks an empty slot. The hash mixes both halves of the 40-bit key. Linear probing resolves the rare collision.

**Group sweep and Burnside average.** The search expands the group and totals fixed lists.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let permutationSize = nextInt(inputData, scanPos)
  let valueLimit = nextInt(inputData, scanPos)
  var firstGenerator = newSeq[int](permutationSize)
  var secondGenerator = newSeq[int](permutationSize)
  for position in 0 .. permutationSize - 1:
    firstGenerator[position] = nextInt(inputData, scanPos) - 1
  for position in 0 .. permutationSize - 1:
    secondGenerator[position] = nextInt(inputData, scanPos) - 1
  var powers = newSeq[int64](permutationSize + 1)
  powers[0] = 1
  for exponent in 1 .. permutationSize:
    powers[exponent] = powers[exponent - 1] * int64(valueLimit)
  var tableCapacity = 1
  while tableCapacity < 4 * factorials[permutationSize]:
    tableCapacity *= 2
  let capacityMask = tableCapacity - 1
  var visited = newSeq[uint64](tableCapacity)
  var queue = newSeq[uint64]()
  var identity = newSeq[int](permutationSize)
  for position in 0 .. permutationSize - 1:
    identity[position] = position
  let identityKey = packPermutation(identity, permutationSize)
  discard tryInsert(visited, capacityMask, identityKey)
  queue.add identityKey
  var queueHead = 0
  var fixedSum: int64 = 0
  var groupSize: int64 = 0
  var currentPerm = newSeq[int](permutationSize)
  var composedPerm = newSeq[int](permutationSize)
  var inCycle = newSeq[bool](permutationSize)
  while queueHead < queue.len:
    let currentKey = queue[queueHead]
    queueHead += 1
    unpackPermutation(currentKey, permutationSize, currentPerm)
    groupSize += 1
    var cycleCount = 0
    for position in 0 .. permutationSize - 1:
      inCycle[position] = false
    for start in 0 .. permutationSize - 1:
      if not inCycle[start]:
        cycleCount += 1
        var cursor = start
        while not inCycle[cursor]:
          inCycle[cursor] = true
          cursor = currentPerm[cursor]
    fixedSum += powers[cycleCount]
    for position in 0 .. permutationSize - 1:
      composedPerm[position] = currentPerm[firstGenerator[position]]
    let firstKey = packPermutation(composedPerm, permutationSize)
    if tryInsert(visited, capacityMask, firstKey):
      queue.add firstKey
    for position in 0 .. permutationSize - 1:
      composedPerm[position] = currentPerm[secondGenerator[position]]
    let secondKey = packPermutation(composedPerm, permutationSize)
    if tryInsert(visited, capacityMask, secondKey):
      queue.add secondKey
  appendOutput($(fixedSum div groupSize mod int64(modValue)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The table capacity stays at least four times the number of stored keys. Inverses need no special handling because a generator's inverse is a positive power of it. Integer division by the group size happens before the modulo.

## Complexity

Each case visits one group element at most once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input text | one input string |
| Group search | up to `N!` elements | hash table of `N!` keys |
| Cycle sums | O(N) per element | two permutation arrays |
| Output | one line per test | block buffer |

The table bounds memory for every legal `N`.

| Measure | Big O |
|---|---|
| Time per test | O(N times group size), at most N times N factorial |
| Space per test | O(N factorial plus N) |

Enumerating inputs and reorderings would cost O(M to the N times group size) and cannot reach ten positions. Burnside's lemma replaces that with one pass over the group.
