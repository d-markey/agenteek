PUSHD "%~dp0.."

CALL .\tools\build.bat

RMDIR /s /q ..\..\publish\agenteek_web

MKDIR ..\..\publish\agenteek_web

COPY .\web\*.html ..\..\publish\agenteek_web
COPY .\web\*.js ..\..\publish\agenteek_web
COPY .\web\*.css ..\..\publish\agenteek_web
