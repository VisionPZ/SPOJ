# LOGIC2 — Logic II (SPOJ)

<https://www.spoj.com/problems/LOGIC2/>

## Problem

Find the one culprit from testimonies when exactly N of M people always lie. Testimonies mention guilt, innocence or the weekday; sentences outside those forms carry no information.

Input: several cases up to EOF. Each case gives M, N and P, then M names and P lines of the form speaker colon speech. Output: the culprit name, Cannot Determine for several culprits, or Impossible for none.

| item | bound |
|---|---|
| people M | 1 to 11 |
| liars N | 1 to M |
| sentences P | 1 to 30 |
| sentence length | at most 250 characters |
| judge limit | 1000 ms, 1536 MB |

The small person count makes exhaustive testing of culprits and weekdays practical.

Sample input:

```
3 1 5
MIKE
CHARLES
KATE
MIKE: I am guilty.
MIKE: Today is Sunday.
CHARLES: MIKE is guilty.
KATE: I am guilty.
KATE: How are you??
```

Sample output:

```
MIKE
```

KATE lies in the sample, and the other two people tell the truth.

## Idea

Try each suspect and each weekday like checking every name on a list against every page of a calendar. For that pair, decide for each speaker whether their useful sentences can all be true or all be false. Count how many people must lie and how many could lie.

The algorithm tests all culprit and weekday pairs and checks whether N lies inside that range. Each pair costs O(P) sentence evaluations. Enumerating every liar subset costs a factor of 2 to the M instead.

People with no useful sentence are flexible, so they can fill any remaining liar slots.

## Why It Works

1. Exactly one person is guilty, so only M culprit choices exist.
2. All day statements refer to one shared weekday, so only seven day choices exist.
3. A truthful speaker has every useful sentence true.
4. A liar has every useful sentence false.
5. A speaker with mixed true and false sentences rules out the current pair.
6. Speakers with no useful sentence can be counted as liars or truth-tellers, so they widen the feasible range.

| term | meaning |
|---|---|
| `kinds` | sentence type, including the day type |
| `targets` | named person or weekday index of a sentence |
| `forcedLiars` | people whose sentences force them to lie |
| `flexiblePeople` | people with no useful sentence |

The four arrays and counters drive one culprit and day check.

Here is the sample check from `gen.py`:

| speaker | useful sentence | truth with MIKE guilty on Sunday |
|---|---|---|
| MIKE | I am guilty. | true |
| MIKE | Today is Sunday. | true |
| CHARLES | MIKE is guilty. | true |
| KATE | I am guilty. | false |

Only KATE lies, which matches N equal to one.

## Code

