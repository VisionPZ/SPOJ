## Problem

Read a count, then that many numbers. Each number appears as uppercase English digit words on one line. Print two lines per number: an overline marker and an extended Roman numeral. An underscore marks a value times one thousand, and a lowercase letter marks a value times one million.

The bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | spelled digits on the first line |
| Number value | 0 through 4294967295 |
| Time limit | 1052 ms |
| Memory limit | 1536 MB |

The numeral width drives the design, since one value can fill twenty characters on each line.

## Idea

Three lookup strings indexed by decimal place give the symbol and underscore for every digit, so one pass writes both lines. A recursive converter would repeat work at each magnitude. Cost per number: at most ten places times four symbols.

## Why It Works

Each decimal place owns a fixed set of Roman symbols and a fixed overline pattern. The brTransData string stores how many symbols a digit uses, then which columns supply them. The brEquivData string stores the symbol for each place and column. The brBarData string stores the matching underscore. Three index formulas drive the lookup:

transStart equals digitValue times five, which selects one digit row.
equivStart equals digitPlace times four, which selects one place row.
symbolKind is the trans column value minus 48, which picks a symbol column.

A worked example for 123045 follows. A dot marks a space in the overline line.

```
place 5 digit 1 -> numeral C    overline _
place 4 digit 2 -> numeral XX   overline __
place 3 digit 3 -> numeral MMM  overline ...
place 1 digit 4 -> numeral XL   overline ..
place 0 digit 5 -> numeral V    overline .
joined numeral: CXXMMMXLV
joined overline: ___......
```

The joined overline has three underscores followed by six spaces, which matches the sample.

## Code

```nim
const firstDigit = "....84.......90...62.....0"
const brTransData = "00000100002000030000212001200022100321104211121300"
const brEquivData = "IIVXXXLCCCDMMIVXXXLCCCDMMivxxxlcccdmmivx"
const brBarData = "             ____________            ___"
```

Each row of brEquivData and brBarData has four entries. Each row of brTransData has five entries. One lookup per emitted symbol keeps the work constant.

```nim
var inputBuf = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputBuf.add inputLine
  inputBuf.add '\n'

var scanPos = 0

proc nextValue(data: string, pos: var int): int =
  var value = 0
  while pos < data.len and data[pos] != '\n':
    if data[pos] < 'A':
      pos += 1
      continue
    let start = pos
    while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
      pos += 1
    let first = data[start]
    let wlen = pos - start
    var digit = int(firstDigit[int(first) - 65]) - 48
    if (first == 'O' and wlen > 2) or (first == 'T' and wlen > 3) or
       (first == 'S' and wlen > 3) or (first == 'F' and data[start + 1] != 'O'):
      digit += 1
    value = value * 10 + digit
  pos += 1
  return value
```

The read loop ends at EOF. The scanner stops at a newline, so one line yields one number. The first letter and word length select the digit, which costs one pass over inputBuf.

```nim
var outputBuf = ""

proc appendOutput(text: string) =
  outputBuf.add text
  if outputBuf.len >= (1 shl 18):
    stdout.write outputBuf
    outputBuf.setLen 0

var numLine = ""
var barLine = ""

proc renderValue(value: int) =
  numLine.setLen 0
  barLine.setLen 0
  if value == 0:
    barLine.add '_'
  else:
    var place = 1000000000
    var digitPlace = 9
    while digitPlace >= 0:
      let digitValue = (value div place) mod 10
      let transStart = digitValue * 5
      let equivStart = digitPlace * 4
      var k = 1
      while k <= int(brTransData[transStart]) - 48:
        let symbolKind = int(brTransData[transStart + k]) - 48
        numLine.add brEquivData[equivStart + symbolKind]
        barLine.add brBarData[equivStart + symbolKind]
        k += 1
      digitPlace -= 1
      place = place div 10
  appendOutput(barLine & "\n" & numLine & "\n")
```

The place loop runs from nine down to zero. The symbol loop runs at most four times. Matching rows keep the underscore aligned with the numeral, so trailing spaces survive.

```nim
let caseCount = nextValue(inputBuf, scanPos)
for i in 0..<caseCount:
  renderValue(nextValue(inputBuf, scanPos))

stdout.write outputBuf
```

The case loop runs caseCount times. The final write flushes the remaining outputBuf. Each case adds two output lines.

## Complexity

Input scanning takes time linear in the input size. Rendering takes at most forty appends per number. Writing takes time linear in the output bytes. The total is O(input + output).

Space holds inputBuf, one outputBuf block, and the two line buffers. The block is 256 KiB. The total is O(input + block).

A recursive converter builds and discards a string at every magnitude. This program emits each symbol once.
