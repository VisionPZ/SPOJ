import strutils

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

proc nextKind(data: string, pos: var int): char =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  let kind = data[pos]
  pos += 1
  return kind

proc readTextLine(data: string, pos: var int): string =
  let start = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  if pos == start:
    if pos < data.len:
      pos += 1
    return ""
  let text = data[start .. pos - 1]
  if pos < data.len:
    pos += 1
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc greatestDivisor(first: int64, second: int64): int64 =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  if left < 0:
    return -left
  return left

proc continuedTerms(numeratorIn: int64, denominatorIn: int64): seq[int64] =
  var numerator = numeratorIn
  var denominator = denominatorIn
  var terms = newSeq[int64]()
  while true:
    let divisor = greatestDivisor(numerator, denominator)
    numerator = numerator div divisor
    denominator = denominator div divisor
    if denominator == 1:
      break
    terms.add(numerator div denominator)
    let remainder = numerator mod denominator
    numerator = denominator
    denominator = remainder
  terms.add(numerator - 1)
  return terms

proc digitCount(value: int64): int =
  var number = value
  if number < 0:
    number = -number
  var count = 1
  while number >= 10:
    number = number div 10
    count += 1
  return count

proc drawFraction(numerator: int64, denominator: int64): string =
  let terms = continuedTerms(numerator, denominator)
  var pictureWidth = 3 * terms.len + 1
  for term in terms:
    pictureWidth += digitCount(term)
  var picture = newSeq[string](2 * terms.len + 1)
  for lineIndex in 0 .. picture.len - 1:
    picture[lineIndex] = repeat('.', pictureWidth)
  var column = 0
  for termIndex in 0 .. terms.len - 1:
    let lineIndex = 2 * termIndex + 1
    let digits = $terms[termIndex]
    for digitIndex in 0 .. digits.len - 1:
      picture[lineIndex][column] = digits[digitIndex]
      column += 1
    picture[lineIndex][column] = '.'
    picture[lineIndex][column + 1] = '+'
    picture[lineIndex][column + 2] = '.'
    column += 3
    var dashColumn = column
    while dashColumn < pictureWidth:
      picture[lineIndex][dashColumn] = '-'
      dashColumn += 1
    let markerColumn = (column + pictureWidth - 1) div 2
    picture[lineIndex - 1][markerColumn] = '1'
  picture[picture.len - 1][pictureWidth - 1] = '1'
  return picture.join("\n") & "\n"

proc restoreFraction(terms: seq[int64]): tuple[numerator: int64, denominator: int64] =
  var numerator: int64 = 1
  var denominator: int64 = 1
  var termIndex = terms.len - 1
  while termIndex >= 0:
    let previousNumerator = numerator
    let previousDenominator = denominator
    numerator = previousDenominator + terms[termIndex] * previousNumerator
    denominator = previousNumerator
    termIndex -= 1
  return (numerator, denominator)

var currentKind = nextKind(inputData, scanPos)
var kindNeedsLineSkip = true
var caseNumber = 0

while currentKind != 'C':
  caseNumber += 1
  appendOutput("Case " & $caseNumber & ":\n")
  if currentKind == 'A':
    let numerator = int64(nextInt(inputData, scanPos))
    let denominator = int64(nextInt(inputData, scanPos))
    appendOutput(drawFraction(numerator, denominator))
    currentKind = nextKind(inputData, scanPos)
    kindNeedsLineSkip = true
  else:
    if kindNeedsLineSkip:
      while scanPos < inputData.len and inputData[scanPos] != '\n':
        scanPos += 1
      if scanPos < inputData.len:
        scanPos += 1
    kindNeedsLineSkip = false
    var coefficients = newSeq[int64]()
    var artLineIndex = 0
    while true:
      let artLine = readTextLine(inputData, scanPos)
      if artLine == "A" or artLine == "B" or artLine == "C":
        currentKind = artLine[0]
        break
      if artLineIndex mod 2 == 1:
        var coefficientPos = 0
        coefficients.add(int64(nextInt(artLine, coefficientPos)))
      artLineIndex += 1
    let restored = restoreFraction(coefficients)
    appendOutput($restored.numerator)
    appendOutput(" ")
    appendOutput($restored.denominator)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
