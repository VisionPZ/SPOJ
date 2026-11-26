# MANIP001 — Basic text manipulation 01 (SPOJ)

<https://www.spoj.com/problems/MANIP001/>

## Problem

Each test line has the fixed shape `TYPE 1: A, TYPE 2: B, TYPE 3: C, TYPE details: D`. Fields B and C may be empty. Print the record as `(A,B,C,'D')`, writing `NULL` for an empty field.

The first line holds t with 1 ≤ t ≤ 20. A, B, C are integers from 0 to 100, and D is free text to the end of the line.

| item | bound |
|---|---|
| tests t | 1 ≤ t ≤ 20 |
| A, B, C | 0 to 100, B and C may be empty |
| D | any text, no newlines |
| judge limit | 1000 ms, 1536 MB |

Marker-based scanning walks each record in a few passes.

Sample input:

```
3
TYPE 1: 2, TYPE 2: 0, TYPE 3: , TYPE details: n/a
TYPE 1: 2, TYPE 2: 1, TYPE 3: 0, TYPE details: nothing
TYPE 1: 0, TYPE 2: , TYPE 3: , TYPE details: nice
```

Sample output:

```
(2,0,NULL,'n/a')
(2,1,0,'nothing')
(0,NULL,NULL,'nice')
```

## Idea

A form with labelled boxes can be filled by jumping from label to label. The program finds the literal markers `TYPE 1:`, `TYPE 2:`, `TYPE 3:`, `TYPE details:` in order and reads whatever sits after each one.

An empty field is simply a field where the next character is a comma or the line ends, so the reader writes NULL instead of a number.

Takeaway: fixed labels make parsing a sequence of label jumps.

## Why It Works

1. The four markers appear in a fixed order, so jumping past each one lands at the next field.
2. A number field that starts with a digit is parsed; one that starts with a comma or newline is empty and prints NULL.
3. The details field runs to the line end, trimmed of trailing spaces.
4. The next record starts with `TYPE 1:`, so the text stop is also bounded by the next record when lines are joined.
5. The output template is fixed, so only the field values vary.

For the sample, the first line has an empty TYPE 3, so the tuple shows NULL in the third slot while keeping 0 for TYPE 2.

A record whose TYPE 1 is 0 still prints its number, because only B and C may be empty.

## Code

**Input and scanning.** The hand reader loads the file and parses integers.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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

The scanner skips spaces and newlines.
Every number is non-negative, so no minus branch is needed.

**Marker search.** Literal text locates each field.

```nim
proc findFrom(data: string, marker: string, startPos: int): int =
  if marker.len == 0:
    return startPos
  var searchPos = startPos
  while searchPos + marker.len <= data.len:
    var matched = true
    var offset = 0
    while offset < marker.len:
      if data[searchPos + offset] != marker[offset]:
        matched = false
        break
      offset += 1
    if matched:
      return searchPos
    searchPos += 1
  return -1

proc movePastMarker(data: string, pos: var int, marker: string) =
  let foundAt = findFrom(data, marker, pos)
  if foundAt >= 0:
    pos = foundAt + marker.len
  else:
    pos = data.len
```

The search compares character by character.
A miss moves the cursor to the end, keeping later reads safe.

**Optional fields.** A field is NULL when no digit follows the label.

```nim
proc readOptionalNumber(data: string, pos: var int): int =
  while pos < data.len and data[pos] == ' ':
    pos += 1
  if pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    return nextInt(data, pos)
  return -1
```

The -1 return marks an empty field.
The caller turns it into the word NULL.

**Details text.** The tail of the record is copied with trailing spaces removed.

```nim
  var detail = ""
  if textEnd > pos:
    detail = data.substr(pos, textEnd - 1)
  while detail.len > 0 and detail[detail.len - 1] == ' ':
    detail.setLen(detail.len - 1)
  pos = textEnd
  return detail
```

The stop point is the line end or the next record, whichever comes first.
Trimming keeps the quoted text exact.

**Record loop.** The four fields are read and printed as a tuple.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  movePastMarker(inputData, scanPos, "TYPE 1:")
  let firstNumber = nextInt(inputData, scanPos)
  movePastMarker(inputData, scanPos, "TYPE 2:")
  let secondNumber = readOptionalNumber(inputData, scanPos)
  movePastMarker(inputData, scanPos, "TYPE 3:")
  let thirdNumber = readOptionalNumber(inputData, scanPos)
  movePastMarker(inputData, scanPos, "TYPE details:")
  let detailText = readDetailText(inputData, scanPos)
  appendOutput("(" & $firstNumber & ",")
  if secondNumber < 0:
    appendOutput("NULL")
  else:
    appendOutput($secondNumber)
  appendOutput(",")
  if thirdNumber < 0:
    appendOutput("NULL")
  else:
    appendOutput($thirdNumber)
  appendOutput(",'" & detailText & "')")
  outputBuffer.add '\n'
```

Each marker jump positions the reader for one field.
Empty slots print NULL.
Every record produces exactly one line.

## Complexity

Each record is scanned a constant number of times.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| parse | marker jumps per record | one detail string |
| output | one line per record | one block buffer |

| measure | Big O |
|---|---|
| time | O(input size) |
| space | O(input size) |

Splitting on commas would break when the details text contains commas.

Takeaway: jump between fixed labels instead of tokenizing.
