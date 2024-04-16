# -*- coding: utf-8 -*-
#----------------------------------------------------------------------------------------
#
# @py getBeamId.py
# @brief ALOSのLEDデータからビーム番号を取得する
# @param[in] ledFile LEDファイルパス
# @note
#
#----------------------------------------------------------------------------------------

# 定数定義
# LEDファイルのファイルディスクリプタのレコード長
SIZE_FILE_DESCRIPTOR = 720

# アンテナビーム番号のオフセット
ANNTENA_BEAM_NUMBER = 1854

# アンテナビーム番号のバイト数
BYTE_ANNTENA_BEAM_NUMBER = 4

# 衛星種文字列を取得
def getStelliteType(fileName):
		# シーンＩＤの取得
		split = fileName.split("-")
		sceneId = split[1]
		# 衛星種文字列を取得
		type = sceneId[0:5]
		return type

# 観測モードの取得
def getObservationMode(fileName, satType):
		# プロダクトIDの取得
		split = fileName.split("-")
		if satType == 'ALOS2':
				productId = split[3]
				mode = productId[0:3]
		elif satType == 'ALPSR':
				productId = split[2]
				mode = productId[0]
		return mode

# ビームIDの取得(ALOS2のみ)
def getBeamID(obMode, beamNum):
		# スポットライトモード or ALOS/PALSAR
		if obMode == 'SBS' or len(obMode) == 1:
			beamId = beamNum
		# 高分解能3mモード
		elif obMode == 'UBS' or obMode == 'UBD':
			if beamNum <= 5:
				beamId = 'U1' + '-' + str(beamNum)
			elif 5 < beamNum and beamNum <= 9:
				beamId = 'U2' + '-' + str(beamNum)
			elif 9 < beamNum and beamNum <= 14:
				beamId = 'U3' + '-' + str(beamNum)
			elif 14 < beamNum and beamNum <= 19:
				beamId = 'U4' + '-' + str(beamNum)
			elif 19 < beamNum:
				beamId = 'U5' + '-' + str(beamNum)
		# 高分解能6mモード
		elif obMode == 'HBS' or obMode == 'HBD':
			if beamNum <= 5:
				beamId = 'U1' + '-' + str(beamNum)
			elif 5 < beamNum and beamNum <= 9:
				beamId = 'U2' + '-' + str(beamNum)
			elif 9 < beamNum and beamNum <= 14:
				beamId = 'U3' + '-' + str(beamNum)
			elif 14 < beamNum and beamNum <= 19:
				beamId = 'U4' + '-' + str(beamNum)
			elif 19 < beamNum:
				beamId = 'U5' + '-' + str(beamNum)
		# 高分解能6mモードフルポラリメトリ
		elif obMode == 'HBQ':
				beamId = 'FP6' + '-' + str(beamNum)
		# 高分解能10mモード
		elif obMode == 'FBS' or obMode == 'FBD':
			if beamNum <= 4:
				beamId = 'F1' + '-' + str(beamNum)
			elif 4 < beamNum and beamNum <= 7:
				beamId = 'F2' + '-' + str(beamNum)
			elif 7 < beamNum and beamNum <= 12:
				beamId = 'F3' + '-' + str(beamNum)
			elif 12 < beamNum and beamNum <= 17:
				beamId = 'F4' + '-' + str(beamNum)
			elif 17 < beamNum:
				beamId = 'F5' + '-' + str(beamNum)
		# 高分解能10mモードフルポラリメトリ
		elif obMode == 'FBQ':
				beamId = 'FP10' + '-' + str(beamNum)
		# 広域観測モード(350km,14MHz)
		elif obMode == 'WBS' or obMode == 'WBD':
				beamId = 'W' + '-' + str(beamNum)
		# 広域観測モード(350km,28MHz)
		elif obMode == 'WWS' or obMode == 'WWD':
				beamId = 'W' + '-' + str(beamNum)
		# 広域観測モード(490km,14MHz)
		elif obMode == 'VBS' or obMode == 'VBD':
				beamId = 'V' + '-' + str(beamNum)
		return beamId

if __name__ == '__main__':
	import sys
	import os
	# 引数取得
	ledFile = sys.argv[1]

	# ビーム番号の取得
	f = open(ledFile, 'rb')
	f.seek(SIZE_FILE_DESCRIPTOR+ANNTENA_BEAM_NUMBER)
	beamNum = int(f.read(BYTE_ANNTENA_BEAM_NUMBER))
	f.close()

	# ビームIDの取得
	fileName = os.path.basename(ledFile)
	satType = getStelliteType(fileName)
	obMode = getObservationMode(fileName, satType)
	beamId = getBeamID(obMode, beamNum)

	print(beamId)
