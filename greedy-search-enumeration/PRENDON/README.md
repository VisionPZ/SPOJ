# PRENDON — Prendonians (SPOJ)
<https://www.spoj.com/problems/PRENDON/>

## Problem

Each three-word record gives a person's own name, gender, and two parents. Decide whether all records form one connected family tree that obeys the marriage rules.

Input starts with T. Each case starts with N, then N lines of three lowercase words. The suffix `jk` marks a male child and `gvw` marks a female child; both parent words carry that suffix. Output `YES` or `NO` for each case.

| item | bound |
|---|---|
| cases T | 1 to 30 |
| people N | 1 to 1000 |
| word length | up to 1000 characters |
| judge limit | 100 ms, 1536 MB |

The first word of each record is unique. A parent may be named without having a record of their own.

Sample input:

```
1
3
docs afegvw fegvw
draw rridajk cajk
pito docsjk drawjk
```

Sample output:

```
YES
```

## Idea

Treat each record like a card in a genealogy box, then check the family rules while sorting the cards.

The algorithm strips each suffix to recover parents and gender. It stores partners in a hash table, builds parent-to-child links for a cycle check, and uses union-find to test relatedness. Sibling marriages are caught by comparing sorted parent pairs.

Checking every pair of people would cost O(N^2) per case. Hashing and linear scans keep each case near O(N), which fits the tight limit.

Stop as soon as any rule fails, because later checks need no work.

## Why It Works

1. Both parent words must share one suffix, and the remaining names must be nonempty and different.
2. Each parent has one partner, recorded by the children they share.
3. Two known males cannot form a couple.
4. Siblings share the same parent pair, so equal parent pairs forbid a marriage.
5. A cycle in parent-to-child links would make someone an ancestor of themselves.
6. Union-find on every name in any record proves that all listed people are related.

| term | meaning |
|---|---|
| `extractedParent` | parent name after removing the gender suffix |
| `partnerOf` | maps each person to their single partner |
| `childLinks` | parent-to-child edges for cycle detection |
| `unionParent` | union-find parents over all names seen |

Unlisted parents still receive an id, since two records can share such a parent and become related through them.

For the sample, docs is female with parents afe and fe. Draw is male with parents rrida and ca. Pito is male with parents docs and draw.

| check | result |
|---|---|
| suffixes on all three records | consistent |
| couple docs and draw | female and male |
| partner sets | docs paired only with draw |
| parent cycle | none |
| relatedness | docs, draw, pito share one component |

All rules hold, so the answer is `YES`.

Cycle detection uses colors 0, 1, and 2. A link to a gray node marks a cycle. Union-find ids are set to themselves when created, which keeps component roots valid.

## Code

**Input and helpers.** The reader loads words, and the suffix helper recovers each parent name.

```nim
import tables

const flushBlockBytes = 1 shl 17
const maleGender = 1
const femaleGender = 2
const noGender = 0

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

proc isLowerLetter(character: char): bool =
  return character >= 'a' and character <= 'z'

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not isLowerLetter(data[pos]):
    pos += 1
  var word = ""
  while pos < data.len and isLowerLetter(data[pos]):
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc extractedParent(word: string, suffixLength: var int): string =
  if word.len >= 2 and word[word.len - 2] == 'j' and word[word.len - 1] == 'k':
    suffixLength = 2
    return word[0 .. word.len - 3]
  if word.len >= 3 and word[word.len - 3] == 'g' and word[word.len - 2] == 'v' and word[word.len - 1] == 'w':
    suffixLength = 3
    return word[0 .. word.len - 4]
  suffixLength = 0
  return ""
```

The word reader accepts lowercase letters only.
The suffix length tells the gender of the child.
A zero suffix length marks an invalid record.

**Graph helpers.** A depth-first pass finds cycles, and union-find tracks relatedness.

```nim
var childLinks: seq[seq[int]]
var visitColors: seq[int]

proc hasParentCycle(node: int): bool =
  visitColors[node] = 1
  for childNode in childLinks[node]:
    if visitColors[childNode] == 1:
      return true
    if visitColors[childNode] == 0 and hasParentCycle(childNode):
      return true
  visitColors[node] = 2
  return false

var allNames = initTable[string, int]()
var allNameCount = 0
var unionParent: seq[int]

proc getNameId(name: string): int =
  if not allNames.hasKey(name):
    allNames[name] = allNameCount
    unionParent[allNameCount] = allNameCount
    allNameCount += 1
  return allNames[name]

proc findRoot(node: int): int =
  var current = node
  while unionParent[current] != current:
    current = unionParent[current]
  return current

proc uniteNames(firstNode: int, secondNode: int) =
  let firstRoot = findRoot(firstNode)
  let secondRoot = findRoot(secondNode)
  if firstRoot != secondRoot:
    unionParent[secondRoot] = firstRoot
```

A gray node revisited during traversal closes a cycle.
Every new name starts as its own component root.
Uniting a child with both parents links whole families.

