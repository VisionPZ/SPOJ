# PERMUT3 — Another Permutation Problem (SPOJ)

<https://www.spoj.com/problems/PERMUT3/>

## Problem

Count the permutations whose up-down pattern matches a given permutation. The pattern records whether each adjacent pair rises or falls. The count includes the given permutation itself.

Each test case starts with a size n. The next line holds a permutation of 1 through n. A single zero ends the input. Each case prints one line with the count, which can exceed 64 bits.

| item | bound |
|---|---|
| permutation size n | 1 to 100 |
| test cases | until a zero line |
| judge limit | 1000 ms, 1536 MB |

The count for n = 100 can have over 150 decimal digits.

Sample input:

```
2
1 2
4
1 3 2 4
0
```

Sample output:

```
1
5
```

## Idea

Track only the relative rank of the last value, like sorting a hand of cards after each new card. When a new value rises, the previous value must rank below it. When it falls, the previous value must rank above it. Prefix and suffix sums give the next row of counts in one pass. Big integers hold counts that exceed 64 bits. Listing every permutation would be far slower than this rank table.

## Why It Works

1. After i positions, only the relative rank of the last value matters.
2. Inserting the next rank j shifts old ranks below j down by one place.
3. An ascent needs an old rank below j, so the new count is a prefix sum.
4. A descent needs an old rank at least j, so the new count is a suffix sum.
5. Summing the final row counts every permutation with that pattern once.
6. Base-10^9 limbs store the answer exactly across hundreds of digits.

| term | meaning |
|---|---|
| `previousRow` | counts by last rank for the current length |
| `prefixSums` | running totals that realize ascents |
| `suffixSums` | running totals that realize descents |
| `limbBase` | 10^9, the base of each big-integer limb |

The two sum arrays turn the rank transition into a linear sweep.

The generator traces the sample case with n = 4:

| length | counts by rank | total |
|---|---|---|
| 1 | 1 | 1 |
| 2 | 0, 1 | 1 |
| 3 | 1, 1, 0 | 2 |
| 4 | 0, 1, 2, 2 | 5 |

The last total 5 matches the sample output.

## Code

**Input and big-integer addition.** The reader loads all tokens and carries sums in base 10^9.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbDigits = 9

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

proc addBig(target: var seq[int], source: seq[int]) =
  var carry = 0
  var limbIndex = 0
  while limbIndex < source.len:
    if limbIndex >= target.len:
      target.add 0
    let total = target[limbIndex] + source[limbIndex] + carry
    target[limbIndex] = total mod limbBase
    carry = total div limbBase
    limbIndex += 1
  while carry > 0:
    if limbIndex >= target.len:
      target.add 0
    let total = target[limbIndex] + carry
    target[limbIndex] = total mod limbBase
    carry = total div limbBase
    limbIndex += 1

proc bigToString(value: seq[int]): string =
  if value.len == 0:
    return "0"
  var text = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    var piece = $value[limbIndex]
    while piece.len < limbDigits:
      piece = "0" & piece
    text.add piece
    limbIndex -= 1
  return text
```

Each limb holds nine decimal digits.
The carry never exceeds one because both operands stay below the base.
Output limbs are padded to nine digits except the highest one.

**Pattern extraction.** Consecutive permutation values define the up-down string.

```nim
while true:
  let count = nextInt(inputData, scanPos)
  if count == 0:
    break
  var pattern = newSeq[int](count)
  if count >= 1:
    var previousValue = nextInt(inputData, scanPos)
    for position in 1 .. count - 1:
      let currentValue = nextInt(inputData, scanPos)
      if currentValue > previousValue:
        pattern[position - 1] = 1
      previousValue = currentValue
```

A rise stores one and a fall stores zero.
Only adjacent pairs are needed, so full permutation storage is avoided.
A zero size ends the input.

**Rank transition.** Sums of the current row produce the next row.

```nim
  var previousRow = newSeq[seq[int]](count + 1)
  previousRow[1] = @[1]
  var step = 1
  while step < count:
    var prefixSums = newSeq[seq[int]](step + 1)
    var suffixSums = newSeq[seq[int]](step + 2)
    for rank in 1 .. step:
      prefixSums[rank] = prefixSums[rank - 1]
      addBig(prefixSums[rank], previousRow[rank])
    for rank in countdown(step, 1):
      suffixSums[rank] = suffixSums[rank + 1]
      addBig(suffixSums[rank], previousRow[rank])
    var currentRow = newSeq[seq[int]](step + 2)
    for rank in 1 .. step + 1:
      if pattern[step - 1] == 1:
        currentRow[rank] = prefixSums[rank - 1]
      else:
        currentRow[rank] = suffixSums[rank]
    previousRow = currentRow
    step += 1
```

An ascent reads the prefix ending before the new rank.
A descent reads the suffix starting at the new rank.
Each row costs one sweep over at most 100 big integers.

**Answer emission.** The sum of the final row is written once.

```nim
  var answer: seq[int]
  for rank in 1 .. count:
    addBig(answer, previousRow[rank])
  appendOutput(bigToString(answer))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Every last rank contributes disjoint permutations.
The decimal string is added to the output buffer.
The buffer flushes in blocks to reduce write calls.

## Complexity

The table holds one row at a time, and each row is built by two sweeps.

| phase | time | space |
|---|---|---|
| input read | one pass over permutation tokens | one input string |
| rank table | n steps over at most n ranks | two rows of big integers |
| output | one buffered line per case | block buffer |

Each step uses big-integer addition proportional to the answer length.

| measure | Big O |
|---|---|
| time | O(n^2 · D) per case, D = answer digits |
| space | O(n · D) |

Enumerating all n! permutations would be impossible at n = 100. The rank table counts them without listing a single one.
