#!python

import shutil
import os
import os.path as op
import subprocess
import re
import datetime

moduleName = "TaxiMap"
authorName = "Relena"

srcPath = "."
dstPath = op.normpath(op.join(os.environ['PROGRAMFILES(X86)'], "Dofus2Beta/app/ui", authorName + "_" + moduleName))

def copyFile(filename):
	shutil.copyfile(op.normpath(op.join(srcPath, filename)), op.normpath(op.join(dstPath, filename)))

def copyDir(dirname):
	shutil.rmtree(op.normpath(op.join(dstPath, dirname)), 1)
	shutil.copytree(op.normpath(op.join(srcPath, dirname)), op.normpath(op.join(dstPath, dirname)))

def makeDir(dirname):
	if not op.isdir(dirname):
		os.makedirs(dirname)

def updateModFile():
	if not op.isfile(op.normpath(op.join(srcPath, "mod.info"))):
		return

	command = ['git', 'describe', '--long']
	out = subprocess.Popen(command, stdout=subprocess.PIPE)
	(sout, serr) = out.communicate()

	result = re.match(r"v(-?[0-9|\.]+)_(-?[0-9|\.]+)-(-?[0-9|\.]+)", sout)
	dofusVersion = result.group(1)
	version = result.group(2)
	revision = result.group(3)

	with open(op.normpath(op.join(srcPath, "mod.info")), "r") as file:
		data = file.read()
		data = data.replace("${name}", moduleName)
		data = data.replace("${author}", authorName)
		data = data.replace("${dofusVersion}", dofusVersion)
		data = data.replace("${version}", version)
		data = data.replace("${tag}", "v" + dofusVersion + "_" + version)
		data = data.replace("${date}", datetime.date.today().isoformat())
		data = data.replace("${filename}", moduleName + "_" + dofusVersion + "_" + version)
		with open(op.normpath(op.join(srcPath, "mod.json")), "w") as outFile:
			outFile.write(data)

if __name__ == "__main__" :
	makeDir(dstPath)
	updateModFile()
	copyFile(authorName + "_" + moduleName + ".dm")
	copyFile(moduleName + ".swf")
	copyDir("xml")