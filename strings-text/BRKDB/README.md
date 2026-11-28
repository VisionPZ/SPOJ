# BRKDB — Brocken Data Base (SPOJ)

<https://www.spoj.com/problems/BRKDB/>

## Problem

A course database lost the column that held the first names of three students. The surviving data fixes the three surnames and their id codes. Given a recovered first name, print three rows that restore the table.

The input holds one name. The output holds three lines, each with that name, one surname, and one id code, in the order shown in the sample.

| Item | Bound |
|---|---|
| Input | one name |
| Output lines | 3 |
| Judge limit | 1000 ms |
| Memory | 1536 MB |

The surname and code values are constants known from the statement.

The sample input:

```
Antonio
```

The sample output:

```
Antonio Silva 200120039010
Antonio Pineda 199810024010
Antonio Monsalve 200410061010
```

## Idea

Like filling three missing cells in a spreadsheet from a remembered list, take the recovered name once. Attach each stored surname and code pair to it. No search is needed because the database has exactly three known people.

The program reads the first token, then appends three fixed rows to the output buffer. Each row reuses the same name string.

Each row costs one buffer append, so the whole case is constant work.

## Why It Works

1. The statement names three students, so the set of surname and code pairs is fixed.
2. The sample fixes the output order as Silva, Pineda, then Monsalve.
3. Prepending the recovered name to each pair reconstructs the three lost rows.
4. The code values are written as literals, so no arithmetic can corrupt them.

| Term | Meaning |
|---|---|
| `deletedName` | the recovered first name read from input |
| `nextToken` | scanner that skips whitespace and returns one word |
| `outputBuffer` | string that collects the three result lines |

All three rows share the same first name.

A script-generated view of the reconstruction:

```
recovered name        Antonio
row 1  Silva          200120039010
row 2  Pineda         199810024010
row 3  Monsalve       200410061010
```

These rows match the sample output byte for byte.

## Code

**Input and scanner.** The name arrives as a single whitespace-delimited token.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var tokenValue = ""
  while pos < data.len and data[pos] > ' ':
    tokenValue.add data[pos]
    pos += 1
  return tokenValue
```

`inputData` ends with a newline, which stops the token scan cleanly. Only the first token is used.

**Output buffer.** The buffer flushes at 128 KiB even though this case is tiny.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One final write after the rows clears any remaining bytes. Three short rows never reach the flush threshold.

**Row writer.** Three literal suffixes complete the table.

```nim
let deletedName = nextToken(inputData, scanPos)
appendOutput(deletedName)
outputBuffer.add " Silva 200120039010\n"
outputBuffer.add deletedName
outputBuffer.add " Pineda 199810024010\n"
outputBuffer.add deletedName
outputBuffer.add " Monsalve 200410061010\n"
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each suffix begins with one space, which separates the name from the surname. The last row ends with a newline.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over one line | input bytes |
| Core work | three literal appends | constant |
| Output | one write | one buffer |

No loop over the database is required because its size is three.

| Measure | Big O |
|---|---|
| Time | O(1) |
| Space | O(1) beyond the input string |

Looking up the codes in a table would add work without changing these fixed answers.
