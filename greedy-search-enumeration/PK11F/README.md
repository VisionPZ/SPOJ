# PK11F — Spelling Suggestion (SPOJ)

<https://www.spoj.com/problems/PK11F/>

## Problem

For each query word, find the smallest weighted edit distance to any dictionary word and list every dictionary word that reaches that distance. Substitution costs one for listed keyboard neighbors and two otherwise; insertion, deletion, and adjacent transposition cost two.

Input has three parts separated by blank lines: near-substitution rules, dictionary words, and query words. Each rule gives one character followed by its near substitutes. Print word:distance:matches per query, with matches sorted in ascending order and separated by one space.

| item | bound |
|---|---|
| near rules | up to 150 |
| dictionary words | up to 150000 |
| query words | up to 5000 |
| word length | under 100 characters |
| judge limit | 12880 ms, 1536 MB |

The dictionary and query counts make repeated full scans costly, so each comparison needs a tight bound.

Sample input:

```
a AqQsSzZ
b BgGvVnN
p P0);:oO[{
r R4$fFeEtT
z ZaAxX

a
A
b
B
Z
angel
angle
anger
angry
ABC

x
s
z
xx
xxx
angre
angri
angrt
angel
ACB
BAC
CAB
```

Sample output:

```
x:2:A B Z a b
s:1:a
z:1:A Z a
xx:4:A B Z a b
xxx:6:A ABC B Z a b
angre:2:anger angle angry
angri:2:angry
angrt:2:anger angry
angel:0:angel
ACB:2:ABC
BAC:2:ABC
CAB:4:A ABC B
```

## Idea

Skip words that cannot win before doing any real work, like ignoring books whose title length is wrong. Each insertion or deletion changes length by one and costs two, so length difference alone gives a lower bound. Once one good match is found, that bound and a narrow DP band cut most comparisons.

The algorithm runs two passes: one to find the best distance, one to collect all words at that distance. A full matrix DP computes every comparison in the oracle; the solution computes only a band around the diagonal and stops a row early when all values exceed the cap.

The second pass guarantees a complete sorted list of suggestions.

## Why It Works

1. Each rule is symmetric, so a near substitution costs one in either direction.
2. A word pair with length difference `d` needs at least 2*d insertion or deletion cost.
3. A path with total cost at most `cap` never leaves the band where column minus row exceeds `cap`.
4. Every DP entry increases along a path, so a row whose minimum exceeds `cap` cannot lead to a better answer.
5. The first pass fixes the true minimum, and the second pass collects exactly the words matching it.

| term | meaning |
|---|---|
| `nearSubstitution` | symmetric table of one-cost character pairs |
| `wordsByLength` | dictionary indices grouped by word length |
| `editDistance` | banded distance, capped at the current best |
| `bestDistance` | smallest distance found for the current query |

Length buckets are visited nearest first, so a small cap arrives early.

The sample query angrt reaches anger by substituting `r` with `e` and `t` with `r`. Both pairs are near substitutions, so the total is 2.

```
angrt -> anger: two near substitutions -> distance 2
angrt -> angry: one far substitution -> distance 2
matches -> anger angry
```

The trace matches the sample line for angrt.

## Code

**Reading and trimming.** Lines keep punctuation, and blank lines split the three sections.

```nim
const flushBlockBytes = 1 shl 17
const maximumCharacters = 160
const unreachableCost = 1000000
```

`nextLine` preserves empty lines as section markers.

`trimmed` removes edge spaces without touching word contents.

**Rules and dictionary.** Near pairs are stored in both directions.

```nim
var lineIndex = 0
while lineIndex < textLines.len and trimmed(textLines[lineIndex]) != "":
  let ruleText = trimmed(textLines[lineIndex])
  let ruleCharacter = int(ruleText[0])
  var fieldIndex = 1
  while fieldIndex < ruleText.len and ruleText[fieldIndex] <= ' ':
    fieldIndex += 1
  while fieldIndex < ruleText.len:
    let pairedCharacter = int(ruleText[fieldIndex])
    nearSubstitution[ruleCharacter][pairedCharacter] = true
    nearSubstitution[pairedCharacter][ruleCharacter] = true
    fieldIndex += 1
  lineIndex += 1
```

Dictionary words are grouped by length.

Queries are all remaining non-empty lines.

**Cost model.** Equal characters cost zero, near pairs cost one, and all others cost two.

```nim
proc substitutionCost(firstCharacter: char, secondCharacter: char): int =
  let firstCode = int(firstCharacter)
  let secondCode = int(secondCharacter)
  if firstCode == secondCode:
    return 0
  if nearSubstitution[firstCode][secondCode]:
    return 1
  return 2
```

Byte codes cover punctuation as well as letters.

The table lookup is constant time.

**Banded DP.** Three rows hold the diagonal offsets needed by transposition.

```nim
  var olderRow = newSeq[int](targetLength + 1)
  var previousRow = newSeq[int](targetLength + 1)
  var currentRow = newSeq[int](targetLength + 1)
  for columnIndex in 0 .. targetLength:
    if columnIndex <= bandWidth:
      previousRow[columnIndex] = 2 * columnIndex
    else:
      previousRow[columnIndex] = unreachableCost
```

Cells outside the band hold a large sentinel.

The length bound rejects hopeless pairs before allocation.

```nim
      if sourceIndex >= 2 and columnIndex >= 2 and
         sourceWord[sourceIndex - 1] == targetWord[columnIndex - 2] and
         sourceWord[sourceIndex - 2] == targetWord[columnIndex - 1]:
        let swapValue = olderRow[columnIndex - 2] + 2
        if swapValue < bestValue:
          bestValue = swapValue
      currentRow[columnIndex] = bestValue
```

A transposition reads two rows back.

Early abort fires when the row minimum exceeds the cap.

**Two passes.** The first pass finds the distance, and the second pass builds the sorted list.

```nim
  var bestMatches = newSeq[string]()
  for wordLength in candidateLengths:
    if 2 * abs(wordLength - queryWord.len) > bestDistance:
      break
    for wordIndex in wordsByLength[wordLength]:
      let candidateDistance = editDistance(queryWord, dictionaryWords[wordIndex], bestDistance)
      if candidateDistance == bestDistance:
        bestMatches.add dictionaryWords[wordIndex]
  insertionSort(bestMatches)
```

Length buckets stop once the lower bound passes the best distance.

Insertion sort gives the required ascending order.

## Complexity

Length buckets and the DP band reduce the work per dictionary word.

| phase | time | space |
|---|---|---|
| input read | one pass over all sections | input string and lines |
| rule setup | one constant-time mark per near pair | character table |
| comparison | band width times word length | three DP rows |
| output | one line per query | block buffer |

The number of surviving comparisons drives the total running time.

| measure | Big O |
|---|---|
| time | O(Q * W * L * B) |
| space | O(D + L) |

Q is the query count, W the compared words, L the word length, B the band width, and D the dictionary size.

A full matrix for every pair pays L squared per word, while the band and length bound skip most pairs entirely.
