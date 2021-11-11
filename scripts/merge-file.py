import argparse

def addTag(file_name, file_content):
	tag = ""
	new_content = []
	if ".en" in file_name:
		tag = "<e2v> "
	if ".vi" in file_name:
		tag = "<v2e> "

	for line in file_content:
		new_content.append(tag+line)

	return new_content


def writeToSourceFile(file_name_1,file_name_2,file_name_3,file_name_4,source_file_name,type):
	file_content_1 = []
	file_content_2 = []

	with open(file_name_1,"r",encoding="utf-8") as fp1:
		file_content_1 = fp1.readlines()
		fp1.close()

	with open(file_name_2,"r",encoding="utf-8") as fp2:
		file_content_2 = fp2.readlines()
		fp2.close()

	with open(file_name_3,"r",encoding="utf-8") as fp3:
		file_content_3 = fp3.readlines()
		fp3.close()

	with open(file_name_4,"r",encoding="utf-8") as fp4:
		file_content_4 = fp4.readlines()
		fp4.close()

	if len(file_content_1) != len(file_content_2):
		print("2 files have not the same size")
		exit()

	if len(file_content_3) != len(file_content_4):
		print("2 files have not the same size")
		exit()

	with open(source_file_name,"a",encoding="utf-8") as fp:
		if type == "sentence":
			for i in range(len(file_content_1)):
				fp.write(file_content_1[i])
				fp.write(file_content_2[i])
				fp.write(file_content_3[i])
				fp.write(file_content_4[i])
		if type == "all":
			fp.write(file_content_1)
			fp.write(file_content_2)
			fp.write(file_content_3)
			fp.write(file_content_4)
		fp.close()



def writeToTargetFile(file_name_1,file_name_2,file_name_3,file_name_4,target_file_name,type):
	file_content_1 = []
	file_content_2 = []

	with open(file_name_1,"r",encoding="utf-8") as fp1:
		file_content_1 = fp1.readlines()
		fp1.close()

	with open(file_name_2,"r",encoding="utf-8") as fp2:
		file_content_2 = fp2.readlines()
		fp2.close()

	with open(file_name_3,"r",encoding="utf-8") as fp3:
		file_content_3 = fp3.readlines()
		fp3.close()

	with open(file_name_4,"r",encoding="utf-8") as fp4:
		file_content_4 = fp4.readlines()
		fp4.close()

	if len(file_content_1) != len(file_content_2):
		print("2 files have not the same size")
		exit()

	if len(file_content_3) != len(file_content_4):
		print("2 files have not the same size")
		exit()

	with open(target_file_name,"a",encoding="utf-8") as fp:
		if type == "sentence":
			for i in range(len(file_content_1)):
				fp.write(file_content_1[i])
				fp.write(file_content_2[i])
				fp.write(file_content_3[i])
				fp.write(file_content_4[i])
		if type == "all":
			fp.write(file_content_1)
			fp.write(file_content_2)
			fp.write(file_content_3)
			fp.write(file_content_4)
		fp.close()

if __name__=="__main__":
	parser = argparse.ArgumentParser(description='ソースファイルを作る')
	parser.add_argument("-s1", "--source_1",help="ファイル名を入力してください")
	parser.add_argument("-s2", "--source_2",help="ファイル名を入力してください")
	parser.add_argument("-s3", "--source_3",help="ファイル名を入力してください")
	parser.add_argument("-s4", "--source_4",help="ファイル名を入力してください")
	parser.add_argument("-msrc", "--merge_source", help="生成ファイル名")

	parser.add_argument("-t1", "--target_1",help="ファイル名を入力してください")
	parser.add_argument("-t2", "--target_2",help="ファイル名を入力してください")
	parser.add_argument("-t3", "--target_3",help="ファイル名を入力してください")
	parser.add_argument("-t4", "--target_4",help="ファイル名を入力してください")
	parser.add_argument("-mtgt", "--merge_target", help="生成ファイル名")

	parser.add_argument("-t", "--type",help='"all" or "sentence"')

	args = parser.parse_args() 

	writeToSourceFile(args.source_1, args.source_2, args.source_3, args.source_4, args.merge_source,args.type)
	writeToTargetFile(args.target_1, args.target_2, args.target_3, args.target_4, args.merge_target,args.type)

	





