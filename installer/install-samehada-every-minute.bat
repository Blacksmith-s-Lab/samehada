@echo OFF
chcp 65001
cls

echo Este script vai registar um agendamento que vai limpar a memória de todos os processos a cada minuto
echo.
set /p DUMMY=Pressione ENTER para continuar ... 
cls

echo Certifique-se de executar este script com privilégios de administrador 
echo.
set /p DUMMY=Pressione ENTER para continuar ... 
cls

echo Precisamos copiar alguns arquivos para o system32
echo.
set /p DUMMY=Pressione ENTER para continuar ... 
cls

xcopy /Y /F "%~dp0..\output\samehada.exe" "C:\Windows\System32\samehada.exe*"
cls

set /p username="Informe o nome do usuário (administrador): "
cls

set /p passwd="Informe a senha do usuário (administrador): "
cls

schtasks /create /sc minute /mo 1 /tn "samehada-every-minute" /tr "C:\Windows\System32\samehada.exe -a -h" /RU %username% /RP %passwd% /RL HIGHEST
echo.
set /p DUMMY=Pressione ENTER para concluir ...