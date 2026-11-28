# MCONSTR — Search of Concatenated Strings (SPOJ)

<https://www.spoj.com/problems/MCONSTR/>

## Problem

Count the text positions where a permutation of all the given strings appears back to back. A position counts once even when several permutations match it, and overlapping matches count separately.

Input contract: each dataset gives n and m, then n element strings, then m text lines whose newlines are ignored. A line with two zeros ends the input. Output contract: print one position count per dataset.

The bounds from the statement:

| item | bound |
|---|---|
| element strings n | 1 to 12 |
| element length | 1 to 20 |
| text lines m | give text length 1 to 5000 |
| judge limit | 100 ms, 1536 MB |

The concatenation always uses every element string exactly once.

Sample input:

```
3 1
aa
b
ccc
aabccczbaacccbaazaabbcccaa
3 1
a
b
c
cbbcbcbabaacabccaccbaacbccbcaaaccccbcbcbbcacbaacccaccbbcaacbbabbabaccc
3 4
aaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
0 0
```

Sample output:

```
5
12
197
```

## Idea

Think of each start position as a sticker album that must receive one of every sticker, in any order. The algorithm runs a subset DP whose states carry bitsets of start positions instead of single positions. Each state transitions once per remaining element, and one transition costs a fixed number of machine words. Testing every permutation at every position would cost factorial work per position. The bitsets merge all orders into one pass.

## Why It Works

1. Every concatenation consumes all n elements, so a subset identifies exactly which elements remain.
2. The characters consumed by a subset equal the sum of its element lengths, whatever the order.
3. Each subset therefore maps a start position to one fixed end position.
4. A bit in the end-position set marks a start that can reach that end with the chosen subset.
5. Intersecting with match positions for one element extends the subset by that element.
6. Merging into the next subset with an OR counts a start once even if several orders reach it.

The terms in the DP:

| term | meaning |
|---|---|
| `matchBits` | start positions where one element matches the text |
| `endBits` | end positions reachable for each subset |
| `nextMask` | subset with one more element chosen |
| `fullMask` | subset containing every element |
| `occurrenceCount` | number of matching text positions |

The final count uses one bit per start, so duplicates never inflate it.

A traced search of the first sample dataset:

```
start 0   aa + b + ccc = aabccc   match
start 7   b + aa + ccc = baaccc   match
start 8   aa + ccc + b = aacccb   match
start 10  ccc + aa + b = cccbaa   match
start 20  b + ccc + aa = bcccaa   match
total = 5
```

Five start positions match, which is the first sample answer.

## Code

**Input and bit helpers.** Tokens supply the element strings and the text lines.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[start ..< pos]

proc hasMoreNumbers(data: string, pos: int): bool =
  var index = pos
  while index < data.len:
    if data[index] >= '0' and data[index] <= '9':
      return true
    index += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc setBit(bits: var seq[uint64], position: int) =
  let wordIndex = position div 64
  bits[wordIndex] = bits[wordIndex] or (uint64(1) shl (position mod 64))

proc countBits(value: uint64): int =
  var current = value
  var total = 0
  while current != 0'u64:
    current = current and (current - 1'u64)
    total += 1
  return total
```

Text lines concatenate without their newlines.
Each bit stands for one text position.
Popcount turns the last bitset into the answer.

**Transition.** One call extends every reachable start by one element.

```nim
proc mergeTransition(currentBits: seq[uint64], matchBits: seq[uint64],
                     shiftAmount: int, target: var seq[uint64]) =
  let wordShift = shiftAmount div 64
  let bitShift = shiftAmount mod 64
  var carry: uint64 = 0
  for wordIndex in 0 .. target.len - 1:
    var value: uint64 = 0
    var nextCarry: uint64 = 0
    if wordIndex >= wordShift:
      let sourceIndex = wordIndex - wordShift
      let combined = currentBits[sourceIndex] and matchBits[sourceIndex]
      if bitShift == 0:
        value = combined
      else:
        value = (combined shl bitShift) or carry
        nextCarry = combined shr (64 - bitShift)
    target[wordIndex] = target[wordIndex] or value
    carry = nextCarry
```

The AND keeps only starts where the element matches.
The shift moves each start to the new end position.
The OR merges starts reachable by different orders.

**Subset sweep and output.** Masks grow until every element is used.

```nim
while hasMoreNumbers(inputData, scanPos):
  let elementCount = nextInt(inputData, scanPos)
  let textLineCount = nextInt(inputData, scanPos)
  if elementCount == 0 and textLineCount == 0:
    break
  var elementStrings = newSeq[string](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    elementStrings[elementIndex] = nextToken(inputData, scanPos)
  var textData = ""
  for lineIndex in 0 .. textLineCount - 1:
    textData.add nextToken(inputData, scanPos)
  let textLength = textData.len
  let wordCount = textLength div 64 + 1
  var elementLengths = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    elementLengths[elementIndex] = elementStrings[elementIndex].len

  var matchBits = newSeq[seq[uint64]](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    matchBits[elementIndex] = newSeq[uint64](wordCount)
    let elementLength = elementLengths[elementIndex]
    for startPosition in 0 .. textLength - elementLength:
      var matches = true
      for offset in 0 .. elementLength - 1:
        if textData[startPosition + offset] != elementStrings[elementIndex][offset]:
          matches = false
          break
      if matches:
        setBit(matchBits[elementIndex], startPosition)

  let maskCount = 1 shl elementCount
  let fullMask = maskCount - 1
  var endBits = newSeq[seq[uint64]](maskCount)
  for mask in 0 .. maskCount - 1:
    endBits[mask] = newSeq[uint64](wordCount)
  for position in 0 .. textLength:
    setBit(endBits[0], position)

  for mask in 0 .. maskCount - 1:
    for elementIndex in 0 .. elementCount - 1:
      if (mask and (1 shl elementIndex)) == 0:
        let nextMask = mask or (1 shl elementIndex)
        mergeTransition(endBits[mask], matchBits[elementIndex],
                        elementLengths[elementIndex], endBits[nextMask])

  var occurrenceCount = 0
  for word in endBits[fullMask]:
    occurrenceCount += countBits(word)
  appendOutput($(occurrenceCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Masks are visited in increasing order, so each subset is complete when processed.
The zero mask starts with every text position available.
The final popcount gives one count per dataset.

## Complexity

The subset sweep dominates, and n is at most twelve.

| phase | time | space |
|---|---|---|
| match table | one comparison per element and text position | n position bitsets |
| subset sweep | one word pass per subset and element | 2^n position bitsets |
| final count | one pass over the last bitset | block buffer |

Each transition touches about text length divided by sixty-four words.

| measure | Big O |
|---|---|
| time | O(2^n times n times textLength / 64) |
| space | O(2^n times textLength / 64) |

Trying every permutation at every position would cost O(n factorial times textLength).
Bitsets fold all orders into one subset sweep.
