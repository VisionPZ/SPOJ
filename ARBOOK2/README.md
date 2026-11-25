# ARBOOK2 — Books (Struct) (SPOJ)

<https://www.spoj.com/problems/ARBOOK2/>

## Problem

Read a count, then read that many books, each given as four lines, and print one formatted line per book. Each output line holds the title, author, subject, and book id separated by ` : `.

The first line holds the book count. Every book then occupies four lines in the order title, author, subject, book id. Titles and subjects can contain spaces, so each field is read as a whole line.

| item | bound |
|---|---|
| book count | positive integer |
| fields per book | four lines |
| book id | integer |
| judge limit | 1000 ms, 1536 MB |

The four-line record shape sets the loop structure.

The sample input:

```
2
thang quy nho
nguyen nhat anh
thanh xuan vuon truong
2
bo cau khong dua thu
nguyen nhat anh
thanh xuan vuon truong
1
```

The sample output:

```
thang quy nho : nguyen nhat anh : thanh xuan vuon truong : 2
bo cau khong dua thu : nguyen nhat anh : thanh xuan vuon truong : 1
```

Both blocks match the statement byte for byte.

## Idea

Treat the input as a stack of four-line cards, one per book. Read each line of a card into its matching field, then write the card as one line. This is like copying index cards onto a list, one card per line, with a separator between fields.

The algorithm is a line reader plus a loop over the count. Each field costs one slice of the input, so the work is linear in the input length. Reading by words would split titles and break the layout.

One count, four line reads per record, and one joined line per record solve the list.

## Why It Works

1. The first line gives the number of book records.
2. Each record consumes exactly four following lines.
3. A whole-line slice keeps spaces inside a title intact.
4. The book id is parsed as an integer, so its text is normalized.
5. Each record appends one line to the shared output buffer.

| term | meaning |
|---|---|
| `bookCount` | number of book records to read |
| `bookTitle` | first line of a record |
| `bookAuthor` | second line of a record |
| `bookSubject` | third line of a record |
| `bookId` | parsed integer from the fourth line |

The four fields map one to one onto the four input lines of a record.

A script trace of the first sample record shows the assembly. The separator appears three times, once between each pair of fields.

```
line 1   thang quy nho            -> bookTitle
line 2   nguyen nhat anh          -> bookAuthor
line 3   thanh xuan vuon truong   -> bookSubject
line 4   2                        -> bookId = 2
output   thang quy nho : nguyen nhat anh : thanh xuan vuon truong : 2
```

The trace matches the first line of the sample answer.

The id parse drops stray spacing around the number. No other rounding guard is needed.

## Code

**Line and integer readers.** These helpers pull whole records and integers from the input string.

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

The line reader stops at each newline and moves past it.
The integer reader skips anything that is not a digit.
Both helpers share the single input string.

**Record loop and output.** The header gives the count, then each record becomes one line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let headerLine = nextLine(inputData, scanPos)
var headerScanPos = 0
let bookCount = nextInt(headerLine, headerScanPos)
for bookIndex in 0 .. bookCount - 1:
  let bookTitle = nextLine(inputData, scanPos)
  let bookAuthor = nextLine(inputData, scanPos)
  let bookSubject = nextLine(inputData, scanPos)
  let idLine = nextLine(inputData, scanPos)
  var idScanPos = 0
  let bookId = nextInt(idLine, idScanPos)
  appendOutput(bookTitle & " : " & bookAuthor & " : " &
               bookSubject & " : " & $bookId)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The count comes from the first line, not from the scanner on the full input.
Four reads per iteration keep records aligned.
The final flush emits every buffered record.

## Complexity

The program reads each field once and writes one line per book.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| record parse | four line slices per book | four field strings |
| output | one append per book | block buffer |

The work grows with the number of books, four reads at a time.

| measure | Big O |
|---|---|
| time | O(L) for input length L |
| space | O(L) for the input string |

A word-based parser would need to reassemble titles after splitting them.
Whole-line reads avoid that extra work and keep each record exact.
