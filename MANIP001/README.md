# MANIP001 — Basic text manipulation 01 (SPOJ)

<https://www.spoj.com/problems/MANIP001/>

## Problem

Extract four parameters from each badly formatted record and print them in a compact form. Every missing numeric field becomes `NULL`.

Input starts with an integer t, followed by t records. Each record carries the markers `TYPE 1:`, `TYPE 2:`, `TYPE 3:`, and `TYPE details:`. The numbers range from 0 to 100. The second number is empty when the first is 0, and the third is empty when the second is 0 or empty. The detail text has 1 to 20 readable characters.

Output has t lines with the shape (A,B,C,'TEXT'). The detail text sits inside single quotes.

The bounds from the statement:

| item | bound |
|---|---|
| test cases t | 1 to 20 |
| each number | 0 to 100 or empty |
| detail text | 1 to 20 characters |
| judge limit | 1000 ms, 1536 MB |

The small case count keeps parsing simple and exact.

Sample input:

```
3
TYPE 1: 2, TYPE 2: 0, TYPE 3: , TYPE details: n/a
TYPE 1: 2, TYPE 2: 1, TYPE 3:0 , TYPE details: nothing
TYPE 1: 0, TYPE 2: , TYPE 3: , TYPE details: nice
```

The sample mixes a missing third field with two complete records.

Sample output:

```
(2,0,NULL,'n/a')
(2,1,0,'nothing')
(0,NULL,NULL,'nice')
```

Each output line mirrors one input record.

## Idea

Treat each marker as a signpost, like stops on a bus route. The algorithm jumps from signpost to signpost, reads a number when one is present, and takes the remaining text as the detail field.

A naive character-by-character state machine must track every marker letter and comma. Jumping to the next marker costs one search and keeps the code short.

Marker jumps plus optional reads solve all t records.

## Why It Works

1. The markers appear in a fixed order, so a forward search never skips a field.
2. An empty field has no digit at its start, so the optional read returns a missing value.
3. The detail text ends at the line break or at the next record marker.
4. A missing value is written as the literal `NULL`.

The main terms:

| term | meaning |
|---|---|
| `findFrom` | searches for a marker from the current position |
| `movePastMarker` | skips a marker and lands on its value |
| `readOptionalNumber` | reads a number or reports a missing field |
| `readDetailText` | takes the text after the last marker |
| `caseCount` | number of records to process |

The table maps each helper to one parsing step.

A trace from the generator with visible numbers:

```
cases: 3
first number: 2
second number: 0
third absent: True
detail length: 3
first output bytes: 17
```

The trace shows that the empty third field becomes `NULL` in the first answer.

## Code

**Input and helpers.** The driver reads all input and defines the marker and field helpers.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

proc readOptionalNumber(data: string, pos: var int): int =
  while pos < data.len and data[pos] == ' ':
    pos += 1
  if pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    return nextInt(data, pos)
  return -1

proc readDetailText(data: string, pos: var int): string =
  while pos < data.len and data[pos] == ' ':
    pos += 1
  var textEnd = pos
  while textEnd < data.len and data[textEnd] != '\n' and data[textEnd] != '\r':
    textEnd += 1
  let nextRecord = findFrom(data, "TYPE 1:", pos)
  if nextRecord >= 0 and nextRecord < textEnd:
    textEnd = nextRecord
  var detail = ""
  if textEnd > pos:
    detail = data.substr(pos, textEnd - 1)
  while detail.len > 0 and detail[detail.len - 1] == ' ':
    detail.setLen(detail.len - 1)
  pos = textEnd
  return detail
```

The read loop stores each record with a trailing newline.
The marker search scans forward and needs no extra table.
The detail reader stops at a line end or at the next record.

**Record assembly.** The main loop reads each record and writes one answer line.

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

stdout.write outputBuffer
outputBuffer.setLen 0
```

Four marker jumps keep the field order fixed.
The negative sentinel marks an empty numeric field.
The buffer flushes once after the loop, not once per record.

## Complexity

Each marker search advances over the input once per record.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parsing | four forward searches per record | a few field values |
| output | one block write | block buffer |

The three phases stay linear in the input size.

| measure | Big O |
|---|---|
| time | O(L) |
| space | O(L) |

L is the input length; rescanning from the start for every marker would repeat work.

Marker jumps and buffered writes handle every record in one pass.
