# G10182 — Criptoanálisis (SPOJ)

<https://www.spoj.com/problems/G10182/>

## Problem

The first line gives a count n; the next n lines hold a text passage, spaces included. Count how many times each letter A-Z appears, ignoring case. Print one line per letter that appears: the uppercase letter, a space, its count. Order lines by count from most to least frequent; when counts tie, put the later alphabet letter first.

| Item | Bound |
|---|---|
| Line count | n lines after the header |
| Line length | up to about 200 characters |
| Output | at most 26 lines |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
3
Esta es una prueba,
Cuentame 1 2 3 4 5,
¡ ¡oohh!! ¿Esta es pregunta facil?
```

```
E 8
A 7
U 4
T 4
S 4
N 3
R 2
P 2
O 2
H 2
C 2
M 1
L 1
I 1
G 1
F 1
B 1
```

## Idea

Tally the letters into a 26-slot array, then sort the present letters by count descending and letter descending. Think of sorting a hand of Scrabble tiles by how many of each you hold. Each input byte costs one range check and maybe one array bump, so counting is a single pass. Rebuilding a hash map per line or rescanning the text per letter would multiply the work.

## Why It Works

1. ASCII letters sit in two 26-byte blocks, so `byteValue - 65` or `byteValue - 97` indexes the right slot.
2. Bytes outside those blocks, including accented characters and digits, are skipped, matching "only letters are analyzed".
3. The sort key `(-count, -index)` puts bigger counts first and, within equal counts, bigger letters first.
4. Letters with count 0 never enter the list, so absent letters print nothing.

| Term | Meaning |
|---|---|
| `lineCount` | n, the number of text lines |
| `textLines` | the n lines taken as raw bytes |
| `letterCounts` | 26 tallies, index 0 is A |
| `presentLetters` | indices with a nonzero tally |
| `byteValue` | one byte of one text line |

The header is parsed from its own slice, so a stray digit inside the text cannot change n.

A script-traced example from `gen.py`:

```
text "abcabc"
tallies a=2 b=2 c=2
order by count then letter: C 2, B 2, A 2
```

Ties fall to the later letter first, exactly as the statement demands.

## Code

**Header and line slice.** This block reads n and keeps the n text lines.

```python
inputData = sys.stdin.buffer.read()
headerEnd = inputData.find(b"\n")
if headerEnd < 0:
    headerBytes = inputData
    textBytes = b""
else:
    headerBytes = inputData[:headerEnd]
    textBytes = inputData[headerEnd + 1:]

scanPos = 0
lineCount, scanPos, _ = nextNumber(headerBytes, scanPos)
textLines = textBytes.split(b"\n")[:lineCount]
```

The header slice isolates n from the body.
The `[:lineCount]` slice stops at exactly n lines.
Splitting raw bytes avoids any text decoding.

**Tally pass.** This block counts letters in one sweep.

```python
letterCounts = [0] * alphabetSize
for textLine in textLines:
    for byteValue in textLine:
        if firstUpperValue <= byteValue <= firstUpperValue + alphabetSize - 1:
            letterCounts[byteValue - firstUpperValue] += 1
        elif firstLowerValue <= byteValue <= firstLowerValue + alphabetSize - 1:
            letterCounts[byteValue - firstLowerValue] += 1
```

Both branches fold lowercase onto the uppercase slot.
Non-letters cost two comparisons and nothing else.
The pass touches each byte once.

**Ordering and output.** This block sorts and prints the ranking.

```python
presentLetters = [letterIndex for letterIndex in range(alphabetSize) if letterCounts[letterIndex] > 0]
presentLetters.sort(key=lambda letterIndex: (-letterCounts[letterIndex], -letterIndex))

answerLines = []
for letterIndex in presentLetters:
    answerLines.append("%s %d" % (chr(firstUpperValue + letterIndex), letterCounts[letterIndex]))
```

The key sorts by count down, then letter down.
At most 26 items sort, so the sort is constant work.
Absent letters stay out of the list.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Tally | O(bytes) | 26 counters |
| Sort | O(26 log 26) | 26 items |
| Output | one write | short buffer |

| Measure | Big O |
|---|---|
| Time | O(N) in input bytes |
| Space | O(N) for the input buffer |

Rescanning the text once per letter would cost 26 passes; this needs one.
