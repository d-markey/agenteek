PUSHD "%~dp0.."

CALL .\tools\build.bat

RMDIR /s /q ..\..\docs\agenteek_web

MKDIR ..\..\docs\agenteek_web

COPY .\web\*.html ..\..\docs\agenteek_web
COPY .\web\*.js ..\..\docs\agenteek_web
COPY .\web\*.css ..\..\docs\agenteek_web
