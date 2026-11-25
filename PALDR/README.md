# PALDR — Even Palindrome (SPOJ)

<https://www.spoj.com/problems/PALDR/>

## Problem

Decide whether one string can be cut into pieces that each read the same forwards and backwards and each have an even length. Print `YES` or `NO` for every test string.

Input starts with the test count T. The next T lines hold one string each, and a line may be empty or end with a carriage return. Output one verdict per line.

| Item | Bound |
|---|---|
| Test cases | below 100 |
| String length | up to 1000000 characters |
| Judge limit | 1000 ms, 1536 MB |

Total input length drives the design, since one string can hold a million characters.

Sample input:

```
3
madam
aA
aabb
```

This asks for three verdicts.

Sample output:

```
NO
NO
YES 
```

The third string splits into `aa` and `bb`.

## Idea

Match characters like snapping together paired dominoes: whenever two equal characters touch, they disappear. An even palindrome always vanishes under this matching rule, so a whole string is splittable exactly when all its characters vanish.

The algorithm walks the string once and keeps a stack. A matching top character pops the stack; any other character is pushed. The string succeeds when the stack ends empty. A search over every even palindromic substring would cost quadratic time per character and is far slower. A single stack pass settles each string in linear time.

## Why It Works

1. An even palindrome has a matching first and last character.
2. Removing those two leaves a smaller even palindrome, so repeated removal empties the piece.
3. Concatenated even palindromes therefore empty the whole string under the same rule.
4. The stack holds the unmatched prefix after any prefix of the string.
5. An empty stack at the end means every character found a partner.

| Term | Meaning |
|---|---|
| `palindromeStack` | unmatched characters seen so far |
| `currentChar` | next character read from the line |
| `lineEnd` | index of the newline closing the line |

The stack state summarizes everything needed from the prefix.

A trace of the stack on two sample strings:

```
aabb : push a, pop a, push b, pop b -> empty -> YES
abab : push a, push b, push a, push b -> [a b a b] -> NO
abba : push a, push b, pop b, pop a -> empty -> YES
```

The trace matches the sample verdict for `aabb`.

## Code

**Input and scanner.** The reader stores stdin once and extracts the test count.

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
```

The scan skips the newline after the count.
Each digit is consumed once.

**Buffered output.** Results collect in one string and flush in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The block size is 131072 bytes.
No per-line write occurs.

**Stack matching.** Each line is scanned and the verdict is buffered.

```nim
let caseCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
if scanPos < inputData.len:
  scanPos += 1

var palindromeStack = ""
for caseIndex in 0 .. caseCount - 1:
  if scanPos >= inputData.len:
    appendOutput("YES \n")
  else:
    var lineEnd = scanPos
    while lineEnd < inputData.len and inputData[lineEnd] != '\n':
      lineEnd += 1
    var charPos = scanPos
    while charPos < lineEnd:
      let currentChar = inputData[charPos]
      if currentChar != '\r':
        if palindromeStack.len > 0 and palindromeStack[palindromeStack.len - 1] == currentChar:
          palindromeStack.setLen(palindromeStack.len - 1)
        else:
          palindromeStack.add currentChar
      charPos += 1
    scanPos = lineEnd + 1
    if palindromeStack.len == 0:
      appendOutput("YES \n")
    else:
      appendOutput("NO\n")
    palindromeStack.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

Carriage returns are skipped before matching.
The stack is reset between test cases.
The final flush happens once.

## Complexity

One pass over each string dominates the work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all input bytes | one input string |
| Stack matching | one operation per character | stack of unmatched characters |
| Output | one write per block | block buffer |

The phase table shows that input size alone sets the cost.

| Measure | Big O |
|---|---|
| Time | O(total input length) |
| Space | O(longest string) |

Checking every even substring would cost O(total length squared), so the stack removes a full factor of the string length.
