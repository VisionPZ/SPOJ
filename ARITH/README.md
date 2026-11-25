# ARITH — Simple Arithmetics (SPOJ)
<https://www.spoj.com/problems/ARITH/>

## Problem

A calculator must print long-number arithmetic the way a pupil writes it on paper, with aligned columns and dashed separators.
Each expression needs a neat layout plus its exact result.

The first line gives T. Each next line holds a positive integer, one of +, -, or *, and a second positive integer, with no spaces. Print the formatted calculation and a blank line after each case.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Expressions T | about 1000 |
| Digits per number | up to 500 |
| Subtraction | second number is smaller |
| Judge time | 5 s |
| Judge memory | 1536 MB |

A row model keeps alignment exact at the maximum digit count.

The sample input and its expected output follow byte for byte.

```
4
12345+67890
324-111
325*4405
1234*4
```

```
 12345
+67890
------
 80235

 324
-111
----
 213

    325
  *4405
  -----
   1625
     0
 1300
1300
-------
1431625

1234
  *4
----
4936

```


## Idea

Store digits least significant first, like writing a column sum from the right-hand edge.
The program converts each operand to a reversed digit list (units digit stored first), so carry and borrow move forward through the array. Each printed line becomes a Row (text with column bounds). It records the left edge, the right edge, and either text or a dash flag.
After all rows are built, the code finds the largest leftward overhang and shifts every row by the same amount. Addition and subtraction cost linear time, while multiplication touches each digit pair once.
Hand-padding strings for each line is easy to get wrong and costs extra passes.
One row model makes alignment arithmetic instead of guesswork.

## Why It Works

1. Reversed digit lists let a carry or borrow advance to the next index without moving backward.
2. `multiplyReversed` adds each digit pair into column j+i exactly once, then pushes the carry upward.
3. A `Row` stores its left and right column, so alignment is an integer subtraction rather than string padding.
4. `dashBetween` spans from the leftmost to the rightmost edge of the two rows next to it.
5. The largest value of minus left over all rows gives the one shift applied to every line.

Four terms describe the layout.

| Term | Meaning |
| --- | --- |
| reversed digits | units digit stored at index zero |
| row | one printed line with column bounds |
| dash row | horizontal separator between two rows |
| overhang | empty columns before a row starts |

They explain why a single shift aligns every printed line.

A script check of `12345+67890` adds reversed lists [5,4,3,2,1] and [0,9,8,7,6].
The column sums produce [5,3,2,0,8], printed as 80235.
The width is 6, so the top row starts at column 1 and the operator row at column 0.
The dash row spans columns 0 through 6, matching the sample.

## Code

**Row model.**
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

`makeTextRow` stores text with its two column bounds. `makeDashRow` marks a separator line. `dashBetween` spans the union of two neighboring rows.

**Digit conversion and addition.**
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
```

`digitsReversed` reads a token from its right end. `dropLeadingZeros` removes extra high zeros from a result. `addReversed` folds one carry across the longer list.

**Subtraction and multiplication.**
```nim
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

`subtractReversed` borrows once when a digit goes negative. `multiplyByDigit` builds one partial product. `multiplyReversed` accumulates all digit pairs into one array.

**Layout renderer.**
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

The renderer assembles text and dash rows in print order. It computes the largest overhang before writing any line. One shared shift aligns every row.

**Expression driver.**
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

The driver finds the operator inside each line. It splits the operands and passes them to the renderer. A block flush keeps memory bounded across 1000 cases.


## Complexity

Multiplication dominates because it visits every digit pair.

| Phase | Time | Space |
| --- | --- | --- |
| digit conversion | O(d) | two lists |
| addition or subtraction | O(d) | one result list |
| multiplication | O(d squared) | one product list |
| rendering | O(d squared) in row count | one row per line |

The output buffer flushes after each case, so memory stays near one block.

Big O uses d as the larger operand digit count.

| Measure | Big O |
| --- | --- |
| time | O(d squared) worst case |
| space | O(d squared) in printed rows |

Naive string padding would repeat alignment work on every line.
