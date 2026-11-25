# CLONE — Find the Clones (SPOJ)

<https://www.spoj.com/problems/CLONE/>

## Problem

Each resident supplies a DNA string of length m over the bases A, C, G and T. Identical strings belong to one original person, so the task is to report how many distinct people appear exactly k times for every k from 1 to n.

Input contains blocks. Each block starts with two integers n and m, followed by n DNA strings of length m. A block with n = m = 0 ends the input.

Output contains n lines per block. Line k holds the number of distinct strings seen exactly k times.

The bounds fix the data size:

| item | bound |
|---|---|
| people n | 1 to 20000 |
| DNA length m | 1 to 20 |
| DNA alphabet | A, C, G, T |
| judge limit | 10000 ms, 1536 MB |

The product n times m drives the reading cost, while n drives the number of output lines.

Sample input:

```
9 6
AAAAAA
ACACAC
GTTTTG
ACACAC
GTTTTG
ACACAC
ACACAC
TCCCCC
TCCCCC
0 0
```

Sample output:

```
1
2
0
1
0
0
0
0
0
```

## Idea

Counting stacks of identical name tags is like sorting a pile of cards and reading each pile size once. The code packs each DNA string into a 64-bit integer and counts equal keys with an open-addressing hash table.

Each key needs two bits per base, so 20 bases fit in 40 bits. One pass builds the counts, and a second pass turns the counts into the requested histogram. A sorting approach costs n log n comparisons of strings; hashing costs one table probe per person.

Hash the packed key, tally it, then tally the tallies.

## Why It Works

1. Two bits encode each of the four bases, so one `sequenceKey` holds any string of up to 20 bases.
2. Equal DNA strings produce equal `sequenceKey` values, and different strings produce different keys.
3. `keySlots`, `countSlots` and `usedSlots` form a hash table with linear probing, so each person needs one search.
4. After the pass, `copyHistogram[countSlots[slotIndex]]` adds one person at the slot's exact copy count.
5. Printing indices 1 through n gives one line per possible copy count, including zeros.

The main terms:

| term | meaning |
|---|---|
| `sequenceKey` | packed two-bit representation of one DNA string |
| `mixKey` | bit mixer that spreads keys over the table |
| `countSlots` | number of people sharing the key in each slot |
| `copyHistogram` | number of distinct people with a given copy count |
| `flushBlockBytes` | buffer size that triggers a single stdout write |

The table turns arbitrary keys into compact copy counts.

The sample trace from gen.py:

```
sequence AAAAAA appears 1 time(s)
sequence ACACAC appears 4 time(s)
sequence GTTTTG appears 2 time(s)
sequence TCCCCC appears 2 time(s)
histogram 1 2 0 1 0 0 0 0 0
```

The four stacks give one singleton, two pairs and one group of four, matching the sample output.

## Code

**Input and key hashing.** The reader loads all bytes, then packs each sequence into one integer.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const bitsPerBase = 2

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextBaseChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let foundChar = data[pos]
  pos += 1
  return foundChar

proc mixKey(key: uint64): uint64 =
  var mixed = key
  mixed = mixed xor (mixed shr 30)
  mixed = mixed * 0xbf58476d1ce4e5b9'u64
  mixed = mixed xor (mixed shr 27)
  mixed = mixed * 0x94d049bb133111eb'u64
  mixed = mixed xor (mixed shr 31)
  return mixed
```

The scanner skips separators and reads digits one at a time.
Base characters need no separator because their count comes from `sequenceLength`.
The mixer avoids clustering when strings share long prefixes.

**Tally and output.** Each block fills the table, then converts counts into one buffered line per copy number.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let peopleCount = nextInt(inputData, scanPos)
  let sequenceLength = nextInt(inputData, scanPos)
  if peopleCount == 0 and sequenceLength == 0:
    break
  var tableCapacity = 1
  while tableCapacity < peopleCount * 4:
    tableCapacity = tableCapacity shl 1
  var keySlots = newSeq[uint64](tableCapacity)
  var countSlots = newSeq[int](tableCapacity)
  var usedSlots = newSeq[bool](tableCapacity)
  for personIndex in 0 .. peopleCount - 1:
    var sequenceKey: uint64 = 0
    for letterIndex in 0 .. sequenceLength - 1:
      let baseChar = nextBaseChar(inputData, scanPos)
      var letterCode = 0
      case baseChar
      of 'C': letterCode = 1
      of 'G': letterCode = 2
      of 'T': letterCode = 3
      else: letterCode = 0
      sequenceKey = (sequenceKey shl bitsPerBase) or uint64(letterCode)
    var slotIndex = int(mixKey(sequenceKey) and uint64(tableCapacity - 1))
    while usedSlots[slotIndex] and keySlots[slotIndex] != sequenceKey:
      slotIndex = (slotIndex + 1) and (tableCapacity - 1)
    if usedSlots[slotIndex]:
      countSlots[slotIndex] += 1
    else:
      usedSlots[slotIndex] = true
      keySlots[slotIndex] = sequenceKey
      countSlots[slotIndex] = 1
  var copyHistogram = newSeq[int](peopleCount + 1)
  for slotIndex in 0 .. tableCapacity - 1:
    if usedSlots[slotIndex]:
      copyHistogram[countSlots[slotIndex]] += 1
  for copies in 1 .. peopleCount:
    appendOutput($copyHistogram[copies])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The table capacity stays a power of two, so masking replaces division.
Probing stops at the first free slot or the matching key.
`appendOutput` writes in blocks, which keeps large outputs cheap.

## Complexity

Reading, counting and printing each have one clear cost.

| phase | time | space |
|---|---|---|
| input read | one pass over all n strings | one input string |
| key counting | one hash probe per person | four arrays of table slots |
| histogram | one pass over table slots | n + 1 counters |
| output | one line per copy count | block buffer |

The table arrays cost O(n) space and the scan touches them once per person.

| measure | Big O |
|---|---|
| time | O(n * m) per block |
| space | O(n) |

Sorting the strings would cost O(n log n * m) per block.
Packing and hashing keep the whole block linear in its input size.
