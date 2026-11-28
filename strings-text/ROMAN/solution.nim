const firstDigit = "....84.......90...62.....0"
const brTransData = "00000100002000030000212001200022100321104211121300"
const brEquivData = "IIVXXXLCCCDMMIVXXXLCCCDMMivxxxlcccdmmivx"
const brBarData = "             ____________            ___"

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

let caseCount = nextValue(inputBuf, scanPos)
for i in 0..<caseCount:
  renderValue(nextValue(inputBuf, scanPos))

stdout.write outputBuf
