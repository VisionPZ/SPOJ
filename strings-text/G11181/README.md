# G11181 — El Diccionario Grado 11 (SPOJ)

<https://www.spoj.com/problems/G11181/>

## Problem

List every distinct word in an input text, lowercased and in alphabetical order. A word is a consecutive run of ASCII letters, so a change of case does not create a new entry.

The input is plain text of at most 5000 lines, with at most 200 characters per line. The output puts one distinct lowercase word per line.

The bounds stated in the problem:

| item | bound |
|---|---|
| input lines | at most 5000 |
| characters per line | at most 200 |
| distinct words | at most 5000 |
| judge limit | 1000 ms, 1536 MB |

The distinct word count keeps the sorted list compact.

Sample input:

```
los pollitos dicen,
pio, PIO,pIo,
cuando tienen hambre.
cuando tiEnen frio,
La gallina busca,
el maiz y el trigo,
les da la comida,
y les presta abrigo
```

Sample output:

```
abrigo
busca
comida
cuando
da
dicen
el
frio
gallina
hambre
la
les
los
maiz
pio
pollitos
presta
tienen
trigo
y
```

## Idea

Sort the words like cards dealt into alphabetical piles, then keep the first card of each matching group. A hand scanner extracts runs of letters and folds uppercase to lowercase as it goes. Sorting groups equal words into adjacent positions, so one pass emits each distinct word. Searching a growing list for every new word would cost far more than one sort. Collect, sort, then drop adjacent duplicates.

## Why It Works

1. A word starts at the first letter after a non-letter and ends at the next non-letter.
2. Folding uppercase to lowercase makes different spellings of one word match.
3. Sorting places equal words in consecutive positions.
4. Comparing each word with its predecessor removes duplicates in one scan.
5. Byte-wise string order gives alphabetical order for lowercase words.

The names below hold the word list and its ordering:

| term | meaning |
|---|---|
| `inputData` | all input lines joined into one string |
| `distinctWords` | lowercased word tokens before deduplication |
| `compareWords` | ordering passed to the sort |
| `wordIndex` | position in the sorted list during output |

These values carry each token from raw text to sorted output.

A script trace from the generator:

```
raw word tokens: 28
distinct: 20
first five sorted: ['abrigo', 'busca', 'comida', 'cuando', 'da']
duplicates removed: ['cuando', 'cuando', 'el', 'el', 'la', 'la', 'les', 'les', 'pio', 'pio', 'pio', 'tienen', 'tienen', 'y', 'y']
```

The 28 tokens collapse to 20 distinct words, listed one per line.

## Code

**Input and helpers.** The reader loads the text and defines letter handling and ordering.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc isLetter(character: char): bool =
  return (character >= 'a' and character <= 'z') or (character >= 'A' and character <= 'Z')

proc compareWords(leftWord: string, rightWord: string): int =
  if leftWord < rightWord:
    return -1
  if leftWord > rightWord:
    return 1
  return 0
```

The loop joins every line with a newline.
The letter test accepts upper and lower ASCII letters.
The comparator gives plain lexicographic order.

**Word extraction.** The scanner folds each letter run into a lowercase token.

```nim
var distinctWords = newSeq[string](0)
var scanPos = 0
while scanPos < inputData.len:
  if isLetter(inputData[scanPos]):
    var loweredWord = ""
    while scanPos < inputData.len:
      var character = inputData[scanPos]
      if character >= 'A' and character <= 'Z':
        character = chr(ord(character) + 32)
      if not isLetter(character):
        break
      loweredWord.add character
      scanPos += 1
    distinctWords.add loweredWord
  else:
    scanPos += 1
```

The scanner skips punctuation and whitespace.
Uppercase letters shift into lowercase before storage.
Each word appends once to the growing list.

**Sort and emit.** Sorting groups duplicates, and one scan prints each group once.

```nim
distinctWords.sort(compareWords)
var wordIndex = 0
while wordIndex < distinctWords.len:
  if wordIndex > 0 and distinctWords[wordIndex] == distinctWords[wordIndex - 1]:
    wordIndex += 1
    continue
  appendOutput(distinctWords[wordIndex])
  appendOutput("\n")
  wordIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The sort groups equal words into adjacent slots.
A word matching its predecessor is skipped.
The final write drains the remaining buffer.

## Complexity

Let w be the number of extracted word tokens and d the number of distinct words.

| phase | time | space |
|---|---|---|
| input read | one pass over the text | one input string |
| word extraction | one append per token | list of w words |
| sort and output | sort w words, emit d lines | block buffer |

The sort dominates the run, while output grows with the distinct count.

| measure | Big O |
|---|---|
| time | O(w log w) for the sort |
| space | O(w) for the word list |

Checking each new word against all earlier words would cost O(w squared) before any sorting.
