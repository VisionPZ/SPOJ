# DPRSDCDR — Depressed Coder (SPOJ)

<https://www.spoj.com/problems/DPRSDCDR/>

## Problem

Tinni must spend at least three hours each day writing code to stay jolly. Meals, sleep, and household chores take ten hours. Classes, lab reports, and test preparation consume more time. Whatever remains is time for programming. Her boyfriend cannot do the arithmetic, so the program decides her mood.

The first input line gives the number of test cases. Each later line holds five integers: the count of tests, the count of lab reports, hours per test, hours per report, and hours of classes. Print `Khushi` when at least three programming hours remain. Print `Hotash` otherwise.

| Item | Bound |
|---|---|
| Test cases | 1 to 1000 |
| Test count | 0 to 3 |
| Lab report count | 0 to 3 |
| Hours per test | 1 to 5 |
| Hours per report | 1 to 5 |
| Class hours | 3 to 8 |
| Judge limit | 1000 ms, 1536 MB |

The sample input:

```
2
2 2 3 1 6
1 2 1 2 3
```

The sample output:

```
Hotash
Khushi
```

## Idea

Think of a lunch tray with fourteen open slots after the meal is set aside. Fill slots with classes, tests, and reports. If three or more slots stay empty, Tinni can program.

The program multiplies each count by its hours and adds the class hours. When that total is at most eleven, fourteen minus the total is at least three, so the answer is `Khushi`. Otherwise it is `Hotash`. Each case costs a few integer operations.

## Why It Works

1. A day has twenty-four hours, and chores take ten, leaving fourteen usable hours.
2. Tests take `nCT * tCT` hours and reports take `nLab * tLab` hours.
3. Classes take `tCls` more hours, so occupied hours are the sum of those three quantities.
4. Free hours equal fourteen minus occupied hours.
5. The threshold checks whether those free hours reach three.

| Term | Meaning |
|---|---|
| `nCT` | number of tests to prepare |
| `nLab` | number of lab reports to write |
| `tCT` | hours needed for one test |
| `tLab` | hours needed for one report |
| `tCls` | hours spent in class |
| `occupiedHours` | fixed hours spent before programming |

A script-generated trace of the sample:

```
case 1: 2*3 + 2*1 + 6 = 14 occupied, 14 - 14 = 0 free -> Hotash
case 2: 1*1 + 2*2 + 3 = 8 occupied, 14 - 8 = 6 free -> Khushi
```

Both traced words match the sample output.

## Code

**Input and scanner.** Read all lines once, then scan integers by byte index.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips non-digits and builds values from digit bytes. The buffer flushes at 128 KiB.

**Driver.** Add the occupied hours and choose the word for each case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let ctCount = nextInt(inputData, scanPos)
  let labCount = nextInt(inputData, scanPos)
  let hoursPerCt = nextInt(inputData, scanPos)
  let hoursPerLab = nextInt(inputData, scanPos)
  let classHours = nextInt(inputData, scanPos)
  let occupiedHours = ctCount * hoursPerCt + labCount * hoursPerLab + classHours
  if occupiedHours <= 11:
    appendOutput("Khushi\n")
  else:
    appendOutput("Hotash\n")
stdout.write outputBuffer
```

Comparing with eleven avoids a subtraction because fourteen minus eleven is three. One final write flushes the buffer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| One case | O(1) arithmetic | O(1) |
| Output | one write per filled buffer | one output string |

| Measure | Big O |
|---|---|
| Time | O(test cases + input size) |
| Space | O(input size) |

Marking each of the fourteen hours separately would cost O(14) per case. That is still constant, but it adds work the multiplication avoids.
