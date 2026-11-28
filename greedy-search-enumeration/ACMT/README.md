# ACMT — Acm Teams (SPOJ)

<https://www.spoj.com/problems/ACMT/>

## Problem

Find the largest number of three-person teams that can be built from experienced members and newbies. Each team uses either one experienced member and two newbies, or two experienced members and one newbie.

The first input line holds the number of test cases. Every following line holds the counts E and N for one case. Print one integer per case, the maximum team count.

| Item | Bound |
|---|---|
| Test cases | 1 to 10 |
| Counts E and N | 0 to 500000 |
| Judge limit | 1000 ms, 1536 MB |

The member counts set the answer; there are only ten cases, so one arithmetic step per case settles the work.

Sample input:

```
2
2 6
4 5
```

The sample has two cases with different mixes of members.

Sample output:

```
2
3
```

Each line answers the case on the same line of the input.

## Idea

Splitting a pile of members into teams is like fitting boxes onto a shelf: three items per box, with two shape choices. Each team always spends three people, so the count cannot exceed the total divided by three.

The algorithm takes the smallest of three values: experienced count, newbie count, and the total divided by three. Every team needs at least one member of each kind, which gives the first two limits. The three-person team size gives the third limit. A search over all mixes of the two team shapes would test many splits; the three limits give the answer at once.

Takeaway: compute the cap, clip it twice, and print it.

## Why It Works

1. Every legal team has exactly three members, so the count cannot exceed the total divided by three.
2. Every legal team has at least one experienced member, so the count cannot exceed E.
3. Every legal team has at least one newbie, so the count cannot exceed N.
4. Write x for teams of one experienced plus two newbies, and y for the other shape. Then x plus y is the total team count.
5. The experienced use is x plus twice y, and the newbie use is twice x plus y. Any count up to the three caps has a valid split, so the smallest cap is attainable.

| Term | Meaning |
|---|---|
| `experienced` | count of experienced members in one case |
| `newbies` | count of newbie members in one case |
| `teamTotal` | the three caps reduced to the smallest one |
| feasibility | a candidate count has a valid split between the two shapes |

The table links the two resource caps to the value printed for each case.

A script-generated trace of the binary-search oracle on the sample:

```
E=2, N=6: low=0, high=2
  k=1: lower=0, upper=1, feasible=True
  k=2: lower=2, upper=2, feasible=True
  answer 2
E=4, N=5: low=0, high=4
  k=2: lower=0, upper=2, feasible=True
  k=3: lower=2, upper=2, feasible=True
  k=4: lower=4, upper=1, feasible=False
  answer 3
```

The independent search agrees with the two sample answers.

For a candidate count k, the number of first-shape teams must be at least 2k minus E and at most N minus k. That interval is nonempty exactly when k obeys all three caps. Zero counts need no guard: the caps return zero for them.

## Code

**Input and scanner.** The reader loads all lines and the scanner extracts the case count and each pair.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`scanPos` skips the line breaks between pairs. The two member counts stay below 500000, so plain integers hold their sum. This block runs once.

**Cap and output.** Each case clips the total cap against both member counts.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let experienced = nextInt(inputData, scanPos)
  let newbies = nextInt(inputData, scanPos)
  var teamTotal = (experienced + newbies) div 3
  if experienced < teamTotal:
    teamTotal = experienced
  if newbies < teamTotal:
    teamTotal = newbies
  appendOutput($teamTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per case. Both clips keep the largest attainable count. The final flush writes all answers together.

## Complexity

Each case needs one division and two comparisons, and the buffer collects the short output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all numbers | one input string |
| Cap and clips | constant work per case | a few integers |
| Output | one append per case | block buffer |

The phase table shows that cost grows with the number of cases alone.

| Measure | Big O |
|---|---|
| Time | O(number of cases) |
| Space | O(input size) |

Trying every split of experienced and newbie members would scan many candidate mixes. The cap argument gives the answer in constant time.
