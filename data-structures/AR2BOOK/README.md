# AR2BOOK — Book (Struct) (SPOJ)

<https://www.spoj.com/problems/AR2BOOK/>

## Problem

Read one book as four lines and print those four fields on one line with the separator ` : ` between them. The fields are title, author, subject, and an integer book id.

The input has exactly four lines in that order. Each text field may contain spaces, so lines must be read whole rather than split into words. The output is one line, then a newline.

| item | bound |
|---|---|
| text fields | three lines, may contain spaces |
| book id | integer |
| judge limit | 1000 ms, 1536 MB |

Reading whole lines is the constraint that shapes the design.

The sample input:

```
nghin le mot dem
khong tac gia
co tich
1
```

The sample output:

```
nghin le mot dem : khong tac gia : co tich : 1
```

Both blocks match the statement byte for byte.

## Idea

Treat each line as one field, like filling four boxes on a form. Copy the first three boxes as they are, parse the fourth as a number, then write the boxes in order with a separator between them. A line reader gives you whole boxes; a word scanner would break the title into pieces.

The algorithm is four line reads plus one bounded integer parse. Each field costs one slice of the input string, so the work is linear in the total input length. Splitting on words would need a join step and could lose the spaces inside a title.

Read by line, join with the separator, print one line.

## Why It Works

1. Each newline ends exactly one field of the book.
2. A line slice keeps spaces inside a field unchanged.
3. The integer scanner removes any stray spacing around the id.
4. Concatenating with the separator produces the required layout.
5. The writer flushes the single answer line after the final newline.

| term | meaning |
|---|---|
| `nextLine` | reader that returns one line and advances the scan position |
| `bookTitle` | first field of the book |
| `bookAuthor` | second field of the book |
| `bookSubject` | third field of the book |
| `bookId` | parsed integer id of the book |

The four fields map one to one onto the four input lines.

A script trace of the sample shows the fields as they are assembled. The separator appears three times, once between each pair of fields.

```
input line 1   nghin le mot dem   -> bookTitle
input line 2   khong tac gia      -> bookAuthor
input line 3   co tich            -> bookSubject
input line 4   1                  -> bookId = 1
output         bookTitle + ' : ' + bookAuthor + ' : ' + bookSubject + ' : ' + bookId
```

The trace yields the same line as the sample answer.

The id is parsed as an integer, so leading spaces or zeros normalize to a plain number. No other rounding guard is needed.

## Code

**Line and integer readers.** These helpers pull whole fields and one integer from the input string.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  let lineText = data[startPos .. pos - 1]
  if pos < data.len:
    pos += 1
  return lineText

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The line reader stops at the first newline and moves past it.
An empty line yields an empty field.
The integer reader skips anything that is not a digit.

**Field assembly and output.** The program reads four fields and writes one joined line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let bookTitle = nextLine(inputData, scanPos)
let bookAuthor = nextLine(inputData, scanPos)
let bookSubject = nextLine(inputData, scanPos)
let bookIdLine = nextLine(inputData, scanPos)
var idScanPos = 0
let bookId = nextInt(bookIdLine, idScanPos)

appendOutput(bookTitle & " : " & bookAuthor & " : " & bookSubject & " : " & $bookId)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The four reads happen in statement order.
The separator is added three times, never at either end.
The final flush emits the buffered answer.

## Complexity

The program reads four lines and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| field parse | four line slices plus one integer | four field strings |
| output | one buffered write | block buffer |

Only four fields exist, so the parse work stays small even for long lines.

| measure | Big O |
|---|---|
| time | O(L) for input length L |
| space | O(L) for the input and field strings |

Reading by word would need an extra join and could change the title text.
Whole-line reads keep each field exact.
