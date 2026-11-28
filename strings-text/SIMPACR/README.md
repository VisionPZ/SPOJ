# SIMPACR — Creating simple acronyms (SPOJ)

<https://www.spoj.com/problems/SIMPACR/>

## Problem

Build an organisation acronym from the first letters of its title words. Skip connective words such as a, in, of, and the, then print the remaining initials in capitals.

Input: first line N, the number of words, with N under 100. Each of the next N lines holds one word, possibly capitalised and possibly carrying trailing spaces. Output: one line holding the acronym in uppercase.

| item | bound |
|---|---|
| word count N | less than 100 |
| words | one per line, trailing spaces possible |
| ignored words | a, in, is, on, of, and, the, for |
| judge limit | 1000 ms, 1536 MB |

Trim surrounding spaces before the ignore test, so a padded connective word stays ignored.

The sample input:

```
5
the
ministry
of
silly
walks
```

The sample output:

```
MSW
```

## Idea

Treat each word as a ticket at a gate, like guests whose names are on a skip list. Trim the ticket, lower it before checking the list, then take its first character. This is a linear scan over the N words with at most eight string comparisons each. Comparing raw lines with trailing spaces misses connectives that should be skipped. Trim once, compare, then capitalise the first character.

## Why It Works

1. Every input line is one word, including any trailing spaces.
2. Surrounding spaces do not belong to the word and are removed first.
3. Ignoring compares the lowered trimmed word, so the list is case-insensitive.
4. A padded connective such as "the " now matches the listed word and is skipped.
5. Only a kept word contributes its first character, uppercased.

| term | meaning |
|---|---|
| `wordCount` | number of words in the title |
| `nextRawLine` | reader that returns one whole line |
| `trimmedWord` | word with surrounding spaces removed |
| `ignoredWords` | the eight connective words |
| `loweredWord` | case-folded copy used for the ignore test |

The raw line, the trimmed word, and the lowered copy serve three steps.

A trace from the generator with visible words:

```
the      -> trimmed the      ignored      -> nothing
ministry -> trimmed ministry kept         -> M
of       -> trimmed of       ignored      -> nothing
silly    -> trimmed silly    kept         -> S
walks    -> trimmed walks    kept         -> W
```

The kept initials spell MSW, which matches the sample.

## Code

**Input and helpers.** The reader returns whole lines and the trimmer removes padding.

```nim
const flushBlockBytes = 1 shl 17
const ignoredWords = ["a", "in", "is", "on", "of", "and", "the", "for"]

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

proc nextRawLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  let rawText = data[pos .. lineEnd - 1]
  pos = lineEnd + 1
  return rawText

proc trimmedWord(rawWord: string): string =
  var firstIndex = 0
  var lastIndex = rawWord.len - 1
  while firstIndex <= lastIndex and rawWord[firstIndex] == ' ':
    firstIndex += 1
  while lastIndex >= firstIndex and rawWord[lastIndex] == ' ':
    lastIndex -= 1
  if firstIndex > lastIndex:
    return ""
  return rawWord[firstIndex .. lastIndex]

proc loweredCharacter(letter: char): char =
  if letter >= 'A' and letter <= 'Z':
    return chr(int(letter) + 32)
  return letter

proc upperCharacter(letter: char): char =
  if letter >= 'a' and letter <= 'z':
    return chr(int(letter) - 32)
  return letter
```

The count uses the hand scanner, and the rest of its line is discarded.
Trimming happens on the raw line before any comparison.
Both case helpers work on ASCII letters without locale rules.

**Buffered acronym loop.** Each word is trimmed, lowered, tested, then reduced to one initial.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let wordCount = nextInt(inputData, scanPos)
discard nextRawLine(inputData, scanPos)
for wordIndex in 0 .. wordCount - 1:
  let rawWord = nextRawLine(inputData, scanPos)
  let wordText = trimmedWord(rawWord)
  var loweredWord = ""
  for letterIndex in 0 .. wordText.len - 1:
    loweredWord.add loweredCharacter(wordText[letterIndex])
  var ignored = false
  for ignoredWord in ignoredWords:
    if loweredWord == ignoredWord:
      ignored = true
  if not ignored and wordText.len > 0:
    appendOutput($upperCharacter(wordText[0]))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first character comes from the trimmed word, never from padding.
An all-space word has a trimmed length of zero and adds nothing.
One buffered write emits the whole acronym after the loop.

## Complexity

Work grows with the number of words and their lengths.

| phase | time | space |
|---|---|---|
| input read | one pass over all input characters | one input string |
| ignore test | up to eight comparisons per word | one lowered copy per word |
| output | one line | block buffer |

The ignore list is fixed, so each word takes constant comparisons.

| measure | Big O |
|---|---|
| time | O(total input characters) |
| space | O(longest word) |

Scanning a joined title and splitting it again adds work without changing the answer; the direct line scan avoids that extra pass.
