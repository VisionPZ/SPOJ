# BIPCSMR16 — Team Building (SPOJ)

<https://www.spoj.com/problems/BIPCSMR16/>

## Problem

A programming club has students from the first, second, and third years. A team has three members and all three may not come from the same year. Given the head counts of the three years, find the largest number of valid teams.

The input starts with the test count `T`. Each following line holds three positive integers `X`, `Y`, and `Z`, the counts for the first, second, and third years. Print one integer per case: the maximum number of teams.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 10000 |
| Year counts `X`, `Y`, `Z` | 1 to 2000000000 |
| Judge limit | 1000 ms |
| Memory | 1536 MB |

The large counts make a per-student simulation impossible, so the answer must come from a formula.

The sample input:

```
2
1 2 3
1 12 3
```

The sample output:

```
2
4
```

## Idea

Like seating guests at tables of three, avoid placing three people from one year at the same table. Spend the most crowded year two at a time and use the other years to fill the seats. For `k` teams, a year with count `c` supplies at most `2k` students, and all three years together supply `3k`.

Let `total` be `X + Y + Z`, `largest` the biggest count, and `others` the sum of the other two counts. If `2 * (total div 3)` is at least `largest`, then `total div 3` teams are possible. Otherwise each team needs a student from outside the largest year, so the answer is `min(others, (largest - 1) div 2)`.

Each case costs a fixed number of integer operations, independent of the head counts.

## Why It Works

1. A valid team has at most two members from any single year.
2. For `k` teams, a year with `c` students can fill at most `min(c, 2k)` seats.
3. Teams exist exactly when `sum of min(count, 2k) >= 3k` over the three years.
4. If the largest group fits within `2k`, the total student count is the only limit.
5. Otherwise `k` cannot exceed `others`, and the largest year cannot supply more than two per team, giving `(largest - 1) div 2`.

| Term | Meaning |
|---|---|
| `totalStudents` | the sum of the three year counts |
| `largestGroup` | the maximum of the three year counts |
| `otherStudents` | total minus the largest group |
| `thirdOfTotal` | `totalStudents div 3`, the student-count ceiling |
| `halfCap` | `(largestGroup - 1) div 2`, the two-per-team ceiling |

The smaller of the last two ceilings gives the answer when the largest group dominates.

A script-generated view of the sample cases:

```
(1, 2, 3)  total 6  largest 3   others 3   third 2  2*2 >= 3 -> 2
(1, 12, 3) total 16 largest 12  others 4   third 5  2*5 < 12 -> min(4, 5) = 4
```

Both rows match the sample output.

## Code

**Input and scanner.** All lines enter one string and the scanner reads each integer.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The newline after each line keeps adjacent triples separate. Only positive counts occur.

**Output buffer.** One buffer collects the per-case answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Flushing by size keeps the write count small for 10000 cases. The final write clears the remaining bytes.

**Team count.** The closed form decides each answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let firstYearCount = int64(nextInt(inputData, scanPos))
  let secondYearCount = int64(nextInt(inputData, scanPos))
  let thirdYearCount = int64(nextInt(inputData, scanPos))
  let totalStudents = firstYearCount + secondYearCount + thirdYearCount
  let largestGroup = max(max(firstYearCount, secondYearCount), thirdYearCount)
  let otherStudents = totalStudents - largestGroup
  let thirdOfTotal = totalStudents div 3
  var teamCount: int64 = 0
  if 2 * thirdOfTotal >= largestGroup:
    teamCount = thirdOfTotal
  else:
    let halfCap = (largestGroup - 1) div 2
    if otherStudents < halfCap:
      teamCount = otherStudents
    else:
      teamCount = halfCap
  appendOutput($(teamCount))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`int64` holds totals up to six billion, which exceed signed 32-bit integers. The two branches cover every possible distribution of students.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| One case | constant integer arithmetic | constant |
| Output | one write per 128 KiB block | one buffer |

No operation depends on the size of a year count.

| Measure | Big O |
|---|---|
| Time | O(T) after reading input |
| Space | O(input bytes) |

Simulating each student or searching over team counts would take far longer for large years.
