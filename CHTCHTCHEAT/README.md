# CHTCHTCHEAT — Cheating!! (SPOJ)

<https://www.spoj.com/problems/CHTCHTCHEAT/>

## Problem

Som answers every essay question by slipping in sentences from one essay about a cow. Detect whether a student did the same.

Input: test count `T`; each case has a lowercase topic, a sentence count `N`, then `N` sentence lines. Output: `Cheating` if a sentence comes from the cow essay and the topic is not `cow`; otherwise `Not cheating`.

| Item | Bound |
|---|---|
| Test count `T` | 0 < T < 50 |
| Topic length | fewer than 25 characters |
| Sentence count `N` | less than 100 |
| Sentence length | fewer than 100 characters |
| Judge limit | 1 s, 1536 MB |

The cow essay has five fixed sentences, so each line needs only a membership check.

Sample input:

```
3
cow
3
Cow is a domesticated animal.
She helps mankind in many ways.
Her milk is healthy for babies.
gandhi
3
Gandhi was an Indian leader.
He loved cows.
Cow is a domesticated animal.
cat
4
Cat drinks milk.
The milk comes from a cow.
Cats are familiar and easily kept animals
Cats can hear sounds too faint or too high.
```

Sample output:

```
Not cheating
Cheating
Not cheating
```

## Idea

Picture the teacher holding one photocopy of the cow essay beside the answer sheet.
Every sentence is compared with those five lines; one match is enough to flag cheating.
The topic `cow` is the excuse: a real cow essay may reuse those lines freely.
A full text search or a language model would be overkill for five exact strings.

## Why It Works

1. The five cow sentences are fixed by the story, so a constant array is a complete reference.
2. A sentence line is read whole, including spaces, so punctuation stays part of the comparison.
3. The topic check is independent of the sentences, and all `N` lines are still consumed, so the next case starts at the right place.
4. One matching sentence sets the flag; later sentences cannot clear it.

| Term | Meaning |
|---|---|
| `cowSentences` | the five quoted lines from the cow essay |
| `topicName` | the lowercase essay topic |
| `cheating` | flag set when a copied line is found |

The trace below comes from `gen.py` on the sample case:

```
trace: topic=gandhi contains cow sentence -> Cheating; topic=cow -> Not cheating
```

That is why the first case is `Not cheating` and the second is `Cheating`.

## Code

**Fixed reference.** The five quoted sentences and the flush size are constants.

```nim
const cowSentenceCount = 5
const cowSentences = [
  "Cow is a domesticated animal.",
  "She helps mankind in many ways.",
  "Her milk is very healthy for babies.",
  "Cows usually eat green grass but they can survive on other things too.",
  "Blah blah blah."
]
const flushBlockBytes = 1 shl 17
```

The array order follows the story. Each entry includes its final period, so comparison is exact.

**Scanners.** Numbers, topic words, and whole sentence lines are read by byte index.

```nim
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
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]

proc nextLine(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  var finishPos = pos
  if finishPos > startPos and data[finishPos - 1] == '\r':
    finishPos -= 1
  if pos < data.len:
    pos += 1
  return data[startPos ..< finishPos]
```

`nextLine` keeps internal spaces and drops a trailing carriage return. All three scanners share one growing position, so no line counter can drift.

**Driver.** Reads all input, then flags each case and appends a verdict.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for _ in 0..<testCount:
  let topicName = nextToken(inputData, scanPos)
  let sentenceCount = nextInt(inputData, scanPos)
  var cheating = false
  for _ in 0..<sentenceCount:
    let sentence = nextLine(inputData, scanPos)
    if topicName != "cow":
      for k in 0..<cowSentenceCount:
        if sentence == cowSentences[k]:
          cheating = true
          break
  if cheating:
    appendOutput("Cheating\n")
  else:
    appendOutput("Not cheating\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loop still runs when `topicName` is `cow`, so the scanner consumes every line. Cost is at most 100 lines times five comparisons per case.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sentence scan | one pass over each line | one line |
| Match check | five comparisons per sentence | none |
| Output | one write per 128 KiB block | block buffer |

Each case touches its `N` lines once, and the fixed reference never changes size.

| Measure | Big O |
|---|---|
| Time | O(total input bytes) |
| Space | O(input bytes + longest line) |

Searching each sentence inside every cow line or building a text index would add needless work. Exact comparison against five constants is both simpler and faster.
