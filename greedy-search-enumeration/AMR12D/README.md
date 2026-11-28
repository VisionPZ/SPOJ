# AMR12D — The Mirror of Galadriel (SPOJ)

<https://www.spoj.com/problems/AMR12D/>

## Problem

A word is magical when every piece of it also appears in reversed form inside the same word. Decide this for each word in a batch.

Input starts with `T`, the test count. Each of the next `T` lines holds one string of lowercase letters. Print `YES` or `NO` on its own line for each string, in input order, with no blank lines.

| item | bound |
|---|---|
| test cases `T` | 1 to 100 |
| word length | 1 to 10 |
| alphabet | lowercase `a` to `z` |
| judge limit | 2000 ms, 1536 MB |

A word of length one always passes, since its only piece reads the same backwards.

Sample input:

```
2
aba
ab
```

Sample output:

```
YES
NO
```

## Idea

A whole string is its own longest piece, so its reverse must fit inside a string of equal length. That forces the reverse to be the string itself, like a mirror image that lands exactly on the original. So test each word for being a palindrome.

The code compares mirrored character pairs and stops at the first mismatch. A substring enumeration would examine up to 55 pieces per word and search each reversed piece among them. The pair check touches at most half of the characters and ends early. The takeaway is that the longest piece decides the whole answer.

## Why It Works

1. The full word is one of its own substrings.
2. Only a substring of equal length can equal its reverse inside the word.
3. Therefore a magical word must equal its own reverse, so it is a palindrome.
4. Every piece of a palindrome is itself a palindrome, hence appears reversed.
5. Comparing mirrored character pairs tests that equality in one pass.

| term | meaning |
|---|---|
| `word` | current lowercase string |
| `leftIndex` | index moving from the front |
| `rightIndex` | index moving from the back |
| `isPalindrome` | result of the mirrored-pair test |

The table names the four values used by the pair comparison.

A script check of two words gives the following counts.

| word | distinct pieces | reversed piece missing | result |
|---|---|---|---|
| `abcba` | 13 | none | YES |
| `abca` | 9 | `ba` | NO |

The first word passes every piece check, while the second fails on `ba`.

## Code

**Input and scanning.** The reader loads the whole input and takes words one at a time.

```nim
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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    word.add data[pos]
    pos += 1
  return word
```

`nextInt` reads the test count by skipping separators.
`nextWord` collects letters until the next separator.
`inputData` keeps every input line in one string.

**Buffered output and palindrome test.** Mirrored pairs decide each verdict.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let word = nextWord(inputData, scanPos)
  var isPalindrome = true
  var leftIndex = 0
  var rightIndex = word.len - 1
  while leftIndex < rightIndex:
    if word[leftIndex] != word[rightIndex]:
      isPalindrome = false
      break
    leftIndex += 1
    rightIndex -= 1
  if isPalindrome:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` batches lines before writing to the terminal.
`leftIndex` and `rightIndex` meet in the middle of `word`.
`isPalindrome` turns false at the first unequal pair.

## Complexity

Reading and parsing touch each input character once.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| word scan | at most half the word length | one word string |
| output | one line per test | block buffer |

| measure | Big O |
|---|---|
| time per word | O(L), where L is word length |
| total time | O(T × L) |
| extra space | O(L) |

Enumerating and searching all substrings costs O(L³) per word, far above the pair scan. The mirrored-pair check gives the answer with one short walk over each word.
