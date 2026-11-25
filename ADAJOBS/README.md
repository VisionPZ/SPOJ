# ADAJOBS — Ada and Jobs (SPOJ)

<https://www.spoj.com/problems/ADAJOBS/>

## Problem

A todo list accepts new job words and answers whether any stored job is a substring of a question word. Insertions affect only later questions.

The first line gives Q. Each later line holds a type 0 or 1 and one lowercase word. Type 0 inserts the word; type 1 prints YES or NO.

| item | bound |
|---|---|
| queries Q | 1 to 10 to the 6 |
| total word length | 2 times 10 to the 6 |
| word alphabet | lowercase letters |
| judge limit | 2000 ms, 1536 MB |

The total word length drives the design; each query needs one line of output.

Sample input:

```
12
0 cat
1 dogville
0 dog
1 dogville
1 gooutwithcat
1 gooutwithcrocodile
1 fancyconcatenation
0 crocodile
1 lacoste
1 gooutwithcrocodile
1 catalanreferendum
1 rocodile
```

Sample output:

```
NO
YES
YES
NO
YES
NO
YES
YES
NO
```

## Idea

Try each stored job length separately, like testing keys from several rings before opening a door. Hash every inserted job and keep it in a set for its own length. A question word yields a rolling hash for each substring; a set lookup answers that length. Comparing every stored job to every substring costs far more. Hashing by length turns each question into a few short scans.

## Why It Works

1. A stored job matches a question only when their lengths are equal at some substring.
2. `firstHashes` and `secondHashes` give every substring hash by two prefix values.
3. Subtracting the shifted prefix yields a substring hash independent of position.
4. `slotOccupied` marks a hash table that holds one entry per inserted job.
5. Two independent 64 bit hashes make an accidental collision negligible.
6. `activeLengths` skips lengths that have no stored job yet.

| term | meaning |
|---|---|
| `firstHashes` | prefix hashes under `firstBase` |
| `secondHashes` | prefix hashes under `secondBase` |
| `patternPresent` | hash table lookup for one length and two hashes |
| `addPattern` | insertion of one new job hash |
| `activeLengths` | lengths with at least one stored job |

The two hash families protect the lookup against collisions.

A script trace of the first four sample queries:

| query | word | stored jobs before it | answer |
|---|---|---|---|
| insert | cat | none | none |
| ask | dogville | cat | NO |
| insert | dog | cat | none |
| ask | dogville | cat, dog | YES |

The YES appears only after dog is inserted, matching the sample output.

The hash table holds at most one entry per inserted job, not one per substring.

## Code

**Input and word scanner.** The reader loads every query and finds the longest word.

```nim
const flushBlockBytes = 1 shl 17
const firstBase = 1000003
const secondBase = 1000033
const mixingFactor = 11995408973635179863'u64

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fillHashes(word: string, firstHashes: var seq[uint64], secondHashes: var seq[uint64]) =
  firstHashes.setLen(word.len + 1)
  secondHashes.setLen(word.len + 1)
  firstHashes[0] = uint64(0)
  secondHashes[0] = uint64(0)
  for charIndex in 0 .. word.len - 1:
    firstHashes[charIndex + 1] = firstHashes[charIndex] * uint64(firstBase) + uint64(int(word[charIndex]))
    secondHashes[charIndex + 1] = secondHashes[charIndex] * uint64(secondBase) + uint64(int(word[charIndex]))
```

The word scanner stops at whitespace.
Two prefix arrays are filled per question.
Unsigned arithmetic wraps, which gives a hash modulo two to the 64.

**Open addressed table.** Jobs are stored by length and by two hashes.

```nim
proc slotStart(patternLength: int, hashOne: uint64, hashTwo: uint64, slotCount: int): int =
  let mixedValue = hashOne + hashTwo * mixingFactor + uint64(patternLength) * uint64(97)
  return int(mixedValue mod uint64(slotCount))

proc patternPresent(patternLength: int, hashOne: uint64, hashTwo: uint64, slotLengths: seq[int], slotFirsts: seq[uint64], slotSeconds: seq[uint64], slotOccupied: seq[bool]): bool =
  var probeIndex = slotStart(patternLength, hashOne, hashTwo, slotOccupied.len)
  while slotOccupied[probeIndex]:
    if slotLengths[probeIndex] == patternLength and slotFirsts[probeIndex] == hashOne and slotSeconds[probeIndex] == hashTwo:
      return true
    probeIndex = (probeIndex + 1) mod slotOccupied.len
  return false

proc addPattern(patternLength: int, hashOne: uint64, hashTwo: uint64, slotLengths: var seq[int], slotFirsts: var seq[uint64], slotSeconds: var seq[uint64], slotOccupied: var seq[bool]) =
  var probeIndex = slotStart(patternLength, hashOne, hashTwo, slotOccupied.len)
  while slotOccupied[probeIndex]:
    if slotLengths[probeIndex] == patternLength and slotFirsts[probeIndex] == hashOne and slotSeconds[probeIndex] == hashTwo:
      return
    probeIndex = (probeIndex + 1) mod slotOccupied.len
  slotOccupied[probeIndex] = true
  slotLengths[probeIndex] = patternLength
  slotFirsts[probeIndex] = hashOne
  slotSeconds[probeIndex] = hashTwo
```