**Record checks.** Each record yields parents, gender, and a partner entry.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  var ownNames = newSeq[string](personCount)
  var firstParents = newSeq[string](personCount)
  var secondParents = newSeq[string](personCount)
  var genders = newSeq[int](personCount)
  var nameToIndex = initTable[string, int]()
  var isValid = true
  for personIndex in 0 .. personCount - 1:
    ownNames[personIndex] = nextWord(inputData, scanPos)
    let firstWord = nextWord(inputData, scanPos)
    let secondWord = nextWord(inputData, scanPos)
    var firstSuffixLength = 0
    var secondSuffixLength = 0
    firstParents[personIndex] = extractedParent(firstWord, firstSuffixLength)
    secondParents[personIndex] = extractedParent(secondWord, secondSuffixLength)
    if firstSuffixLength == 0 or secondSuffixLength == 0 or firstSuffixLength != secondSuffixLength:
      isValid = false
    if firstParents[personIndex].len == 0 or secondParents[personIndex].len == 0:
      isValid = false
    if firstParents[personIndex] == secondParents[personIndex]:
      isValid = false
    if firstSuffixLength == 2:
      genders[personIndex] = maleGender
    else:
      genders[personIndex] = femaleGender
    nameToIndex[ownNames[personIndex]] = personIndex
  var partnerOf = initTable[string, string]()
  if isValid:
    for personIndex in 0 .. personCount - 1:
      let firstParent = firstParents[personIndex]
      let secondParent = secondParents[personIndex]
      if partnerOf.hasKey(firstParent) and partnerOf[firstParent] != secondParent:
        isValid = false
        break
      if partnerOf.hasKey(secondParent) and partnerOf[secondParent] != firstParent:
        isValid = false
        break
      partnerOf[firstParent] = secondParent
      partnerOf[secondParent] = firstParent
      var firstGender = noGender
      var secondGender = noGender
      if nameToIndex.hasKey(firstParent):
        firstGender = genders[nameToIndex[firstParent]]
      if nameToIndex.hasKey(secondParent):
        secondGender = genders[nameToIndex[secondParent]]
      if firstGender == maleGender and secondGender == maleGender:
        isValid = false
        break
  if isValid:
    for personIndex in 0 .. personCount - 1:
      let firstParent = firstParents[personIndex]
      let secondParent = secondParents[personIndex]
      var firstKey = ""
      var secondKey = ""
      if nameToIndex.hasKey(firstParent):
        let parentIndex = nameToIndex[firstParent]
        var leftParent = firstParents[parentIndex]
        var rightParent = secondParents[parentIndex]
        if leftParent > rightParent:
          swap leftParent, rightParent
        firstKey = leftParent & "|" & rightParent
      if nameToIndex.hasKey(secondParent):
        let parentIndex = nameToIndex[secondParent]
        var leftParent = firstParents[parentIndex]
        var rightParent = secondParents[parentIndex]
        if leftParent > rightParent:
          swap leftParent, rightParent
        secondKey = leftParent & "|" & rightParent
      if firstKey != "" and firstKey == secondKey:
        isValid = false
        break
```

Both parent words must carry the same suffix.
A partner table rejects a second spouse.
Equal sorted parent pairs reveal a sibling marriage.

**Tree checks and answer.** Cycles and disconnection finish the validation.

```nim
  if isValid:
    childLinks = newSeq[seq[int]](personCount)
    for personIndex in 0 .. personCount - 1:
      let firstParent = firstParents[personIndex]
      let secondParent = secondParents[personIndex]
      if nameToIndex.hasKey(firstParent):
        childLinks[nameToIndex[firstParent]].add personIndex
      if nameToIndex.hasKey(secondParent):
        childLinks[nameToIndex[secondParent]].add personIndex
    visitColors = newSeq[int](personCount)
    for personIndex in 0 .. personCount - 1:
      if visitColors[personIndex] == 0 and hasParentCycle(personIndex):
        isValid = false
        break
  if isValid:
    allNames = initTable[string, int]()
    allNameCount = 0
    unionParent = newSeq[int](3 * personCount + 2)
    for personIndex in 0 .. personCount - 1:
      let childId = getNameId(ownNames[personIndex])
      let firstId = getNameId(firstParents[personIndex])
      let secondId = getNameId(secondParents[personIndex])
      uniteNames(childId, firstId)
      uniteNames(childId, secondId)
    let baseRoot = findRoot(getNameId(ownNames[0]))
    for personIndex in 1 .. personCount - 1:
      if findRoot(getNameId(ownNames[personIndex])) != baseRoot:
        isValid = false
        break
  if isValid:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Only listed parents create edges, since unlisted names have no records.
Every listed person must share one component root.
One line per case reports the verdict.

## Complexity

Hashing gives expected constant-time name lookups, and each person contributes two parent links.

| phase | time | space |
|---|---|---|
| parse records | O(total word length) | arrays of N strings |
| partner and sibling checks | O(N) | hash tables of N entries |
| cycle detection | O(N) | adjacency of 2N links |
| relatedness | O(N) | union-find over at most 3N names |
| output | one line per case | block buffer |

At most 3N distinct names appear, counting both parents of every listed person.

| measure | Big O |
|---|---|
| time per case | O(total word length + N) |
| space per case | O(N + total word length) |

Pairwise relationship checks would cost O(N^2) and waste the tight limit.

Hash tables and linear graph passes keep validation fast for every case.
