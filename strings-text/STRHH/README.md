# STRHH — Half of the half (SPOJ)

<https://www.spoj.com/problems/STRHH/>

## Problem

For each string of `2k` characters, take the first half and print every second character of that half, starting with its first character. Print one result line per case.

The input starts with the case count. Each following line holds one string of even length. The output holds one line of selected characters per case.

| Item | Bound |
|---|---|
| Test cases `t` | 1 to 100 |
| String length | `2k`, with k from 1 to 100 |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
4
your
progress
is
noticeable
```

```
y
po
i
ntc
```

## Idea

Pick alternate characters from the first half, like taking every other bead from the left half of a necklace. The program halves the string length and walks even positions up to that bound.

Each case costs one pass over its first half. Building the whole first half as a substring would copy bytes that the walk never reads.

One index, stepping by two, selects every output character.

## Why It Works

1. The string has `2k` characters, so its first half ends at index `k - 1`.
2. The required positions are 0, 2, 4, and so on, while the position stays below `k`.
3. The scan stops at `k`, so the second half is never touched.

| Term | Meaning |
|---|---|
| `sequence` | the string read for one case |
| `halfLength` | `sequence.len div 2`, the end of the first half |
| `charIndex` | the next even position to print |

The loop visits only the positions the answer needs.

A traced run of the sample:

```
your       halfLength 2 -> indices 0     -> "y"
progress   halfLength 4 -> indices 0,2   -> "po"
is         halfLength 1 -> indices 0     -> "i"
noticeable halfLength 5 -> indices 0,2,4 -> "ntc"
```

The trace matches all four sample output lines.

## Code

**Token reader.** The program reads a string skipping whitespace.

```nim
proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

The `var` parameter keeps the position between cases. Trailing spaces in the input cannot become part of a token.

**Case loop.** One walk over the first half per case.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let sequence = nextToken(inputData, scanPos)
  let halfLength = sequence.len div 2
  var charIndex = 0
  while charIndex < halfLength:
    appendOutput($sequence[charIndex])
    charIndex += 2
  outputBuffer.add '\n'
```

`charIndex` advances by two, so only even positions are read. One newline is added after each case, which gives one answer line per case.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| One case | O(k) for a string of `2k` characters | one string |
| Output | one write per block | one buffer |

The total work follows the total string length.

| Measure | Big O |
|---|---|
| Time | O(total input characters) |
| Space | O(input bytes) |

Copying each first half first would double the byte work. Walking even positions in place keeps the pass minimal.
