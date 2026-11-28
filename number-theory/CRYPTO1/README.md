# CRYPTO1 — The Bytelandian Cryptographer (Act I) (SPOJ)

<https://www.spoj.com/problems/CRYPTO1/>

## Problem

Each input value is a timestamp squared modulo a large prime. Recover the original timestamp and print it as a GMT date and time.

Input: one encrypted integer per line, continuing to the end of the stream.

Output: the hidden GMT date and time in the 26-character form, one line per value.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Encrypted values | one or more lines |
| Modulus | 4000000007, a prime |
| True timestamps | between 1970 and 2030 |
| Guard value | 1900000000 seconds |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The guard value sits past the year 2030, so it separates the two square roots.

The sample input and output:

```
1749870067
```

```
Sun Jun 13 16:20:39 2004
```

## Idea

Undo the square with a modular square root, like opening a padlock with the one key that fits. The modulus is prime and leaves remainder 3 when divided by 4, so one exponentiation finds a root.

The program raises each encrypted value to the power `(p + 1) / 4` modulo p. That gives one root r, and the other is `p - r`. The date window selects the real timestamp.

Each value costs O(log² p) modular operations, well under a thousand steps. Trying every second from 1970 to 2030 would cost about 1.9 billion trials.

Exponentiation replaces the whole search.

## Why It Works

The prime has a special shape that makes square roots easy.

1. For a prime p with `p mod 4 = 3`, the value `a^((p+1)/4)` is a square root of a modulo p.
2. Squaring that exponent gives `(p + 1) / 2`, and Euler's criterion turns `a^((p-1)/2)` into 1.
3. The two roots are r and `p - r`. Only one lands inside the 1970 to 2030 window.
4. Products of two residues can exceed 64 bits, so multiplication adds under the modulus by repeated doubling.

The constants and helpers are as follows:

| Term | Meaning |
| --- | --- |
| `4000000007` | prime modulus p, with `p mod 4 = 3` |
| `1000000002` | the exponent `(p + 1) / 4` |
| `cipherModulus - rootValue` | the other root |
| `lastPossibleSecond` | guard value 1900000000 |
| `clockLine` | converts seconds since 1970 to a date string |

The year loop steps forward from 1970, and the month loop steps within that year.

A script checks both roots of the sample value 1749870067:

| Candidate | Timestamp | GMT date | In range |
| --- | --- | --- | --- |
| r | 2912856368 | Fri Apr 21 14:46:08 2062 | no |
| p - r | 1087143639 | Sun Jun 13 16:20:39 2004 | yes |

The program prints the 2004 date.

## Code

**Constants and tables.** The modulus, exponent, and calendar words are fixed values.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const cipherModulus: int64 = 4000000007
const rootExponent: int64 = 1000000002
const lastPossibleSecond: int64 = 1900000000

var weekdayName = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
var monthName = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
```

`rootExponent` is `(p + 1) / 4`. The three arrays map small indexes to words and month lengths. These values cost no work at run time.

**Input.** The whole stream is read into one string before any decoding.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
```

The loop runs to the end of the file. The index i tracks the current byte. One pass over the input supplies every value.

**Digit scanner.** The scanner builds a 64-bit integer by index.

```nim
proc nextInt(): int64 =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value: int64 = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(int(inputData[i]) - 48)
    i = i + 1
  return value
```

No substring or parse call runs here. The leading skip absorbs spaces and newlines. Each value costs one pass over its digits.

**Modular arithmetic.** Multiplication doubles under the modulus, and power walks the exponent bits.

```nim
proc multiplyMod(firstValue: int64, secondValue: int64): int64 =
  var doublingValue = firstValue
  var runningValue: int64 = 0
  var walker = secondValue
  while walker > 0:
    if (walker and 1) != 0:
      runningValue = (runningValue + doublingValue) mod cipherModulus
    doublingValue = (doublingValue + doublingValue) mod cipherModulus
    walker = walker shr 1
  return runningValue

proc powerMod(baseValue: int64): int64 =
  var multiplier = baseValue
  var answer: int64 = 1
  var walker = rootExponent
  while walker > 0:
    if (walker and 1) != 0: answer = multiplyMod(answer, multiplier)
    multiplier = multiplyMod(multiplier, multiplier)
    walker = walker shr 1
  return answer
```

