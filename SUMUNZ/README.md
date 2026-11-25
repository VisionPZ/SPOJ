# SUMUNZ — Sum Until 0 (SPOJ)

<https://www.spoj.com/problems/SUMUNZ/>

## Problem

The input is one list of numbers written in bracket form, like `[3,6,7,2,0,4]`. Add up the elements that come before the first 0. If no 0 appears, add every element. If the list is empty, the answer is 0.

| Item | Bound |
|---|---|
| Input form | one bracketed list of integers |
| Element values | fit in machine words |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
[3,6,7,2,0,4,0,45,32,0]
```

```
18
```

## Idea

Walk the bytes once, pull out each signed integer as it appears, and keep a running total that stops at the first 0. Think of reading a number tape: you add each number to a tally and cut the tape the moment a 0 shows up. The hand scanner costs one character check per byte. Building the whole list first, with `eval`, allocates every element object before any adding happens.

## Why It Works

1. Brackets, commas and spaces are not digits or minus signs, so the scanner skips them for free.
2. A minus sign flips the sign of the digit run that follows it.
3. The running total equals the sum of elements before the first 0 by construction.
4. An empty list yields no digit runs, so the total stays 0.

| Term | Meaning |
|---|---|
| `nextSignedNumber` | reads one integer, with its optional minus sign |
| `minusSignValue` | byte 45, the `-` character |
| `elementValue` | the number just scanned |
| `total` | running sum of elements before the first 0 |
| `found` | true when a digit run existed at that spot |

The loop breaks on `found == False`, which covers both the first 0 and end of input.

A script-traced example from `gen.py`:

```
tokens 3, 6, 7, 2, 0, 4, ...
running 3 -> 9 -> 16 -> 18 -> stop at 0
result 18
```

The trace matches the sample answer.

## Code

**Signed scanner.** This block reads one integer, skipping punctuation.

```python
def nextSignedNumber(data, position):
    length = len(data)
    while position < length:
        byteValue = data[position]
        if firstDigitValue <= byteValue <= firstDigitValue + 9 or byteValue == minusSignValue:
            break
        position += 1
    sign = 1
    if position < length and data[position] == minusSignValue:
        sign = -1
        position += 1
    value = 0
    found = position < length
    while position < length and firstDigitValue <= data[position] <= firstDigitValue + 9:
        value = value * 10 + data[position] - firstDigitValue
        position += 1
    return sign * value, position, found
```

The skip loop ignores brackets, commas and whitespace.
The sign branch keeps negative elements correct.
Scanning costs one pass over the consumed characters.

**Sum loop.** This block totals values until the first 0.

```python
inputData = sys.stdin.buffer.read()
scanPos = 0
total = 0
while True:
    elementValue, scanPos, found = nextSignedNumber(inputData, scanPos)
    if not found:
        break
    if elementValue == 0:
        break
    total += elementValue
```

Each call advances `scanPos` past one number.
The zero test stops the sum exactly at the first 0.
No list object is ever built.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scan and sum | O(bytes) | constant |
| Output | one write | one short string |

| Measure | Big O |
|---|---|
| Time | O(N) |
| Space | O(N) for the input buffer |

`eval` plus a loop also works but allocates one object per element first.
