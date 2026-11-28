# MAYACAL — Calendar of the Maya (SPOJ)

<https://www.spoj.com/problems/MAYACAL/>

## Problem

A Calendar Round date repeats every 18,980 days. Find every Long Count date in baktuns 8 and 9 that carries the same day name.

Read `d` data sets. Each gives a Tzolkin day number and name, then a Haab day number and month name. Print how many matching dates lie from 8.0.0.0.0 through 9.19.19.17.19, then one Long Count date per line in ascending order.

Print `0` when the date cannot occur.

The bounds and judge limits:

| Item | Bound |
| --- | --- |
| Data sets `d` | 1 to 30 |
| Tzolkin day number | 1 to 13 |
| Haab day number | 1 to 20, or 1 to 5 in Wayeb |
| Long Count range | 8.0.0.0.0 through 9.19.19.17.19 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The range holds 288000 consecutive days, and every answer must lie inside it.

The sample case:

```
2
3 Lamat 6 Pax
1 Ajaw 9 Chen
```

```
15
8.0.17.17.8
8.3.10.12.8
8.6.3.7.8
8.8.16.2.8
8.11.8.15.8
8.14.1.10.8
8.16.14.5.8
8.19.7.0.8
9.1.19.13.8
9.4.12.8.8
9.7.5.3.8
9.9.17.16.8
9.12.10.11.8
9.15.3.6.8
9.17.16.1.8
0
```

## Idea

Picture two wheels with different teeth: one turns every 260 days, the other every 365 days. They line up again after 18,980 days.

The program converts the query into one position in each wheel. A scan of at most 73 offsets finds the first day where both positions match. From there, each answer sits exactly 18,980 days later.

Cost per query: 73 candidate starts at most, then one line per answer. Simulating all 288000 days for each query costs far more.

## Why It Works

Five facts prove the alignment exact.

1. The Tzolkin position fixes the day name modulo 20 and the day number modulo 13. Because 2 is the inverse of 20 modulo 13, the formula returns the only position from 0 through 259.
2. The Haab position counts days from the year start. Month starts sit 20 days apart, and Wayeb starts at day 360.
3. The two wheels agree only when their positions differ by 2 modulo 5. The reference positions are 99 and 42, and the gap of 57 leaves remainder 2. A different gap makes the date illegal.
4. Candidate offsets have the form `deltaTzolkin + 260 * stepCount` for `stepCount` from 0 through 72. The one candidate leaving `deltaHaab` modulo 365 gives the first matching day.
5. Later matches sit 18980 days apart. The count is `(finalDay - firstDay) div 18980 + 1`, with `finalDay` set to 1439999.

The constants and their roles:

| Term | Meaning |
| --- | --- |
| `cycleTzolkin` | 260-day name and number wheel |
| `cycleHaab` | 365-day month wheel |
| `cycleCalendarRound` | 18980-day alignment of both wheels |
| `referenceDay` | absolute day of 8.0.0.0.0 |
| `finalDay` | absolute day of 9.19.19.17.19 |
| `referenceResidue` | required gap of 2 modulo 5 |
| `modNorm` | remainder helper keeping results non-negative |

These constants let one query resolve with a few arithmetic steps.

A script traces the first sample date, 3 Lamat 6 Pax:

```
Lamat index, Pax index    : 7, 15
Tzolkin, Haab positions   : 67, 305
position gap modulo 5     : 2
deltaTzolkin, deltaHaab   : 228, 263
stepCount                 : 24
first day                 : 1158468
answer count              : 15
```

The first day is 8.0.17.17.8 and the last is 9.17.16.1.8. The second sample date cannot occur, so its count is zero.

## Code

**Constants and lookup.** Fixed tables describe both wheels and the range.

```nim
const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  cycleTzolkin = 260
  cycleHaab = 365
  cycleCalendarRound = 18980
  referenceDay = 1152000
  finalDay = 1439999
  daysPerBaktun = 144000
  daysPerKatun = 7200
  daysPerTun = 360
  daysPerWinal = 20
  referenceTzolkinPosition = 99
  referenceHaabPosition = 42
  referenceResidue = 2
  tzolkinNames = ["Imix", "Ik", "Akbal", "Kan", "Chikchan", "Kimi", "Manik", "Lamat", "Muluk", "Ok", "Chuen", "Eb", "Ben", "Ix", "Men", "Kib", "Kaban", "Etznab", "Kawak", "Ajaw"]
  haabNames = ["Pohp", "Wo", "Sip", "Zotz", "Sek", "Xul", "Yaxkin", "Mol", "Chen", "Yax", "Sak", "Keh", "Mak", "Kankin", "Muan", "Pax", "Kayab", "Kumku", "Wayeb"]
  haabMonthLengths = [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 5]
  haabMonthStarts = [0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240, 260, 280, 300, 320, 340, 360]

proc modNorm(value, modulus: int): int =
  let wrapped = value mod modulus
  if wrapped < 0:
    result = wrapped + modulus
  else:
    result = wrapped

proc findNameIndex(names: openArray[string], word: string): int =
  result = -1
  for i in 0 .. names.len - 1:
    if names[i] == word:
      result = i
      return
```

