# AREMPLOYEE — Employee (Struct) (SPOJ)

<https://www.spoj.com/problems/AREMPLOYEE/>

## Problem

Read one employee record and echo its four fields on a single line. The fields arrive on four lines in the order id, name, gender, salary.

Input has four lines: an id string, a name string that may contain spaces, a gender string, and an integer salary. Output has one line in the form ID : name : gender : salary. The spaces around each colon are part of the format.

The bounds from the statement:

| item | bound |
|---|---|
| id | string |
| name | string, may contain spaces |
| gender | string |
| salary | integer |
| judge limit | 1000 ms, 1536 MB |

Only the name field can contain spaces, so line boundaries carry the structure.

Sample input:

```
NV02
Tran Thanh Hung
M
1500
```

The sample name has three words on one line.

Sample output:

```
NV02 : Tran Thanh Hung : M : 1500
```

Each sample field reappears in the required order.

## Idea

Keep the four lines separate, like four labeled slots on a form. The algorithm reads each line once, parses the salary as a number, and joins the slots with ` : `.

A naive approach could split every line into words and lose the name spacing, or scan characters twice. Reading four lines directly costs one pass and preserves the name.

Four reads and one join give the answer.

## Why It Works

1. Each field occupies its own line, so a line reader keeps the name intact.
2. The salary is the only numeric field, so `nextInt` converts exactly that value.
3. Joining the four fields with ` : ` reproduces the output template.

The main terms:

| term | meaning |
|---|---|
| `employeeId` | first line, the employee id |
| `employeeName` | second line, the full name |
| `employeeGender` | third line, the gender code |
| `employeeSalary` | fourth line read as an integer |
| `nextDataLine` | reader that returns the next nonempty line |

The table maps each line to one output slot.

A trace from the generator with visible numbers:

```
input lines: 4
name words: 3
salary digits: 4
output bytes: 34
output: NV02 : Tran Thanh Hung : M : 1500
```

The trace shows that three name words stay together in the final line.

## Code

**Input and helpers.** The driver reads all input, defines the scanner, and buffers output.

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

proc nextDataLine(data: string, pos: var int): string =
  while pos < data.len:
    var lineEnd = pos
    while lineEnd < data.len and data[lineEnd] != '\n':
      lineEnd += 1
    var lineText = ""
    if lineEnd > pos:
      lineText = data.substr(pos, lineEnd - 1)
    pos = lineEnd + 1
    if lineText.len > 0 and lineText[lineText.len - 1] == '\r':
      lineText.setLen(lineText.len - 1)
    if lineText.len > 0:
      return lineText
  return ""
```

The read loop stores every line with a trailing newline.
The scanner skips non-digits and builds the salary value.
The line reader trims a trailing carriage return when one appears.

**Field assembly.** The program reads four fields and writes one joined line.

```nim
let employeeId = nextDataLine(inputData, scanPos)
let employeeName = nextDataLine(inputData, scanPos)
let employeeGender = nextDataLine(inputData, scanPos)
let employeeSalary = nextInt(inputData, scanPos)
appendOutput(employeeId & " : " & employeeName & " : " & employeeGender & " : " & $employeeSalary)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first three reads stop at line ends and keep all name words.
The integer read consumes the salary after the gender line.
The final write flushes one short line to standard output.

## Complexity

Each field is read once and joined once.

| phase | time | space |
|---|---|---|
| input read | one pass over four lines | one input string |
| field assembly | four reads and one join | four field strings |
| output | one block write | block buffer |

The three phases do a fixed amount of work.

| measure | Big O |
|---|---|
| time | O(L) |
| space | O(L) |

L is the total input length; splitting every line into words would add needless passes.

The program handles one record with four direct reads.
