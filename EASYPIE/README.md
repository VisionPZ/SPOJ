# EASYPIE — Easy Problem (SPOJ)
<https://www.spoj.com/problems/EASYPIE/>

## Problem

A contest director rates problem difficulty from the submission log left after a contest.
The program turns that log into nine short statistics lines.

Read `t` test cases.
Each case starts with the submission count, then that many submissions.
A submission holds a time, a team name, a problem letter, and a result `A` or `R`.
For each of nine problems, print its letter and the count of accepted solutions.
Also print the average submissions per solving team and the average seconds to solve.
Teams that never solved a problem are excluded from both averages.

The sample prints a trailing space on every output line.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Submissions per case | up to 2000 |
| Submission time | up to 18000 s |
| Teams | up to 62 |
| Problems | 9, A through I |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Every case writes exactly nine lines.

The sample input and expected output follow verbatim.

```
1
12 
10 wawu1 B R 
100 chau1 A A 
2000 uwr2 B A 
2010 wawu1 A R 
2020 wawu1 A A 
2020 wawu1 B A 
4000 wawu2 C R 
6000 chau1 A R 
7000 chau1 A A 
8000 pp1 A A 
8000 zil2 B R 
9000 zil2 B A 

```

```
A 3 1.33 3373.33 
B 3 1.67 4340.00 
C 0 
D 0 
E 0 
F 0 
G 0 
H 0 
I 0 
```

Problem A shows three solves with averages 1.33 and 3373.33.

## Idea

Close each team-problem pair at its first accept, like stamping a ticket when a customer first succeeds.
Later submissions of a closed pair no longer count.

A flat hash table (a table indexed directly by a key) maps a team name to a numeric index in constant time.
At the first accept, add that pair's submission count and accept time to the problem totals.
Integer arithmetic rounds each average half up, with no floating point.

Cost per submission is constant.
Rescanning the log once per problem would take nine passes.
One scan, one stamp per pair, nine lines out.

## Why It Works

Four facts prove the method.

1. The rules discard later submissions of a problem by a team after that team solves it.
2. The counter for a pair therefore holds submissions up to and including the first accept.
3. Summing those counters and first accept times over solving teams gives both averages.
4. Adding the denominator before division supplies the half-cent tie in the rounding formula.

The main tables and their roles follow.

| Term | Meaning |
| --- | --- |
| `solvedFlags` | one flag per team and problem pair |
| `submissionCounts` | attempts up to the first accept |
| `scaledNumerator` | numerator shifted two decimal places |
| `roundedCents` | average in hundredths, rounded half up |

The sample problem A averages 1.33 submissions and 3373.33 seconds.

A script reduces the sample rows for problem A and prints each step.

```
groups for problem A:
  chau1  submissions=1 firstAcceptTime=100
  wawu1  submissions=2 firstAcceptTime=2020
  pp1    submissions=1 firstAcceptTime=8000
accepted=3 submissionSum=4 timeSum=10120
submissions: (2*400 + 3) div (2*3) = 803 div 6 = 133 -> 1.33
time: (2*1012000 + 3) div (2*3) = 2024003 div 6 = 337333 -> 3373.33
```

Three solving teams produce the printed averages.

## Code

**Constants.**

```nim
const firstDigitValue = 48
const firstUpperCaseValue = 65
const firstLowerCaseValue = 97
const base36 = 36
const problemCount = 9
const maxTeamCount = 62
const teamSlotCount = 1 shl 12
const flushBlockBytes = 1 shl 17
const acceptedMark = 'A'
```

The first uppercase value anchors problem letters A through I. The base 36 code packs team names into integers. The output block holds 128 KiB.

