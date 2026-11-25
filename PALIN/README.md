# PALIN — The Next Palindrome

## Problem

Given a positive integer `K`, output the smallest palindrome strictly larger than `K`. A palindrome reads the same in both directions, and numbers have no leading zeros.

| Item | Bound |
|---|---|
| Digits in `K` | 1,000,000 |
| Time limit | 2 s to 9 s, the judge table disagrees with itself |
| Memory limit | 1536 MB |
| Source limit | 50000 B |

`K` does not fit any machine integer. It is a string of digits.

Input quirks, from a checker against the original problem: blank lines, lines that are not numbers, spaces between digits, leading zeros, and no final newline. The program reads runs of digits and ignores every other character.

```
input:  808   2133
output: 818   2222
```

## Idea

A palindrome is fixed by its first half. So copy the left half onto the right half. That copy is the closest palindrome with the same left half. It is the answer unless it is not bigger than `K`. In that case raise the left half by one and mirror again.

Three parts:

1. Compare the number against itself from the middle outwards.
2. Bump the innermost left digit, carrying leftwards, or handle the case where the carry runs off the left edge.
3. Copy the left half onto the right half again.

The number lives inside one buffer that holds the whole input. Digits are never moved, so the work per test case costs no allocations.

## Why It Works

**A palindrome of n digits is chosen by its first ceil(n/2) digits.** The rest are copies. Two palindromes of the same length are ordered by value exactly as their left halves are ordered. So the next palindrome is the next possible left half, mirrored.

**Mirroring decides everything.** Copy the left half over the right half. The result beats `K` exactly when the original right half was not bigger than its reversed copy. Comparing from the middle outwards finds the first mismatched pair. If the left digit is smaller, the right half was bigger. The mirror is then too small, so the left half must go up. If the left digit is bigger, the mirror already beats `K`. If every pair matches, `K` is already a palindrome and the mirror equals `K`, so the left half must go up.

| Input | Pair found from the middle | Move | Answer |
|---|---|---|---|
| 2133 | 1 vs 3 | left half +1 at digit 2 | 2222 |
| 12932 | 2 vs 3 | left half +1 at digit 2 | 13031 |
| 12921 | all pairs equal | left half +1 at digit 2 | 13031 |
| 54321 | 4 vs 2 | left half already larger | 54345 |
| 9999 | all pairs equal | all 9s: 1, 3 zeros, 1 | 10001 |
| 9 | all pairs equal | all 9s: 1, 0 zeros, 1 | 11 |
| 0 | all pairs equal | left half +1 at digit 1 | 1 |

A one digit input needs no special case. The compare loop finds no pair, so it bumps the digit, and the mirror step copies zero characters.

**Why the bump belongs at the middle.** A digit `i` places from the middle moves the value by at least 10^i.
It also moves the palindrome further from `K`. So the smallest change that crosses `K` is a change to the middle. Bumping the innermost left digit is the cheapest change that raises the left half by one.

Carry turns each `9` into `0` while it moves left. Digits right of the carry point are already fixed. They never change. A carry off the left edge means every digit was `9`. The answer then has n+1 digits: `1`, n−1 zeros, then `1`. That case writes its own answer and skips the mirror step, because the carry overwrote the digits.

**No palindrome is skipped.** Every palindrome belongs to the mirror class of one left half.
Left halves order the same way their mirrors do, so the next left half gives the next palindrome.

## Code

Whole input in one buffer (`inputData`), output flushed every `flushBlockBytes` (256 KiB). `i` walks the buffer and never goes backwards.

Reading, then the test case count:

```nim
var inputData = ""
var line = ""
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'
```

```nim
var inputLength = inputData.len
var i = 0
var caseCount = 0
while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
  i = i + 1
while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
  caseCount = caseCount * 10 + (ord(inputData[i]) - 48)
  i = i + 1
```

Per test case: take the next run of digits in place, dropping leading zeros. `numberStart` is the first kept digit, `numberEnd` is one past the last. `numberLength` is the digit count with zeros dropped.

```nim
  while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var numberStart = i
  while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
    i = i + 1
  var numberEnd = i
  if numberStart == numberEnd:
    break
  while numberStart < numberEnd - 1 and inputData[numberStart] == '0':
    numberStart = numberStart + 1
  var numberLength = numberEnd - numberStart
```

`k` and `l` are the two middle positions, counted from `numberStart`. The loop walks them outwards to the first mismatched pair. `k < 0` means every pair matched, which means `K` is a palindrome.

```nim
  var k = numberLength div 2 - 1
  var l = numberLength - numberLength div 2
  while k >= 0 and inputData[numberStart + k] == inputData[numberStart + l]:
    k = k - 1
    l = l + 1
  var carried = false
  if k < 0 or inputData[numberStart + k] < inputData[numberStart + l]:
```

Bump the innermost left digit, carrying leftwards from `i`. A carry off the left edge means every digit was `9`; the answer is then `1`, n-1 zeros, `1`, written straight to `outputBuffer`.

```nim
    var i = numberStart + (numberLength - 1 - numberLength div 2)
    while i >= numberStart:
      if inputData[i] < '9':
        inputData[i] = chr(ord(inputData[i]) + 1)
        break
      inputData[i] = '0'
      i = i - 1
    if i < numberStart:
      outputBuffer.add '1'
      for i in 1 .. numberLength - 1:
        outputBuffer.add '0'
      outputBuffer.add "1\n"
      carried = true
```

Otherwise copy the left half onto the right half with `i`, then write the run.

```nim
  if not carried:
    var i = 0
    while i < numberLength div 2:
      inputData[numberEnd - 1 - i] = inputData[numberStart + i]
      i = i + 1
    outputBuffer.add inputData.substr(numberStart, numberEnd - 1)
    outputBuffer.add '\n'
```

```nim
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

## Complexity

Per test case with n digits:

- Compare: at most floor(n/2) character reads.
- Carry: at most ceil(n/2) writes.
- Mirror: floor(n/2) writes.
- Output: n bytes.

Total: O(n) character operations per case, O(total digits) over the input. Time O(total digits). Space O(total digits) for the input buffer and the output block. Both hold in the limits even when the input is 1 GB of digits, and no allocation happens per test case.
