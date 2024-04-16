# -*- coding: utf-8 -*-
#----------------------------------------------------------------------------------------
#
# @py checkcorr.py（作成中）
# @brief 相関係数をチェックする（作成中）
# @param[in] 
# @note
#
#----------------------------------------------------------------------------------------
import numpy as np
import sys

def Gen_flt32b_read(filename, width):
	f = open(filename,'rb')
	X = np.fromfile(f,dtype = np.float32, count = -1)
	f.close()
	X = X.byteswap()
	X.shape = (len(X)/width,width)
	return X

argvs = sys.argv
argc = len(argvs)
if (argc != 4):
	print 'input six parameters!'
	print '1:power data name'
	print '2:simulated image '
	print '3:width'
	print '4:ref point(range)'
	print '5:ref point(azimuth)'

else:
	power_mat = Gen_flt32b_read(argvs[1],int(argvs[3]))
	sim_mat = Gen_flt32b_read(argvs[2],int(argvs[3]))
	
	a = X[1770:2794,721:1745]
	b = X[1770:2794,721:1745]
	corr = np.corrcoef(a,b)[0,1]