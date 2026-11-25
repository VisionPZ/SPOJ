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

      # The statement's note requires a space before an emo.  When a line
      # starts with a separator and its first word is an emo, that one space
      # is part of the answer; leading spaces before ordinary words are not.
      if not haveKept and wordIsEmoji and leadingSeparator != 0:
        if leadingSeparator == 1:
          target[outputLength] = ' '
          inc outputLength
        else:
          target[outputLength] = char(194)
          target[outputLength + 1] = char(160)
          inc outputLength, 2

      if haveKept:
        # Between words the statement asks for one ordinary space, even when
        # the input used a non-breaking space there.
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
