#!/usr/bin/env python

#This script will take any ts file name as per the alex pipeline and fold that candidate for raw data (i.e. with frequency information), if the raw file to fold has different name enter infile

#prepfold -ncpus 3 -npart 128 -n 128 -noxwin -accelcand 1 -accelfile /beegfsBN/u/tasha/NGC6440_meerkat/1123.5/decimated_rfifind/03_DEDISPERSION/1123_tdec4/full/ck00/1123_tdec4_full_ck00_DM227.67_ACCEL_20_JERK_60.cand -dm 227.67 -mask /beegfsBN/u/tasha/NGC6440_meerkat/1123.5/decimated_rfifind/01_RFIFIND/1123_tdec4_rfifind.mask -o raw_fold_1123_tdec4_full_ck00_DM227.67_z20_w60    /beegfsBN/u/tasha/NGC6440_meerkat/1123.5/decimated_rfifind/1123_tdec4.fil


#ts_fold_1123_tdec4_full_ck00_DM229.98_z20_w60_JERK_Cand_26

import numpy as np
import matplotlib.pyplot as plt
import argparse
import os,sys, subprocess

for j in range(1, len(sys.argv)):
	if(sys.argv[j] == '-num'):
		num = int(sys.argv[j+1])
	elif(sys.argv[j] == '-obs'):
		obsfile = sys.argv[j+1]
	elif(sys.argv[j] == '-infile'):
		infile = sys.argv[j+1]
        elif(sys.argv[j] == '-h'):
                print("python ts2raw.py -num numberintsfile -infile /dir/filetofold -obs /dir/datafile.fil")
		exit()
#num=100
#input
#ts_basename = 'ts_fold_1123_tdec4_full_ck00_DM229.98_z20_ACCEL_Cand_26'
#input
#obsfile = '/beegfsBN/u/tasha/NGC6440_meerkat/1123.5/decimated_rfifind/1123_tdec4.fil'
print(num)
with open ('list.txt','r') as tsfile:
    for line_no, line in enumerate(tsfile, start=1):
        #print(line_no)
        if(line_no == num):
            print("inside")
            ts_file=line # The content of the line is in variable 'line'
tsfile.close()

ts_basename = ts_file.split('.pfd.ps')[0]
print(ts_basename)
obs = obsfile.split('/')[-1].split('.fil')[0]
print(obs)
val = ts_basename.split(obs+'_')
print(val)
seg = val[1].split('_')[0]
ck = val[1].split('_')[1]
infile = ts_basename.split("ts_fold_")[-1]
accel1 = infile.split("_z")
z = accel1[-1].split("_")[0]
#w=accel1[-1].split("_")[1].split("w")[-1]
accelcand = accel1[0]+'_ACCEL_'+z+'.cand'
candnum = ts_basename.split("_")[-1]
dm = accel1[0].split("DM")[-1]


#if 'JERK' in infile:
#	ofile = infile.split("_JERK")[0]
if 'ACCEL' in infile:
	ofile = infile.split("_ACCEL")[0]

mask = obs+'_rfifind.mask'
print("obs,seg,ck,z,dm,accelcand,candnum")

print(obs)
print(seg)
print(ck)
print(z)
print(dm)
print(accelcand)
print(candnum)
print(obsfile)

try:
	os.mkdir('ts2raw')
except OSError as error:	
	print("file exists")
print('prepfold -ncpus 3 -npart 128 -n 128 -noxwin -accelcand %s -accelfile 03_DEDISPERSION/%s/%s/%s/%s -dm %s -mask 01_RFIFIND/%s -o ts2raw/raw_fold_%s %s' % (candnum, obs, seg, ck, accelcand, dm, mask, ofile, obsfile))

cmd = "prepfold -ncpus 3 -npart 128 -n 128 -noxwin -accelcand %s -accelfile 03_DEDISPERSION/%s/%s/%s/%s -dm %s -mask 01_RFIFIND/%s -o ts2raw/raw_fold_%s %s" % (candnum, obs, seg, ck, accelcand, dm, mask, ofile, obsfile)

executable = cmd.split()[0]
list_for_Popen = cmd.split()
proc = subprocess.Popen(list_for_Popen)
proc.communicate()

















