import sys


def remove_multiple(file):
	last_value = None
	last_line = None
	for line in file:
		toks = line.split('\t')
		if not toks:
			continue
		if toks[0] == last_value:
			last_line = None
		else:
			if last_line:
				print(last_line)
			last_value = toks[0]
			last_line = line.strip()
	if last_line:
		print(last_line)


if __name__ == '__main__':
	remove_multiple(sys.stdin)
