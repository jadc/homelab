import sys

if len(sys.argv) < 2:
    print("Usage: fcm <argument>", file=sys.stderr)
    sys.exit(1)

print(sys.argv[1])
