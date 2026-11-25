# RG11_2 — Claves Seguras Grado 11 (SPOJ)

<https://www.spoj.com/problems/RG11_2/>

## Problem

Read potential passwords until the line containing "end".
Each password contains only lowercase letters and has length one to twenty.
A password is acceptable when it obeys three rules.
It needs at least one vowel, never three vowels or consonants in a row,
and never a repeated letter except ee or oo.

Print one verdict per password using the exact format in the sample.

| Item | Bound |
|---|---|
| Passwords | until the word "end" |
| Length | 1 to 20 lowercase letters |
| Vowels | a, e, i, o, u |
| Judge limit | 1000 ms |

Every check scans the word once from left to right.

Sample input:

```
a
tv
ptoui
bontres
zoggax
wiinq
eep
houctuh
end
```

Sample output:

```
<a> is acceptable.
<tv> is not acceptable.
<ptoui> is not acceptable.
<bontres> is not acceptable.
<zoggax> is not acceptable.
<wiinq> is not acceptable.
<eep> is acceptable.
<houctuh> is acceptable.
```

## Idea

Treat the word as a sequence of traffic lights.
A vowel light and a consonant light cannot stay green three turns in a row.
A repeated letter is a red light unless it is ee or oo.

One state machine tracks the current run of vowels or consonants.
A separate flag remembers whether any vowel appeared.
Each new letter either extends the run or resets it.

## Why It Works

1. A run of three same-type letters violates the second rule immediately.
2. Comparing each letter with its predecessor catches forbidden repeats.
3. The vowel flag enforces the first rule after the scan ends.
4. Resetting the opposite run keeps the state exact at every position.

| Term | Meaning |
|---|---|
| `vowelRun` | count of consecutive vowels so far |
| `consonantRun` | count of consecutive consonants so far |
| `hasVowel` | whether any vowel has appeared |
| `previous` | letter read immediately before the current one |

Script-generated example from `gen.py`:

```
a -> acceptable
tv -> not acceptable
eep -> acceptable
```

The word tv fails because it has no vowel.

## Code

**Rules and input.** This block reads all lines and defines the checks.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc isVowelLetter(value: char): bool =
  return value == 'a' or value == 'e' or value == 'i' or
         value == 'o' or value == 'u'

proc isAcceptable(word: string): bool =
  if word.len == 0: return false
  var hasVowel = false
  var vowelRun = 0
  var consonantRun = 0
  var previous = char(0)
  for index in 0..<word.len:
    let current = word[index]
    if current == previous and current != 'e' and current != 'o':
      return false
    if isVowelLetter(current):
      hasVowel = true
      vowelRun += 1
      consonantRun = 0
      if vowelRun >= 3: return false
    else:
      consonantRun += 1
      vowelRun = 0
      if consonantRun >= 3: return false
    previous = current
  return hasVowel

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The vowel test uses five direct comparisons.
A repeat fails unless the letter is e or o.
The word is rebuilt from non-space bytes of each line.

**Verdict loop.** This block walks the word and writes each result.

```nim
var lineStart = 0
while lineStart < inputData.len:
  var lineEnd = lineStart
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var word = ""
  for index in lineStart..<lineEnd:
    let current = inputData[index]
    if current > ' ': word.add current
  if word == "end": break
  if word.len > 0:
    appendOutput("<")
    appendOutput(word)
    if isAcceptable(word):
      appendOutput("> is acceptable.\n")
    else:
      appendOutput("> is not acceptable.\n")
  lineStart = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The "end" marker stops all output.
Run counters reset whenever the letter type changes.
Each verdict ends with one newline.

## Complexity

The scan is linear in the total input length.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Validation | O(L) per password | one word |
| Output | one write per 128 KiB block | block buffer |

L is the password length, at most twenty.

| Measure | Big O |
|---|---|
| Time | O(I) for I input bytes |
| Space | O(I) |

Generating every valid word of a length would be exponential.
A single left-to-right check decides each password in linear time.