`multiplyMod` runs about 30 doublings and reduces after each addition. `powerMod` walks about 30 exponent bits. Each set bit calls `multiplyMod`, so the pair costs O(log² p).

**Calendar helpers.** Leap years and month lengths turn a day count into a date.

```nim
proc leapFlag(year: int64): int64 =
  if year mod 4 == 0 and (year mod 100 != 0 or year mod 400 == 0): return 1
  return 0

proc daysInYearOf(year: int64): int64 =
  return 365 + leapFlag(year)

proc daysInMonthOf(year: int64, j: int): int64 =
  var baseLength = int64(monthLength[j])
  if j == 1 and leapFlag(year) == 1: baseLength = 29
  return baseLength

proc isLeapYear(year: int64): bool =
  return leapFlag(year) == 1
```

`leapFlag` applies the 4, 100, and 400 rules. `daysInYearOf` and `daysInMonthOf` return lengths. Each call costs constant work.

**Two-digit format and date line.** The date line assembles the 26-character string.

```nim
proc padTwo(numberValue: int64): string =
  if numberValue < 10: return "0" & $numberValue
  return $numberValue

proc clockLine(timeStamp: int64): string =
  var dayCount = timeStamp div 86400
  var secondsOfDay = timeStamp mod 86400
  var hourValue = secondsOfDay div 3600
  var minuteValue = (secondsOfDay mod 3600) div 60
  var secondValue = secondsOfDay mod 60
  var year: int64 = 1970
  var remainingDays = dayCount
  while true:
    var daysInYear = daysInYearOf(year)
    if remainingDays >= daysInYear:
      remainingDays = remainingDays - daysInYear
      year = year + 1
    else:
      break
  var j = 0
  var daysInMonth = daysInMonthOf(year, j)
  while remainingDays >= daysInMonth:
    remainingDays = remainingDays - daysInMonth
    j = j + 1
    daysInMonth = daysInMonthOf(year, j)
  var dayOfMonth = remainingDays + 1
  var result: string
  result.add weekdayName[int(dayCount mod 7)]
  result.add " "
  result.add monthName[j]
  result.add " "
  if dayOfMonth < 10:
    result.add " "
    result.add $dayOfMonth
  else:
    result.add $dayOfMonth
  result.add " "
  result.add padTwo(hourValue)
  result.add ":"
  result.add padTwo(minuteValue)
  result.add ":"
  result.add padTwo(secondValue)
  result.add " "
  result.add $year
  return result
```

`padTwo` adds a leading zero below ten. The year loop walks forward from 1970, then the month loop walks within that year. `dayOfMonth` adds one because remaining days start at zero.

**Driver.** Each value yields a root, a timestamp, and one date line.

```nim
var outputBuffer: string
while true:
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  if i >= inputData.len: break
  var encryptedValue = nextInt()
  var rootValue = powerMod(encryptedValue)
  var timeStamp = rootValue
  if timeStamp > lastPossibleSecond: timeStamp = cipherModulus - rootValue
  outputBuffer.add clockLine(timeStamp)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The outer loop runs until the input is spent. `cipherModulus - rootValue` selects the root inside the date window. The buffer flushes every 128 KiB.

## Complexity

Each value pays for one modular exponentiation and one calendar conversion.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| One root | O(log² p) modular operations | O(1) |
| One date line | about 60 year steps | O(1) |
| Output | one write per 128 KiB block | 128 KiB |
| Total per value | O(log² p) | O(1) |

Work per value does not depend on the number of values.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(log² p) per encrypted value |
| Space | O(1) per value |

Trying every second from 1970 to 2030 would cost about 1.9 billion trial multiplications.
