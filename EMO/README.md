# EMO — Emoticons (SPOJ)
<https://www.spoj.com/problems/EMO/>

## Problem

A chat message contains pairs of emoticons. The first one in a pair is the expected one and the second one is the typed mistake. Replace each pair with its first emoticon and print the cleaned message.

Each input line ends with a full stop. An emoticon starts with `:`, `-`, or `>`, is two to five characters long, and has a space before and after it. The end of input is marked by `#`, which is not processed. Curly double quotes become straight double quotes. The input contains at most 1,000,000 characters, and the judge limit is 200 ms with a 1536 MB memory limit.

The sample is printed on one line in the statement. Those are five original lines joined without a separator:

```
Always remember: “For every problem there is a fast, easy and wrong solution” :P :[ . Sometimes a line :O :T may contain only emoticons like the next  one. -_- -__ . And can be of different lengths too -_- -_ .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ :) .#
```

```
Always remember: "For every problem there is a fast, easy and wrong solution" :P .Sometimes a line :O may contain only emoticons like the next one. -_- .And can be of different lengths too -_- .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ .
```

The statement note says that the third line has a space before its emo. That line begins with a non-breaking space, and the space is part of the answer. Leading spaces before ordinary words are discarded.

## Idea

Read the whole input with one bulk call. Walk the raw bytes once and write corrected bytes into one output buffer. Split each line at ASCII spaces and at the non-breaking space. A word of two to five bytes starting with `:`, `-`, or `>` is an emoticon. Keep the first emoticon of a pair and skip the second one together with one separator.

A leading separator is written back only when the first word of the line is an emoticon. Between words the output always uses one ordinary ASCII space, even when the input used a non-breaking space there. Curly quotes are translated while bytes are copied.

The `#` marker may be the whole line or may be appended directly after a line's full stop. The scan finds a `#` anywhere in the current line, processes only the bytes before it, then stops the input loop.

## Why It Works

1. A faulty emoticon follows the correct one, so a pending flag marks the second element of a pair.
2. Skipping the second word also skips one separator, which leaves the kept word spacing unchanged.
3. The statement's note makes a leading separator significant only when an emo follows it.
4. Other leading separators and empty words are ignored, so unnecessary spaces are discarded.
5. Internal separators collapse to one ASCII space, as the statement requires for adjacent words.
6. The scan counts normalized bytes, so curly quotes cannot change emoticon detection.
7. Direct byte writes remove per-line strings, slices, and quote-normalization copies.
8. Output leaves in 128 KiB blocks, which keeps write calls rare.

| Term | Meaning |
|---|---|
| `source` | unchecked byte view of the input data |
| `leadingSeparator` | separator seen before the first word of the line |
| `pendingEmoji` | flag marking a kept emoticon that may start a pair |
| `haveKept` | true once at least one word has been written for this line |
| `terminator` | true when this line contains the `#` end marker |

The five sample lines after reconstruction:

```
line 1  :P :[ .                 -> :P .
line 2  Sometimes ... next  one. -> Sometimes ... next one.
line 3  \u00a0-_- -__ .          -> \u00a0-_- .
line 4  And ... too -_- -_ .     -> And ... too -_- .
line 5  Even ... :/ :) .#        -> Even ... :/ .
```

## Code

**Bulk input and buffered output.**
```nim
const flushBlockBytes = 1 shl 17

proc run() =
  var inputData = stdin.readAll()
  if inputData.len == 0:
    return
  let source = cast[ptr UncheckedArray[char]](addr inputData[0])
  let dataLength = inputData.len
  var outputData = newString(dataLength + 8)
  let target = cast[ptr UncheckedArray[char]](addr outputData[0])
  var outputLength = 0
  var scanPos = 0

  proc flushOutput() =
    if outputLength > 0:
      discard stdout.writeBuffer(addr outputData[0], outputLength)
      outputLength = 0
```
One bulk read fills the input buffer, and output leaves in 128 KiB blocks.

