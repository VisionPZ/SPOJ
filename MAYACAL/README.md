## Problem

Read a Calendar Round date and print every matching Long Count date in baktuns 8 and 9. A date holds a Tzolkin day number and name, then a Haab day number and month name. Print the answers in ascending order, or print 0 when the date cannot occur. The Long Count date 8.0.0.0.0 fell on 9 Ajaw 3 Sip.

| item | bound |
|---|---|
| data sets | 1 to 30 |
| Tzolkin day number | 1 to 13 |
| Haab day number | 1 to 20, or 1 to 5 in Wayeb |
| Long Count range | 8.0.0.0.0 through 9.19.19.17.19 |
| judge limit | 3000 ms, 1536 MB |

The range holds 288,000 consecutive days, and every answer must lie inside it.

## Idea

Both parts of the Calendar Round repeat. The Tzolkin repeats every 260 days, and the Haab repeats every 365 days. Together they repeat every 18,980 days. Turn the query into one position in each cycle. Find the first day where both positions match, then advance by 18,980 days while the day stays in range.

Cost per query: test at most 73 candidate starts, then write one line per answer.

## Why It Works

The Tzolkin position fixes the day name modulo 20 and the day number modulo 13. Because 2 is the inverse of 20 modulo 13, the formula below returns the only position in 0 through 259. The Haab position counts days from the start of the year. Month starts sit 20 days apart, and Wayeb starts at day 360.

| term | meaning |
|---|---|
| `tzolkinNameIndex` | day name, numbered from 0 |
| `modNorm((tzolkinNumber - 1 - tzolkinNameIndex) * 2, 13)` | offset into this name run |
| `haabMonthStarts[haabMonthIndex] + haabNumber - 1` | day counted from the year start |
| `referenceResidue` | position gap of the known reference date |

The two cycles can agree only when their positions differ by 2 modulo 5. The reference positions are 99 and 42, and their gap is 57, which leaves remainder 2. A query with a different gap is illegal.

Now find the first matching day. The Tzolkin match fixes the day offset modulo 260. The Haab match fixes it modulo 365. Candidate offsets are `deltaTzolkin + cycleTzolkin * stepCount` for `stepCount` from 0 to 72. The unique candidate that leaves `deltaHaab` modulo 365 gives the first day. Later matches sit exactly 18,980 days apart.

This trace uses the sample date 3 Lamat 6 Pax.

| quantity | value |
|---|---|
| Lamat index, Pax index | 7, 15 |
| Tzolkin position, Haab position | 67, 305 |
| position gap modulo 5 | 2 |
| `deltaTzolkin`, `deltaHaab` | 228, 263 |
| `stepCount` | 24 |
| first day | 1,158,468 |
| answer count | 15 |

The first day is 8.0.17.17.8, and the last is 9.17.16.1.8.

## Code

**Constants and name lookup.**

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

`referenceDay` is 8 times 144,000. `modNorm` keeps remainders non-negative for negative inputs. Name lookup scans at most 20 names.

**Byte readers.**

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

Each reader stops at the first byte outside its class. The word reader reuses its buffer, so it allocates no token strings. Cost: one pass over the bytes each call skips.

**Long Count writer.**

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

Five divisions split the absolute day into place values. The writer builds one line and appends it to the shared buffer. Cost: one formatted line per answer.

**One query.**

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

The first two conditions reject numbers and names outside the spec. The residue check rejects impossible Calendar Round pairs. The loop has 73 steps because 18,980 divided by 260 is 73.

**Driver and buffered output.**

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

The read loop reaches the end of input, so one pass loads all bytes. The buffer keeps at most one block before a write.

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

The loop adds 18,980 days per answer and stops at the last legal day. `setLen(0)` reuses the buffer after each flush. The final write covers the tail.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over the input bytes | input bytes |
| one query | at most 73 candidate steps | constant |
| output | one write per 256 KiB block | 256 KiB |
| all data sets | O(73 times the set count plus the answer count) | input plus one block |

Work grows with the number of answers, not with the size of the Long Count range.

| measure | form |
|---|---|
| time | O(d) for d data sets and their answers |
| space | O(1) working storage |

Simulating all 288,000 days for each query costs O(288,000 times d) time and gives the same answers.
