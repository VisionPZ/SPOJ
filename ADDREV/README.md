# ADDREV — Adding Reversed Numbers (SPOJ)
<https://www.spoj.com/problems/ADDREV/>

## Problem

A clerk receives account numbers already written backwards and must add two of them in that notation.
The receipt must show the sum backwards too, without any leading zero digits.

The first line gives the case count. Each next line holds two reversed numbers separated by a space. Print one reversed sum per line.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Input form | two digit strings per case |
| Digit strings | may exceed 64 bits |
| Judge time | 5 s |
| Judge memory | 1536 MB |

String arithmetic keeps long tokens safe and exact.

The sample input and its expected output follow byte for byte.

```
3
24 1
4358 754
305 794
```

```
34
1998
1
```


## Idea

Read the tokens as least-significant digit first (units column first) and add them column by column. This is column arithmetic on a page turned upside down.
The program stores each token as a digit list in the given order. Schoolbook addition runs from low column to high column and emits digits in that same order.
The emitted order is already the reversed sum, so no second reversal is needed. Trailing high-end zeros are removed before printing, then low-end zero digits are skipped.
Integer conversion would overflow on long tokens and would add two parsing passes.
Digit-wise addition gives the answer in one pass and stays exact.

## Why It Works

1. The judge writes each number with its low digit first, so token index 0 is the units column.
2. Adding columns left to right builds the sum with its units digit first, which is the reversed sum.
3. A carry never reaches 2, because two decimal digits plus a carry stay below 20.
4. Extra zeros at the high end are trimmed first, so a sum of 2 never prints as 20.
5. `parseCount` takes only digits from the first line, so blank lines do not shift parsing.

Four terms describe the arithmetic.

| Term | Meaning |
| --- | --- |
| reversed number | digits written from units upward |
| column | one index position in both digit lists |
| carry | the overflow passed into the next column |
| leading zero | a high digit of zero that must be dropped |

The terms explain why one forward loop produces the required output.

A script check of `24 1` gives digit lists [2,4] and [1]. The columns produce 2+1=3 and 4+0=4, so the printed list is 34.
For `4358 754`, the columns are 4+7, 3+5, 5+4, and 8+0. Carry propagation yields 1, 9, 9, 8, printed as 1998.
Both results match the sample output.

## Code

**Case count parser.**
```nim
proc parseCount(text: string): int =
  var value = 0
  for c in text:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value
```

The parser keeps only digit characters from the first line. Non-digits cannot corrupt the count. The routine costs one pass over that line.

**Reversed sum builder.**
```nim
proc appendReversedSum(firstToken: string, secondToken: string) =
  var digits: seq[int]
  var carry = 0
  let size = max(firstToken.len, secondToken.len)
  for i in 0 ..< size:
    var firstDigit = 0
    if i < firstToken.len:
      firstDigit = firstToken[i].ord - '0'.ord
    var secondDigit = 0
    if i < secondToken.len:
      secondDigit = secondToken[i].ord - '0'.ord
    let value = firstDigit + secondDigit + carry
    digits.add(value mod 10)
    carry = value div 10
  while carry > 0:
    digits.add(carry mod 10)
    carry = carry div 10
  while digits.len > 1 and digits[^1] == 0:
    setLen(digits, digits.len - 1)
  var i = 0
  while i < digits.len and digits[i] == 0:
    i = i + 1
  if i == digits.len:
    outputBuffer.add('0')
  else:
    while i < digits.len:
      outputBuffer.add((digits[i] + '0'.ord).chr)
      i = i + 1
```

Each column adds two digits and the carry. Digits are appended low end first, so the list is the reversed sum. The trailing zero trim handles sums such as 305 plus 794.

**Line driven driver.**
```nim
while stdin.readLine(line):
  let pairCount = parseCount(line)
  for _ in 0 ..< pairCount:
    discard stdin.readLine(line)
    var firstToken = ""
    var secondToken = ""
    var picking = 0
    for c in line:
      if c in {'0' .. '9'}:
        if picking == 0:
          firstToken.add(c)
        else:
          secondToken.add(c)
      else:
        picking = 1
    appendReversedSum(firstToken, secondToken)
    outputBuffer.add('\n')
    flushBlock()

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
```

Every input line after the first holds one pair. Non-digit characters separate the two tokens. One final write flushes the accumulated answers.


## Complexity

The cost is one pass over digits and one block write.

| Phase | Time | Space |
| --- | --- | --- |
| parse count | length of first line | constant |
| add one case | length of the longer token | digit list |
| output | total emitted digits | one output block |

Long tokens stay linear in the digit count instead of growing a big integer.

Big O uses D as the total number of digit characters.

| Measure | Big O |
| --- | --- |
| time | O(D) |
| space | O(max token length) |

Digit strings avoid overflow and still beat repeated integer reversal.
