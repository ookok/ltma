$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# MSVC setup
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\;$env:PATH"

# Include paths for C compilation (workaround: cc-flags not forwarded by moonc)
$env:INCLUDE = @(
  "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\include"
  "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\VS\include"
  "C:\Program Files (x86)\Windows Kits\10\include\10.0.26100.0\ucrt"
  "C:\Program Files (x86)\Windows Kits\10\include\10.0.26100.0\um"
  "C:\Program Files (x86)\Windows Kits\10\include\10.0.26100.0\shared"
  "$ProjectRoot\.mooncaches\tree-sitter\include"
  "$ProjectRoot\.mooncaches\onnxruntime\onnxruntime-win-x64-1.21.0\include"
) -join ";"

# Library paths for linking (#pragma comment(lib, ...) + LIB env)
$env:LIB = @(
  "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\lib\x64"
  "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\ucrt\x64"
  "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64"
  "$ProjectRoot\.mooncaches\tree-sitter\lib"
  "$ProjectRoot\.mooncaches\onnxruntime\onnxruntime-win-x64-1.21.0\lib"
) -join ";"

moon build --target native @args
