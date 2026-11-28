# FUCT_FOR_PALIN — Palindrome number (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_PALIN/>

## Problem

Decide whether a number reads the same forward and backward.
The first input line holds the test count t.
Each next line holds one number n.
Ignore trailing zeros before making the decision.
Print YES for a palindrome and NO otherwise, one answer per line.

| Item | Bound |
|---|---|
| Tests | 1 ≤ t ≤ 1000 |
| Number | 0 ≤ n < 10⁹ |
| Judge limit | 1000 ms, 1536 MB |

Trailing zeros change the verdict, so they must go first.

The sample case:

```
8
19523
233332
859
11
819918000
10100
5252
23432
```

```
NO
YES
NO
YES
YES
YES
NO
YES
```

## Idea

Erase trailing zeros, then compare digits from both ends.
Think of mirrored bookends: match the outer pair, move inward, and repeat.
One mismatch settles the test, and matching pairs can be skipped.
Working on the token avoids converting the number to binary integer form.

## Why It Works

1. Trailing zeros add no value, so ignoring them preserves the intended number.
2. After erasure, `lastDigit` marks the final digit that still counts.
3. Comparing `leftDigit` with `lastDigit` checks the outermost remaining pair.
4. A mismatch sets the flag false and stops the test immediately.
5. A token of all zeros leaves no digits, which reads the same both ways.

| Term | Meaning |
|---|---|
| `numberToken` | decimal digits read as one word |
| `lastDigit` | index of the last digit after trailing zeros |
| `leftDigit` | index marching forward from the first digit |
| `isPalindrome` | flag that stays true while pairs match |
| `appendOutput` | buffered line writer |

The two indexes visit only half of the kept digits.

A script-traced example from `gen.py`:

```
819918000 819918 True
10100 101 True
5252 5252 False
```

The stripped tokens explain all three verdicts.

## Code

**Input and hand scanners.** This block loads stdin and reads integers or words.

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

The readLine loop stores every input line in one string.
`nextInt` gets the test count, and `nextToken` gets each number.
Both scanners advance a shared index.

**Buffered output.** This block collects verdict lines.

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

**Palindrome test loop.** This block strips zeros and compares digit pairs.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let numberToken = nextToken(inputData, scanPos)
  var lastDigit = numberToken.len - 1
  while lastDigit >= 0 and numberToken[lastDigit] == '0':
    lastDigit -= 1
  var isPalindrome = true
  var leftDigit = 0
  while leftDigit < lastDigit:
    if numberToken[leftDigit] != numberToken[lastDigit]:
      isPalindrome = false
      break
    leftDigit += 1
    lastDigit -= 1
  if isPalindrome:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The strip loop runs once per trailing zero.
The compare loop stops at the first mismatch.
The final write flushes the buffer at end of input.

## Complexity

The cost is one pass over tokens and one pass over kept digits per test.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Zero stripping | O(d) digits per test | output buffer |
| Pair comparison | O(d) digits per test | output buffer |
| Output | one write per 128 KiB block | block buffer |

With d at most ten, each test is tiny.

| Measure | Big O |
|---|---|
| Time | O(t · d) for d digits per test |
| Space | O(P) for P input bytes |

Trying every suffix alignment costs O(d²) per test, so two indexes win.
