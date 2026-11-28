# NAIVELOK — Naive Loki (SPOJ)

<https://www.spoj.com/problems/NAIVELOK/>

## Problem

Count removal choices that turn a palindromic string into a non-palindrome. Two choices differ when some position is removed in one and kept in the other. The answer is modulo 1000000007.

Input starts with the test count, followed by one string per line. Output one count per line. There are 2^n removal choices for a string of length n.

The bounds from the statement:

| item | bound |
|---|---|
| test cases | 1 to 1000 |
| string length n | 1 to 100 |
| allowed characters | a-z, A-Z, 0-9 |
| judge limit | 1000 ms, 1536 MB |

A string length of 100 rules out listing removal choices.

Sample input:

```
2
AA
b99b
```

Sample output:

```
0
6
```

## Idea

Count the palindromic leftovers first, then subtract them from all choices, like counting losing tickets before finding the number of winners.

A removal choice keeps a subsequence of the original string. Interval dynamic programming counts all palindromic subsequences. Each interval costs constant time. Listing all 2^n choices would cost exponential time.

A table of n squared cells replaces an exponential list.

## Why It Works

1. A removal choice keeps exactly one subsequence of the string.
2. A kept subsequence is a palindrome when it reads the same both ways.
3. The table cell for an interval counts its palindromic subsequences.
4. Matching ends add the inner count once more.
5. Unmatched ends subtract the shared inner count.
6. The answer subtracts palindromic choices from all 2^n choices.

The code uses these names:

| term | meaning |
|---|---|
| `palindromeTable` | counts for every string interval |
| `palindromeSubsets` | choices that leave a palindrome |
| `totalSubsets` | all removal choices, modulo the modulus |
| `nonPalindromeWays` | choices that leave a non-palindrome |
| `innerCount` | count for the interval inside matching ends |

Each name covers one step of the count.

The string b99b traces as follows:

```
empty: 1 palindrome
length 1: 4 palindromes
length 2: 2 palindromes (bb, 99)
length 3: 2 palindromes (b9b twice)
length 4: 1 palindrome
palindromic choices = 1 + 4 + 2 + 2 + 1 = 10
all choices = 2^4 = 16
answer = 16 - 10 = 6
```

The six non-palindromic choices match the sample output.

Every table cell is reduced modulo 1000000007, so counts never overflow.

## Code

**Input and scanning.** The reader loads the tokens and reads each string as one token.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue = 1000000007

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart ..< pos]
```

`nextToken` stops at the first whitespace byte.
The table covers every interval up to length 100.
Integer parsing uses no sign in this problem.

**Interval count.** Each cell combines two smaller intervals.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var palindromeTable: array[101, array[101, int64]]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let secretString = nextToken(inputData, scanPos)
  let stringLength = secretString.len
  for spanLength in 0 ..< stringLength:
    for leftIndex in 0 ..< stringLength - spanLength:
      let rightIndex = leftIndex + spanLength
      if spanLength == 0:
        palindromeTable[leftIndex][rightIndex] = 2
      else:
        var innerCount: int64 = 1
        if spanLength >= 2:
          innerCount = palindromeTable[leftIndex + 1][rightIndex - 1]
        var cellValue = palindromeTable[leftIndex + 1][rightIndex] + palindromeTable[leftIndex][rightIndex - 1] - innerCount
        if secretString[leftIndex] == secretString[rightIndex]:
          cellValue = cellValue + innerCount
        palindromeTable[leftIndex][rightIndex] = (cellValue + modulusValue) mod modulusValue
  let palindromeSubsets = palindromeTable[0][stringLength - 1]
  var totalSubsets: int64 = 1
  for bitIndex in 0 ..< stringLength:
    totalSubsets = (totalSubsets * 2) mod modulusValue
  var nonPalindromeWays = (totalSubsets - palindromeSubsets + modulusValue) mod modulusValue
  appendOutput($nonPalindromeWays)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`innerCount` is one for a two-character interval.
Matching ends add `innerCount`, and the cell stays non-negative.
The final subtraction uses the modulus before one write.

## Complexity

Each test case fills one interval table for its string.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| interval count | one pass over all intervals | table of 101 by 101 cells |
| output | one line per case | block buffer |

The phase table shows quadratic work in the string length.

| measure | Big O |
|---|---|
| time | O(T * n^2) |
| space | O(n^2) |

Listing every removal choice costs O(T * 2^n) time.
Interval dynamic programming stays bounded by 100 squared cells.
