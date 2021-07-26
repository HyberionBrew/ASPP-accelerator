import numpy as np
import sys 
viv_path = "/home/fabian/Documents/Bachelorarbeit/asp1x1/asp1x1.sim/sim_1/behav/xsim/"
file_res =  open(viv_path+"ofm.data", 'r')
file_should = open("result/result_acc.data",'r')


count = 0
error_count = 0
while True:
	line1 = file_res.readline()
	#print(line1)
	line2 = file_should.readline()
	if not line2:
		break
	if not line1:
		print("ERROR not enough printed out! (tb)")
		break
	if line1 != line2:
		error_count = error_count +1
		print(len(line1))
		print(len(line2))
		print(count)
		print("ERROR")

	count = count +1

print(str(error_count)+" : Errors in acc_result")



file_res =  open(viv_path +"ofm_final.data", 'r')
file_should = open("result/result_final.data",'r')


count = 0
error_count = 0
while True:
	line1 = file_res.readline()
	#print(line1)
	line2 = file_should.readline()
	if not line2:
		break
	if not line1:
		print("ERROR not enough printed out! (tb)")
		break
	if line1 != line2:
		error_count = error_count +1
		print(line1)
		print(line2)
		print(count)
		print("ERROR")

	count = count +1

print(str(error_count)+" : Errors in final result")
