import sys

firstUpperValue = 65
lastUpperValue = 90
firstLowerValue = 97
lastLowerValue = 122
lowercaseShift = 32

inputData = sys.stdin.buffer.read()
seenWords = set()
currentWord = bytearray()
for byteValue in inputData:
    if firstUpperValue <= byteValue <= lastUpperValue:
        currentWord.append(byteValue + lowercaseShift)
    elif firstLowerValue <= byteValue <= lastLowerValue:
        currentWord.append(byteValue)
    else:
        if currentWord:
            seenWords.add(bytes(currentWord))
            currentWord.clear()
if currentWord:
    seenWords.add(bytes(currentWord))

sortedWords = sorted(seenWords)
outputBuffer = b""
if sortedWords:
    outputBuffer = b"\n".join(sortedWords) + b"\n"
sys.stdout.buffer.write(outputBuffer)
