var output: string
var positions: string

proc flushOut() =
  if positions.len > 0:
    output.add(positions)
    setLen(positions, 0)
  if output.len >= 1 shl 19:
    stdout.write(output)
    setLen(output, 0)

proc readLineText(): string =
  var current = ""
  discard stdin.readLine(current)
  return current

proc readCount(text: string): int =
  var value = 0
  for i in 0 ..< text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
  return value

proc buildPrefix(needle: string): seq[int] =
  var border: seq[int]
  setLen(border, needle.len)
  if needle.len > 0:
    border[0] = 0
  var fallback = 0
  for i in 1 ..< needle.len:
    while fallback > 0 and needle[i] != needle[fallback]:
      fallback = border[fallback - 1]
    if needle[i] == needle[fallback]:
      fallback += 1
    border[i] = fallback
  return border

proc appendPositions(needle: string, border: seq[int], haystack: string) =
  var matched = 0
  for i in 0 ..< haystack.len:
    while matched > 0 and haystack[i] != needle[matched]:
      matched = border[matched - 1]
    if haystack[i] == needle[matched]:
      matched += 1
    if matched == needle.len:
      positions.add($(i - needle.len + 1))
      positions.add('\n')
      if positions.len >= 1 shl 19:
        flushOut()
      matched = border[matched - 1]

while true:
  let lengthText = readLineText()
  if lengthText.len == 0:
    break
  let needleLength = readCount(lengthText)
  let needle = readLineText()
  let haystack = readLineText()
  if needle.len == 0:
    output.add('\n')
    continue
  let border = buildPrefix(needle)
  appendPositions(needle, border, haystack)
  flushOut()
  output.add('\n')
stdout.write(output)
