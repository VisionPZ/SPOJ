# DOCTOR — The Cow Doctor (SPOJ)

<https://www.spoj.com/problems/DOCTOR/>

## Problem

A test material detects a set of diseases, and mixing materials detects the union of their sets. Find how many materials can be dropped while every dropped set remains mixable from the kept ones.

Input holds several cases. Each starts with `n m`, then `m` lines of a count and that many disease numbers. A case with `n = m = 0` ends the input. Output holds one removable count per case.

The bounds from the statement:

| item | bound |
|---|---|
| diseases n | 1 to 300 |
| materials m | 1 to 200 |
| detected diseases per material | 1 to 300 |
| judge limit | 2000 ms, 1536 MB |

Repeated diseases in a material do not change its set, and duplicate materials keep one representative.

Sample input:

```
10 5
2 1 2
2 2 3
3 1 2 3
4 1 2 3 4
1 4
3 7
1 1
1 2 
1 3
2 1 2
2 1 3
2 3 2
3 1 2 3
0 0
```

This figure is the sample input copied from the statement.

Sample output:

```
2
4
```

This figure is the sample output, one count per case.

## Idea

A set can be dropped when every disease in it appears in some smaller kept set.

Think of a recipe shelf: keep every ingredient that no smaller recipe can supply, and all other recipes become redundant.

Encode each material as a bitset and mark the irreducible distinct sets. Each pair of sets costs five word operations.

Trying all subfamilies of materials costs exponential time. The bitset test settles each material in one pass over the others.

## Why It Works

1. Mixing takes the union of detected diseases, never a symmetric difference.
2. A set `S` is mixable from other sets exactly when those sets are subsets of `S` whose union is `S`.
3. If every disease in `S` appears in some proper subset from the list, the union of those subsets equals `S`.
4. If a disease in `S` appears in no proper subset, no mixture of other materials can produce `S`.
5. Keep one copy of each irreducible distinct set, and drop every other material.

The main terms:

| term | meaning |
|---|---|
| `DiseaseSet` | five 64-bit words holding up to 300 diseases |
| `isSubset` | test that one material detects no disease outside another |
| `coveredBySubsets` | union of all proper subsets of one material |
| `irreducibleCount` | number of distinct sets that must stay |

The table names the pieces of the irreducibility test.

A script traced the first sample case:

```
{1,2}: disease 1 has no proper subset -> keep
{2,3}: disease 3 has no proper subset -> keep
{1,2,3}: {1,2} union {2,3} = {1,2,3} -> drop
{1,2,3,4}: {1,2,3} union {4} = {1,2,3,4} -> drop
{4}: disease 4 has no proper subset -> keep
removable = 5 - 3 = 2
```

Two materials drop, which matches the sample answer.

The `identical` check skips copies of the same set, so only one representative can be counted as irreducible. The `not` operator complements a word and exposes diseases outside a candidate subset.

## Code

**Input and scanner.** The reader loads all cases, and the scanner walks integer tokens.

```nim
const flushBlockBytes = 1 shl 17
const wordCount = 5
const bitsPerWord = 64

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
```

Disease numbers become zero-based bits.
Five words cover all 300 diseases.
One output buffer holds every case answer.

**Bitset helpers.** These routines test subsets, equality, and full disease coverage.

```nim
type DiseaseSet = array[wordCount, int64]

proc isSubset(candidate: DiseaseSet, target: DiseaseSet): bool =
  for wordIndex in 0 .. wordCount - 1:
    if (candidate[wordIndex] and not target[wordIndex]) != 0:
      return false
  return true

proc identical(firstSet: DiseaseSet, secondSet: DiseaseSet): bool =
  for wordIndex in 0 .. wordCount - 1:
    if firstSet[wordIndex] != secondSet[wordIndex]:
      return false
  return true

proc coveredBySubsets(materialSets: seq[DiseaseSet], materialIndex: int): bool =
  var covered: DiseaseSet
  for wordIndex in 0 .. wordCount - 1:
    covered[wordIndex] = 0
  for otherIndex in 0 .. materialSets.len - 1:
    if otherIndex == materialIndex or identical(materialSets[otherIndex], materialSets[materialIndex]):
      continue
    if isSubset(materialSets[otherIndex], materialSets[materialIndex]):
      for wordIndex in 0 .. wordCount - 1:
        covered[wordIndex] = covered[wordIndex] or materialSets[otherIndex][wordIndex]
  for wordIndex in 0 .. wordCount - 1:
    if (materialSets[materialIndex][wordIndex] and not covered[wordIndex]) != 0:
      return false
  return true
```

Subset tests run one word at a time.
The coverage union skips identical sets.
A missing disease makes the material irreducible.

**Case driver.** The driver builds bitsets, counts irreducible sets, and writes the answer.

```nim
while true:
  let diseaseCount = nextInt(inputData, scanPos)
  let materialCount = nextInt(inputData, scanPos)
  if diseaseCount == 0 and materialCount == 0:
    break
  var materialSets = newSeq[DiseaseSet](materialCount)
  for materialIndex in 0 .. materialCount - 1:
    for wordIndex in 0 .. wordCount - 1:
      materialSets[materialIndex][wordIndex] = 0
    let detectedCount = nextInt(inputData, scanPos)
    for detectedIndex in 0 .. detectedCount - 1:
      let diseaseIndex = nextInt(inputData, scanPos) - 1
      let wordIndex = diseaseIndex div bitsPerWord
      let bitIndex = diseaseIndex mod bitsPerWord
      materialSets[materialIndex][wordIndex] = materialSets[materialIndex][wordIndex] or
        (int64(1) shl bitIndex)

  var irreducibleCount = 0
  for materialIndex in 0 .. materialCount - 1:
    var earlierTwin = false
    for otherIndex in 0 .. materialIndex - 1:
      if identical(materialSets[otherIndex], materialSets[materialIndex]):
        earlierTwin = true
        break
    if not earlierTwin and not coveredBySubsets(materialSets, materialIndex):
      irreducibleCount += 1
  appendOutput($(materialCount - irreducibleCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each bit index is set once while reading.
Earlier twins mark later copies as removable.
The answer subtracts kept representatives from all materials.

## Complexity

Each case compares every material with every other material using five machine words.

The cost breakdown by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over disease lists | one input string |
| bitset build | O(m) materials times list size | 5 words per material |
| irreducibility | O(m^2) comparisons | one coverage bitset |
| output | one line per case | block buffer |

The pairwise comparison phase dominates both reading and writing.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(m^2) per case |
| space | O(m) |

Enumerating all subfamilies of materials takes exponential time, while the bitset test needs one pass per pair.
