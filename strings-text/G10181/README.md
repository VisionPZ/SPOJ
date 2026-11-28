# G10181 — Diccionario Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10181/>

## Problem

Turn every word in a text into lowercase and print each distinct word once in alphabetical order. A word is a run of consecutive ASCII letters, so punctuation ends a word.

The input holds at most 5000 lines of at most 200 characters each. Print one lowercase word per line for every distinct word in the text.

| Item | Bound |
|---|---|
| Lines | at most 5000 |
| Characters per line | at most 200 |
| Distinct words | at most 5000 |
| Judge limit | 1000 ms, 1536 MB |

The word count drives the sort; the byte count drives the sweep.

Sample input:

```
los pollitos dicen
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

Fold each letter to lowercase while reading, like dropping mail into boxes, then sort the boxes at the end. A byte sweep builds words with one buffer and collects them into a set. Each byte costs two range checks, and the sort touches only distinct words. Splitting on whitespace first would miss words glued to punctuation. The single sweep settles both case folding and word boundaries.

## Why It Works

1. Uppercase ASCII codes run from 65 to 90, and lowercase codes run from 97 to 122.
2. Adding 32 maps code 65 to 97, so CASA and casa become the same word.
3. Commas, periods, digits, and newlines fail both letter checks and end the current word.
4. Sorting lowercase byte strings gives exactly alphabetical order.
5. After sorting, equal neighbors collapse into one printed word.

The terms used in the sweep:

| Term | Meaning |
|---|---|
| `seenWords` | every completed word collected before sorting |
| `currentWord` | lowercase letters of the word being built |
| `lowercaseShift` | 32, the gap between uppercase and lowercase codes |
| `byteCode` | the numeric code of one input byte |
| `previousWord` | the last word printed, used to skip duplicates |

Each term maps to one stage of the sweep or the final print.

A script-traced example:

```
input text: A a Bb
byte codes: 65, 32, 97, 32, 66, 98
folded words: 65+32=97 -> a; 97 -> a; 66+32=98 -> bb
distinct set: a, bb
sorted output: a, bb
```

The trace shows case folding and dedup in one pass over six bytes.

## Code

**Input and buffered output.** These declarations load all stdin and set up block writes.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const firstUpperValue = 65
const lastUpperValue = 90
const firstLowerValue = 97
const lastLowerValue = 122
const lowercaseShift = 32

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
```

One read loop captures the whole text. The buffer flushes at 131072 bytes.

**Word folding and collection.** This block folds letters and flushes words at each separator.

```nim
proc compareWords(leftWord: string, rightWord: string): int =
  if leftWord < rightWord:
    return -1
  if leftWord > rightWord:
    return 1
  return 0

var seenWords: seq[string] = @[]
var currentWord = ""
for byteCharacter in inputData:
  let byteCode = ord(byteCharacter)
  if byteCode >= firstUpperValue and byteCode <= lastUpperValue:
    currentWord.add chr(byteCode + lowercaseShift)
  elif byteCode >= firstLowerValue and byteCode <= lastLowerValue:
    currentWord.add chr(byteCode)
  else:
    if currentWord.len > 0:
      seenWords.add currentWord
      currentWord.setLen 0
if currentWord.len > 0:
  seenWords.add currentWord
  currentWord.setLen 0
```

The final flush catches a word at end of input. Each byte is visited once.

**Ordering and output.** This block sorts the words, drops repeats, and writes them.

```nim
sort(seenWords, compareWords)

var previousWord = ""
for word in seenWords:
  if word != previousWord:
    appendOutput(word)
    appendOutput("\n")
    previousWord = word

stdout.write outputBuffer
outputBuffer.setLen 0
```

The comparator orders lowercase strings byte by byte. One final write releases any buffered text.

## Complexity

The sweep and the sort dominate the work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input string |
| Word sweep | one check per byte | collected words |
| Sort | one sort of distinct words | word list |
| Output | one line per distinct word | block buffer |

The byte sweep grows with the text, while the sort grows with distinct words.

| Measure | Big O |
|---|---|
| Time | O(N + W log W) |
| Space | O(N) |

Here N is input bytes and W is distinct words. Sorting per line would repeat work, so one global sort wins.
