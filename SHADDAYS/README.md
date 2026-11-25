# SHADDAYS — Add Days (SPOJ)

<https://www.spoj.com/problems/SHADDAYS/>

## Problem

Each query gives a valid Gregorian date and a number of days. The task is to print the date reached by moving forward that number of days.

Input starts with a query count. Each query then holds a date in dd-mm-yyyy form, followed by one day count. Output holds one date per query in the same form.

| Item | Bound |
|---|---|
| Query count | 1 ≤ t ≤ 100 |
| Days to add | 1 ≤ x ≤ 9999 |
| Date form | valid dd-mm-yyyy Gregorian date |
| Judge limit | 1000 ms, 1536 MB |

The day count per query drives a direct calendar conversion.

The sample case:

```
3
10-12-2020
12
29-02-2016
1010
03-12-2019
120
```

```
22-12-2020
05-12-2018
01-04-2020
```

## Idea

Convert a date into one day number, add the offset, then convert back. Think of a ruler marked by days: a date is a tick, and adding days slides along it. The program uses civil calendar conversion formulas, with constant work per query. Stepping one day at a time costs up to 9999 steps per query. Two arithmetic conversions replace repeated calendar stepping.

## Why It Works

1. A civil date maps to an integer day number through era and year-of-era formulas.
2. Both conversions respect leap years and the full 400-year Gregorian cycle.
3. Adding the offset changes only the day number, never the calendar rules.
4. The inverse formula returns year, month, and day from that day number.
5. Padding writes two digits for day and month, four for year.

| Term | Meaning |
|---|---|
| `daysFromCivil` | converts a date into one day number |
| `civilFromDays` | converts a day number back into a date |
| `era` | one 400-year block in the Gregorian cycle |
| `paddedNumber` | writes a number with leading zeros |
| `startingDayNumber` | day number of the query's start date |

The two conversions handle all calendar rules in arithmetic.

A script-traced example from `gen.py`:

```
start 29-02-2016
add 1010 days
result 05-12-2018
```

The trace matches the second sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects all input bytes.
The scanner skips the dashes in a date without special handling.
Scanning costs one pass over the consumed characters.

**Calendar conversions.** This block maps dates to day numbers and back.

```nim
proc daysFromCivil(yearValue, monthValue, dayValue: int): int64 =
  var adjustedYear = int64(yearValue)
  let monthNumber = int64(monthValue)
  let dayNumber = int64(dayValue)
  if monthNumber <= 2:
    adjustedYear -= 1
  let era = adjustedYear div 400
  let yearOfEra = adjustedYear - era * 400
  let shiftedMonth = monthNumber + (if monthNumber > 2: -3 else: 9)
  let dayOfYear = (153 * shiftedMonth + 2) div 5 + dayNumber - 1
  let dayOfEra = yearOfEra * 365 + yearOfEra div 4 - yearOfEra div 100 + dayOfYear
  return era * 146097 + dayOfEra - 719468

proc civilFromDays(dayCount: int64): tuple[yearValue: int, monthValue: int, dayValue: int] =
  let shiftedDays = dayCount + 719468
  let era = shiftedDays div 146097
  let dayOfEra = shiftedDays - era * 146097
  let yearOfEra = (dayOfEra - dayOfEra div 1460 + dayOfEra div 36524 - dayOfEra div 146096) div 365
  var calendarYear = yearOfEra + era * 400
  let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra div 4 - yearOfEra div 100)
  let shiftedMonth = (5 * dayOfYear + 2) div 153
  let calendarDay = dayOfYear - (153 * shiftedMonth + 2) div 5 + 1
  var calendarMonth = shiftedMonth + (if shiftedMonth < 10: 3 else: -9)
  if calendarMonth <= 2:
    calendarYear += 1
  return (int(calendarYear), int(calendarMonth), int(calendarDay))

proc paddedNumber(value: int, width: int): string =
  var text = $(value)
  while text.len < width:
    text = "0" & text
  return text
```

Both conversions run in constant time.
The shifted month avoids a separate leap-year table.
Padding preserves the dd-mm-yyyy output shape.

**Buffered output.** This block collects finished date lines.

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

**Query loop.** This block converts, adds, and formats every answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let startDay = nextInt(inputData, scanPos)
  let startMonth = nextInt(inputData, scanPos)
  let startYear = nextInt(inputData, scanPos)
  let daysToAdd = nextInt(inputData, scanPos)
  let startingDayNumber = daysFromCivil(startYear, startMonth, startDay)
  let resultDate = civilFromDays(startingDayNumber + int64(daysToAdd))
  appendOutput(paddedNumber(resultDate.dayValue, 2) & "-" & paddedNumber(resultDate.monthValue, 2) & "-" & paddedNumber(resultDate.yearValue, 4) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly t times.
The int64 sum prevents overflow across the allowed years.
Each answer costs two conversions and one buffer append.

## Complexity

The cost splits into input, one conversion pair per query, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Conversions | O(1) per query | constant |
| Output | one write per 128 KiB block | block buffer |

Every phase stays small at t = 100.

| Measure | Big O |
|---|---|
| Time | O(t) |
| Space | O(N) for the input buffer |

Stepping day by day costs O(sum of x), up to 999000 steps; conversion stays constant.
