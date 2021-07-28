import sys

def replace_rareword(input_filename, output_filename):
	frequences = {}

	with open(input_filename,'r',encoding='utf-8') as f:
		lines = f.readlines()
		f.close()

	content = ' '.join(line.replace('\n', '') for line in lines)
	content = content.split(' ')
	for word in content:
		if word in frequences:
			frequences[word] += 1
		else:
			frequences[word] = 1

	output_lines = []

	for line in lines:
		for word in line.replace('\n', '').split(' '):
			if frequences[word] < 5:
				line = line.replace(word, '<unk>')
		output_lines.append(line)

	with open(output_filename, 'w',encoding='utf-8') as f:
		f.writelines(output_lines)
		f.close()

if __name__=='__main__':
	replace_rareword(sys.argv[1], sys.argv[2])