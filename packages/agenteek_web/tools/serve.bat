@ECHO OFF

PUSHD "%~dp0.."

IF "%~1" == ":main" (
    CALL dart pub global run dhttpd --port=8123 --path=.\web
    EXIT /B
)

REM start CORS proxies
START "CORS-GitHub" /MIN CMD /D /C dart run .\tools\cors.dart https://api.githubcopilot.com 8125

CMD /D /C "%~f0" :main < nul

REM kill CORS proxies
TASKKILL /FI "WINDOWTITLE eq CORS-GitHub"
