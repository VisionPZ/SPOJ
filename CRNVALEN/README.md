# CRNVALEN — The Valentine Confession (SPOJ)

<https://www.spoj.com/problems/CRNVALEN/>

## Problem

Each girl reports how many of the other girls double date. Let D be the unknown count of double daters. A double dater reports D - 1, and a single dater reports D. Recover D or report invalid data.

Input starts with the test count T. Each case has n, then n reports on one line. Output one integer per case: the count D, or -1 when no count explains the reports.

| item | bound |
|---|---|
| test count T | 1 to 100 |
| girls n | 2 to 10000 |
| each report | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
1
3
2 2 2
```

Sample output:

```
3
```

## Idea

Treat the reports as two labeled piles, like sorting coins into heads and tails. The larger pile value is the answer, and the smaller pile value sits exactly one below it.

Scanning the reports once finds both values and their frequencies. Testing the two shapes of valid data costs constant time per case. A brute search over every possible D would cost O(n^2) per case. Takeaway: one scan finds the two report values, and two checks decide validity.

## Why It Works

1. A double dater excludes herself from her own report, so she says D - 1.
2. A single dater counts every double dater, so she says D.
3. Reports therefore take at most two adjacent values.
4. When all reports agree on value v, either all girls are single and v = 0, or all are double and v = n - 1.
5. With two values, the lower value must be D - 1 and its frequency must equal D.

| term | meaning |
|---|---|
| `highestReport` | larger of the two observed report values |
| `nextReport` | smaller of the two observed report values |
| `highestCount` | number of girls giving `highestReport` |
| `nextCount` | number of girls giving `nextReport` |
| `extraReport` | flag for a third distinct report value |

A script with reports 0 1 1 gives highest 1 twice and next 0 once. Next equals highest minus 1, and nextCount equals highest, so the answer is 1. This matches a scenario with one double dater.

The two uniform cases use the boundary identities v = 0 and v = n - 1. No rounding appears, and all counts fit in 64 bits.

## Code

**Input reader.** The whole stream is loaded and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The reader appends a newline after every input line.
`nextInt` skips all non-digit separators.
`appendOutput` flushes the buffer once it grows large.

**Count scan.** Each report updates at most two tracked values.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let girlCount = nextInt(inputData, scanPos)
  var highestReport = -1'i64
  var nextReport = -1'i64
  var highestCount = 0'i64
  var nextCount = 0'i64
  var extraReport = false
  for girlIndex in 0 .. girlCount - 1:
    let report = nextInt(inputData, scanPos)
    if report > highestReport:
      nextReport = highestReport
      nextCount = highestCount
      highestReport = report
      highestCount = 1
    elif report == highestReport:
      highestCount += 1
    elif report > nextReport:
      nextReport = report
      nextCount = 1
    elif report == nextReport:
      nextCount += 1
    else:
      extraReport = true
  var answer = -1'i64
  if highestCount == girlCount:
    if highestReport == 0:
      answer = 0
    elif highestReport == girlCount - 1:
      answer = girlCount
  elif not extraReport and nextReport == highestReport - 1 and nextCount == highestReport:
    answer = highestReport
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A larger report displaces the old top value into `nextReport`.
A third distinct value sets `extraReport` and forces -1.
The final line writes one answer for each test case.

## Complexity

Each case scans its reports once and writes one line.

| phase | time | space |
|---|---|---|
| read all input | one pass over the stream | one input string |
| report scan | one pass over n reports | five counters |
| output | one buffered write | one output string |

| measure | Big O |
|---|---|
| time | O(T * n) |
| space | O(L) for input length L |

Trying every possible D for every case would multiply the work by n. Takeaway: two tracked values and their counts settle each case in one pass.
