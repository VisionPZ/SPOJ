# AR2EMPLOYEES — Employees (Struct) (SPOJ)

<https://www.spoj.com/problems/AR2EMPLOYEES/>

## Problem

Read a count, then read that many employees, each given as four lines, and print one formatted line per employee. Each output line holds the id, name, gender, and salary separated by ` : `.

The first line holds the employee count. Every employee then occupies four lines in the order id, name, gender, salary. Names can contain spaces, so each field is read as a whole line.

| item | bound |
|---|---|
| employee count | positive integer |
| fields per employee | four lines |
| salary | integer |
| judge limit | 1000 ms, 1536 MB |

The four-line record shape sets the loop structure.

The sample input:

```
3
NV01
Tran Thanh Hung
F
1500
NV02
Nguyen Ngoc Bich
M
2000
NV03
Tran Trung Hau
F
1700
```

The sample output:

```
NV01 : Tran Thanh Hung : F : 1500
NV02 : Nguyen Ngoc Bich : M : 2000
NV03 : Tran Trung Hau : F : 1700
```

Both blocks match the statement byte for byte.

## Idea

Treat the input as a stack of four-line cards, one per employee. Read the first line of each card as the id, the next as the name, and so on, then write the card as one line. This is like reading index cards in order and rewriting each on a single line with separators.

The algorithm is a line reader plus a loop over the count. Each field costs one slice of the input, so the work is linear in the input length. Reading by words would split names and break the layout.

One count, four line reads per record, and one joined line per record solve the list.

## Why It Works

1. The first line gives the number of employee records.
2. Each record consumes exactly four following lines.
3. A whole-line slice keeps spaces inside a name intact.
4. The salary is parsed as an integer, so its text is normalized.
5. Each record appends one line to the shared output buffer.

| term | meaning |
|---|---|
| `employeeCount` | number of employee records to read |
| `employeeId` | first line of a record |
| `employeeName` | second line of a record, may contain spaces |
| `employeeGender` | third line of a record |
| `employeeSalary` | parsed integer from the fourth line |

The four fields map one to one onto the four input lines of a record.

A script trace of the first sample record shows the assembly. The separator appears three times, once between each pair of fields.

```
line 1   NV01             -> employeeId
line 2   Tran Thanh Hung  -> employeeName
line 3   F                -> employeeGender
line 4   1500             -> employeeSalary = 1500
output   NV01 : Tran Thanh Hung : F : 1500
```

The trace matches the first line of the sample answer.

The salary parse drops stray spacing around the number. No other rounding guard is needed.

## Code

**Line and integer readers.** These helpers pull whole records and integers from the input string.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  let lineText = data[startPos .. pos - 1]
  if pos < data.len:
    pos += 1
  return lineText

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The line reader stops at each newline and moves past it.
The integer reader skips anything that is not a digit.
Both helpers share the single input string.

**Record loop and output.** The header gives the count, then each record becomes one line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let headerLine = nextLine(inputData, scanPos)
var headerScanPos = 0
let employeeCount = nextInt(headerLine, headerScanPos)
for employeeIndex in 0 .. employeeCount - 1:
  let employeeId = nextLine(inputData, scanPos)
  let employeeName = nextLine(inputData, scanPos)
  let employeeGender = nextLine(inputData, scanPos)
  let salaryLine = nextLine(inputData, scanPos)
  var salaryScanPos = 0
  let employeeSalary = nextInt(salaryLine, salaryScanPos)
  appendOutput(employeeId & " : " & employeeName & " : " &
               employeeGender & " : " & $employeeSalary)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The count comes from the first line, not from the scanner on the full input.
Four reads per iteration keep records aligned.
The final flush emits every buffered record.

## Complexity

The program reads each field once and writes one line per employee.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| record parse | four line slices per employee | four field strings |
| output | one append per employee | block buffer |

The work grows with the number of employees, four reads at a time.

| measure | Big O |
|---|---|
| time | O(L) for input length L |
| space | O(L) for the input string |

A word-based parser would need to reassemble names after splitting them.
Whole-line reads avoid that extra work and keep each record exact.
