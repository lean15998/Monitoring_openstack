Phân tích tiến trình


volatility -f THUTRANG-20220630-073335.raw imageinfo
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 pslist
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 psscan | grep 1176
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 psscan | grep 3168
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 psscan | grep 2788
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 pstree
Phân tích các tiến trình DLL

volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 1176
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 3168
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 2788

Mạng

volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 connections
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 connscan


Phân tích Registry

volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1176 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1984 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1944 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 printkey -K "Microsoft\Windows\CurrentVersion\Run"
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 filescan | grep -i "\Desktop"
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1176 -t Mutant
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1984 -t Mutant
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1944 -t Mutant
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 filescan | grep -i "\Desktop"
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1984 -t file
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1944 -t file
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 filescan | grep -i "\Desktop"
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 memdump -p 1176,1984,1944 -D .
strings 1176.dmp
strings 1984.dmp
strings 1944.dmp
DÒng thời gian

volatility -f THUTRANG-20220630-073335.raw  --profile WinXPSP2x86 timeliner --output-file=timeline.txt --output=body  
volatility -f THUTRANG-20220630-073335.raw  --profile WinXPSP2x86 mftparser --output-file=mftparser.txt --output=body
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 shellbags --output-file=shellbags.txt --output=body
cat timeline.txt >> largetimeliner.txt
cat mftparser.txt >> largetimeliner.txt
cat shellbags.txt >> largetimeliner.txt
mactime -b largetimeliner.txt -d -z UTC+0000 | egrep -i '(tasksche|@WanaDecryptor@|taskdl|taskse)'
