var inputLine = ""
while readLine(stdin, inputLine):
  var value = 0
  var digitIndex = 0
  while digitIndex < inputLine.len and inputLine[digitIndex] >= '0' and inputLine[digitIndex] <= '9':
    value = value * 10 + int(inputLine[digitIndex]) - 48
    digitIndex += 1
  stdout.write $(value)
  stdout.write "\n"
  flushFile(stdout)
  if value == 42:
    break
