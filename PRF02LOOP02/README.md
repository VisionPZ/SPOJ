# PRF02LOOP02 — LOOP (SPOJ)
<https://www.spoj.com/problems/PRF02LOOP02/>

## Problem

Print the lowercase English alphabet as a title line, then print all 26 letters on one comma-separated line. The program reads no input and writes the same text for every run.

The input is empty. The output has two lines: the word alphabet, then letters a through z separated by a comma and a space.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Input | empty |
| Output lines | 2 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The 26 letters never change, so no output value depends on input.

The sample input is empty. The sample output follows.

    alphabet
    a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

## Idea

A fixed alphabet is like a row of labelled mailboxes: walk down the row once and copy each label out.
The program walks character codes 97 through 122 and converts each code to its letter.
A separator goes out before every letter except the first, so no trailing comma appears.
The title goes out first, then the letters, and one final newline ends the stream.
The work stays constant, since the alphabet size never changes.

## Why It Works

1. Character code 97 is a and code 122 is z in the ASCII table.
2. The inclusive range from 97 to 122 holds 26 codes.
3. The separator is emitted before codes 98 through 122, which gives 25 separators.
4. Twenty-five separators between 26 letters form one comma-separated line.
5. One newline after the title and one after the last letter match the sample byte for byte.

The terms carry the proof.

| Term | Meaning |
| --- | --- |
| firstLowerLetter | code 97, the letter a |
| lastLowerLetter | code 122, the letter z |
| letterSeparator | the two characters placed between letters |
| outputBuffer | the single string that collects output text |

The term table fixes the four values that shape the output.

A script check of the sample gives codes 97, 98, 99 at the start and 122 at the end.
Those codes become a, b, c and z. The line holds 26 entries and 25 separators, across 2 output lines.

No rounding applies, and the code range is fixed, so no guard is needed.

## Code

**Constants and full input read.** The header fixes the character range and the output strings.

```nim
const flushBlockBytes = 1 shl 17
const firstLowerLetter = 97
const lastLowerLetter = 122
const alphabetHeading = "alphabet"
const letterSeparator = ", "

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

```

The constants hold the code bounds and the literal text. The read loop fills one input string even though no value is used.

**Integer scanner.** The hand scanner skips non-digits and folds digits into an integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

It advances one position per numeric character. No negative branch appears because there is no signed input.

**Buffered writer.** One buffer collects output and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large blocks keep write calls rare. A final write empties any text left in the buffer.

**Alphabet emission.** The loop maps each code to a letter and inserts separators.

```nim
appendOutput(alphabetHeading)
outputBuffer.add '\n'
for letterCode in firstLowerLetter .. lastLowerLetter:
  if letterCode > firstLowerLetter:
    appendOutput(letterSeparator)
  appendOutput($char(letterCode))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first letter gets no separator. Each later letter gets one comma and space. The last newline closes the output.

## Complexity

The program emits a fixed 26 letters, independent of input size.

The phases split as follows.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over an empty stream | one input string |
| letter emission | 26 conversions | output buffer |
| output | two lines | one block buffer |

The phase table shows that no phase grows with input.

The asymptotic costs are:

| Measure | Big O |
| --- | --- |
| time | O(1) |
| space | O(1) |

A program that built the alphabet from a lookup table would do the same constant work.

The fixed output makes this one of the cheapest possible solutions.
