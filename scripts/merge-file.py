import argparse

def addTag(file_name, file_content):
	tag = ""
	new_content = []
	if ".en" in file_name:
		tag = "<e2v>"
	if ".vi" in file_name:
		tag = "<v2e>"

	for line in file_content:
		new_content.append(tag+line)

	return new_content


def writeToSourceFile(file_name_1,file_name_2,source_file_name):
	file_content_1 = []
	file_content_2 = []

	with open(file_name_1,"r") as fp1:
		file_content_1 = fp1.readlines()
		fp1.close()

	with open(file_name_2,"r") as fp2:
		file_content_2 = fp2.readlines()
		fp2.close()

	tagged_1 = addTag(file_name_1, file_content_1)
	tagged_2 = addTag(file_name_2, file_content_2)

	if len(tagged_1) != len(tagged_2):
		print("2 files have not the same size")
		exit()

	with open(source_file_name,"a") as fp:
		for i in range(len(tagged_1)):
			fp.write(tagged_1[i])
			fp.write(tagged_2[i])
		fp.close()

def writeToTargetFile(file_name_1,file_name_2,target_file_name):
	file_content_1 = []
	file_content_2 = []

	with open(file_name_1,"r") as fp1:
		file_content_1 = fp1.readlines()
		fp1.close()

	with open(file_name_2,"r") as fp2:
		file_content_2 = fp2.readlines()
		fp2.close()


	if len(file_content_1) != len(file_content_2):
		print("2 files have not the same size")
		exit()

	with open(target_file_name,"a") as fp:
		for i in range(len(file_content_1)):
			fp.write(file_content_1[i])
			fp.write(file_content_2[i])
		fp.close()

if __name__=="__main__":
	parser = argparse.ArgumentParser(description='ソースファイルを作る')
	parser.add_argument("-s1", "--source_1",help="ファイル名を入力してください")
	parser.add_argument("-s2", "--source_2",help="ファイル名を入力してください")
	parser.add_argument("-msrc", "--merge_source", help="生成ファイル名")

	parser.add_argument("-t1", "--target_1",help="ファイル名を入力してください")
	parser.add_argument("-t2", "--target_2",help="ファイル名を入力してください")
	parser.add_argument("-mtgt", "--merge_target", help="生成ファイル名")

	args = parser.parse_args() 

	writeToSourceFile(args.source_1, args.source_2, args.merge_source)
	writeToTargetFile(args.target_1, args.target_2, args.merge_target)

	