`referenceDay` is 8 times 144000. `modNorm` keeps remainders non-negative for negative inputs. Name lookup scans at most 20 names.

**Byte readers.** Numbers and words are read straight from the buffer.

```nim
proc skipSeparators(inputData: string, i: var int) =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] == ' ' or inputData[i] == '\n' or inputData[i] == '\r' or inputData[i] == '\t'):
    inc i

proc scanNumber(inputData: string, i: var int): int =
  skipSeparators(inputData, i)
  var value = 0
  let dataLength = inputData.len
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (int(inputData[i]) - firstDigitValue)
    inc i
  result = value

proc scanWord(inputData: string, i: var int, wordBuffer: var string) =
  wordBuffer.setLen(0)
  skipSeparators(inputData, i)
  let dataLength = inputData.len
  while i < dataLength and ((inputData[i] >= 'A' and inputData[i] <= 'Z') or (inputData[i] >= 'a' and inputData[i] <= 'z')):
    wordBuffer.add inputData[i]
    inc i
```

Each reader stops at the first byte outside its class. The word reader reuses its buffer, so it allocates no token strings. Cost is one pass over the bytes each call skips.

**Long Count writer.** Five divisions split an absolute day into place values.

```nim
proc appendLongCountDate(outputBuffer: var string, dayNumber: int) =
  var remaining = dayNumber
  let baktunCount = remaining div daysPerBaktun
  remaining = remaining mod daysPerBaktun
  let katunCount = remaining div daysPerKatun
  remaining = remaining mod daysPerKatun
  let tunCount = remaining div daysPerTun
  remaining = remaining mod daysPerTun
  let winalCount = remaining div daysPerWinal
  let kinCount = remaining mod daysPerWinal
  outputBuffer.add($baktunCount & "." & $katunCount & "." & $tunCount & "." & $winalCount & "." & $kinCount & "\n")
```

The writer builds one line and appends it to the shared buffer. Cost is one formatted line per answer.

**One query.** Validation, alignment, and the candidate scan resolve a date.

```nim
  let tzolkinNumber = scanNumber(inputData, i)
  scanWord(inputData, i, tzolkinWord)
  let haabNumber = scanNumber(inputData, i)
  scanWord(inputData, i, haabWord)
  let tzolkinNameIndex = findNameIndex(tzolkinNames, tzolkinWord)
  let haabMonthIndex = findNameIndex(haabNames, haabWord)
  var occurrenceCount = 0
  var firstDay = 0
  if tzolkinNumber >= 1 and tzolkinNumber <= 13 and tzolkinNameIndex >= 0 and haabMonthIndex >= 0:
    let monthLength = haabMonthLengths[haabMonthIndex]
    if haabNumber >= 1 and haabNumber <= monthLength:
      let tzolkinPosition = tzolkinNameIndex + 20 * modNorm((tzolkinNumber - 1 - tzolkinNameIndex) * 2, 13)
      let haabPosition = haabMonthStarts[haabMonthIndex] + haabNumber - 1
      if modNorm(tzolkinPosition - haabPosition, 5) == referenceResidue:
        let deltaTzolkin = modNorm(tzolkinPosition - referenceTzolkinPosition, cycleTzolkin)
        let deltaHaab = modNorm(haabPosition - referenceHaabPosition, cycleHaab)
        var stepCount = 0
        while stepCount < 73 and (deltaTzolkin + cycleTzolkin * stepCount) mod cycleHaab != deltaHaab:
          inc stepCount
        if stepCount < 73:
          firstDay = referenceDay + deltaTzolkin + cycleTzolkin * stepCount
          if firstDay <= finalDay:
            occurrenceCount = (finalDay - firstDay) div cycleCalendarRound + 1
```

The first two conditions reject numbers and names outside the spec. The residue check rejects impossible pairs. The loop has 73 steps because 18980 divided by 260 is 73.

**Driver and buffered output.** The case loop writes the count and every date.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""
var i = 0
var tzolkinWord = ""
var haabWord = ""
let caseCount = scanNumber(inputData, i)
var j = 0
while j < caseCount:
```

The read loop reaches end of input, so one pass loads all bytes. The buffer keeps at most one block before a write.

**Answer lines.** The count and every date leave through one shared buffer.

```nim
  outputBuffer.add $occurrenceCount
  outputBuffer.add '\n'
  var k = 0
  while k < occurrenceCount:
    appendLongCountDate(outputBuffer, firstDay + cycleCalendarRound * k)
    inc k
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  inc j
if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The loop adds 18980 days per answer and stops at the last legal day. `setLen(0)` reuses the buffer after each flush. The final write covers the tail.

## Complexity

Work grows with the answer count, not with the Long Count range.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over the input bytes | input bytes |
| One query | at most 73 candidate steps | constant |
| Output | one write per 256 KiB block | one output block |
| All data sets | O(73 * d + answer count) | input plus one block |

Here `d` is the number of data sets.

| Measure | Big O |
| --- | --- |
| Time | O(d + answer count) |
| Space | O(1) working storage |

Simulating all 288000 days for each query costs O(288000 * d) time and gives the same answers.
