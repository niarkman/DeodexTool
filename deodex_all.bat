::
:: Auto-deodexer for MIUI rom
:: Script created by niark@MAN! for MIUI France
:: File : deodex.bat
::

@echo off

:: Déclaration des variables & constantes
Set home=%CD%
Set workdir=%home%\Workdir
Set base=%home%\Base_ROM
Set out=%home%\Output_ROM
Set tools=%home%\Tools

FOR /R %base% %%i IN (*.zip) DO (
call deodex_rom %%~ni.zip %%~ni-deodexed.zip
)

:: FIN
cd %home%
:END