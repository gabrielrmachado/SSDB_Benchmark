import os
import numpy as np

class SciDB:
    def __init__(self, compile_benchGen=False):
        if compile_benchGen:
            # os.system("pwd")
            print("Compiling benchGen.cc...")
            # os.chdir("SciDB/scripts")
            os.system("g++ benchGen.cc -o benchGen")
            print("benchGen.cc compiled.")
            print("Generating data using benchGen...")
            os.chdir("../data")
            os.system("../scripts/benchGen -tiny -t ../scripts/tileData")