**Line scan, end marker, and leading separator.**
```nim
  while scanPos < dataLength:
    let lineStart = scanPos
    while scanPos < dataLength and source[scanPos] != '\n' and source[scanPos] != '\r':
      inc scanPos
    var lineEnd = scanPos
    while scanPos < dataLength and source[scanPos] == '\r':
      inc scanPos
    if scanPos < dataLength and source[scanPos] == '\n':
      inc scanPos

    var terminator = false
    for position in lineStart..<lineEnd:
      if source[position] == '#':
        lineEnd = position
        terminator = true
        break

    var checkPos = lineStart
    var leadingSeparator = 0
    while checkPos < lineEnd:
      if source[checkPos] == ' ':
        leadingSeparator = 1
        inc checkPos
      elif ord(source[checkPos]) == 194 and checkPos + 1 < lineEnd and
           ord(source[checkPos + 1]) == 160:
        leadingSeparator = 2
        inc checkPos, 2
      else:
        break
    if checkPos == lineEnd:
      if terminator:
        break
      continue
```
Carriage returns and line feeds end a line. A `#` truncates the line, and the loop stops after writing that line's corrected text. The leading separator is remembered for the first word.

**Word scan and emoticon pairs.**
```nim
    var pendingEmoji = false
    var haveKept = false
    var linePos = checkPos
    while linePos < lineEnd:
      let wordStart = linePos
      var wordLength = 0
      var leadingByte = char(0)
      var hasCurlyQuote = false
      while linePos < lineEnd:
        let currentByte = source[linePos]
        if currentByte == ' ':
          break
        if ord(currentByte) == 194 and linePos + 1 < lineEnd and
           ord(source[linePos + 1]) == 160:
          break
        if wordLength == 0:
          leadingByte = currentByte
        inc wordLength
        if ord(currentByte) == 226 and linePos + 2 < lineEnd and
           ord(source[linePos + 1]) == 128 and
           (ord(source[linePos + 2]) == 156 or ord(source[linePos + 2]) == 157):
          hasCurlyQuote = true
          linePos += 3
        else:
          inc linePos
      let wordEnd = linePos
      if linePos < lineEnd:
        if source[linePos] == ' ':
          while linePos < lineEnd and source[linePos] == ' ':
            inc linePos
        else:
          linePos += 2

      if wordEnd == wordStart:
        continue

      let wordIsEmoji = wordLength >= 2 and wordLength <= 5 and
                        (leadingByte == ':' or leadingByte == '-' or leadingByte == '>')
      if wordIsEmoji and pendingEmoji:
        pendingEmoji = false
        continue
      pendingEmoji = wordIsEmoji
```
Words are split on ASCII spaces and on the two bytes of a non-breaking space. Empty words from repeated separators are skipped, a second consecutive emoticon is dropped, and the pending flag tracks the next pair.

**Spacing, quote translation, and final write.**
```nim
      if not haveKept and wordIsEmoji and leadingSeparator != 0:
        if leadingSeparator == 1:
          target[outputLength] = ' '
          inc outputLength
        else:
          target[outputLength] = char(194)
          target[outputLength + 1] = char(160)
          inc outputLength, 2

      if haveKept:
        target[outputLength] = ' '
        inc outputLength

      if hasCurlyQuote:
        var readPos = wordStart
        while readPos < wordEnd:
          let currentByte = source[readPos]
          if ord(currentByte) == 226 and readPos + 2 < wordEnd and
             ord(source[readPos + 1]) == 128 and
             (ord(source[readPos + 2]) == 156 or ord(source[readPos + 2]) == 157):
            target[outputLength] = '"'
            inc outputLength
            readPos += 3
          else:
            target[outputLength] = currentByte
            inc outputLength
            inc readPos
      elif wordEnd > wordStart:
        copyMem(addr target[outputLength], addr source[wordStart], wordEnd - wordStart)
        inc outputLength, wordEnd - wordStart

      haveKept = true
      if outputLength >= flushBlockBytes:
        flushOutput()

    target[outputLength] = '\n'
    inc outputLength
    if outputLength >= flushBlockBytes:
      flushOutput()
    if terminator:
      break

  flushOutput()

run()
```
A leading separator survives only before an emo. Internal separators become one ASCII space. Curly quotes become straight quotes as bytes are copied. Each line ends with a newline, and the last block is flushed after the loop.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one bulk read | input bytes |
| Line scan | one pass over line bytes | one buffer |
| Output | one write per 128 KiB block | one buffer |

| Measure | Big O |
|---|---|
| Time | O(total input characters) |
| Space | O(total input characters) |

The scan visits each byte a constant number of times. Repeated whole-line substitutions are gone.