**Input and sentence parsing.** The reader scans lines by hand and maps speech to sentence kinds.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const dayCount = 7
const kindSelfGuilty = 0
const kindSelfInnocent = 1
const kindOtherGuilty = 2
const kindOtherInnocent = 3
const kindDay = 4

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc nextLine(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r' or data[pos] == ' ' or data[pos] == '\t'):
    pos += 1
  var line = ""
  while pos < data.len and data[pos] != '\n' and data[pos] != '\r':
    line.add data[pos]
    pos += 1
  if pos < data.len and data[pos] == '\r':
    pos += 1
  if pos < data.len and data[pos] == '\n':
    pos += 1
  return line

proc nextToken(text: string, pos: var int): string =
  while pos < text.len and not ((text[pos] >= 'a' and text[pos] <= 'z') or (text[pos] >= 'A' and text[pos] <= 'Z')):
    pos += 1
  var word = ""
  while pos < text.len and ((text[pos] >= 'a' and text[pos] <= 'z') or (text[pos] >= 'A' and text[pos] <= 'Z')):
    word.add text[pos]
    pos += 1
  return word

proc findName(names: seq[string], candidate: string): int =
  for nameIndex in 0 .. names.len - 1:
    if names[nameIndex] == candidate:
      return nameIndex
  return -1

proc findDay(candidate: string): int =
  let weekdays = @["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  for dayIndex in 0 .. dayCount - 1:
    if weekdays[dayIndex] == candidate:
      return dayIndex
  return -1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Unknown sentence forms get a negative kind and are ignored later.
Line reading handles both carriage returns and plain newlines.
One buffer collects all case answers.

**Culprit and weekday search.** The driver tests each pair and checks the liar count.

```nim
while hasDigits(inputData, scanPos):
  let personCount = nextInt(inputData, scanPos)
  let liarCount = nextInt(inputData, scanPos)
  let sentenceCount = nextInt(inputData, scanPos)
  var names = newSeq[string](personCount)
  for personIndex in 0 .. personCount - 1:
    names[personIndex] = nextLine(inputData, scanPos)
  var speakers = newSeq[int](sentenceCount)
  var kinds = newSeq[int](sentenceCount)
  var targets = newSeq[int](sentenceCount)
  for sentenceIndex in 0 .. sentenceCount - 1:
    let speech = nextLine(inputData, scanPos)
    kinds[sentenceIndex] = -1
    var colonPos = 0
    while colonPos < speech.len and speech[colonPos] != ':':
      colonPos += 1
    if colonPos >= speech.len:
      continue
    let speaker = findName(names, speech[0 .. colonPos - 1])
    if speaker < 0:
      continue
    speakers[sentenceIndex] = speaker
    var wordPos = colonPos + 1
    let firstWord = nextToken(speech, wordPos)
    let secondWord = nextToken(speech, wordPos)
    let thirdWord = nextToken(speech, wordPos)
    let fourthWord = nextToken(speech, wordPos)
    if firstWord == "I" and secondWord == "am":
      if thirdWord == "guilty":
        kinds[sentenceIndex] = kindSelfGuilty
      elif thirdWord == "not" and fourthWord == "guilty":
        kinds[sentenceIndex] = kindSelfInnocent
    elif firstWord == "Today" and secondWord == "is":
      let statedDay = findDay(thirdWord)
      if statedDay >= 0:
        kinds[sentenceIndex] = kindDay
        targets[sentenceIndex] = statedDay
    else:
      let subject = findName(names, firstWord)
      if subject >= 0 and secondWord == "is":
        if thirdWord == "guilty":
          kinds[sentenceIndex] = kindOtherGuilty
          targets[sentenceIndex] = subject
        elif thirdWord == "not" and fourthWord == "guilty":
          kinds[sentenceIndex] = kindOtherInnocent
          targets[sentenceIndex] = subject
  var possible = newSeq[bool](personCount)
  for culprit in 0 .. personCount - 1:
    for day in 0 .. dayCount - 1:
      var forcedLiars = 0
      var flexiblePeople = 0
      var consistent = true
      for person in 0 .. personCount - 1:
        var hasUseful = false
        var allTrue = true
        var allFalse = true
        for sentenceIndex in 0 .. sentenceCount - 1:
          if kinds[sentenceIndex] < 0 or speakers[sentenceIndex] != person:
            continue
          var truth: bool
          case kinds[sentenceIndex]
          of kindSelfGuilty:
            truth = person == culprit
          of kindSelfInnocent:
            truth = person != culprit
          of kindOtherGuilty:
            truth = targets[sentenceIndex] == culprit
          of kindOtherInnocent:
            truth = targets[sentenceIndex] != culprit
          else:
            truth = day == targets[sentenceIndex]
          hasUseful = true
          if not truth:
            allTrue = false
          if truth:
            allFalse = false
        if not hasUseful:
          flexiblePeople += 1
        elif not allTrue and not allFalse:
          consistent = false
          break
        elif allFalse:
          forcedLiars += 1
      if consistent and forcedLiars <= liarCount and liarCount <= forcedLiars + flexiblePeople:
        possible[culprit] = true
  var winnerCount = 0
  var winnerName = ""
  for culprit in 0 .. personCount - 1:
    if possible[culprit]:
      winnerCount += 1
      winnerName = names[culprit]
  if winnerCount == 0:
    appendOutput("Impossible")
  elif winnerCount > 1:
    appendOutput("Cannot Determine")
  else:
    appendOutput(winnerName)
  outputBuffer.add '\n'
```

The parse pass keeps only recognised sentence forms.
The pair loop stops early on a contradiction.
The final count chooses one of three answers.
The block buffer flushes when it grows large.

## Complexity

Each case checks at most eleven culprits and seven weekdays.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| sentence parse | one line per sentence | three arrays |
| pair search | seven times M times P checks | one flag per person |
| output | one write per block | block buffer |

The pair search is the only nested phase.

| measure | Big O |
|---|---|
| time per case | O(7 * M * P) |
| space per case | O(M + P) |

Checking every liar subset would cost O(2 to the M) more, while the feasible liar range avoids that factor.
The small bounds keep every case inside the time limit.
