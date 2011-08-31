::
:: Auto-deodexer for MIUI rom
:: Script created by niark@MAN! for MIUI France
:: Version : 1.1
:: File    : deodex.bat
::

@echo off

:: Vérification de des arguments 1 et 2
if (%1)==() GOTO END
if (%2)==() GOTO END

:: Déclaration des variables & constantes
Set home=%CD%
Set workdir=%home%\Workdir
Set base=%home%\Base_ROM
Set out=%home%\Output_ROM
Set tools=%home%\Tools

:: Décompression de la rom
echo Décompression de l'archive
echo %base%\%1%
cd %base%
rmdir /S /Q %workdir%\Rom_Decompressed
mkdir %workdir%\Rom_Decompressed
cd %workdir%\Rom_Decompressed
cmd /c "%tools%\7z.exe" x %base%\%1%

:: Récupération des fichiers à deodexer
rmdir /S /Q %workdir%\Origin
mkdir %workdir%\Origin
FOR /r %workdir%\Rom_Decompressed\system\framework\ %%i IN (*.odex) DO (
copy %workdir%\Rom_Decompressed\system\framework\%%~ni.odex %workdir%\Origin
copy %workdir%\Rom_Decompressed\system\framework\%%~ni.jar %workdir%\Origin
)
FOR /r %workdir%\Rom_Decompressed\system\app\ %%i IN (*.odex) DO (
copy %workdir%\Rom_Decompressed\system\app\%%~ni.odex %workdir%\Origin
copy %workdir%\Rom_Decompressed\system\app\%%~ni.apk %workdir%\Origin
)

:: Deodex des JAR
echo Deodexing JAR
rmdir /S /Q %workdir%\Deodexed
mkdir %workdir%\Deodexed
FOR /r %workdir%\Origin %%i IN (*.jar) DO (
:: Décompression du JAR
echo ## %%~nxi - %%~ni
mkdir %workdir%\Deodexed\%%~ni
cd %workdir%\Deodexed\%%~ni
cmd /c "%tools%\7z.exe" x %%i
:: Deodex du JAR
cd %workdir%\Origin
java -Xmx512m -jar %tools%\baksmali.jar -c core.jar:core-junit.jar:ext.jar:framework.jar:android.policy.jar:services.jar:javax.obex.jar:bouncycastle.jar:com.android.location.provider.jar -d framework -d deodexed_JAR -x %workdir%\Origin\%%~ni.odex -o %workdir%\Deodexed\%%~ni\smali
java -jar  %tools%\smali.jar %workdir%\Deodexed\%%~ni\smali -o "%workdir%\Deodexed\%%~ni\classes.dex"
:: Copie du JAR d'origine
copy %%i %workdir%\Deodexed
:: Intégration de classes.dex
cd %workdir%\Deodexed\%%~ni
cmd /c "%tools%\7z.exe" u %workdir%\Deodexed\%%~ni.jar classes.dex
:: Nettoyage
cd %workdir%\Deodexed
rmdir /S /Q %workdir%\Deodexed\%%~ni
)

:: Deodex des APK
echo Deodexing APK
FOR /r %workdir%\Origin %%i IN (*.apk) DO (
:: Décompression de l'APK
echo ## %%~nxi - %%~ni
mkdir %workdir%\Deodexed\%%~ni
cd %workdir%\Deodexed\%%~ni
cmd /c "%tools%\7z.exe" x %%i
:: Deodex de l'APK
cd %workdir%\Origin
java -Xmx512m -jar %tools%\baksmali.jar -c core.jar:core-junit.jar:ext.jar:framework.jar:android.policy.jar:services.jar:javax.obex.jar:bouncycastle.jar:com.android.location.provider.jar -d framework -d deodexed_JAR -x %workdir%\Origin\%%~ni.odex -o %workdir%\Deodexed\%%~ni\smali
if "%%~ni"=="Mms" (
echo ## Modification attendue de MmsTabActivity.smali
cmd /c %tools%\notepad2 %workdir%\Deodexed\%%~ni\smali\com\android\mms\ui\MmsTabActivity.smali)
echo ## Compilation de %%~ni
java -jar  %tools%\smali.jar %workdir%\Deodexed\%%~ni\smali -o "%workdir%\Deodexed\%%~ni\classes.dex"
:: Copie de l'APK d'origine
copy %%i %workdir%\Deodexed\%%~ni.zip
:: Intégration de classes.dex
cd %workdir%\Deodexed\%%~ni
cmd /c "%tools%\7z.exe" u %workdir%\Deodexed\%%~ni.zip classes.dex
::ZipAlign
cd %workdir%\Deodexed
move /Y %%~ni.zip %%~ni._apk
%tools%\zipalign -f 4 %workdir%\Deodexed\%%~ni._apk %workdir%\Deodexed\%%~ni.apk
:: Nettoyage
cd %workdir%\Deodexed
del %%~ni._apk
rmdir /S /Q %workdir%\Deodexed\%%~ni
)

cd %home%

:: Intégration des JAR et des APK
xcopy /SQY %workdir%\Deodexed\*.jar %workdir%\Rom_Decompressed\system\framework\
xcopy /SQY %workdir%\Deodexed\*.apk %workdir%\Rom_Decompressed\system\app\

:: Suppression des ODEX
del /Q %workdir%\Rom_Decompressed\system\framework\*.odex
del /Q %workdir%\Rom_Decompressed\system\app\*.odex

:: Création du zip
cd %workdir%\Rom_Decompressed
cmd /c "%tools%\7z.exe a %out%\%2%_unsigned.zip *"

:: Signature
cd %out%
java -Xmx512m -jar %tools%\signapk.jar -w %tools%\testkey.x509.pem %tools%\testkey.pk8 %2_unsigned.zip %2.zip
::del /Q %2_unsigned.zip

:: Nettoyage
pause
rmdir /S /Q %workdir%\Deodexed\
rmdir /S /Q %workdir%\Origin\
rmdir /S /Q %workdir%\Rom_Decompressed\

:: FIN
cd %home%
:END