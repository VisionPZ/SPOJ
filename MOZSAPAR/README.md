# MOZSAPAR — Sharmeen and parentheses (SPOJ)

<https://www.spoj.com/problems/MOZSAPAR/>

## Problem

Replace every `?` in a bracket string with `(` or `)` so the result is a valid parentheses sequence. Print `yes` when a replacement exists and `no` otherwise.

The first input line holds `T`, the number of strings. Each following line holds one string of `(`, `)`, and `?`. The total length of all strings is at most 1000000.

| item | bound |
|---|---|
| test cases `T` | 1 to 100000 |
| string length `n` | 1 to 100000 |
| total length | at most 1000000 |
| judge limit | 1000 ms, 1536 MB |

A valid sequence never has more closing brackets than opening brackets in any prefix, and ends with equal counts.

Sample input:

```
2
(()??((??)
((??
```

Sample output:

```
yes
yes
```

The first string can become `(())((()))` and many other valid forms.

## Idea

Filling gaps is like balancing a stack of plates: add enough plates early so every later removal has one to take. Count the openings required by the final totals, then spend that budget on the earliest question marks. One pass counts the brackets and one pass checks the balance. Trying every assignment would cost two to the power of the question mark count. The budget rule keeps each case linear in its length.

## Why It Works

1. Let `O`, `C`, and `Q` be the counts of `(`, `)`, and `?`.
2. Final equality requires `O + k = C + (Q - k)`, where `k` marks become openings.
3. Solving gives `k = (C + Q - O) / 2`, which is an integer when `n` is even.
4. An assignment exists only when `0 <= k <= Q` and no prefix balance goes negative.
5. Using the earliest `Q` marks as openings maximizes every prefix balance, so it detects every impossible case.

| term | meaning |
|---|---|
| `openingCount` | `O`, the fixed opening brackets |
| `closingCount` | `C`, the fixed closing brackets |
| `questionCount` | `Q`, the replaceable positions |
| `openingsNeeded` | `k`, the number of marks that become openings |
| `balance` | openings minus closings in the current prefix |

The generator checks both sample strings. The first has `O = 4`, `C = 2`, `Q = 4`, so `k = 1`. The second has `O = 2`, `C = 0`, `Q = 2`, so `k = 0`.

| string | O | C | Q | k | answer |
|---|---|---|---|---|---|
| `(()??((??)` | 4 | 2 | 4 | 1 | yes |
| `((??` | 2 | 0 | 2 | 0 | yes |
| `?` | 0 | 0 | 1 | none | no |

The odd-length string fails before any prefix check.

## Code

**Input and token scanning.** The reader loads the text and returns whole strings.

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

`nextToken` skips whitespace and collects one bracket string.
`nextInt` reads the case count from the first line.
Both scanners share the same position marker.

**Budget and balance check.** Counts fix the budget, then the prefix pass validates it.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequence = nextToken(inputData, scanPos)
  let sequenceLength = sequence.len
  var openingCount = 0
  var closingCount = 0
  var questionCount = 0
  for charIndex in 0 .. sequenceLength - 1:
    if sequence[charIndex] == '(':
      openingCount += 1
    elif sequence[charIndex] == ')':
      closingCount += 1
    else:
      questionCount += 1
  let openingsNeeded = (closingCount + questionCount - openingCount) div 2
  var possible = true
  if sequenceLength mod 2 != 0 or openingsNeeded < 0 or openingsNeeded > questionCount:
    possible = false
  var balance = 0
  var questionsUsed = 0
  if possible:
    for charIndex in 0 .. sequenceLength - 1:
      let currentChar = sequence[charIndex]
      if currentChar == '(':
        balance += 1
      elif currentChar == ')':
        balance -= 1
      else:
        if questionsUsed < openingsNeeded:
          balance += 1
        else:
          balance -= 1
        questionsUsed += 1
      if balance < 0:
        possible = false
        break
  if possible and balance == 0:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first pass fixes `k` from the three counts.
The second pass spends `k` on the earliest marks.
A negative balance ends the case immediately.

## Complexity

Each case makes two passes over its string.

| phase | time | space |
|---|---|---|
| input read | one pass over all strings | one input string |
| counting | one pass over `n` | counters only |
| prefix check | one pass over `n` | counters only |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(n) |
| space per case | O(n) for the token |

Enumerating every replacement costs exponential time in the mark count.

Two linear passes decide the same question.
