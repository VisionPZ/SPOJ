# FUCT_IF_CHKDATE — Date validation (SPOJ)

<https://www.spoj.com/problems/FUCT_IF_CHKDATE/>

## Problem

Each test gives a month, a day, and a year. The task is to print "VALID" when that date exists in the Gregorian calendar and "INVALID" otherwise.

Input starts with a test count. Each test line holds three integers: month, day, year. Output holds one word per test.

| Item | Bound |
|---|---|
| Test count | 1 ≤ t ≤ 1000 |
| Month, day, year | integers; day can be negative |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
7
9 8 2018
3 39 2000
2 29 2018
20 -4 1998 
2 29 2000
7 31 1986 
11 31 2002
```

```
VALID
INVALID
INVALID
INVALID
VALID
VALID
INVALID
```

## Idea

Check the month first, then check the day against the length of that month. Think of tearing a page off a calendar: the page only exists for months 1 through 12, and the day must fit the printed rows of that page. The program keeps a twelve-entry table of month lengths and one leap-year rule, so each test costs a few comparisons. Testing every day of the year instead would need up to 365 checks per test.

## Why It Works

1. A month number outside 1..12 has no calendar page, so it is invalid at once.
2. Each month has a fixed length, stored in `daysOfMonth` at its month index.
3. Only February changes length: 29 days in a leap year, 28 otherwise.
4. A year is leap exactly when it is divisible by 400, or divisible by 4 but not 100.
5. A day is valid exactly when it lies in 1..month length.

| Term | Meaning |
|---|---|
| `daysOfMonth` | month length table, index 1..12 |
| `isLeapYear` | Gregorian leap-year rule |
| `monthLimit` | allowed largest day for the month |
| `isValidDate` | combines month, day, and leap checks |

The two arithmetic rules cover every calendar case.

A script-traced example from `gen.py`:

```
february 2018 limit 28 -> day 29 INVALID
february 2000 limit 29 -> day 29 VALID
```

The trace matches the third and fifth sample answers.

## Code

**Input and hand scanner.** This block loads stdin and reads signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var isNegative = false
  if position < data.len and data[position] == '-':
    isNegative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if isNegative:
    return -value
  return value
```

One readLine loop collects all input bytes.
The scanner stops at '-' so negative days parse correctly.
Scanning costs one pass over the consumed characters.

**Calendar rules.** This block stores month lengths and the leap rule.

```nim
const daysOfMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

proc isLeapYear(yearValue: int): bool =
  return yearValue mod 400 == 0 or (yearValue mod 4 == 0 and yearValue mod 100 != 0)

proc isValidDate(monthValue, dayValue, yearValue: int): bool =
  if monthValue < 1 or monthValue > 12:
    return false
  var monthLimit = daysOfMonth[monthValue]
  if monthValue == 2 and isLeapYear(yearValue):
    monthLimit += 1
  return dayValue >= 1 and dayValue <= monthLimit
```

The table index needs no bounds work because months are checked first.
Only February gets the leap-day bump.
Each check runs in constant time.

**Buffered output.** This block collects finished answer words.

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

**Test loop.** This block reads triples and prints one verdict each.

```nim
let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let monthValue = nextSignedInt(inputData, scanPos)
  let dayValue = nextSignedInt(inputData, scanPos)
  let yearValue = nextSignedInt(inputData, scanPos)
  if isValidDate(monthValue, dayValue, yearValue):
    appendOutput("VALID\n")
  else:
    appendOutput("INVALID\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly t times.
Each answer costs one table lookup and a few comparisons.

## Complexity

The cost splits into input, one constant-time check per test, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Date checks | O(1) per test | constant |
| Output | one write per 128 KiB block | block buffer |

Every phase stays small at t = 1000.

| Measure | Big O |
|---|---|
| Time | O(t) |
| Space | O(N) for the input buffer |

Stepping through all days of a year costs O(365) per test; the table check stays constant.