**Bulk input.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
```

One read loop fills the input buffer before any parsing. The scanner walks that buffer by index. The cost is one pass over the bytes.

**Scanners and team encoding.**

```nim
proc skipWhitespace(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    i += 1

proc scanInteger(data: string, i: var int): int =
  skipWhitespace(data, i)
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc scanTokenSpan(data: string, i: var int): tuple[first: int, last: int] =
  skipWhitespace(data, i)
  let tokenFirst = i
  while i < data.len and data[i] > ' ':
    i += 1
  return (tokenFirst, i)

proc encodeTeam(data: string, tokenFirst: int, tokenLast: int): int =
  var code = 0
  for i in tokenFirst..<tokenLast:
    let character = data[i]
    if character >= '0' and character <= '9':
      code = code * base36 + int(character) - firstDigitValue
    else:
      code = code * base36 + int(character) - firstLowerCaseValue + 10
  return code
```

scanInteger stops at the first space. scanTokenSpan records two indices instead of copying a field. encodeTeam treats a name as a base 36 number, so lookup needs no string key.

**Output helpers.**

```nim
var outputBuffer = ""

proc flushIfNeeded(buffer: var string) =
  if buffer.len >= flushBlockBytes:
    stdout.write buffer
    buffer.setLen 0

proc appendAverage(numerator: int, denominator: int, buffer: var string) =
  let scaledNumerator = numerator * 100
  let roundedCents = (2 * scaledNumerator + denominator) div (2 * denominator)
  buffer.add $(roundedCents div 100)
  buffer.add '.'
  let fractionPart = roundedCents mod 100
  if fractionPart < 10:
    buffer.add '0'
  buffer.add $fractionPart
```

flushIfNeeded writes a full block and reuses the buffer. appendAverage formats hundredths with integer division. A leading zero is added for single-digit fractions.

**Fixed tables and reset.**

```nim
var teamSlotCodes = newSeq[int](teamSlotCount)
var teamSlotIndices = newSeq[int](teamSlotCount)
var solvedFlags = newSeq[bool](maxTeamCount * problemCount)
var submissionCounts = newSeq[int](maxTeamCount * problemCount)
var acceptedPerProblem = newSeq[int](problemCount)
var submissionSumPerProblem = newSeq[int](problemCount)
var timeSumPerProblem = newSeq[int](problemCount)

let caseCount = scanInteger(inputData, i)
for j in 0..<caseCount:
  for k in 0..<teamSlotCount:
    teamSlotIndices[k] = -1
  for l in 0..<maxTeamCount * problemCount:
    solvedFlags[l] = false
    submissionCounts[l] = 0
  for k in 0..<problemCount:
    acceptedPerProblem[k] = 0
    submissionSumPerProblem[k] = 0
    timeSumPerProblem[k] = 0
```

The 4096 hash slots are cleared each case. The solved flags and problem totals are also reset. The reset cost is fixed and small.

**Scan all submissions.**

```nim
  let submissionCount = scanInteger(inputData, i)
  var nextTeamIndex = 0
  for k in 0..<submissionCount:
    let submissionTime = scanInteger(inputData, i)
    let teamSpan = scanTokenSpan(inputData, i)
    let problemSpan = scanTokenSpan(inputData, i)
    let resultSpan = scanTokenSpan(inputData, i)
    let problemIndex = int(inputData[problemSpan.first]) - firstUpperCaseValue
    let isAccepted = inputData[resultSpan.first] == acceptedMark
    let teamCode = encodeTeam(inputData, teamSpan.first, teamSpan.last)
    var slotIndex = teamCode and (teamSlotCount - 1)
    while teamSlotIndices[slotIndex] != -1 and teamSlotCodes[slotIndex] != teamCode:
      slotIndex = (slotIndex + 1) and (teamSlotCount - 1)
    if teamSlotIndices[slotIndex] == -1:
      teamSlotCodes[slotIndex] = teamCode
      teamSlotIndices[slotIndex] = nextTeamIndex
      nextTeamIndex += 1
    let teamIndex = teamSlotIndices[slotIndex]
    let l = teamIndex * problemCount + problemIndex
    if not solvedFlags[l]:
      submissionCounts[l] += 1
      if isAccepted:
        solvedFlags[l] = true
        acceptedPerProblem[problemIndex] += 1
        submissionSumPerProblem[problemIndex] += submissionCounts[l]
        timeSumPerProblem[problemIndex] += submissionTime
```

The loop runs once per submission. Open addressing keeps team lookup constant. The solved flag skips pairs that already closed. The first accept updates all three problem totals.

**Write nine lines.**

```nim
  for k in 0..<problemCount:
    outputBuffer.add chr(firstUpperCaseValue + k)
    outputBuffer.add ' '
    outputBuffer.add $acceptedPerProblem[k]
    outputBuffer.add ' '
    if acceptedPerProblem[k] > 0:
      appendAverage(submissionSumPerProblem[k],
                    acceptedPerProblem[k], outputBuffer)
      outputBuffer.add ' '
      appendAverage(timeSumPerProblem[k],
                    acceptedPerProblem[k], outputBuffer)
      outputBuffer.add ' '
    outputBuffer.add '\n'
    flushIfNeeded(outputBuffer)

stdout.write outputBuffer
```

The loop always writes nine problem letters. Averages appear only when at least one team solved the problem. The trailing space matches the sample bytes.

## Complexity

The phases and their costs follow.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(input bytes) | one input buffer |
| Per-case reset | O(4096 + 62*9) | fixed tables |
| Submission scan | O(1) per submission | fixed tables |
| Output | O(9) lines per case | one output block |

Total time is linear in the input size.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(total input bytes) |
| Space | O(input bytes) plus fixed tables |

Rescanning earlier submissions for every new one would cost quadratic time per case.
