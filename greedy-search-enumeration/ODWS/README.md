# ODWS — One day with string (SPOJ)

<https://www.spoj.com/problems/ODWS/>

## Problem

Count the lowercase strings of a fixed length that sit strictly between two given strings in dictionary order. Report that count modulo one billion and seven.

Input starts with the test count. Each test then gives string s and string t on separate lines, with t greater than s and both of equal length.

Output one line per test: `Case ` plus the case number, a colon, and the answer.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| string length | 1 to 100 |
| letters | lowercase English only |
| modulus | 1000000007 |
| judge limit | 500 ms, 1536 MB |

The equal length turns each string into a base-26 number, so counting reduces to subtracting two ranks.

Sample input:

```
3
ad
ag
abcdefg
abcdefh
xy
yz
```

Sample output:

```
Case 1: 2
Case 2: 0
Case 3: 26
```

## Idea

Treat each word as a number written in base 26, like reading a car odometer. The words strictly between two ranks are the gap between the two numbers, minus one. Read both words once, compute each rank with modular arithmetic, then subtract. Listing every word between them would take 26 to the length power; ranking takes one pass per word. A single subtraction replaces an enormous enumeration.

## Why It Works

1. Dictionary order on equal-length lowercase words matches numeric order in base 26.
2. Letter a has value 0, letter b has value 1, up to letter z with value 25.
3. The rank of a word is the sum of letter values times powers of 26.
4. Words strictly between s and t number rank(t) minus rank(s) minus one.
5. Reducing each rank modulo the modulus keeps every intermediate value small.

| term | meaning |
|---|---|
| `wordRank` | base-26 value of one word modulo the modulus |
| `lowerRank` | rank of the smaller word |
| `upperRank` | rank of the larger word |
| `betweenCount` | number of words strictly between the two |

The four rows cover the full computation from two words to one answer.

A worked example from the generator:

```
ad -> 0*26 + 3 = 3
ag -> 0*26 + 6 = 6
6 - 3 - 1 = 2
xy -> 23*26 + 24 = 622
yz -> 24*26 + 25 = 649
649 - 622 - 1 = 26
```

The two gaps match Case 1: 2 and Case 3: 26 in the sample output.

## Code

**Constants and input.** The reader loads all lines and defines the word scanner.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const firstLetterCode = 97
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextLowerWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word
```

The scanner skips line breaks and spaces between words.
Each word costs one pass over its letters.
The test count is the only number read from the stream.

**Ranking and output.** Each word becomes one modular rank, then one answer line.

```nim
proc wordRank(word: string): int64 =
  var rankValue: int64 = 0
  for letter in word:
    rankValue = (rankValue * alphabetSize + int64(int(letter) - firstLetterCode)) mod modulusValue
  return rankValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let lowerWord = nextLowerWord(inputData, scanPos)
  let upperWord = nextLowerWord(inputData, scanPos)
  let lowerRank = wordRank(lowerWord)
  let upperRank = wordRank(upperWord)
  let betweenCount = (upperRank - lowerRank - 1 + modulusValue) mod modulusValue
  appendOutput("Case " & $caseIndex & ": " & $betweenCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The modular multiply keeps ranks inside int64.
Adding one modulus before the subtraction avoids a negative result.
The buffer holds all short answer lines and flushes once.

## Complexity

One rank pass handles each of the two words in a test.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | one input string |
| ranking | two passes over a word of length L | constant |
| output | one line per test | block buffer |

Hundreds of tests stay far below the time limit.

| measure | Big O |
|---|---|
| time | O(T times L) |
| space | O(total input bytes) |

Listing every word between s and t would cost O(26 to the L) per test, so ranking wins.
The rank formula turns a huge dictionary scan into two short walks.
