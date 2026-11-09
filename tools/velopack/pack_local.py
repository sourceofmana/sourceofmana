#!/usr/bin/env python3
#
# Pack a Windows export into a local Velopack feed, to test the installer and the updater.
# Requires the .NET 8 SDK: winget install Microsoft.DotNet.SDK.8
#
# Usage: python tools/velopack/pack_local.py <export dir> <version> [feed dir]
#
# Example:
#   python tools/velopack/pack_local.py build/export-0.0.9 0.0.9 build/velopack-setup
#   build/velopack-setup/SourceOfMana-win-Setup.exe
#   python tools/velopack/pack_local.py build/export-0.0.10 0.0.10
#   python -m http.server 8000 --directory build/velopack-feed
#   "$LOCALAPPDATA/SourceOfMana/current/Source of Mana.exe" --update-url=http://127.0.0.1:8000

import argparse
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

#
def ReadVersions():
	versions = {}
	for line in (ROOT / "versions.cfg").read_text().splitlines():
		key, sep, value = line.partition("=")
		if sep:
			versions[key.strip()] = value.strip()
	return versions

def GetRuntimeMajors(dotnet):
	output = subprocess.run([dotnet, "--list-runtimes"], capture_output=True, text=True, check=True).stdout
	return {int(major) for major in re.findall(r"^Microsoft\.NETCore\.App (\d+)\.", output, re.MULTILINE)}

def FindVpk(dotnet, tools, version):
	if not list(tools.glob("**/vpk.dll")):
		subprocess.run([dotnet, "tool", "install", "vpk", "--version", version, "--tool-path", str(tools)], check=True)

	runtimes = GetRuntimeMajors(dotnet)
	for dll in sorted(tools.glob("**/tools/net*/any/vpk.dll"), key=lambda path: float(path.parent.parent.name[3:]), reverse=True):
		if int(float(dll.parent.parent.name[3:])) in runtimes:
			return dll
	sys.exit("No vpk build matches the installed .NET runtimes, install the .NET 8 SDK")

#
def Main():
	parser = argparse.ArgumentParser(description="Pack a Windows export into a local Velopack feed.")
	parser.add_argument("export_dir")
	parser.add_argument("version")
	parser.add_argument("feed_dir", nargs="?", default="build/velopack-feed")
	args = parser.parse_args()

	dotnet = shutil.which("dotnet")
	if not dotnet:
		sys.exit("dotnet not found, install the .NET 8 SDK: winget install Microsoft.DotNet.SDK.8")

	velopack = ReadVersions()["VELOPACK"]
	vpk = FindVpk(dotnet, ROOT / "build" / ".tools" / f"vpk-{velopack}", velopack)

	command = [dotnet, str(vpk)]
	if platform.system() != "Windows":
		command.append("[win]")
	command += [
		"pack",
		"--packId", "SourceOfMana",
		"--packVersion", args.version,
		"--packTitle", "Source of Mana",
		"--packAuthors", "Manasource",
		"--packDir", args.export_dir,
		"--mainExe", "Source of Mana.exe",
		"--icon", str(ROOT / "data/press/logo/logo_colored.ico"),
		"--splashImage", str(ROOT / "data/press/installer/splash.png"),
		"--splashProgressColor", "#9A7D6B",
		"--skipVeloAppCheck",
		"--noPortable",
		"--outputDir", args.feed_dir,
	]
	subprocess.run(command, check=True)

	feedDir = Path(args.feed_dir).resolve()
	print(f'Feed ready in {feedDir}, serve it with: python -m http.server 8000 --directory "{feedDir}"')


if __name__ == "__main__":
	Main()
