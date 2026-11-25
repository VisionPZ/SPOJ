<https://www.spoj.com/problems/G10_2/>

## Problem

Tavas has a score from 0 to 99 and a keyboard without digits. He must send the score as an English cardinal number. Output lowercase letters and hyphens only, with no spaces.

| item | bound |
|---|---|
| score s | 0 to 99 |
| judge limit | 12000 ms, 1536 MB |

Values from 21 to 99 join a decade word and a unit word with one hyphen.

Sample input:

```
6
```

Sample output:

```
six
```

Other examples from the statement:

```
99
```

```
ninety-nine
```

```
20
```

```
twenty
```

## Idea

Two short word lists cover every score, like a recipe with two ingredient shelves. Numbers below twenty use one list directly. Higher numbers combine a decade word, a hyphen, and a unit word.

## Why It Works

1. The values 0 through 19 have unique single words.
2. Multiples of ten from 20 to 90 have unique decade words.
3. Other values join the decade word, a hyphen, and the unit word.
4. Integer division extracts the decade digit and modulo extracts the unit digit.
5. Scanning all tokens keeps the program correct if extra numbers appear.

| term | meaning |
|---|---|
| `smallWords` | words for the values 0 through 19 |
| `decadeWords` | words for tens from 20 to 90 |
| `spellScore` | converts one score into its word |
| `hasMoreScore` | tests whether another number remains in the input |

A direct lookup table avoids long chains of conditional statements.

## Code

**Word lists and spelling.** Two constant arrays and a short conversion procedure.

```nim
const flushBlockBytes = 1 shl 17
const smallWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const decadeWords = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

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

proc spellScore(value: int): string =
  if value < 20:
    return smallWords[value]
  let decade = value div 10
  let unit = value mod 10
  if unit == 0:
    return decadeWords[decade]
  return decadeWords[decade] & "-" & smallWords[unit]

proc hasMoreScore(data: string, pos: int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  return probe < data.len
```

Forty and ninety use their stated spellings.
Only values above nineteen need a hyphen.
The probe advances past non-digit characters safely.

**Output loop.** Every parsed score becomes one line of text.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreScore(inputData, scanPos):
  let score = nextInt(inputData, scanPos)
  appendOutput(spellScore(score))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop ends when no further digit is found.
One newline follows each spelled score.
The buffer flushes in blocks of 128 KiB.

## Complexity

Each score spends constant work in the converter.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| spelling | constant work per score | two constant word lists |
| output | one write per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(1) per score |
| space | O(1) besides the input buffer |

A long chain of explicit cases is slower to write and easier to misspell.

