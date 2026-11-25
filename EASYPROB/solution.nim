const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc represent(value: int): string =
  if value == 0:
    return "0"
  if value == 1:
    return "2(0)"
  if value == 2:
    return "2"
  var highestPower = 0
  var probe = 1
  while probe * 2 <= value:
    probe *= 2
    highestPower += 1
  var terms = ""
  var exponent = highestPower
  while exponent >= 0:
    if (value div probe) mod 2 == 1:
      var term = ""
      if exponent == 1:
        term = "2"
      elif exponent == 0:
        term = "2(0)"
      else:
        term = "2(" & represent(exponent) & ")"
      if terms.len > 0:
        terms.add '+'
      terms.add term
    probe = probe div 2
    exponent -= 1
  return terms

let targets = @[137, 1315, 73, 136, 255, 1384, 16385]
for target in targets:
  appendOutput($(target) & "=" & represent(target))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
