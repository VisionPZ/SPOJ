# MCLONUM — Closest Number (SPOJ)

<https://www.spoj.com/problems/MCLONUM/>

## Problem

Two long decimal numbers give a target and a bag of digits. Rearrange the bag into an n-digit number with no leading zero, and report the smallest result not below the target and the largest result strictly below it.

Each input case uses two lines: first the target `A`, then the digit source `B`. Cases continue until end of input. For each case, print the least valid number at least `A`, or 0 if none exists, then the greatest valid number below `A`, or 0 if none exists.

The bounds from the statement:

| item | bound |
|---|---|
| digits n | 1 to 60 |
| input cases | as many as fit in the file |
| digits | no leading zero in A or B |
| judge limit | 1000 ms, 1536 MB |

Both answers use exactly the digits of B, once each.

Sample input:

```
3075
6604
3000203
4562454
```

Sample output:

```
4066
0
4244556
2655444
```

## Idea

Think of matching the target digit by digit, like turning a combination lock until one wheel can be moved. Keep the prefix equal for as long as possible, then make one decisive change and sort the remaining digits.

The algorithm stores the digit counts before each position. For the lower answer, it scans positions from right to left and takes the rightmost spot where a larger digit fits, then fills the tail ascending. The upper answer is symmetric: it takes the rightmost spot where a smaller digit fits, then fills the tail descending.

A rightmost change keeps the longest equal prefix, so it produces the closest number. Enumerating all permutations grows factorially and fails at 60 digits.

Try the target itself first when its digit multiset matches the bag exactly.

## Why It Works

1. A number exceeds the target at the first position where its digit is larger, provided all earlier digits match.
2. A number falls below the target at the first position where its digit is smaller, provided all earlier digits match.
3. A later change leaves a longer equal prefix, which always gives a closer number.
4. Among changes at one position, the smallest larger digit or largest smaller digit wins.
5. Sorting the remaining digits ascending or descending completes the closest choice.
6. If the digit multisets match, the target itself is valid and beats every larger arrangement.

The main terms and formulas:

| term | meaning |
|---|---|
| `availableDigits` | count of each digit in B |
| `snapshots` | digit counts before each position of A |
| `equalLength` | number of leading positions that can match A |
| `chosenDigit` | digit placed at the changed position |

The table names the state used by both builders.

The gen.py oracle enumerates sorted distinct permutations of B. On the first sample case it yields these values:

```
B = 6604 -> sorted digits 0 0 4 6 6
first permutation at least 3075 -> 4066
no permutation below 3075 starts without a zero -> 0
```

The trace matches the first two lines of the sample output.

## Code

**Input and scanner.** All lines are read once, and each number field is collected as text.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextField(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var field = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    field.add data[pos]
    pos += 1
  return field

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Reading fields keeps all 60 digits intact.
No integer conversion happens on the numbers themselves.
The loop pairs fields until input runs out.

**Lower builder.** The rightmost increase gives the smallest valid number at least A.

```nim
proc buildAtLeast(aNumber: string, availableDigits: seq[int], digitLength: int): string =
  var snapshots = newSeq[seq[int]](digitLength)
  var counts = availableDigits
  var equalLength = 0
  var stopped = false
  for position in 0 .. digitLength - 1:
    snapshots[position] = counts
    if stopped:
      continue
    let wantedDigit = int(aNumber[position]) - 48
    if counts[wantedDigit] > 0 and not (position == 0 and wantedDigit == 0):
      counts[wantedDigit] -= 1
      equalLength += 1
    else:
      stopped = true
  if equalLength == digitLength:
    return aNumber
  var position = equalLength
  if position >= digitLength:
    position = digitLength - 1
  while position >= 0:
    let beforeCounts = snapshots[position]
    let wantedDigit = int(aNumber[position]) - 48
    var candidateDigit = wantedDigit + 1
    var chosenDigit = -1
    while candidateDigit <= 9:
      if beforeCounts[candidateDigit] > 0 and not (position == 0 and candidateDigit == 0):
        chosenDigit = candidateDigit
        break
      candidateDigit += 1
    if chosenDigit >= 0:
      var builtNumber = ""
      for prefixIndex in 0 ..< position:
        builtNumber.add aNumber[prefixIndex]
      builtNumber.add chr(48 + chosenDigit)
      var remaining = beforeCounts
      remaining[chosenDigit] -= 1
      for digitValue in 0 .. 9:
        var repeatCount = remaining[digitValue]
        while repeatCount > 0:
          builtNumber.add chr(48 + digitValue)
          repeatCount -= 1
      return builtNumber
    position -= 1
  return "0"
```

A full match returns the target itself.
The clamp keeps the position inside the snapshots.
The tail is filled from 0 up to 9.

**Upper builder and driver.** The rightmost decrease gives the largest number below A.

```nim
proc buildBelow(aNumber: string, availableDigits: seq[int], digitLength: int): string =
  var snapshots = newSeq[seq[int]](digitLength)
  var counts = availableDigits
  var equalLength = 0
  var stopped = false
  for position in 0 .. digitLength - 1:
    snapshots[position] = counts
    if stopped:
      continue
    let wantedDigit = int(aNumber[position]) - 48
    if counts[wantedDigit] > 0 and not (position == 0 and wantedDigit == 0):
      counts[wantedDigit] -= 1
      equalLength += 1
    else:
      stopped = true
  var position = equalLength
  if position >= digitLength:
    position = digitLength - 1
  while position >= 0:
    let beforeCounts = snapshots[position]
    let wantedDigit = int(aNumber[position]) - 48
    var candidateDigit = wantedDigit - 1
    var chosenDigit = -1
    while candidateDigit >= 0:
      if beforeCounts[candidateDigit] > 0 and not (position == 0 and candidateDigit == 0):
        chosenDigit = candidateDigit
        break
      candidateDigit -= 1
    if chosenDigit >= 0:
      var builtNumber = ""
      for prefixIndex in 0 ..< position:
        builtNumber.add aNumber[prefixIndex]
      builtNumber.add chr(48 + chosenDigit)
      var remaining = beforeCounts
      remaining[chosenDigit] -= 1
      var digitValue = 9
      while digitValue >= 0:
        var repeatCount = remaining[digitValue]
        while repeatCount > 0:
          builtNumber.add chr(48 + digitValue)
          repeatCount -= 1
        digitValue -= 1
      return builtNumber
    position -= 1
  return "0"

while scanPos < inputData.len:
  let aNumber = nextField(inputData, scanPos)
  if aNumber.len == 0:
    break
  let bNumber = nextField(inputData, scanPos)
  if bNumber.len == 0:
    break
  var availableDigits = newSeq[int](10)
  for digitChar in bNumber:
    availableDigits[int(digitChar) - 48] += 1
  appendOutput(buildAtLeast(aNumber, availableDigits, aNumber.len))
  outputBuffer.add '\n'
  appendOutput(buildBelow(aNumber, availableDigits, aNumber.len))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The tail is filled from 9 down to 0.
A missing change yields 0 for that line.
Two buffered lines are emitted per input case.

## Complexity

Each builder scans at most 60 positions and ten digit slots.

| phase | time | space |
|---|---|---|
| input read | one pass over digit fields | one input string |
| digit counts | one pass over n digits | ten counters |
| builders | n positions times ten digit choices | n count snapshots |
| output | two lines per case | block buffer |

The snapshots dominate space, and the digit scan dominates time.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(n times 10) per answer |
| space | O(n times 10) |

Enumerating all permutations would cost factorial time and cannot handle 60 digits.

The snapshot method keeps the search linear in the digit count.
