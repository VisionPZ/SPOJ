# AUTOMATA — GAME2 (SPOJ)

<https://www.spoj.com/problems/AUTOMATA/>

## Problem

A pattern uses lowercase letters, `?` for one optional character, and `*` for any run of characters. Decide whether the pattern describes the whole subject string, not a substring. Print `Yes` when it does and `No` otherwise.

| item | bound |
|---|---|
| test cases T | up to 50 |
| pattern alphabet | a-z, `?`, `*` |
| subject alphabet | a-z |
| practical length | up to 10000 per comment |
| judge limit | 1000 ms, 1536 MB |

A match covers every character of the subject. The sample's a?b rejects abbb because `?` consumes exactly one character.

Sample input:

```
5
a?b
acb
a?b
abbb
a*b
abbbb
a*b
asbdfuisdhfsbdfsdfb
abb
bb
```

Sample output:

```
Yes
No
Yes
Yes
No
```

## Idea

Treat each star as a bookmark you can move forward when a later letter fails. This is the classic greedy wildcard scan: consume letters directly, remember the last star, and retry from it on mismatch. Each subject position advances once, and each pattern position is revisited only through its most recent star. A dynamic-programming table would fill a cell for every pattern and subject pair and repeat work that the bookmark skips. Keep the bookmark and scan once.

## Why It Works

1. A literal or `?` consumes exactly one subject character when it applies.
2. A `*` consumes zero characters at first and stores the retry position.
3. On mismatch, extending that star by one character keeps all earlier choices valid.
4. When no star exists, the remaining subject cannot be consumed, so matching fails.
5. Trailing stars are dropped, and a full pattern scan means success.

| term | meaning |
|---|---|
| `lastStar` | pattern index of the newest star, or -1 when absent |
| `starTextPos` | number of subject characters covered by that star |
| `patternPos` | current position in the pattern |
| `textPos` | current position in the subject |

For pattern a*b and subject abbbb, the star starts at subject index 1. The final `b` fails at index 4, so the star grows until its copy ends at the last `b`, and the answer is `Yes`.

| pattern | subject | result |
|---|---|---|
| a?b | acb | Yes |
| a?b | abbb | No |
| a*b | abbbb | Yes |
| abb | bb | No |

The retry never rewinds past the stored bookmark, so the scan stays linear on ordinary inputs.

## Code

**Input and tokens.** The reader loads stdin once and returns whitespace-delimited strings.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1
```

The scanner treats every whitespace character as a separator.
Each test case consumes one pattern token and one subject token.

**Greedy matcher.** One bookmark drives all retries after a failed literal.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc wildcardMatch(pattern: string, text: string): bool =
  var textPos = 0
  var patternPos = 0
  var lastStar = -1
  var starTextPos = 0
  while textPos < text.len:
    if patternPos < pattern.len and (pattern[patternPos] == '?' or pattern[patternPos] == text[textPos]):
      textPos += 1
      patternPos += 1
    elif patternPos < pattern.len and pattern[patternPos] == '*':
      lastStar = patternPos
      patternPos += 1
      starTextPos = textPos
    elif lastStar >= 0:
      patternPos = lastStar + 1
      starTextPos += 1
      textPos = starTextPos
    else:
      return false
  while patternPos < pattern.len and pattern[patternPos] == '*':
    patternPos += 1
  return patternPos == pattern.len
```

A missing bookmark ends the attempt immediately.
Trailing stars are skipped before the final equality check.

**Driver.** Each case appends one answer line to the shared buffer.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let language = nextToken(inputData, scanPos)
  let subject = nextToken(inputData, scanPos)
  if wildcardMatch(language, subject):
    appendOutput("Yes\n")
  else:
    appendOutput("No\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

No per-line writes happen inside the loop.
A single flush emits all answers.

## Complexity

The scan advances the subject pointer once per character.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| match | one pass over subject plus retries | four integer cursors |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| time | O(length of pattern + length of subject) per ordinary case |
| space | O(1) beyond input and output buffers |

A full dynamic-programming table would spend O(pattern length times subject length) cells on every case.

The bookmark keeps the common path linear and simple.
