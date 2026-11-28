# STRINGQ — String Queries (SPOJ)

<https://www.spoj.com/problems/STRINGQ/>

## Problem

For each query on a lowercase string, either count rearrangements of a substring that read the same backwards, or sort that substring. Answer each count query modulo 106109099, then print the final string.

Input starts with the test count T. Each case gives the string, then a query count, then that many lines of the form `Q a b` or `U a b` with one-based inclusive bounds. Print one line per count query and one final line per case.

| item | bound |
|---|---|
| test count T | 1 to 10 |
| string length | 1 to 50000 |
| queries per case | 1 to 2000 |
| judge limit | 1000 ms, 1536 MB |

The modulus is prime, so factorial inverses exist for all supported lengths.

Sample input:

```
2
nittirichy
3
Q 2 5
U 1 4
Q 1 5
shabba
5
Q 2 3
Q 2 6
U 1 4
Q 2 5
Q 1 6
```

Sample output:

```
2
2
inttirichy
0
2
0
0
abhsba
```

The first query counts the two palindromes of `itti`.

## Idea

A string whose every substring has its reverse present must itself be a palindrome, like a row of tiles that matches its own mirror. A palindrome permutation exists when at most one letter has an odd count, and its count is a multinomial of the paired letters. Counting sort updates the string in one pass over the chosen range. Enumerating all rearrangements would be factorial in the range length. Count letters once per query and use precomputed factorials.

## Why It Works

1. The whole string is one of its substrings, so its reverse must also be a substring of the same length.
2. Two strings of equal length with one contained in the other are equal, so the arrangement is a palindrome.
3. A palindrome needs matching letters on both sides, leaving at most one unpaired letter.
4. The first half is a permutation of the paired letters, giving the multinomial count.
5. Counting sort rebuilds an updated range from letter frequencies without changing the multiset.

| term | meaning |
|---|---|
| `oddGroups` | letters with an odd count in the range |
| `halfLength` | number of positions in one half of the palindrome |
| `factorials` | precomputed factorials modulo the modulus |
| `inverseFactorials` | precomputed inverse factorials modulo the modulus |

The table covers both the count formula and the update path.

A script trace for the sample ranges:

```
range itti: counts i=2 t=2, oddGroups=0, halfLength=2, 2!/(1!1!) = 2
range ha: counts h=1 a=1, oddGroups=2, answer 0
range intti after update: counts i=2 t=2 n=1, oddGroups=1, 2!/(1!1!) = 2
```

The trace reproduces all three sample answers.

## Code

**Input and scanner.** All input is read once, then tokens are parsed by hand.

```nim
const modulus = 106109099
const maxTextLength = 50000
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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Query types are single letters, so the token reader handles them.
Bounds are positive and need no sign branch.
The scanner advances past whitespace between tokens.

**Factorial tables.** Modular exponentiation builds the inverse factorial table once.

```nim
proc powMod(baseValue: int64, exponentValue: int64): int64 =
  var powerResult: int64 = 1
  var power = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      powerResult = powerResult * power mod modulus
    power = power * power mod modulus
    remaining = remaining div 2
  return powerResult

var factorials = newSeq[int64](maxTextLength + 1)
var inverseFactorials = newSeq[int64](maxTextLength + 1)
factorials[0] = 1
for lengthValue in 1 .. maxTextLength:
  factorials[lengthValue] = factorials[lengthValue - 1] * int64(lengthValue) mod modulus
inverseFactorials[maxTextLength] = powMod(factorials[maxTextLength], int64(modulus - 2))
for lengthValue in countDown(maxTextLength, 1):
  inverseFactorials[lengthValue - 1] = inverseFactorials[lengthValue] * int64(lengthValue) mod modulus
```

The modulus is prime, so Fermat's rule applies.
Binary exponentiation keeps the cost logarithmic.
Both tables have one entry per possible length.

**Query processing.** Counts drive either a counting sort or a palindrome count.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var currentText = nextToken(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let queryType = nextToken(inputData, scanPos)
    let leftIndex = nextInt(inputData, scanPos) - 1
    let rightIndex = nextInt(inputData, scanPos) - 1
    if queryType[0] == 'U':
      var letterCounts = newSeq[int](26)
      for textIndex in leftIndex .. rightIndex:
        letterCounts[int(currentText[textIndex]) - 97] += 1
      var writeIndex = leftIndex
      for letterIndex in 0 .. 25:
        for repeatIndex in 0 .. letterCounts[letterIndex] - 1:
          currentText[writeIndex] = chr(97 + letterIndex)
          writeIndex += 1
    else:
      var letterCounts = newSeq[int](26)
      var oddGroups = 0
      for textIndex in leftIndex .. rightIndex:
        letterCounts[int(currentText[textIndex]) - 97] += 1
      for letterIndex in 0 .. 25:
        if (letterCounts[letterIndex] and 1) == 1:
          oddGroups += 1
      if oddGroups > 1:
        appendOutput("0")
      else:
        let halfLength = (rightIndex - leftIndex + 1) div 2
        var answerValue = factorials[halfLength]
        for letterIndex in 0 .. 25:
          answerValue = answerValue * inverseFactorials[letterCounts[letterIndex] div 2] mod modulus
        appendOutput($answerValue)
      outputBuffer.add '\n'
  appendOutput(currentText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The counting sort writes letters in ascending order.
Two odd groups force an immediate zero answer.
Each final string is written after its case.

## Complexity

Work splits into table setup and per-query scans.

| phase | time | space |
|---|---|---|
| factorial setup | one table up to 50000 | two tables |
| count query | one scan of the range | 26 counters |
| update query | one scan and rewrite | 26 counters |
| output | one line per query | block buffer |

The phase table shows that each query touches its range once.

| measure | Big O |
|---|---|
| time | O(max length + total queried length) |
| space | O(max length) for tables |

Listing every rearrangement would cost factorial time in the range length.
The multinomial count avoids that work.
