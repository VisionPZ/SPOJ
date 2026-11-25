# FN16CLK — Clock Breaking (SPOJ)

<https://www.spoj.com/problems/FN16CLK/>

## Problem

A broken digital clock shows a seven-segment display for several consecutive minutes. Some segments are permanently off, some are permanently on, and the rest work. Find the status of every display position, or report that the pictures cannot come from consecutive minutes.

Input holds several test cases until end of file. Each case starts with `n`, the number of pictures. The next `8n - 1` lines hold `n` pictures of seven rows and 21 columns each. Blank lines separate pictures, and the last picture has no blank line after it. The character `X` marks an on segment, and `.` marks everything else. Output seven rows of 21 characters for each possible case: `0` for burnt out, `1` for burnt in, `W` for definitely working, `?` for unknown, and `.` for non-segments. Print `impossible` when no start time fits.

| item | bound |
|---|---|
| pictures per case n | 1 to 100 |
| display size | 7 rows by 21 columns |
| minutes in a day | 1440 |
| test cases | until end of file |
| judge limit | 4000 ms, 1536 MB |

The colon segments work at all times, and no picture shows `X` outside a real segment.

Sample input:

```
3
......XX.....XX...XX.
.....X..X...X..X....X
.....X..X.X.X..X....X
.............XX...XX.
.....X..X......X.X..X
.....X..X......X.X..X
......XX.....XX...XX.

......XX.....XX...XX.
.....X..X...X..X....X
.....X..X.X.X..X....X
.............XX...XX.
.....X..X......X.X..X
.....X..X......X.X..X
......XX.....XX...XX.

.............XX...XX.
........X...X..X....X
........X.X.X..X....X
.............XX......
........X...X..X.X..X
........X...X..X.X..X
......XX.....XX...XX.
2
......XX.....XX...XX.
...X....X...X..X.X..X
...X....X.X.X..X.X..X
......XX..........XX.
...X.X....X.X..X.X..X
...X.X......X..X.X..X
......XX.....XX...XX.

......XX.....XX......
...X....X...X..X.....
...X....X.X.X..X.....
......XX.............
...X.X....X.X..X.....
...X.X......X..X.....
......XX.....XX......
```

Sample output:

```
.??...WW.....??...??.
?..?.W..?...?..1.0..?
?..?.W..?.?.?..1.0..?
.??...??.....11...WW.
?..?.W..?.0.W..?.1..?
?..?.W..?...W..?.1..?
.??...11.....??...??.
impossible
```

## Idea

Treat the pictures like photos of a clock taken at unknown minutes. Try all 1440 possible start minutes, like sliding a film strip past a fixed template. A start time is valid when every segment that changed in the photos also changes in the template. Combine the facts from all valid starts to label each segment. Guessing each segment status would test three states per segment. Checking start times instead shares one template pass across all 147 positions. Short takeaway: align time first, then read off segment statuses.

## Why It Works

1. Build the ideal display for each of the 1440 minutes once.
2. A segment observed both on and off must work, so its ideal value must also change across the pictures.
3. A segment observed only on is burnt in unless the ideal display turns it off in a valid start.
4. A segment observed only off is burnt out unless the ideal display turns it on in a valid start.
5. A valid start must make every changing segment change in the ideal clock.
6. If no start passes that test, the pictures cannot be consecutive minutes.

| term | meaning |
|---|---|
| `actualDisplays` | ideal 7 by 21 picture for every minute |
| `alwaysOff` | positions that are never part of a segment |
| `clocks` | the observed pictures of one test case |
| `matches` | frames where an ideal pixel equals the observed pixel |
| `answer` | status character for each display position |

In the first sample case, the colon segments show both values across the pictures and their ideal value stays on. Those positions receive `W`. Several minute-segment positions stay on in every picture and never appear in a valid template as off, so they receive `1`. The second sample case has no start time that explains every changing segment, so it prints `impossible`.

Bit masks describe digit rows, with one bit per column. Integer modulo keeps the minute wrap at 1440, so midnight needs no separate branch.

## Code

**Tables and input.** The prelude holds digit masks and reads whole lines.

```nim
const flushBlockBytes = 1 shl 17
const totalMinutes = 1440
const digitSegments: array[10, array[7, int]] = [
  [6, 9, 9, 0, 9, 9, 6],
  [0, 8, 8, 0, 8, 8, 0],
  [6, 8, 8, 6, 1, 1, 6],
  [6, 8, 8, 6, 8, 8, 6],
  [0, 9, 9, 6, 8, 8, 0],
  [6, 1, 1, 6, 8, 8, 6],
  [6, 1, 1, 6, 9, 9, 6],
  [6, 8, 8, 0, 8, 8, 0],
  [6, 9, 9, 6, 9, 9, 6],
  [6, 9, 9, 6, 8, 8, 6]
]
const digitStarts = [0, 5, 12, 17]
const separatorColumns = [4, 9, 11, 16]
const middleRows = [1, 2, 4, 5]
const middleColumns = [1, 2, 6, 7, 13, 14, 18, 19]
const endRows = [0, 3, 6]
const endColumns = [0, 3, 5, 8, 12, 15, 17, 20]
const colonRows = [0, 1, 3, 5, 6]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextLine(data: string, pos: var int): string =
  var start = pos
  while start < data.len and data[start] == '\n':
    start += 1
  var finish = start
  while finish < data.len and data[finish] != '\n':
    finish += 1
  result = ""
  for index in start .. finish - 1:
    result.add data[index]
  pos = finish
  if pos < data.len:
    pos += 1
```

