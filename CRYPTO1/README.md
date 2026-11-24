## Problem

Read encrypted numbers from standard input. Each number is a timestamp squared modulo 4000000007. Print the GMT date and time it hides, in standard 26-character form.

The statement and judge table give these bounds.

| item | bound |
|---|---|
| encrypted values | one or more lines of input |
| modulus | 4000000007, a prime |
| true timestamps | between 1970 and 2030 |
| guard value | 1 900 000 000 seconds |
| judge limit | 1000 ms, 1536 MB |

The guard value sits past the year 2030.

## Idea

Undo the square with a modular square root. The modulus is prime and leaves remainder 3 when divided by 4, so one exponentiation gives a root. The real timestamp is that root or its complement to the modulus, and the date window picks the right one.

Cost per value: about 30 exponent bits and 30 doubling steps each, under a thousand modular operations.

## Why It Works

For a prime p with p mod 4 = 3, the value a^((p+1)/4) is a square root of a modulo p. Squaring that exponent gives (p+1)/2, and Euler's criterion turns a^((p-1)/2) into 1.

The two roots are r and p - r. Only one lands in the 1970 to 2030 window. Products of two residues can exceed 64 bits, so `multiplyMod` doubles under the modulus instead of multiplying.

These constants form the root step.

| term | meaning |
|---|---|
| `4000000007` | prime modulus p, with p mod 4 = 3 |
| `1000000002` | the exponent (p+1)/4 |
| `cipherModulus - rootValue` | the other root, used when the first is too large |

Only one root falls inside the date window.

This trace uses the sample encrypted value 1749870067.

| candidate | timestamp | GMT date | in range |
|---|---|---|---|
| root | 2912856368 | Fri Apr 21 14:46:08 2062 | no |
| p - root | 1087143639 | Sun Jun 13 16:20:39 2004 | yes |

The program prints the 2004 date.

## Code

**Constants.**

```nim
import strutils

const flushBlockBytes = 1 shl 17
const cipherModulus: int64 = 4000000007
const rootExponent: int64 = 1000000002
const lastPossibleSecond: int64 = 1900000000
```

`rootExponent` is (p+1)/4, and `lastPossibleSecond` bounds the date. These values are fixed, not read per case. Cost: no work at run time.

**Calendar tables.**

```nim
var weekdayName = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
var monthName = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
```

`weekdayName` and `monthName` turn small indices into words. `monthLength` holds the common-year lengths. Cost: constant space.

**Input.**

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
```

The read loop runs to EOF, so all values land in one string. `i` tracks the current byte. Cost: one pass over the input.

**Digit scanner.**

```nim
proc nextInt(): int64 =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value: int64 = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(int(inputData[i]) - 48)
    i = i + 1
  return value
```

The scanner skips spacing and builds an `int64` by index. No substring or parse call runs here. Cost: one pass over each value's digits.

**Modular product.**

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
```

The loop runs while `walker > 0`, so it takes about 30 doublings. Each addition reduces under `cipherModulus`, which avoids a 64-bit overflow. Cost: O(log p).

**Modular power.**

```nim
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

`powerMod` walks the bits of `rootExponent`. Each set bit calls `multiplyMod` to keep products in range. Cost: O(log p) modular products.

**Calendar helpers.**

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

`leapFlag` applies the 4, 100, and 400 rules. `daysInYearOf` and `daysInMonthOf` turn a year and month into lengths. Cost: constant work per call.

**Two-digit format.**

```nim
proc padTwo(numberValue: int64): string =
  if numberValue < 10: return "0" & $numberValue
  return $numberValue
```

`padTwo` adds a leading zero below ten. The value still comes from a plain integer. Cost: one short string.

**Date line.**

```nim
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

The year loop walks forward from 1970, then the month loop walks within that year. `weekdayName[int(dayCount mod 7)]` picks the day name. `dayOfMonth` adds one because the remaining days start at zero. Cost: about 60 year steps.

**Driver.**

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

The outer loop runs until the input is spent. `cipherModulus - rootValue` selects the root inside the date window. The buffer flushes every 128 KiB. Cost: one date line per value.

## Complexity

Costs by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| one root | O(log p) doublings per bit | constant |
| one date line | about 60 year steps | constant |
| output | one write per 128 KiB block | 128 KiB |

The two nested loops cost O(log^2 p) per value.

Big O terms:

| measure | form |
|---|---|
| time | O(log^2 p) per encrypted value |
| space | O(1) per value |

Work per value does not depend on the number of values.

Trying each second from 0 to 2030 and squaring it costs about 1.9 * 10^9 trial multiplications. One exponentiation replaces that scan.
