import sys

tokens = sys.stdin.buffer.read().split()
answers = []
scanPos = 0
tokenCount = len(tokens)
while scanPos < tokenCount:
    groupEnd = scanPos + 5
    if groupEnd > tokenCount:
        groupEnd = tokenCount
    total = 0
    for idx in range(scanPos, groupEnd):
        total += int(tokens[idx])
    scanPos = groupEnd
    if total % 2 == 0:
        answers.append(str(total / 2))
    else:
        answers.append(str(total / 5))
if answers:
    sys.stdout.write("\n".join(answers) + "\n")