Each digit mask holds seven rows of four columns.
The line reader skips the blank separators between pictures.
The minute count skips the hour leading zero when it is zero.

**Ideal clock.** The code builds every minute and marks non-segment positions.

```nim
var actualDisplays: array[totalMinutes, array[7, array[21, bool]]]
for minute in 0 .. totalMinutes - 1:
  let hour = minute div 60
  let minutePart = minute mod 60
  let digits = [hour div 10, hour mod 10, minutePart div 10, minutePart mod 10]
  for row in 0 .. 6:
    for column in 0 .. 20:
      actualDisplays[minute][row][column] = false
  for digitIndex in 0 .. 3:
    if digitIndex == 0 and digits[0] == 0:
      continue
    let digit = digits[digitIndex]
    let startColumn = digitStarts[digitIndex]
    for row in 0 .. 6:
      let mask = digitSegments[digit][row]
      for offset in 0 .. 3:
        if (mask and (1 shl offset)) != 0:
          actualDisplays[minute][row][startColumn + offset] = true
  actualDisplays[minute][2][10] = true
  actualDisplays[minute][4][10] = true

var alwaysOff: array[7, array[21, bool]]
for row in 0 .. 6:
  for column in 0 .. 20:
    alwaysOff[row][column] = false
for row in 0 .. 6:
  for index in 0 .. separatorColumns.len - 1:
    alwaysOff[row][separatorColumns[index]] = true
for rowIndex in 0 .. middleRows.len - 1:
  for columnIndex in 0 .. middleColumns.len - 1:
    alwaysOff[middleRows[rowIndex]][middleColumns[columnIndex]] = true
for rowIndex in 0 .. endRows.len - 1:
  for columnIndex in 0 .. endColumns.len - 1:
    alwaysOff[endRows[rowIndex]][endColumns[columnIndex]] = true
for index in 0 .. colonRows.len - 1:
  alwaysOff[colonRows[index]][10] = true
```

The digit loop turns mask bits into on pixels.
The colon is on at rows two and four of column ten.
The non-segment table protects positions that cannot burn out.

**Diagnosis and output.** The driver tests every start minute and writes the labels.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var linePos = 0
while true:
  let headerLine = nextLine(inputData, linePos)
  if headerLine.len == 0:
    break
  var headerPos = 0
  let frameCount = nextInt(headerLine, headerPos)
  var clocks = newSeq[array[7, array[21, bool]]](frameCount)
  for frame in 0 .. frameCount - 1:
    for row in 0 .. 6:
      let imageLine = nextLine(inputData, linePos)
      for column in 0 .. 20:
        clocks[frame][row][column] = imageLine[column] == 'X'
  var answer: array[7, array[21, char]]
  for row in 0 .. 6:
    for column in 0 .. 20:
      var seenOn = false
      var seenOff = false
      for frame in 0 .. frameCount - 1:
        if clocks[frame][row][column]:
          seenOn = true
        else:
          seenOff = true
      if seenOn and seenOff:
        answer[row][column] = 'W'
      elif seenOn and not alwaysOff[row][column]:
        answer[row][column] = '1'
      elif seenOff and not alwaysOff[row][column]:
        answer[row][column] = '0'
      else:
        answer[row][column] = '.'
  var possible = false
  for startMinute in 0 .. totalMinutes - 1:
    var matches: array[7, array[21, int]]
    for row in 0 .. 6:
      for column in 0 .. 20:
        matches[row][column] = 0
    for frame in 0 .. frameCount - 1:
      let minute = (startMinute + frame) mod totalMinutes
      for row in 0 .. 6:
        for column in 0 .. 20:
          if actualDisplays[minute][row][column] == clocks[frame][row][column]:
            matches[row][column] += 1
    var valid = true
    for row in 0 .. 6:
      for column in 0 .. 20:
        if answer[row][column] == 'W' and matches[row][column] != frameCount:
          valid = false
    if not valid:
      continue
    for row in 0 .. 6:
      for column in 0 .. 20:
        if (answer[row][column] == '1' or answer[row][column] == '0') and
            matches[row][column] == frameCount:
          answer[row][column] = '?'
    possible = true
  if not possible:
    appendOutput("impossible")
    outputBuffer.add '\n'
  else:
    for row in 0 .. 6:
      for column in 0 .. 20:
        appendOutput($answer[row][column])
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A changing observed segment must also change in the ideal clock.
A matching burnt label drops to `?` because working also explains it.
All answer characters pass through the shared output buffer.

## Complexity

The ideal clock is built once, and each test case scans 1440 start minutes.

| phase | time | space |
|---|---|---|
| template build | one pass over 1440 minutes | 1440 pictures |
| input read | one pass over observed pictures | n pictures |
| diagnosis | 1440 times n times 147 comparisons | one match counter |
| output | seven rows per possible case | block buffer |

| measure | Big O |
|---|---|
| preprocessing | O(1440 * 4 * 7 * 4) |
| time per test case | O(1440 * n * 147) |
| space | O(1440 * 147 + n * 147) |

Searching segment statuses directly would test three states for each of 147 positions. The start-minute sweep tests 1440 alignments and labels every position at once. Short takeaway: align the film strip, then read the labels.
