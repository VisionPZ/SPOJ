# KIT — Krypt in Time (SPOJ)

<https://www.spoj.com/problems/KIT/>

## Problem

Encrypt lowercase words by shifting each letter by the next unused number from a pad. The pad supplies one shift per letter, and shifts wrap from z back to a.

Input starts with the pad size, then the pad numbers, which may span several lines. Words follow as whitespace-separated tokens until the token -1. Output one encrypted word per line.

| item | bound |
|---|---|
| pad size N | up to 100 |
| each pad number | 0 to 25 |
| total letters | at most N |
| judge limit | 3000 ms, 1536 MB |

The pad cursor keeps advancing across word boundaries.

Sample input:

```
10
1 2 3 4 5 4 3 2 1 0
aa aaa
zzzzz
-1
```

Sample output:

```
bc
def
dcbaz
```

The word aaa consumes the third, fourth and fifth pad numbers.

## Idea

Treat the pad as a deck of shift cards dealt once per letter, like dealing cards from a shuffled deck until none remain. Read the first N numbers into the deck, then walk the remaining tokens and shift each letter by the next card. One pass over the tokens does all the work, in O(N) time. Restarting the pad for each word would give wrong answers and repeat work. A single cursor makes the order exact.

## Why It Works

1. Token parsing treats spaces and line breaks as the same separator.
2. Reading exactly N numbers separates the pad from the words.
3. The cursor advances once per encrypted letter and never resets.
4. Adding a shift modulo 26 wraps letters past z back to a.
5. The token -1 ends the input and is never encrypted.

The main terms:

| term | meaning |
|---|---|
| `padSize` | number of shifts in the pad |
| `padValues` | shift amounts read from input |
| `padCursor` | index of the next unused shift |
| `nextToken` | reader that returns one whitespace-delimited token |
| `encryptedWord` | output word after shifting |

The cursor is the only state that changes between words.

A script trace of the sample:

```
pad: 1 2 3 4 5 4 3 2 1 0
aa -> bc
aaa -> def
zzzzz -> dcbaz
```

The final word uses shifts 4, 3, 2, 1 and 0 in that order.

## Code

**Input and token readers.** One buffer supplies both numbers and words.

```nim
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

proc isSeparator(character: char): bool =
  return character == ' ' or character == '\n' or character == '\r' or character == '\t'

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and isSeparator(data[pos]):
    pos += 1
  result = ""
  while pos < data.len and not isSeparator(data[pos]):
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The number scanner skips all separators before digits.
The token reader keeps letters and the minus sign together.
Both readers advance the same buffer position.

**Pad setup and encryption.** Each letter takes one shift and advances the cursor.

```nim
let padSize = nextInt(inputData, scanPos)
var padValues = newSeq[int](padSize)
for padIndex in 0 .. padSize - 1:
  padValues[padIndex] = nextInt(inputData, scanPos)
var padCursor = 0
while true:
  let word = nextToken(inputData, scanPos)
  if word.len == 0:
    break
  if word == "-1":
    break
  var encryptedWord = newString(word.len)
  for charIndex in 0 .. word.len - 1:
    let shift = padValues[padCursor]
    padCursor += 1
    let letterCode = int(word[charIndex]) - int('a')
    encryptedWord[charIndex] = chr((letterCode + shift) mod 26 + int('a'))
  appendOutput(encryptedWord)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop stops after exactly padSize numbers.
A missing token and -1 both end the reading loop.
Each encrypted word is written once to the block buffer.

## Complexity

Work is proportional to the pad size plus the letters in the words.

| phase | time | space |
|---|---|---|
| input read | one pass over the buffer | one input string |
| pad setup | one number per pad entry | pad array |
| encryption | one shift per letter | one output word |
| output | one line per word | block buffer |

The pad array is the only size-dependent structure.

| measure | Big O |
|---|---|
| time | O(N + total letters) |
| space | O(N) |

Resetting the pad for each word would repeat work and shift letters incorrectly.
The shared cursor keeps encryption linear in the input size.
