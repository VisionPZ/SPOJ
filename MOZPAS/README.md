# MOZPAS — Prangon and String (SPOJ)

<https://www.spoj.com/problems/MOZPAS/>

## Problem

Build the lexicographically smallest string of length n made only of lowercase English letters, where no letter may appear more than m times.

Input holds two integers, n and m. Output holds the string, then a newline.

| Item | Bound |
|---|---|
| String length | 1 ≤ n ≤ 100000 |
| Letter quota | 1 ≤ m ≤ 100000 |
| Feasibility | m × 26 ≥ n |
| Judge limit | 1000 ms, 1536 MB |

One pass over the n positions is enough.

The sample case:

```
5 1
```

```
abcde
```

## Idea

Line the letters up in alphabetical order: m copies of 'a', then m copies of 'b', and so on, stopping when the string is full. Think of stacking identical letter tiles in rows, 'a' row first, then 'b'. Position i then falls in row `i div m`, so its letter is `i div m` steps down the alphabet. That costs one division per position. Trying every letter at every position costs 26^n strings.

## Why It Works

1. Sorting any valid string alphabetically keeps all letter counts, so it stays valid, and a sorted string is never larger than the unsorted one. The answer is therefore a sorted string.
2. A sorted string is fully decided by how many copies of each letter it holds.
3. To be smallest, hold as many 'a' as possible: `min(m, n)`. Then fill the rest with as many 'b' as possible, and so on.
4. Greedy never gets stuck. After k letters are placed, the free quota left is `26 × m - k`, which is at least `n - k` because `26 × m ≥ n`.
5. The first m positions get letter 0, the next m get letter 1, so position i gets letter `i div m`. The `mod 26` is only a safety wrap: `26 × m ≥ n` keeps `i div m` below 26.

| Term | Meaning |
|---|---|
| `stringLength` | n, the length to build |
| `letterLimit` | m, the most copies of one letter |
| `letterIndex` | which letter goes at this position, 0 for 'a' |
| `letterCount` | 26, the size of the alphabet |
| `firstLetterCode` | 97, the code of 'a' |

The written string is the answer.

A script-traced example from `gen.py`:

```
n 5 m 1
letter quotas taken 1 1 1 1 1
answer abcde
```

The trace matches the sample answer. For n = 7 and m = 3 the same quotas give `aaabbbc`.

## Code

**Input and hand scanner.** This block loads stdin and reads the two integers.

```nim
const firstDigitValue = 48
const firstLetterCode = 97
const letterCount = 26
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects all input bytes.
The scanner skips spaces and newlines without special handling.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block collects letters and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(character: char) =
  outputBuffer.add character
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Build loop.** This block writes one letter per position.

```nim
let stringLength = nextInt(inputData, scanPos)
let letterLimit = nextInt(inputData, scanPos)

for positionIndex in 0..<stringLength:
  let letterIndex = (positionIndex div letterLimit) mod letterCount
  appendOutput(chr(firstLetterCode + letterIndex))
appendOutput('\n')

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly n times, one integer division per position.
`div letterLimit` picks the row, `mod letterCount` keeps the letter inside the alphabet.
The newline is appended after the last letter.

## Complexity

The cost splits into input, one division per position, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Build | O(1) per position | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(n) for the output buffer |

Backtracking over all strings costs O(26^n); the row formula stays at n steps.
