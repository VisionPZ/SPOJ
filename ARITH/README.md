## Problem

Read one arithmetic expression per line: a positive integer, an operator `+ - *`, and another positive integer. Print the calculation the way it is done by hand: the two operands stacked, a rule, the result, and for multiplication every partial product with its sum. Put a blank line after every case, including the last.

| Item | Bound |
| --- | --- |
| Cases | about 1000 |
| Digits per number | 500 |
| Subtraction | second number smaller |
| Leading zeros | none |
| Judge limits | 5 s, 1536 MB |

## Idea

Store each number as digit values with the least significant digit first. Addition, subtraction and multiplication walk forward through those lists, so a carry or a borrow never moves backward. Each printed line becomes a `Row` that records its left edge, its right edge, and either text or a dash flag. Find the largest leftward overhang, shift every row by it, then append spaces, text or dashes. Multiplication visits each digit pair once, so 500 x 500 = 250 000 digit steps per case.

## Why It Works

A reversed number starts with its least significant digit, so column-by-column addition of two digit lists builds the reversed sum. Printing that list backwards gives the normal sum. Subtraction uses the same columns and adds 10 once when a digit goes negative.

Every output line is one `Row`. Text rows hold a string, dash rows hold none. `dashBetween` takes the smallest left edge and the largest right edge of two rows, so one rule covers both lines it joins.

For multiplication, `partialTexts[i]` holds `firstDigits` times digit `i` of `secondDigits`, with leading zeros dropped. Row `i` starts at `width - i - partialTexts[i].len`, which lines digit `i` up under that digit of the second operand. The smallest `left` value over all rows becomes `shift`, and every row moves right by that much.

The program prints `325*44` as follows.

| Line | Text | Left edge | Right edge |
| --- | --- | --- | --- |
| first operand | 325 | 0 | 3 |
| operator with second | *44 | 0 | 3 |
| first rule | ---- | -1 | 3 |
| partial at digit 0 | 1300 | -1 | 3 |
| partial at digit 1 | 1300 | -2 | 2 |
| second rule | ----- | -2 | 3 |
| product | 14300 | -2 | 3 |

The smallest left edge is -2, so `shift` is 2 and every row gains two leading spaces.

## Code

One buffer collects the output, and each helper adds text or a rule to it.

```nim
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
```

The flush check runs after each case, so memory stays near one block. `parseCount` reads only digits from the first line.

Rows describe printed lines. A dash row carries no text.

```nim
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
```

`dashBetween` spans both rows it joins. Each row costs constant space.

Digits are reversed once on input and once on output.

```nim
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
```

`dropLeadingZeros` keeps the value 0 as one digit. Each pass costs O(d).

Addition loops over `max(first.len, second.len)` columns and carries at most 1. Subtraction loops over `first.len` columns.

```nim
proc addReversed(first: seq[int], second: seq[int]): seq[int] =
  var answer: seq[int]
  var carry = 0
  let size = max(first.len, second.len)
  for i in 0 ..< size:
    let top = if i < first.len: first[i] else: 0
    let bottom = if i < second.len: second[i] else: 0
    let value = top + bottom + carry
    answer.add(value mod 10)
    carry = value div 10
  if carry > 0:
    answer.add(carry)
  return answer

proc subtractReversed(first: seq[int], second: seq[int]): seq[int] =
  var answer: seq[int]
  var borrow = 0
  for i in 0 ..< first.len:
    let top = first[i]
    let bottom = if i < second.len: second[i] else: 0
    var value = top - bottom - borrow
    if value < 0:
      value += 10
      borrow = 1
    else:
      borrow = 0
    answer.add(value)
  return answer
```

A negative column adds 10 once and sets `borrow`, which is enough for digit minus digit minus 1.

Multiplication visits every digit pair once and keeps the carry in place.

```nim
proc multiplyByDigit(first: seq[int], digit: int): seq[int] =
  var answer: seq[int]
  var carry = 0
  for i in 0 ..< first.len:
    let value = first[i] * digit + carry
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
  for i in 0 ..< second.len:
    var carry = 0
    for j in 0 ..< first.len:
      let value = answer[j + i] + second[i] * first[j] + carry
      answer[j + i] = value mod 10
      carry = value div 10
    var k = first.len + i
    while carry > 0:
      let value = answer[k] + carry
      answer[k] = value mod 10
      carry = value div 10
      k += 1
  return answer
```

The answer table has `first.len + second.len` slots. Index `j + i` is the column of digit pair `j, i`, and `k` writes the final carry.

Text rows are built from the digit lists.

```nim
proc digitsToString(digits: seq[int]): string =
  var text = ""
  for i in countdown(digits.len - 1, 0):
    text.add((digits[i] + '0'.ord).chr)
  return text
```

`countdown` prints the least significant digit last. This pass costs O(d).

The renderer builds every row, finds the shift, and writes the block.

```nim
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
    for i in 0 ..< secondDigits.len:
      let partial = dropLeadingZeros(multiplyByDigit(firstDigits, secondDigits[i]))
      partialTexts.add(digitsToString(partial))
    var resultDigits = dropLeadingZeros(multiplyReversed(firstDigits, secondDigits))
    let resultText = digitsToString(resultDigits)
    let resultRow = makeTextRow(width - resultText.len, width, resultText)
    var firstPartial = makeTextRow(width - 0 - partialTexts[0].len, width - 0, partialTexts[0])
    rows.add(dashBetween(operatorRow, firstPartial))
    if secondDigits.len == 1:
      rows.add(resultRow)
    else:
      for i in 0 ..< secondDigits.len:
        rows.add(makeTextRow(width - i - partialTexts[i].len, width - i, partialTexts[i]))
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
```

The partial loop runs once per digit of the second number, and each partial costs O(d). The two final loops find the shift and print each row once.

The driver reads the case count, finds the operator in each line, and renders one case.

```nim
var line = ""
discard stdin.readLine(line)
let pairCount = parseCount(line)
for _ in 0 ..< pairCount:
  if not stdin.readLine(line):
    break
  var operator = '+'
  var splitAt = -1
  for i in 0 ..< line.len:
    if line[i] in {'+', '-', '*'}:
      operator = line[i]
      splitAt = i
      break
  if splitAt < 0:
    continue
  renderPair(line[0 ..< splitAt], operator, line[splitAt + 1 ..< line.len])
stdout.write(outputBuffer)
```

The operator scan stops at the first `+`, `-` or `*`. Input is read line by line, and the final write flushes any bytes left in the buffer.

## Complexity

Let `d` be the maximum digit count, 500, and `c` the case count.

| Phase | Time per case | Space |
| --- | --- | --- |
| Digit conversion | O(d) | O(d) |
| Addition or subtraction | O(d) | O(d) |
| Multiplication | O(d^2) | O(d) |
| Row layout and output | O(d^2) for multiplication | O(d) plus one block |

The total time is O(c d^2) and the total space is O(d + flushBlockBytes). A 500-digit multiplication needs 250 000 digit steps and prints roughly the same number of characters.
