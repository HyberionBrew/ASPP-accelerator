import sys
f = open("arg_file.txt","w")
f.write("-gPARALLEL_OFMS="+str(sys.argv[2])+" ")
f.write("-gMAX_OFMS="+str(sys.argv[3])+" ")
f.write("-gFILTER_DEPTH="+str(sys.argv[1])+" ")
f.close()
print("Updated generics")