Linear probing ends when an empty slot is found.
The length is part of the key, so equal hashes of different lengths stay distinct.
Duplicate insertions reuse the same slot.

**Powers and question loop.** Each question scans substrings of the active lengths only.

```nim
let queryCount = nextInt(inputData, scanPos)
var queryKinds = newSeq[int](queryCount)
var queryWords = newSeq[string](queryCount)
var maximumLength = 0
for queryIndex in 0 .. queryCount - 1:
  queryKinds[queryIndex] = nextInt(inputData, scanPos)
  queryWords[queryIndex] = nextWord(inputData, scanPos)
  if queryWords[queryIndex].len > maximumLength:
    maximumLength = queryWords[queryIndex].len

var firstPowers = newSeq[uint64](maximumLength + 1)
var secondPowers = newSeq[uint64](maximumLength + 1)
firstPowers[0] = uint64(1)
secondPowers[0] = uint64(1)
for powerIndex in 1 .. maximumLength:
  firstPowers[powerIndex] = firstPowers[powerIndex - 1] * uint64(firstBase)
  secondPowers[powerIndex] = secondPowers[powerIndex - 1] * uint64(secondBase)

var slotCount = 8
while slotCount < queryCount * 4 + 8:
  slotCount = slotCount * 2
var slotLengths = newSeq[int](slotCount)
var slotFirsts = newSeq[uint64](slotCount)
var slotSeconds = newSeq[uint64](slotCount)
var slotOccupied = newSeq[bool](slotCount)
var activeLengths = newSeq[int](maximumLength + 1)
var firstHashes = newSeq[uint64](1)
var secondHashes = newSeq[uint64](1)
```

The table is sized to hold every insertion.
Power arrays are shared by all words.
The active length list short-circuits empty lengths.

```nim
for queryIndex in 0 .. queryCount - 1:
  let queryWord = queryWords[queryIndex]
  if queryWord.len == 0:
    continue
  fillHashes(queryWord, firstHashes, secondHashes)
  if queryKinds[queryIndex] == 0:
    let wordLength = queryWord.len
    addPattern(wordLength, firstHashes[wordLength], secondHashes[wordLength], slotLengths, slotFirsts, slotSeconds, slotOccupied)
    activeLengths[wordLength] = 1
  else:
    var foundMatch = false
    for patternLength in 1 .. queryWord.len:
      if activeLengths[patternLength] == 0:
        continue
      let substringCount = queryWord.len - patternLength
      for startPos in 0 .. substringCount:
        let hashOne = firstHashes[startPos + patternLength] - firstHashes[startPos] * firstPowers[patternLength]
        let hashTwo = secondHashes[startPos + patternLength] - secondHashes[startPos] * secondPowers[patternLength]
        if patternPresent(patternLength, hashOne, hashTwo, slotLengths, slotFirsts, slotSeconds, slotOccupied):
          foundMatch = true
          break
      if foundMatch:
        break
    if foundMatch:
      appendOutput("YES\n")
    else:
      appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first match ends the search for that question.
Answers go through the block buffer, never one write each.
The last line is flushed once after the loop.

## Complexity

Each question pays one hash scan per active stored length, and the table holds one entry per job.

| phase | time | space |
|---|---|---|
| input read | one pass over all words | one array of words |
| insertion | two prefix evaluations and one table probe | one stored hash |
| question | active lengths times question length | two prefix arrays |
| output | one line per question | block buffer |

A missing length costs a single check.

| measure | Big O |
|---|---|
| time | O(sum of question lengths times active lengths) |
| space | O(total stored jobs plus longest word) |

Checking every job against every substring would take far longer than these table probes.

Grouping jobs by length keeps each question bounded by its own length and the number of active lengths.
