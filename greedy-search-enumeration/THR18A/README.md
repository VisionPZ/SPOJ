# THR18A — ICPC Finals (SPOJ)

<https://www.spoj.com/problems/THR18A/>

## Problem

A two-legged football final between Persepolis and Esteghlal is decided by aggregate goals, then by the away goals rule, and otherwise by penalty kicks. The program reads both match scores and prints the winner or `Penalty`.

Input holds two lines. The first line gives `p1` and `s1`, the goals of Persepolis and Esteghlal in the match where Persepolis is at home. The second line gives `s2` and `p2`, the goals of Esteghlal and Persepolis in the match where Esteghlal is at home. Output holds one line with the verdict.

| Item | Bound |
|---|---|
| Goals per match | 0 ≤ every integer ≤ 20 |
| Judge limit | 1000 ms, 1536 MB |

The sample cases:

```
3 0
2 1
```

```
Persepolis
```

```
3 1
2 0
```

```
Esteghlal
```

```
2 0
2 0
```

```
Penalty
```

## Idea

Add the two scores for each team, compare the totals, and only look at away goals when the totals match. Think of a referee following a fixed checklist: total goals first, away goals second, shootout third. The whole decision is four additions and a few comparisons, so it costs constant time. Scanning the four numbers is the only real work.

## Why It Works

1. Each team plays one home and one away match, so its aggregate is home goals plus away goals.
2. The rules rank aggregate goals above away goals, which the comparison order follows.
3. Away goals are read from the match where the team was the visitor: `s1` for Esteghlal, `p2` for Persepolis.
4. Equal aggregates and equal away goals leave no rule to break the tie, so the verdict is `Penalty`.

| Term | Meaning |
|---|---|
| `persepolisHomeGoals` | `p1`, Persepolis goals at home |
| `persepolisAwayGoals` | `p2`, Persepolis goals away |
| `esteghlalHomeGoals` | `s2`, Esteghlal goals at home |
| `esteghlalAwayGoals` | `s1`, Esteghlal goals away |
| `persepolisAggregate` | `p1 + p2` |
| `esteghlalAggregate` | `s2 + s1` |

The first sample runs through the checklist as:

```
p1=3 s1=0 s2=2 p2=1
Persepolis aggregate 3+1=4, Esteghlal aggregate 2+0=2
4 > 2, so the first rule already decides: Persepolis
```

## Code

**Input and hand scanner.** This block loads stdin and reads the four integers.

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

One readLine loop collects all input bytes.
The scanner skips whitespace between digits.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block holds the verdict line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Decision ladder.** This block applies the two rules in order.

```nim
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

The four reads follow the statement order exactly.
The `elif` chain reaches away goals only when aggregates tie.
Each verdict costs one string append.

## Complexity

The cost splits into reading four numbers and one comparison chain.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Decision | constant | constant |
| Output | one small write | buffer |

| Measure | Big O |
|---|---|
| Time | O(1) |
| Space | O(1) |

Nothing scales with the input: the program always reads four integers and compares two pairs of sums.
