# MOZMCAN — Can Sharmeen Solve it? (SPOJ)

<https://www.spoj.com/problems/MOZMCAN/>

## Problem

A string and a target count arrive together, and the task finds a longest substring.
The substring must contain exactly X subsequences of `sms`.
If several substrings tie, choose the one with the smallest start.
If none works, print `-1`.
The first line holds the test count t, with 1 ≤ t ≤ 10.
Each later case gives a lowercase string of length n ≤ 1000 and an integer X ≤ 10⁸.
Print the chosen start and end positions as two numbers, or `-1`.

| Item | Bound |
|---|---|
| Test cases | 1 ≤ t ≤ 10 |
| String length | 1 ≤ n ≤ 1000 |
| Target | 0 ≤ X ≤ 10⁸ |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
2
smsmmsms 1
mmsm 1
```

```
1 5
-1
```

## Idea

Grow a window while its pattern count stays at or below the target.
Think of a camera frame sliding right, widening when the scene still fits.
Four counters describe the window: s count, m count, `smPairs`, and `msPairs`.
Appending an s closes every stored `sm` pair.
Removing the left character updates the same counters in constant time.
The right edge moves at most n times, so one case costs linear time.
A naive scan of all substrings would cost quadratic time.

## Why It Works

1. Extending a window never reduces its count of `sms`.
2. The right edge only moves right, so it advances at most n times.
3. `smPairs` counts ordered pairs with s before m inside the window.
4. `msPairs` counts ordered pairs with m before s inside the window.
5. Appending an s adds `smPairs` completed patterns and adds existing m to `msPairs`.
6. Removing a left s subtracts `msPairs` patterns and the pairs it started.
7. Removing a left m subtracts only the pairs it started, since no s precedes it.
8. Each left edge uses its widest valid window, then ties favor the earliest start.

| Term | Meaning |
|---|---|
| `total` | number of `sms` subsequences in the current window |
| `smPairs` | ordered pairs with s before m |
| `msPairs` | ordered pairs with m before s |
| `bestLength` | longest acceptable window found so far |

For `smsmmsms` with target 1, the left edge at position 0 stops at position 5.
The output `1 5` is the longest window with exactly one copy.

## Code

**Input and hand scanners.** This block loads input and reads integers and tokens.

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
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token
```

The read loop stores every input line in one string.
`nextInt` reads the case count and the target.
`nextToken` reads one lowercase string.

**Buffered output helper.** This block collects finished lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer writes to stdout once every 128 KiB.
A final write flushes any remaining bytes.

**Sliding window.** This block grows and shrinks the window and records the best answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let text = nextToken(inputData, scanPos)
  let target = int64(nextInt(inputData, scanPos))
  var insideS = 0
  var insideM = 0
  var smPairs = 0
  var msPairs = 0
  var total: int64 = 0
  var right = 0
  var bestLength = 0
  var bestStart = 0
  var bestEnd = 0
  for left in 0 ..< text.len:
    while right < text.len:
      let incoming = text[right]
      var growth = 0
      if incoming == 's':
        growth = smPairs
      if total + int64(growth) <= target:
        if incoming == 's':
          total += int64(smPairs)
          msPairs += insideM
          insideS += 1
        elif incoming == 'm':
          smPairs += insideS
          insideM += 1
        right += 1
      else:
        break
    if right > left and total == target:
      let length = right - left
      if length > bestLength:
        bestLength = length
        bestStart = left
        bestEnd = right - 1
    if right > left:
      let leaving = text[left]
      if leaving == 's':
        total -= int64(msPairs)
        smPairs -= insideM
        insideS -= 1
      elif leaving == 'm':
        msPairs -= insideS
        insideM -= 1
    else:
      right = left + 1
  if bestLength == 0:
    appendOutput "-1\n"
  else:
    appendOutput($(bestStart + 1) & " " & $(bestEnd + 1) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The right edge grows only while the count stays within the target.
Left removals reverse each counter change in constant time.
Ties keep the earliest start because left edges increase in order.

## Complexity

Each case moves the right edge once and the left edge once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scanning | one pass over integers and tokens | constant |
| Window scan | two passes over string positions | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(sum of string lengths) |
| Space | O(n) for the longest string |

A naive enumeration checks every substring and costs O(n²) per case.
The sliding window replaces that with one linear sweep.
