# THR18A — ICPC (SPOJ)

<https://www.spoj.com/problems/THR18A/>

## Problem

Two football matches decide a winner. Compare the combined goals first, then the goals scored away from home, and name the winner or a penalty shootout.

The input has four numbers: the goals in the first match, Persepolis at home, then the goals in the second match, Esteghlal at home. Print one team name or Penalty.

| item | bound |
|---|---|
| each goal count | 0 to 20 |
| judge limit | 1000 ms, 1536 MB |

Exactly one case is given per run.

Sample input:

```
3 0
2 1
```

Sample output:

```
Persepolis
```

## Idea

Score the tie like a two-round contest with a backup rule. Add each team's goals from both matches. When totals tie, count only goals scored in the other team's stadium. If those also tie, nobody wins on the rules. Three comparisons produce the answer.

## Why It Works

1. Aggregate score is the sum of a team's goals in both matches.
2. A larger aggregate decides the winner immediately.
3. On a tie, away goals count for the team visiting that stadium.
4. Equal away goals mean the rules cannot decide, so penalties follow.

| term | meaning |
|---|---|
| `persepolisAggregate` | goals Persepolis scored across both matches |
| `esteghlalAggregate` | goals Esteghlal scored across both matches |
| `persepolisAwayGoals` | goals Persepolis scored in the second match |
| `esteghlalAwayGoals` | goals Esteghlal scored in the first match |

The order of input lines is fixed by the home team.

Script-generated trace for the second sample case:

```
team | home goals | away goals | aggregate
Persepolis | 3 | 0 | 3
Esteghlal | 2 | 1 | 3
```

Away goals are 0 against 1, so Esteghlal wins.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

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
```

The four goals are read in input order.
The scanner skips spaces and line breaks.
Parsing costs a few digit operations.

**Winner decision and output.** Ordered comparisons apply the rules.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let persepolisHomeGoals = nextInt(inputData, scanPos)
let esteghlalAwayGoals = nextInt(inputData, scanPos)
let esteghlalHomeGoals = nextInt(inputData, scanPos)
let persepolisAwayGoals = nextInt(inputData, scanPos)
let persepolisAggregate = persepolisHomeGoals + persepolisAwayGoals
let esteghlalAggregate = esteghlalHomeGoals + esteghlalAwayGoals
if persepolisAggregate > esteghlalAggregate:
  appendOutput("Persepolis")
elif esteghlalAggregate > persepolisAggregate:
  appendOutput("Esteghlal")
elif persepolisAwayGoals > esteghlalAwayGoals:
  appendOutput("Persepolis")
elif esteghlalAwayGoals > persepolisAwayGoals:
  appendOutput("Esteghlal")
else:
  appendOutput("Penalty")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Aggregate goals are checked before away goals.
The last branch covers a complete tie.
One word is written from the block buffer.

## Complexity

One case needs only a handful of operations.

| phase | time | space |
|---|---|---|
| input read | four integers | one input string |
| comparison | constant comparisons and sums | five integers |
| output | one word | block buffer |

No loop or table is needed.

| measure | Big O |
|---|---|
| time | O(1) apart from input bytes |
| space | O(1) apart from buffers |

Enumerating score scenarios would add work without changing the rule.
