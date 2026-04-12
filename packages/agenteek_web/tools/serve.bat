@ECHO OFF

PUSHD "%~dp0.."

IF "%~1" == ":main" (
    CALL dart pub global run dhttpd --port=8123 --path=.\web
    EXIT /B
)

REM start CORS proxies
START "CORS-Imaging" /MIN CMD /D /C dart run .\tools\cors.dart https://demo-imaging-v3.castsoftware.com 8124
START "CORS-Highlight" /MIN CMD /D /C dart run .\tools\cors.dart http://localhost:5185 8125
START "CORS-GitHub" /MIN CMD /D /C dart run .\tools\cors.dart https://api.githubcopilot.com 8126
CMD /D /C "%~f0" :main < nul

REM kill CORS proxies
TASKKILL /FI "WINDOWTITLE eq CORS-GitHub"
TASKKILL /FI "WINDOWTITLE eq CORS-Highlight"
TASKKILL /FI "WINDOWTITLE eq CORS-Imaging"
