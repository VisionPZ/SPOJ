# ALGOUPT09 — Karaokêeeeeeee (SPOJ)

<https://www.spoj.com/problems/ALGOUPT09/>

## Problem

Translate each lyric line with a Japanese-to-Portuguese dictionary and print the result. Words missing from the dictionary stay unchanged.

Input starts with T test cases. Each case starts with M dictionary entries and N lyric lines. Each entry is a Japanese word on one line and its Portuguese translation on the next line. A translation may contain several lowercase words. Each lyric line holds lowercase words separated by single spaces and may be empty. No line exceeds 80 letters.

Output has N translated lines per case, followed by one blank line. The blank line appears after the final case as well.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | not bounded in the statement |
| dictionary words M | 1 to 1000000 |
| lyric lines N | 1 to 1000 |
| line length | at most 80 letters |
| judge limit | 1000 ms, 1536 MB |

The large dictionary bound drives the choice of a hash table.

Sample input:

```
1
4 3
galaxy
cara tossiu
kagayaku
canalha do
atsuki
alto que
yuushi
util
o galaxy
o galaxy
o kagayaku atsuki yuushi
```

The sample maps four Japanese words to Portuguese phrases.

Sample output:

```
o cara tossiu
o cara tossiu
o canalha do alto que util

```

The blank line after the third translated line closes the case.

## Idea

A dictionary is like a label maker: each Japanese word maps to one fixed phrase. Store the pairs in a hash table, then replace each lyric word by its stored phrase.

A linear search through M entries per word would cost O(M) per lookup. Hashing finds each phrase in expected constant time and keeps the whole case near linear.

One table build plus one pass over lyric lines gives the answer.

## Why It Works

1. Each Japanese word appears once per case, so one table slot holds its phrase.
2. Lyric words are separated by single spaces, so a token walk finds exact keys.
3. A key miss leaves the original word in place.
4. A phrase with several words is inserted as one joined string.
5. One blank line after each case matches the output contract.

The main terms:

| term | meaning |
|---|---|
| `wordMap` | hash table from Japanese word to Portuguese phrase |
| `initTable` | creates that table for one case |
| `nextLine` | returns the next input line without its newline |
| `translateLyric` | replaces each word in one lyric line |
| `caseCount` | number of cases to translate |

The table maps each helper to one part of the translation step.

A trace from the generator with visible numbers:

```
dictionary words: 4
lyric lines: 3
lyric words in last line: 4
third output length: 26
blank lines appended: 1
```

The trace shows the four words in the last sample line and the final blank line.

## Code

**Input and helpers.** The driver reads all input, defines the scanner, and buffers output.

```nim
import tables

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
```

The read loop keeps empty lyric lines as consecutive newlines.
The scanner reads only the numeric headers and counts.
The buffer writes once its size reaches `flushBlockBytes`.

**Line reader and translator.** The helpers read whole lines and translate one lyric line.

```nim
proc nextLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  var lineText = ""
  if lineEnd > pos:
    lineText = data.substr(pos, lineEnd - 1)
  pos = lineEnd + 1
  if lineText.len > 0 and lineText[lineText.len - 1] == '\r':
    lineText.setLen(lineText.len - 1)
  return lineText

proc skipLine(data: string, pos: var int) =
  discard nextLine(data, pos)

proc translateLyric(lineText: string, wordMap: Table[string, string]): string =
  if lineText.len == 0:
    return ""
  var translated = ""
  var tokenStart = 0
  while tokenStart < lineText.len:
    var tokenEnd = tokenStart
    while tokenEnd < lineText.len and lineText[tokenEnd] != ' ':
      tokenEnd += 1
    if translated.len > 0:
      translated.add ' '
    let wordToken = lineText.substr(tokenStart, tokenEnd - 1)
    if wordMap.hasKey(wordToken):
      translated.add wordMap[wordToken]
    else:
      translated.add wordToken
    tokenStart = tokenEnd + 1
  return translated
```

The line reader advances past the newline after every line.
The empty-line guard returns an empty translation for a blank lyric.
A table lookup costs expected constant time per word.

**Case loop.** Each case builds a fresh table, then writes the translated lines and a blank line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let wordCount = nextInt(inputData, scanPos)
  let lineCount = nextInt(inputData, scanPos)
  skipLine(inputData, scanPos)
  var wordMap = initTable[string, string]()
  for wordIndex in 0 .. wordCount - 1:
    let japaneseWord = nextLine(inputData, scanPos)
    let portugueseText = nextLine(inputData, scanPos)
    wordMap[japaneseWord] = portugueseText
  for lineIndex in 0 .. lineCount - 1:
    let lyricLine = nextLine(inputData, scanPos)
    appendOutput(translateLyric(lyricLine, wordMap))
    outputBuffer.add '\n'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The header skip consumes the rest of the M and N line.
Each case uses a new table, so keys from other cases cannot leak.
The extra append writes the blank line required after every case.

## Complexity

Dictionary build and lyric translation are the two costs per case.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table build | M insertions | M stored phrases |
| lyric translation | one lookup per lyric word | one output line |
| output | block writes | block buffer |

The table bound M dominates space and build time.

| measure | Big O |
|---|---|
| time | O(L + M + W) per case |
| space | O(L + M) |

L is the input length and W is the total number of lyric words; a linear dictionary scan would cost O(M) per word.

Hashing turns each lookup into one table access, so one pass over the lyrics suffices.
