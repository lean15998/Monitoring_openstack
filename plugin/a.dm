Phân tích tiến trình


volatility -f THUTRANG-20220630-073335.raw imageinfo
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 pslist
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 pstree
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 psscan | grep 1176
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 psscan | grep 3168
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 psscan | grep 2788


Phân tích các tiến trình DLL

  volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 1176
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 3168
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 2788
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 dlllist -p 2820

Mạng

volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 connections
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 connscan


Phân tích Registry

volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1176 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1984 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1944 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 2820 -t key
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1176 -t Mutant
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1984 -t file
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 1944 -t file
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 handles -p 2820 -t file
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 printkey -K "Microsoft\Windows\CurrentVersion\Run"
volatility -f THUTRANG-20220630-073335.raw --profile WinXPSP2x86 memdump -p 1176,3168,2788,2820 -D .
strings 1176.dmp > 1176.txt

cat 1176.txt | grep "cmd.exe /c start /b @WanaDecryptor@.exe vs" -A 20
cat 1176.txt | grep "Microsoft Enhanced RSA and AES Cryptographic Provider" -A 50
cat 1176.txt | grep "gx7ekbenv2riucmf.onion" -A 10
cat 1176.txt | grep "msg/m_bulgarian.wnry" -A 40
cat 1176.txt |  grep "115p7UMMngoj1pMvkpHijcRdfJNXj6LrLn" -A 10










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
