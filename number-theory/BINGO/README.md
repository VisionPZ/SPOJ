# BINGO — Bullshit Bingo (SPOJ)

<https://www.spoj.com/problems/BINGO/>

## Problem

Count the different words heard in each finished game, then print their average as a reduced fraction. A word is a run of letters; every other character separates words.

Input is the lecture text, read to end of file. The text contains BULLSHIT, always in uppercase, and each occurrence ends one game. Words compare without regard to case. Words left over after the last BULLSHIT belong to no finished game. Output is one line with numerator, a space, a slash, a space, and denominator. Reduce first, so no integer above 1 divides both numbers.

The bounds from the statement:

| Item | Bound |
|---|---|
| Completed games | at least 1 |
| Different words per game | at most 500 |
| Word length | at most 25 letters |
| Line length | at most 100 characters |
| Judge limits | 5 s, 1536 MB |

The 500-word cap keeps one game's distinct set small.

The sample input:

```
Programming languages can be classified BULLSHIT into following types:
- imperative and BULLSHIT procedural languages
- functional languages
- logical BULLSHIT programming languages
- object-oriented BULLSHIT languages
```

The sample output:

```
9 / 2
```

## Idea

Count each word once per game, add the four counts, and divide by the number of finished games. Think of crossing names off a list: a name already crossed off gets no second mark.

The program uses an open-addressing hash set. The word `normalizedWord` holds the lowercase spelling. The table `slotGeneration` stamps each slot with the current game, so a new game reuses the table without clearing it. Each word takes one short probe run, and the cost per word is a few comparisons.

Scanning a list for every word costs up to 500 comparisons, because a game can hold 500 distinct words. The hash set keeps the cost near one probe per word.

A small stamped table makes each word cheap and each game independent.

## Why It Works

Four facts carry the result.

1. Every BULLSHIT closes the current game and adds `wordPool.len` to the running sum.
2. Lowercasing first makes `normalizedWord` the same for Bingo and bingo, as the rules demand.
3. `activeGeneration` changes at each game end, so old slots count as empty in the new game.
4. `greatestCommonDivisor` removes the shared factor and leaves a reduced fraction.

The main terms and formulas:

| Term | Meaning |
|---|---|
| `normalizedWord` | the lowercase spelling used for every comparison |
| `wordPool.len` | the distinct word count at a game end |
| `slotGeneration` | the stamp that marks slots live in this game |
| `activeGeneration` | the stamp value of the current game |
| `greatestCommonDivisor` | Euclid's gcd, the common factor to remove |

Each term names a value the driver reads or updates.

A script-traced run over the sample text gives this table:

```
game 1: 5 words -> 5 distinct (be, can, classified, languages, programming)
game 2: 5 words -> 5 distinct (and, following, imperative, into, types)
game 3: 5 words -> 4 distinct (functional, languages, logical, procedural)
game 4: 4 words -> 4 distinct (languages, object, oriented, programming)
sum: 18 distinct over 4 games -> 18 / 4 = 9 / 2
```

The counts 5, 5, 4 and 4 sum to 18, and 18 over 4 reduces to 9 / 2.

## Code

**Shared constants.** Sizes and hash constants used by every game.

```nim
const flushBlockBytes = 1 shl 18
const uppercaseShift = 32
const slotTableSize = 4096
const hashSeed = 5381
const hashBase = 33
const hashMask = 0x7fffffff
```

`slotTableSize` exceeds the 500-word cap, so probing always finds a free slot. `uppercaseShift` is 32, the gap between an uppercase letter and its lowercase form. The mask keeps the hash non-negative before the modulo.

**Token reader.** Splits the input buffer into runs of letters.

```nim
proc isAsciiLetter(character: char): bool =
  result = (character >= 'a' and character <= 'z') or
           (character >= 'A' and character <= 'Z')

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not isAsciiLetter(data[pos]):
    pos += 1
  if pos >= data.len:
    return ""
  let wordStart = pos
  while pos < data.len and isAsciiLetter(data[pos]):
    pos += 1
  return data[wordStart ..< pos]
```

`pos` advances over every byte exactly once, so the scan costs one pass. `isAsciiLetter` rejects digits and punctuation, which the rules call separators. An empty string signals end of input.

**Normalize, hash and insert.** One spelling per word, one slot per distinct word.

```nim
proc normalizeWord(rawWord: string) =
  normalizedWord.setLen 0
  for letter in rawWord:
    if letter >= 'A' and letter <= 'Z':
      normalizedWord.add chr(int(letter) + uppercaseShift)
    else:
      normalizedWord.add letter

proc wordHashKey(word: string): int =
  result = hashSeed
  for letter in word:
    result = (result * hashBase + int(letter)) and hashMask

proc noteDistinctWord(word: string) =
  var slotIndex = wordHashKey(word) mod slotTableSize
  while slotGeneration[slotIndex] == activeGeneration:
    if wordPool[slotWordIndex[slotIndex]] == word:
      return
    slotIndex = (slotIndex + 1) mod slotTableSize
  slotGeneration[slotIndex] = activeGeneration
  slotWordIndex[slotIndex] = wordPool.len
  wordPool.add word
```

`normalizeWord` reuses one buffer, so no string is built for a repeat word. `wordHashKey` scans at most 25 letters. `noteDistinctWord` stops at the first stale slot and appends only new words.

**Fraction reduction.** Removes the common factor and buffers the answer.

```nim
proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var largerValue = firstValue
  var smallerValue = secondValue
  while smallerValue > 0:
    let remainderValue = largerValue mod smallerValue
    largerValue = smallerValue
    smallerValue = remainderValue
  return largerValue

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`greatestCommonDivisor` runs in logarithmic steps. `appendOutput` flushes only after 256 KiB, never per word. A zero divisor cannot occur, since at least one game completes.

**Driver.** Reads the whole stream, closes each game, and writes the fraction.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
while true:
  let rawWord = nextWord(inputData, scanPos)
  if rawWord.len == 0:
    break
  normalizeWord(rawWord)
  if normalizedWord == "bullshit":
    totalDistinctWords += wordPool.len
    completedGameCount += 1
    wordPool.setLen 0
    activeGeneration += 1
  else:
    noteDistinctWord(normalizedWord)

let commonDivisor = greatestCommonDivisor(totalDistinctWords, completedGameCount)
appendOutput($(totalDistinctWords div commonDivisor))
appendOutput(" / ")
appendOutput($(completedGameCount div commonDivisor))
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

`inputData` holds every line, so word boundaries span lines without special cases. The loop ignores words after the last game end. The final write covers the one-line answer.

## Complexity

The phases split into input, per-word work, and one output line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Token scan | one pass over letters and separators | one word slice |
| Distinct insert | a few probes per word | table plus at most 500 words |
| Fraction | one gcd call | two integers |

The table stays fixed because a game holds at most 500 distinct words.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(total input characters) |
| Space | O(distinct words in one game) |

A list-based check costs O(500) comparisons per word. The stamped hash set costs a few probes, so the whole run is linear in the input size.
