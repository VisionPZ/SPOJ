## Problem

The program reads a contest submission history and rates every problem. Each test case lists submissions with a time, a team name, a problem letter, and a result. For each of the nine problems, print the count of accepted solutions and two averages when that count is positive. The averages are submissions per solving team and seconds taken to solve.

The judge bounds fit one sequential scan.

| Bound | Value |
| --- | --- |
| Submissions per case | 2000 |
| Submission time | 18000 s |
| Teams | 62 |
| Problems | 9, A through I |
| Time and memory limit | 3 s, 1536 MB |

Every test case writes exactly nine lines.

## Idea

Scan the submissions in order and keep one solved flag and one submission counter per team and problem pair. The first accepted submission of a pair closes that pair. At that moment, add the counter and the time to the totals of the problem. Skip every later submission of a closed pair. A flat table of 4096 slots maps a team name to a numeric index in constant time. Integer arithmetic rounds each average half up, so 1.235 becomes 1.24. Each submission costs constant work.

## Why It Works

The rules discard all submissions of a problem by a team after that team solves it. The counter for a pair therefore holds the submissions up to and including the first accept. Those are exactly the submissions of the teams that solved the problem. Summing the counters and first accept times over those teams gives both averages.

The rounding step works on integer cents.

- `scaledNumerator` shifts two decimal places into the integer part.
- Adding `denominator` before the division supplies the half-cent tie.
- Dividing by `2 * denominator` completes the round-half-up step.

A worked example uses problem A from the sample.

```
groups for problem A:
  chau1  submissions=1 firstAcceptTime=100
  wawu1  submissions=2 firstAcceptTime=2020
  pp1    submissions=1 firstAcceptTime=8000
accepted=3 submissionSum=4 timeSum=10120
submissions: (2*400 + 3) div (2*3) = 803 div 6 = 133 -> 1.33
time: (2*1012000 + 3) div (2*3) = 2024003 div 6 = 337333 -> 3373.33
```

Three teams solved problem A with four submissions and 10120 seconds in total.

## Code

The input loop reads the whole stream before any parsing starts.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
```

One read loop fills the buffer. The scanner walks it by index. The cost is one pass over the input bytes.

The scanner reads numbers and field spans without allocating new strings.

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
```

The digit loop stops at the first space, so trailing spaces in the sample are harmless. A token span records two indices instead of copying the field. Each field costs one pass over its characters.

A team name becomes one integer through base 36 digits.

```nim
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

The loop runs once per character, at most five times. Digits use values 0 to 9 and letters use 10 to 35. The code fits the open addressing table.

Averages are formatted with integer division only.

```nim
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

The formula rounds half up without floating point error. The fraction gets a leading zero when needed. The cost is constant for each average.

One loop updates every team and problem pair.

```nim
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

The loop bound is the submission count of the case. The solved flag skips every pair that already closed. Open addressing keeps the team lookup constant. Each submission costs constant work.

Nine lines are appended for every case.

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
```

The loop always runs nine times. The condition prints averages only for solved problems. The trailing space matches the sample bytes. Block flushing keeps memory small.

## Complexity

Reading costs one pass over the input bytes. Each case resets 4096 hash slots, 558 pair slots, and 9 problem slots. Each submission costs constant work plus at most five team characters. Writing costs nine lines per case.

Total time is linear in the number of submissions and input bytes. Total space is a fixed set of tables plus the input and output buffers. A naive method that rescans earlier submissions for every new one costs quadratic time per case.
