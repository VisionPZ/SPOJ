# PATIOSLB — Patio paving slabs (SPOJ)

<https://www.spoj.com/problems/PATIOSLB/>

## Problem

Choose slabs whose lengths plus the grout gaps exactly fill a row. Print the chosen lengths from largest to smallest, or print `-1` when no choice fits.

Input starts with the test count. Each test case has a row length, a slab count, and the list of slab lengths.

Output is one line per case. A valid line lists the chosen lengths in descending order; an impossible case prints `-1`. When several choices fit, the one using the largest slabs wins.

| item | bound |
|---|---|
| test cases | given on the first line |
| row length | positive integer in cm |
| slab count | positive integer |
| slab lengths | positive integers in cm |
| judge limit | 1000 ms, 1536 MB |

Each chosen slab takes its own length plus one centimetre of grout, and the row ends add two more centimetres.

Sample input:

```
2
100
9
20 40 30 24 31 18 55 40 23
50
4
2 0 30 40
```

Sample output:

```
55 23 18
-1
```

## Idea

Turn each slab length into a weight that already includes its grout gap, like packing boxes with their own padding. Sort the slabs from largest to smallest and greedily keep a slab whenever a completion still exists.

A suffix reachability table answers whether the remaining slabs can hit a remaining sum. Each check is one bit test, so reconstruction stays fast. Taking slabs in descending order automatically picks the largest possible first slab, then the next largest, and so on.

Sort descending, build suffix reachability, then keep every slab that still allows a completion.

## Why It Works

1. A row of length `L` needs chosen lengths plus gaps to equal `L`.
2. With `k` chosen slabs there are `k-1` inner gaps and two end gaps, so the gap total is `k+1`.
3. Hence the sum of chosen lengths plus `k` equals `L-1`.
4. Give each slab the weight `length + 1`; the required sum is `L-1`.
5. A suffix table stores every sum reachable from the slabs at and after a position.
6. Including the largest feasible slab, then repeating, yields the lexicographically largest descending list.

| term | meaning |
|---|---|
| `rowLength` | total row length in centimetres |
| `targetSum` | row length minus one, the required weight sum |
| `slabLengths` | available lengths sorted descending |
| `suffixBits` | reachable sums from each suffix of the slab list |
| `remainingSum` | weight still needed after the kept slabs |

For the sample row of 100 cm, the target is 99. Weights 56, 24, and 19 sum to 99, giving lengths 55, 23, and 18. Their gaps add four centimetres and fill the row exactly.

A second sample row of 50 cm has target 49, which no subset of its weights reaches.

## Code

**Input and bitset helpers.** The reader loads all cases and defines single-bit operations on 64-bit words.

```nim
const flushBlockBytes = 1 shl 17

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

proc setBit(bits: var seq[uint64], position: int) =
  let wordIndex = position shr 6
  let bitOffset = position and 63
  bits[wordIndex] = bits[wordIndex] or (uint64(1) shl uint(bitOffset))

proc testBit(bits: seq[uint64], position: int): bool =
  let wordIndex = position shr 6
  let bitOffset = position and 63
  return (bits[wordIndex] and (uint64(1) shl uint(bitOffset))) != uint64(0)

proc shiftOrInto(destination: var seq[uint64], source: seq[uint64], shiftAmount: int) =
  let wordShift = shiftAmount shr 6
  let bitShift = shiftAmount and 63
  var sourceIndex = 0
  while sourceIndex < source.len:
    let sourceValue = source[sourceIndex]
    if sourceValue != uint64(0):
      let lowTarget = sourceIndex + wordShift
      if bitShift == 0:
        if lowTarget < destination.len:
          destination[lowTarget] = destination[lowTarget] or sourceValue
      else:
        if lowTarget < destination.len:
          destination[lowTarget] = destination[lowTarget] or (sourceValue shl uint(bitShift))
        let highTarget = lowTarget + 1
        if highTarget < destination.len:
          destination[highTarget] = destination[highTarget] or (sourceValue shr uint(64 - bitShift))
    sourceIndex += 1
```

A bitset holds all reachable sums at once.
A shift by a slab weight adds the choice that uses that slab.
Words are skipped when their bits are all zero.

**Suffix tables and greedy choice.** Slabs are sorted, suffix sums are built, then the largest feasible slabs are kept.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowLength = nextInt(inputData, scanPos)
  let slabCount = nextInt(inputData, scanPos)
  var slabLengths = newSeq[int](slabCount)
  var slabCursor = 0
  while slabCursor < slabCount:
    slabLengths[slabCursor] = nextInt(inputData, scanPos)
    slabCursor += 1
  var sortCursor = 1
  while sortCursor < slabCount:
    let insertionValue = slabLengths[sortCursor]
    var shiftCursor = sortCursor - 1
    while shiftCursor >= 0 and slabLengths[shiftCursor] < insertionValue:
      slabLengths[shiftCursor + 1] = slabLengths[shiftCursor]
      shiftCursor -= 1
    slabLengths[shiftCursor + 1] = insertionValue
    sortCursor += 1
  let targetSum = rowLength - 1
  if targetSum < 0:
    appendOutput("-1\n")
    continue
  let wordCount = targetSum div 64 + 1
  var suffixBits = newSeq[seq[uint64]](slabCount + 1)
  var emptyBits = newSeq[uint64](wordCount)
  setBit(emptyBits, 0)
  suffixBits[slabCount] = emptyBits
  var reverseCursor = slabCount - 1
  while reverseCursor >= 0:
    suffixBits[reverseCursor] = suffixBits[reverseCursor + 1]
    shiftOrInto(suffixBits[reverseCursor], suffixBits[reverseCursor + 1], slabLengths[reverseCursor] + 1)
    reverseCursor -= 1
  var remainingSum = targetSum
  var chosenLengths = newSeq[int](0)
  var itemCursor = 0
  while itemCursor < slabCount:
    let slabWeight = slabLengths[itemCursor] + 1
    if slabWeight <= remainingSum and testBit(suffixBits[itemCursor + 1], remainingSum - slabWeight):
      chosenLengths.add slabLengths[itemCursor]
      remainingSum = remainingSum - slabWeight
    itemCursor += 1
  if remainingSum != 0:
    appendOutput("-1\n")
  else:
    var chosenCursor = 0
    while chosenCursor < chosenLengths.len:
      if chosenCursor > 0:
        appendOutput(" ")
      appendOutput($chosenLengths[chosenCursor])
      chosenCursor += 1
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Insertion sort puts the longest slab first.
Each suffix is the union of skipping and taking its first slab.
The greedy pass keeps a slab only when a completion remains.

## Complexity

Each suffix bitset costs one shifted copy, and reconstruction tests one bit per slab.

| phase | time | space |
|---|---|---|
| input read | one pass over all slabs | one input string |
| sort | O(m^2) insertions | slab array |
| suffix bitsets | m shifts of T/64 words | m bitsets of T/64 words |
| reconstruction | one bit test per slab | chosen slab list |

The target sum sets the bitset width and the slab count sets its height.

| measure | Big O |
|---|---|
| time | O(m * T/64 + m^2) |
| space | O(m * T/64) |

Testing every subset would take exponential time in the slab count.

Convert gaps into weights, build suffix bitsets, and greedily keep the largest feasible slabs.
