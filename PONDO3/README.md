# PONDO3 — Pondo Three (SPOJ)
<https://www.spoj.com/problems/PONDO3/>

## Problem

There are n Pondo and x bomboos. One bomboo keeps Pondo i alive for d_i days, and every Pondo must eat. Share the bomboos so that all Pondo survive the same number of days, as large as possible. Report that number of days.

The first line gives n and x. The next line or lines give the n survival lengths. Print one integer, the maximum number of days.

| Constraint | Value |
| --- | --- |
| Pondo count n | positive integer |
| Bomboo count x | positive integer |
| Survival length d_i | positive integer |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

A Pondo that eats k bomboos survives k times d_i days.

The first sample pair follows byte for byte.

```
3 17
1 2 5
```

```
10
```

Ten days need 10, 5 and 2 bomboos, which sum to 17.

## Idea

Sharing the bomboos is like filling glasses of different widths to the same level: raise the common level until the supply runs out. The program guesses a day count and checks whether the bomboos cover it. One check divides the guess by each survival length and rounds up. Each guess costs O(n), and a binary search needs O(log range) guesses. Trying every possible day count can take hundreds of billions of checks. Search the day count, and test each guess with rounded divisions.

## Why It Works

1. A Pondo with survival length d_i needs ceil(T / d_i) bomboos to live T days.
2. The total need at day count T is the sum of those n rounded values.
3. A day count is feasible exactly when that total is at most x.
4. If T is feasible, every smaller count is also feasible.
5. Monotonicity allows binary search over the day count.
6. The search cap x times the largest survival length is always feasible.

The terms below describe the search state.

| Term | Meaning |
| --- | --- |
| `lowDays` | largest day count known to be feasible |
| `highDays` | smallest day count known to be infeasible, used as a cap |
| `midDays` | day count under test |
| `neededBomboo` | bomboos required by the current test |
| `survivalDays` | one survival length per Pondo |

The feasibility loop stops early once the needed count passes x.

A script check of the first sample tests two day counts.

| Day count T | ceil(T / 1) | ceil(T / 2) | ceil(T / 5) | Bomboos needed | Feasible |
| --- | --- | --- | --- | --- | --- |
| 10 | 10 | 5 | 2 | 17 | yes |
| 11 | 11 | 6 | 3 | 20 | no |

The largest feasible count is 10. Multiplying the largest survival length by x keeps every cap safe, and all products use `int64`.

## Code

**Input and scanner.** The first two values give the Pondo count and the bomboo supply.

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

The scanner treats spaces and line breaks alike. It builds each value from its digits.

**Buffered output.** The answer leaves through one shared string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One final flush emits the single integer. The buffer never writes per guess.

**Day-count search.** The driver loads the survival lengths, then binary searches the answer.

```nim
let pondoCount = nextInt(inputData, scanPos)
let bombooCount = int64(nextInt(inputData, scanPos))
var survivalDays = newSeq[int64](pondoCount)
var longestLife: int64 = 0
for pondoIndex in 0 .. pondoCount - 1:
  survivalDays[pondoIndex] = int64(nextInt(inputData, scanPos))
  if survivalDays[pondoIndex] > longestLife:
    longestLife = survivalDays[pondoIndex]
var lowDays: int64 = 0
var highDays = bombooCount * longestLife
while lowDays < highDays:
  let midDays = (lowDays + highDays + 1) div 2
  var neededBomboo: int64 = 0
  for pondoIndex in 0 .. pondoCount - 1:
    neededBomboo += (midDays + survivalDays[pondoIndex] - 1) div survivalDays[pondoIndex]
    if neededBomboo > bombooCount:
      break
  if neededBomboo <= bombooCount:
    lowDays = midDays
  else:
    highDays = midDays - 1
appendOutput($lowDays)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Adding the divisor minus one rounds each division up. The rounded-up midpoint prevents an endless loop. An early break avoids summing useless terms after the supply is exceeded.

## Complexity

Each binary-search step scans all Pondo once.

| Phase | Time | Space |
| --- | --- | --- |
| read input | one pass over n lengths | one length array |
| one feasibility test | one pass over n lengths | constant |
| binary search | O(log range) tests | constant |
| output | one line | block buffer |

The logarithm counts the bits in the maximum possible day count.

| Measure | Big O |
| --- | --- |
| time | O(n log(x times d_max)) |
| space | O(n) |

Testing each day count up to the answer costs O(answer times n), which is far larger. One monotone test and a binary search give the maximum shared survival time.
