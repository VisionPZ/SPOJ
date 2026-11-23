const flushBlockBytes = 1 shl 19

var outputBuffer: string

proc flushBlock() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    setLen(outputBuffer, 0)

proc appendSpaces(count: int) =
  for _ in 0 ..< count:
    outputBuffer.add(' ')

proc appendText(text: string) =
  outputBuffer.add(text)
  outputBuffer.add('\n')

proc appendDashes(count: int) =
  for _ in 0 ..< count:
    outputBuffer.add('-')
  outputBuffer.add('\n')

proc parseCount(token: string): int =
  var value = 0
  for c in token:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value

type Row = object
  isDash: bool
  left: int
  right: int
  text: string

proc makeTextRow(left, right: int, text: string): Row =
  return Row(isDash: false, left: left, right: right, text: text)

proc makeDashRow(left, right: int): Row =
  return Row(isDash: true, left: left, right: right, text: "")

proc dashBetween(upper: Row, lower: Row): Row =
  return makeDashRow(min(upper.left, lower.left), max(upper.right, lower.right))

proc digitsReversed(token: string): seq[int] =
  var digits: seq[int]
  for i in countdown(token.len - 1, 0):
    digits.add(token[i].ord - '0'.ord)
  return digits

proc dropLeadingZeros(digits: seq[int]): seq[int] =
  var answer = digits
  while answer.len > 1 and answer[^1] == 0:
    setLen(answer, answer.len - 1)
  return answer

proc addReversed(first: seq[int], second: seq[int]): seq[int] =
  var answer: seq[int]
  var carry = 0
  let size = max(first.len, second.len)
  for position in 0 ..< size:
    let top = if position < first.len: first[position] else: 0
    let bottom = if position < second.len: second[position] else: 0
    let value = top + bottom + carry
    answer.add(value mod 10)
    carry = value div 10
  if carry > 0:
    answer.add(carry)
  return answer

proc subtractReversed(first: seq[int], second: seq[int]): seq[int] =
  var answer: seq[int]
  var borrow = 0
  for position in 0 ..< first.len:
    let top = first[position]
    let bottom = if position < second.len: second[position] else: 0
    var value = top - bottom - borrow
    if value < 0:
      value += 10
      borrow = 1
    else:
      borrow = 0
    answer.add(value)
  return answer

proc multiplyByDigit(first: seq[int], digit: int): seq[int] =
  var answer: seq[int]
  var carry = 0
  for position in 0 ..< first.len:
    let value = first[position] * digit + carry
    answer.add(value mod 10)
    carry = value div 10
  while carry > 0:
    answer.add(carry mod 10)
    carry = carry div 10
  if answer.len == 0:
    answer.add(0)
  return answer

proc multiplyReversed(first: seq[int], second: seq[int]): seq[int] =
  var answer: seq[int]
  setLen(answer, first.len + second.len)
  for position in 0 ..< second.len:
    var carry = 0
    for inner in 0 ..< first.len:
      let value = answer[inner + position] + second[position] * first[inner] + carry
      answer[inner + position] = value mod 10
      carry = value div 10
    var writeAt = first.len + position
    while carry > 0:
      let value = answer[writeAt] + carry
      answer[writeAt] = value mod 10
      carry = value div 10
      writeAt += 1
  return answer

proc digitsToString(digits: seq[int]): string =
  var text = ""
  for position in countdown(digits.len - 1, 0):
    text.add((digits[position] + '0'.ord).chr)
  return text

proc renderPair(first: string, operator: char, second: string) =
  let width = max(first.len, second.len + 1)
  let firstDigits = digitsReversed(first)
  let secondDigits = digitsReversed(second)
  var topRow = makeTextRow(width - first.len, width, first)
  var operatorRow = makeTextRow(width - second.len - 1, width, operator & second)
  var rows: seq[Row]
  rows.add(topRow)
  rows.add(operatorRow)
  if operator == '+' or operator == '-':
    var resultDigits: seq[int]
    if operator == '+':
      resultDigits = addReversed(firstDigits, secondDigits)
    else:
      resultDigits = subtractReversed(firstDigits, secondDigits)
    resultDigits = dropLeadingZeros(resultDigits)
    let resultText = digitsToString(resultDigits)
    let resultRow = makeTextRow(width - resultText.len, width, resultText)
    rows.add(dashBetween(operatorRow, resultRow))
    rows.add(resultRow)
  else:
    var partialTexts: seq[string]
    for row in 0 ..< secondDigits.len:
      let partial = dropLeadingZeros(multiplyByDigit(firstDigits, secondDigits[row]))
      partialTexts.add(digitsToString(partial))
    var resultDigits = dropLeadingZeros(multiplyReversed(firstDigits, secondDigits))
    let resultText = digitsToString(resultDigits)
    let resultRow = makeTextRow(width - resultText.len, width, resultText)
    var firstPartial = makeTextRow(width - 0 - partialTexts[0].len, width - 0, partialTexts[0])
    rows.add(dashBetween(operatorRow, firstPartial))
    if secondDigits.len == 1:
      rows.add(resultRow)
    else:
      for row in 0 ..< secondDigits.len:
        rows.add(makeTextRow(width - row - partialTexts[row].len, width - row, partialTexts[row]))
      let lastPartial = makeTextRow(width - (secondDigits.len - 1) - partialTexts[^1].len, width - (secondDigits.len - 1), partialTexts[^1])
      rows.add(dashBetween(lastPartial, resultRow))
      rows.add(resultRow)
  var shift = 0
  for row in rows:
    if -row.left > shift:
      shift = -row.left
  for row in rows:
    appendSpaces(row.left + shift)
    if row.isDash:
      appendDashes(row.right - row.left)
    else:
      appendText(row.text)
  outputBuffer.add('\n')
  flushBlock()

var line = ""
discard stdin.readLine(line)
let pairCount = parseCount(line)
for _ in 0 ..< pairCount:
  if not stdin.readLine(line):
    break
  var operator = '+'
  var splitAt = -1
  for index in 0 ..< line.len:
    if line[index] in {'+', '-', '*'}:
      operator = line[index]
      splitAt = index
      break
  if splitAt < 0:
    continue
  renderPair(line[0 ..< splitAt], operator, line[splitAt + 1 ..< line.len])
stdout.write(outputBuffer)
