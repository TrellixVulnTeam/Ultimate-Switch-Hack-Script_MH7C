::Script by Shadow256
Setlocal enabledelayedexpansion
@echo off
chcp 65001 >nul
IF EXIST templogs (
	del /q templogs 2>nul
	rmdir /s /q templogs 2>nul
)
mkdir templogs
IF EXIST "tools\packs_version.txt" (
	echo Il semble qu'une mise à jour des packs via le script ait échouée précédemment et n'ai pas été réussie depuis, par sécurité ce script va donc s'arrêter.
	echo Si vous êtes certains d'avoir mis à jour correctement le dossier des packs (par exemple en retéléchargeant le script et en extrayant le dossier "tools\sd_switch" de l'archive dans le dossier "tools" du script, vous pouvez supprimer manuellement le fichier "tools\packs_version.txt" et relancer ce script et cette erreur n'apparaîtra plus. Notez que si ceci n'a pas été fait correctement, ce script pourrait avoir des comportements anormaux.
	goto:endscript
)
echo Ce script va vous permettre de préparer une carte SD pour le hack Switch en y installant les outils importants.
echo Pendant le script, les droits administrateur seront peut-être demandé.
echo.
echo ATTENTION: Si vous décidez de formater votre carte SD, toutes les données de celle-ci seront perdues. Sauvegardez les données importante avant de formater.
echo ATTENTION: Choisissez bien la lettre du volume qui correspond à votre carte SD car aucune vérification ne pourra être faites à ce niveau là.
echo.
echo Je ne pourrais être tenu pour responsable de quelque domage que se soit lié à l'utilisation de ce script ou des outils qu'il contient.
echo.
echo.
pause
:define_volume_letter
%windir%\system32\wscript //Nologo //B TOOLS\Storage\functions\list_volumes.vbs
TOOLS\gnuwin32\bin\grep.exe -c "" <templogs\volumes_list.txt >templogs\count.txt
set /p tempcount=<templogs\count.txt
del /q templogs\count.txt
IF "%tempcount%"=="0" (
	echo Aucun disque compatible trouvé. Veuillez insérer votre carte SD puis relancez le script.
	echo Le script va maintenant s'arrêté.
	goto:endscript
)
echo.
echo Liste des disques:
:list_volumes
IF "%tempcount%"=="0" goto:set_volume_letter
TOOLS\gnuwin32\bin\tail.exe -%tempcount% <templogs\volumes_list.txt | TOOLS\gnuwin32\bin\head.exe -1
set /a tempcount-=1
goto:list_volumes
:set_volume_letter
echo.
echo.
set volume_letter=
set /p volume_letter=Entrez la lettre du volume de la SD que vous souhaitez utiliser:
call TOOLS\Storage\functions\strlen.bat nb "%volume_letter%"
IF %nb% EQU 0 (
	echo La lettre de lecteur ne peut être vide. Réessayez.
	goto:define_volume_letter
)
set volume_letter=%volume_letter:~0,1%
set nb=1
CALL TOOLS\Storage\functions\CONV_VAR_to_MAJ.bat volume_letter
set i=0
:check_chars_volume_letter
IF %i% LSS %nb% (
	set check_chars_volume_letter=0
	FOR %%z in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
		IF "!volume_letter:~%i%,1!"=="%%z" (
			set /a i+=1
			set check_chars_volume_letter=1
			goto:check_chars_volume_letter
		)
	)
	IF "!check_chars_volume_letter!"=="0" (
		echo Un caractère non autorisé a été saisie dans la lettre du lecteur. Recommencez.
		set volume_letter=
		goto:define_volume_letter
	)
)
IF NOT EXIST "%volume_letter%:\" (
	echo Ce volume n'existe pas. Recommencez.
	set volume_letter=
	goto:define_volume_letter
)
TOOLS\gnuwin32\bin\grep.exe "Lettre volume=%volume_letter%" <templogs\volumes_list.txt | TOOLS\gnuwin32\bin\cut.exe -d ; -f 1 | TOOLS\gnuwin32\bin\cut.exe -d = -f 2 > templogs\tempvar.txt
set /p temp_volume_letter=<templogs\tempvar.txt
IF NOT "%volume_letter%"=="%temp_volume_letter%" (
	echo Cette lettre de volume n'est pas dans la liste. Recommencez.
	goto:define_volume_letter
)
set /p format_choice=Souhaitez-vous formaté la SD (volume "%volume_letter%")? (O/n):
IF NOT "%format_choice%"=="" set format_choice=%format_choice:~0,1%
IF /i "%format_choice%"=="o" (
	echo.
	echo Quel type de formatage souhaitez-vous effectuer:
	echo 1: EXFAT (la Switch doit avoir le support pour ce format d'installé^)?
	echo 2: FAT32 (limité au fichier de moins de 4 GO^)?
	echo Tout autre choix: Annule le formatage.
	echo.
	set /p format_type=Choisissez le type de formatage à effectuer:
) else (
	goto:copy_to_sd
)
IF "%format_type%"=="1" goto:format_exfat
IF "%format_type%"=="2" goto:format_fat32
set format_choice=
goto:copy_to_sd
:format_exfat
echo Formatage en cours...
echo.
chcp 850 >nul
format %volume_letter%: /X /Q /FS:EXFAT
IF %errorlevel% NEQ 0 (
	chcp 65001 >nul
	echo Un problème s'est produit pendant la tentative de formatage, le script va maintenant s'arrêter.
	goto:endscript
) else (
chcp 65001 >nul
	echo Formatage effectué avec succès.
	echo.
	goto:copy_to_sd
)
:format_fat32
echo Formatage en cours...
echo.
TOOLS\fat32format\fat32format.exe -q -c128 %volume_letter%
echo.
IF "%ERRORLEVEL%"=="5" (
	echo La demande d'élévation n'a pas été acceptée, le formatage est annulé.
	::echo.
	goto:copy_to_sd
)
IF "%ERRORLEVEL%"=="32" (
	echo Le formatage n'a pas été effectué.
	echo Essayez d'éjecter proprement votre clé USB, réinsérez-là et relancez immédiatement ce script.
	echo Vous pouvez également essayer de fermer toutes les fenêtres de l'explorateur Windows avant le formatage, parfois cela règle le bug.
	echo.
	echo Le script va maintenant s'arrêter.
	goto:endscript
)
IF "%ERRORLEVEL%"=="2" (
	echo Le volume à formater n'existe pas. Vous avez peut-être débranché ou éjecté la carte SD durant ce script.
	echo.
	echo Le script va maintenant s'arrêter.
	goto:endscript
)
IF NOT "%ERRORLEVEL%"=="1" (
	IF NOT "%ERRORLEVEL%"=="0" (
		echo Une erreur inconue s'est produite pendant le formatage.
		echo.
		echo Le script va maintenant s'arrêter.
		goto:endscript
	)
)
IF "%ERRORLEVEL%"=="1" (
	echo Le formatage a été annulé par l'utilisateur.
)
IF "%ERRORLEVEL%"=="0" (
	echo Formatage effectué avec succès.
)
:copy_to_sd
set /p cancel_copy=Souhaitez-vous annuler la copie des différents fichiers vers votre SD (volume "%volume_letter%")? (O/n):
IF NOT "%cancel_copy%"=="" set cancel_copy=%cancel_copy:~0,1%
IF /i "%cancel_copy%"=="o" goto:endscript
set /p launch_manual=Souhaitez-vous lancer la page d'information sur se qui peut être copié (vivement conseillé)? (O/n):
IF NOT "%launch_manual%"=="" set launch_manual=%launch_manual:~0,1%
IF /i "%launch_manual%"=="o" (
	start DOC\files\sd_prepare.html
)

set /p copy_sdfilesswitch_pack=Souhaitez-vous copier le pack pour, entre autres, lancer Atmosphere via Hekate (pack Kosmos, anciennement nommé SDFilesSwitch)? (O/n):
IF NOT "%copy_sdfilesswitch_pack%"=="" set copy_sdfilesswitch_pack=%copy_sdfilesswitch_pack:~0,1%
IF /i "%copy_sdfilesswitch_pack%"=="o" goto:ask_nogc_sdfilesswitch
goto:skip_ask_nogc_sdfilesswitch
:ask_nogc_sdfilesswitch
	echo.
	echo Souhaitez-vous activer le patch NOGC pour Kosmos  (firmware 4.0.0 et supérieur^)?
	echo Ce patch est utile pour ceux ayant mis à jour avec la méthode ChoiDuJour à partir du firmware 3.0.2 et inférieur et ne voulant pas que le firmware du port cartouche soit mis à jour, permettant ainsi le downgrade en-dessous de la version 4.0.0 sans perdre l'usage du port cartouche.
	echo Attention,, si un firmware supérieur au 4.0.0 est chargé une seule fois par le bootloader de Nintendo (démarrage classique^) ou sans ce patche, le firmware du port cartouche sera mis à jour et donc l'activation de ce patch sera inutile.
	set /p sdfilesswitch_enable_nogc_patch=Souhaitez-vous activer le patch nogc? (O/n^):
	IF NOT "%sdfilesswitch_enable_nogc_patch%"=="" set sdfilesswitch_enable_nogc_patch=%sdfilesswitch_enable_nogc_patch:~0,1%
:skip_ask_nogc_sdfilesswitch

set /p copy_atmosphere_pack=Souhaitez-vous copier le pack pour lancer Atmosphere via le payload Fusee-primary d'Atmosphere (CFW Atmosphere complet)? (O/n):
IF NOT "%copy_atmosphere_pack%"=="" set copy_atmosphere_pack=%copy_atmosphere_pack:~0,1%
IF /i "%copy_atmosphere_pack%"=="o" goto:ask_nogc_atmosphere
goto:skip_ask_nogc_atmosphere
	:ask_nogc_atmosphere
	echo.
	echo Souhaitez-vous activer le patch NOGC pour Atmosphere  (firmware 4.0.0 et supérieur^)?
	echo Ce patch est utile pour ceux ayant mis à jour avec la méthode ChoiDuJour à partir du firmware 3.0.2 et inférieur et ne voulant pas que le firmware du port cartouche soit mis à jour, permettant ainsi le downgrade en-dessous de la version 4.0.0 sans perdre l'usage du port cartouche.
	echo Attention,, si un firmware supérieur au 4.0.0 est chargé une seule fois par le bootloader de Nintendo (démarrage classique^) ou sans ce patche, le firmware du port cartouche sera mis à jour et donc l'activation de ce patch sera inutile.
	set /p atmosphere_enable_nogc_patch=Souhaitez-vous activer le patch nogc? (O/n^):
	IF NOT "%atmosphere_enable_nogc_patch%"=="" set atmosphere_enable_nogc_patch=%atmosphere_enable_nogc_patch:~0,1%
:skip_ask_nogc_atmosphere

set /p copy_reinx_pack=Souhaitez-vous copier le pack pour lancer ReiNX? (O/n):
IF NOT "%copy_reinx_pack%"=="" set copy_reinx_pack=%copy_reinx_pack:~0,1%
IF /i "%copy_reinx_pack%"=="o" (
	echo.
	echo Souhaitez-vous activer le patch NOGC pour ReiNX (firmware 4.0.0 et supérieur^)?
	echo Ce patch est utile pour ceux ayant mis à jour avec la méthode ChoiDuJour à partir du firmware 3.0.2 et inférieur et ne voulant pas que le firmware du port cartouche soit mis à jour, permettant ainsi le downgrade en-dessous de la version 4.0.0 sans perdre l'usage du port cartouche.
	echo Attention,, si un firmware supérieur au 4.0.0 est chargé une seule fois par le bootloader de Nintendo (démarrage classique^) ou sans ce patche, le firmware du port cartouche sera mis à jour et donc l'activation de ce patch sera inutile.
	set /p reinx_enable_nogc_patch=Souhaitez-vous activer le patch nogc? (O/n^):
	IF NOT "!reinx_enable_nogc_patch!"=="" set reinx_enable_nogc_patch=!reinx_enable_nogc_patch:~0,1!
)

set /p copy_sxos_pack=Souhaitez-vous copier le pack pour lancer SXOS? (O/n):
IF NOT "%copy_sxos_pack%"=="" set copy_sxos_pack=%copy_sxos_pack:~0,1%

set /p copy_memloader=Souhaitez-vous copier les fichiers nécessaire à Memloader pour monter la SD, la partition EMMC, la partition Boot0 ou la partition Boot1 sur un PC en lançant simplement le payload de Memloader? (Si la copie de SXOS a été souhaité, le payload sera aussi copié à la racine de la SD pour pouvoir le lancer grâce au payload de SXOS) (O/n):
IF NOT "%copy_memloader%"=="" set copy_memloader=%copy_memloader:~0,1%

IF /i "%copy_sxos_pack%"=="o" (
	set /p copy_payloads=Souhaitez-vous copier les fichiers de payloads des fonctions choisient précédemment à la racine de la SD pour être compatible avec le lancement de payloads du payload SX_Loader? (O/n^):
	IF NOT "!copy_payloads!"=="" set copy_payloads=!copy_payloads:~0,1!
)
set /p copy_emu=Souhaitez-vous copier le pack d'émulateurs? (O/n):
IF NOT "%copy_emu%"=="" set copy_emu=%copy_emu:~0,1%
IF /i "%copy_emu%"=="o" (
	IF /i NOT "%del_files_dest_copy%"=="o" (
		set /p keep_emu_configs=Souhaitez-vous concerver vos anciens fichiers de configurations d'émulateurs? (O/n^):
		IF NOT "!keep_emu_configs!"=="" set keep_emu_configs=!keep_emu_configs:~0,1!
	)
)
:define_select_profile
echo Sélection du profile pour la copie des homebrews optionnels:
set /a temp_count=1
copy nul templogs\profiles_list.txt >nul
IF NOT EXIST "tools\sd_switch\mixed\profiles\*.ini" (
	goto:no_profile_created
)
cd tools\sd_switch\mixed\profiles
for %%p in (*.ini) do (
	set temp_profilename=%%p
	set temp_profilename=!temp_profilename:~0,-4!
	echo !temp_count!: !temp_profilename!
	echo %%p>> ..\..\..\..\templogs\profiles_list.txt
	set /a temp_count+=1
)
cd ..\..\..\..
:no_profile_created
IF EXIST "tools\default_configs\mixed_profile_all.ini" (
	echo %temp_count%: Tous les homebrews optionnels.
) else (
	set /a temp_count-=1
	set no_default_config=Y
)
echo 0: Accéder à la gestion des profiles.
echo Tout autre choix: Ne copier aucun des homebrews optionnels.
echo.
set profile_path=
set mixed_profile=
set /p mixed_profile=Choisissez un profile: 
IF "%mixed_profile%"=="" (
	set pass_copy_mixed_pack=Y
	goto:skip_verif_mixed_profile
)
call TOOLS\Storage\functions\strlen.bat nb "%mixed_profile%"
set i=0
:check_chars_mixed_profile
IF %i% NEQ %nb% (
	set check_chars=0
	FOR %%z in (0 1 2 3 4 5 6 7 8 9) do (
		IF "!mixed_profile:~%i%,1!"=="%%z" (
			set /a i+=1
			set check_chars=1
			goto:check_chars_mixed_profile
		)
	)
	IF "!check_chars!"=="0" (
		set pass_copy_mixed_pack=Y
		goto:skip_verif_mixed_profile
	)
)
IF %mixed_profile% GTR %temp_count% (
	set pass_copy_mixed_pack=Y
		goto:skip_verif_mixed_profile
)
IF "%mixed_profile%"=="0" (
	call tools\Storage\mixed_pack_profiles_management.bat
	goto:define_select_profile
)
IF %mixed_profile% EQU %temp_count% (
	IF NOT "%no_default_config%"=="Y" (
		set profile_path=tools\default_configs\mixed_profile_all.ini
		goto:skip_verif_mixed_profile
	)
)
TOOLS\gnuwin32\bin\sed.exe -n %mixed_profile%p <templogs\profiles_list.txt > templogs\tempvar.txt
set /p profile_path=<templogs\tempvar.txt
set profile_path=tools\sd_switch\mixed\profiles\%profile_path%
:skip_verif_mixed_profile
del /q templogs\profiles_list.txt >nul
:define_del_files_dest_copy
set del_files_dest_copy=
IF /i NOT "%format_choice%"=="o" (
	echo Suppression de données de la SD:
	echo 1: Remettre les données de tous les CFWs à zéro sur la SD ^(supprimera les thèmes, configurations personnels, mods de jeux car les dossiers "titles" seront remis à zéro... donc bien sauvegarder vos données personnelles si vous souhaitez les concerver^)?
	echo 2: Supprimer toutes les données de la SD?
	echo 0: Copier normalement les fichiers sans supprimer de données de la SD?
	echo.
	set /p del_files_dest_copy=Faites votre choix: 
) else (
	set del_files_dest_copy=0
)
IF "%del_files_dest_copy%"=="1" goto:confirm_settings
IF "%del_files_dest_copy%"=="2" goto:confirm_settings
IF "%del_files_dest_copy%"=="0" goto:confirm_settings
echo Choix inexistant.
goto:define_del_files_dest_copy

:confirm_settings
echo.
echo Résumé de se qui sera copié sur la SD, lecteur "%volume_letter%:":
echo.
echo CFWs et packs:
IF /i "%copy_sdfilesswitch_pack%"=="o" (
	IF /i "%sdfilesswitch_enable_nogc_patch%"=="o" (
		echo Pack Kosmos avec le patche NOGC
	) else (
	echo Pack Kosmos
	)
)
IF /i "%copy_atmosphere_pack%"=="o" (
	IF /i "%atmosphere_enable_nogc_patch%"=="o" (
		echo Pack Atmosphere avec le patche NOGC
	) else (
	echo Pack Atmosphere
	)
)
IF /i "%copy_reinx_pack%"=="o" (
	IF /i "%reinx_enable_nogc_patch%"=="o" (
		echo Pack ReiNX avec le patche NOGC
	) else (
	echo Pack ReiNX
	)
)
IF /i "%copy_sxos_pack%"=="o" (
	IF /i "%copy_payloads%"=="o" (
		echo Pack SX OS avec copie de payloads des autres CFWs sélectionnés à la racine de la SD pour être lancés via le SX Loader
	) else (
		echo Pack SX OS
	)
)
IF /i "%copy_memloader%"=="o" echo Pack Memloader
IF /i "%copy_emu%"=="o" (
	IF /i "%keep_emu_configs%"=="o" (
		echo Pack d'émulateurs avec concervation des fichiers de configurations de ceux-ci sur la SD
	) else (
		echo Pack d'émulateurs avec suppression des fichiers de configurations de ceux-ci sur la SD
	)
)
echo.
echo Homebrews optionnels:
IF "%pass_copy_mixed_pack%"=="Y" (
	echo Aucun homebrew optionnel ne sera copié.
) else (
	tools\gnuwin32\bin\sort.exe -n "%profile_path%"
)
echo.
IF /i "%del_files_dest_copy%"=="1" echo Attention: Les fichiers de tous les CFWs seront réinitialisé avant la copie, dossier "titles" de ceux-ci inclus.
IF /i "%del_files_dest_copy%"=="2" echo Attention: Les fichiers de la SD seront intégralement supprimés avant la copie.
IF /i "%del_files_dest_copy%"=="0" echo Les fichiers de la SD seront concervés et seul les fichiers mis à jour seront remplacés.
set confirm_copy=
set /p confirm_copy=Souhaitez-vous confirmer ceci? (O/n): 
IF /i "%confirm_copy%"=="o" (
	goto:begin_copy
) else IF /i "%confirm_copy%"=="n" (
	echo Opération annulée.
	goto:endscript
) else (
	echo Choix inexistant.
	goto:confirm_settings
)

:begin_copy
echo Copie en cours...

IF /i "%del_files_dest_copy%"=="1" (
	call :delete_cfw_files
	set del_files_dest_copy=0
) else IF /i "%del_files_dest_copy%"=="2" (
	rmdir /s /q "%volume_letter%:\" >nul 2>&1
	set del_files_dest_copy=0
)

IF /i "%copy_atmosphere_pack%"=="o" (
	IF EXIST "%volume_letter%:\atmosphere\kip_patches\fs_patches" rmdir /s /q "%volume_letter%:\atmosphere\kip_patches\fs_patches" >nul
	IF EXIST "%volume_letter%:\atmosphere\exefs_patches" rmdir /s /q "%volume_letter%:\atmosphere\exefs_patches" >nul
	%windir%\System32\Robocopy.exe TOOLS\sd_switch\atmosphere %volume_letter%:\ /e >nul
	IF /i "%copy_payloads%"=="o" copy /V /B TOOLS\sd_switch\payloads\Atmosphere_fusee-primary.bin %volume_letter%:\Atmosphere_fusee-primary.bin >nul
	IF /i "%copy_sdfilesswitch_pack%"=="o" copy /V /B TOOLS\sd_switch\payloads\Atmosphere_fusee-primary.bin %volume_letter%:\bootloader\payloads\Atmosphere_fusee-primary.bin >nul
	IF EXIST "%volume_letter%:\switch\GagOrder.nro" del /q "%volume_letter%:\switch\GagOrder.nro" >nul
	IF EXIST "%volume_letter%:\atmosphere\exefs_patches\Signature_Patches_by_br4z0rf_and_Jakibaki" rmdir /s /q "%volume_letter%:\atmosphere\exefs_patches\Signature_Patches_by_br4z0rf_and_Jakibaki" >nul
	IF EXIST "%volume_letter%:\switch\appstore\res" rmdir /s /q "%volume_letter%:\switch\appstore\res" >nul
	IF EXIST "%volume_letter%:\BCT.ini" del /q "%volume_letter%:\BCT.ini" >nul
	IF EXIST "%volume_letter%:\fusee-secondary.bin" del /q "%volume_letter%:\fusee-secondary.bin" >nul
	IF /i "%atmosphere_enable_nogc_patch%"=="O" (
		%windir%\System32\Robocopy.exe TOOLS\sd_switch\atmosphere_patches_nogc %volume_letter%:\ /e >nul
	)
	copy /V /B TOOLS\sd_switch\payloads\Hekate.bin %volume_letter%:\atmosphere\reboot_payload.bin >nul
	copy /V /B TOOLS\sd_switch\payloads\Lockpick_RCM.bin %volume_letter%:\bootloader\payloads\Lockpick_RCM.bin >nul
	del /Q /S "%volume_letter%:\atmosphere\.emptydir" >nul
)

IF /i "%copy_sdfilesswitch_pack%"=="o" (
	IF EXIST "%volume_letter%:\atmosphere\kip_patches\fs_patches" rmdir /s /q "%volume_letter%:\atmosphere\kip_patches\fs_patches" >nul
	IF EXIST "%volume_letter%:\atmosphere\exefs_patches" rmdir /s /q "%volume_letter%:\atmosphere\exefs_patches" >nul
	%windir%\System32\Robocopy.exe TOOLS\sd_switch\sdfilesswitch %volume_letter%:\ /e >nul
	IF /i "%copy_payloads%"=="o" copy /V /B TOOLS\sd_switch\payloads\Hekate.bin %volume_letter%:\Hekate.bin >nul
	IF /i "%copy_memloader%"=="o" copy /V /B TOOLS\sd_switch\payloads\memloader.bin %volume_letter%:\bootloader\payloads\memloader.bin >nul
	IF EXIST "%volume_letter%:\bootlogo.bmp" del /q "%volume_letter%:\bootlogo.bmp" >nul
	IF EXIST "%volume_letter%:\hekate_ipl.ini" del /q "%volume_letter%:\hekate_ipl.ini" >nul
	IF EXIST "%volume_letter%:\switch\GagOrder.nro" del /q "%volume_letter%:\switch\GagOrder.nro" >nul
	IF EXIST "%volume_letter%:\atmosphere\exefs_patches\Signature_Patches_by_br4z0rf_and_Jakibaki" rmdir /s /q "%volume_letter%:\atmosphere\exefs_patches\Signature_Patches_by_br4z0rf_and_Jakibaki" >nul
	IF EXIST "%volume_letter%:\switch\appstore\res" rmdir /s /q "%volume_letter%:\switch\appstore\res" >nul
	IF EXIST "%volume_letter%:\switch\CFWSettings" rmdir /s /q "%volume_letter%:\switch\CFWSettings" >nul
	IF EXIST "%volume_letter%:\switch\CFW-Settings" rmdir /s /q "%volume_letter%:\switch\CFW-Settings" >nul
	IF EXIST "%volume_letter%:\modules\atmosphere\fs_mitm.kip" del /q "%volume_letter%:\modules\atmosphere\fs_mitm.kip" >nul
	IF /i "%sdfilesswitch_enable_nogc_patch%"=="O" (
		%windir%\System32\Robocopy.exe TOOLS\sd_switch\sdfilesswitch_patches_nogc %volume_letter%:\ /e >nul
	)
	copy /V /B TOOLS\sd_switch\payloads\Hekate.bin %volume_letter%:\atmosphere\reboot_payload.bin >nul
	copy /V /B TOOLS\sd_switch\payloads\Lockpick_RCM.bin %volume_letter%:\bootloader\payloads\Lockpick_RCM.bin >nul
	del /Q /S "%volume_letter%:\bootloader\.emptydir" >nul
)

IF /i "%copy_reinx_pack%"=="o" (
	%windir%\System32\Robocopy.exe TOOLS\sd_switch\reinx %volume_letter%:\ /e >nul
	IF /i "%reinx_enable_nogc_patch%"=="n" del /q %volume_letter%:\ReiNX\nogc >nul
	IF /i "%copy_payloads%"=="o" copy /V /B TOOLS\sd_switch\payloads\ReiNX.bin %volume_letter%:\ReiNX.bin >nul
	IF /i "%copy_sdfilesswitch_pack%"=="o" copy /V /B TOOLS\sd_switch\payloads\ReiNX.bin %volume_letter%:\bootloader\payloads\ReiNX.bin >nul
	IF EXIST "%volume_letter%:\switch\GagOrder.nro" del /q "%volume_letter%:\switch\GagOrder.nro" >nul
	IF EXIST "%volume_letter%:\switch\appstore\res" rmdir /s /q "%volume_letter%:\switch\appstore\res" >nul
	IF EXIST "%volume_letter%:\ReiNX\titles\010000000000100D" rmdir /s /q "%volume_letter%:\ReiNX\titles\010000000000100D" >nul
)

IF /i "%copy_sxos_pack%"=="o" (
	%windir%\System32\Robocopy.exe TOOLS\sd_switch\sxos %volume_letter%:\ /e >nul
	IF /i "%copy_payloads%"=="o" copy /V /B TOOLS\sd_switch\payloads\SXOS.bin %volume_letter%:\SXOS.bin >nul
	IF /i "%copy_sdfilesswitch_pack%"=="o" copy /V /B TOOLS\sd_switch\payloads\SXOS.bin %volume_letter%:\bootloader\payloads\SXOS.bin >nul
	IF EXIST "%volume_letter%:\switch\GagOrder.nro" del /q "%volume_letter%:\switch\GagOrder.nro" >nul
	IF EXIST "%volume_letter%:\switch\appstore\res" rmdir /s /q "%volume_letter%:\switch\appstore\res" >nul
	copy /V /B TOOLS\sd_switch\payloads\Lockpick_RCM.bin %volume_letter%:\Lockpick_RCM.bin >nul
	del /Q /S "%volume_letter%:\sxos\.emptydir" >nul
)

IF /i "%copy_memloader%"=="o" (
	%windir%\System32\Robocopy.exe TOOLS\memloader\mount_discs %volume_letter%:\ /e >nul
	IF /i "%copy_sxos_pack%"=="o" copy /V /B TOOLS\memloader\memloader.bin %volume_letter%:\Memloader.bin >nul
	IF /i "%copy_sdfilesswitch_pack%"=="o" copy /V /B TOOLS\memloader\memloader.bin %volume_letter%:\bootloader\payloads\Memloader.bin >nul
)

IF /i "%copy_emu%"=="o" (
	IF EXIST "%volume_letter%:\switch.settings" move "%volume_letter%:\switch.settings" "%volume_letter%:\switch.settings.bak" >nul
			%windir%\System32\Robocopy.exe TOOLS\sd_switch\emulators %volume_letter%:\ /e >nul
	IF /i "%keep_emu_configs%"=="o" (
		del /q "%volume_letter%:\switch.settings" >nul
		move "%volume_letter%:\switch.settings.bak" "%volume_letter%:\switch.settings" >nul
	) else (
		IF EXIST "%volume_letter%:\switch.settings.bak" del /q "%volume_letter%:\switch.settings.bak" >nul
	)
)

:copy_mixed_pack
%windir%\System32\Robocopy.exe tools\sd_switch\mixed\base %volume_letter%:\ /e >nul
IF "%pass_copy_mixed_pack%"=="Y" goto:skip_copy_mixed_pack
tools\gnuwin32\bin\grep.exe -c "" <"%profile_path%" > templogs\tempvar.txt
set /p temp_count=<templogs\tempvar.txt
for /l %%i in (1,1,%temp_count%) do (
	TOOLS\gnuwin32\bin\sed.exe -n %%ip <"%profile_path%" >templogs\tempvar.txt
	set /p temp_homebrew=<templogs\tempvar.txt
	%windir%\System32\Robocopy.exe tools\sd_switch\mixed\modular\!temp_homebrew! %volume_letter%:\ /e >nul
)
:skip_copy_mixed_pack

del /Q /S "%volume_letter%:\switch\.emptydir" >nul
del /Q /S "%volume_letter%:\Backup\.emptydir" >nul
del /Q /S "%volume_letter%:\pk1decryptor\.emptydir" >nul
IF EXIST "%volume_letter%:\tinfoil\" del /Q /S "%volume_letter%:\tinfoil\.emptydir" >nul 2>&1
echo Copie terminée.
goto:endscript

:delete_cfw_files
IF EXIST "%volume_letter%:\atmosphere" rmdir /s /q "%volume_letter%:\atmosphere"
IF EXIST "%volume_letter%:\bootloader" rmdir /s /q "%volume_letter%:\bootloader"
IF EXIST "%volume_letter%:\config" rmdir /s /q "%volume_letter%:\config"
IF EXIST "%volume_letter%:\ftpd" rmdir /s /q "%volume_letter%:\ftpd"
IF EXIST "%volume_letter%:\modules" rmdir /s /q "%volume_letter%:\modules"
IF EXIST "%volume_letter%:\ReiNX" rmdir /s /q "%volume_letter%:\ReiNX"
IF EXIST "%volume_letter%:\sept" rmdir /s /q "%volume_letter%:\sept"
IF EXIST "%volume_letter%:\SlideNX" rmdir /s /q "%volume_letter%:\SlideNX"
IF EXIST "%volume_letter%:\sxos\titles" rmdir /s /q "%volume_letter%:\sxos\titles"
IF EXIST "%volume_letter%:\boot.dat" del /q "%volume_letter%:\boot.dat"
IF EXIST "%volume_letter%:\hbmenu.nro" del /q "%volume_letter%:\hbmenu.nro"
IF EXIST "%volume_letter%:\xor.play.json" del /q "%volume_letter%:\xor.play.json"
IF EXIST "%volume_letter%:\switch\Kip_Select" rmdir /s /q "%volume_letter%:\switch\Kip_Select"
IF EXIST "%volume_letter%:\switch\Kosmos-Toolbox" rmdir /s /q "%volume_letter%:\switch\Kosmos-Toolbox"
IF EXIST "%volume_letter%:\switch\KosmosUpdater" rmdir /s /q "%volume_letter%:\switch\KosmosUpdater"
IF EXIST "%volume_letter%:\switch\ldnmitm_config" rmdir /s /q "%volume_letter%:\switch\ldnmitm_config"
IF EXIST "%volume_letter%:\switch\ReiNXToolkit" rmdir /s /q "%volume_letter%:\switch\ReiNXToolkit"
IF EXIST "%volume_letter%:\switch\ROMMENU" rmdir /s /q "%volume_letter%:\switch\ROMMENU"
IF EXIST "%volume_letter%:\switch\reboot_to_payload" rmdir /s /q "%volume_letter%:\switch\reboot_to_payload"
IF EXIST "%volume_letter%:\switch\sx_installer" rmdir /s /q "%volume_letter%:\switch\sx_installer"
IF EXIST "%volume_letter%:\switch\SXDUMPER" rmdir /s /q "%volume_letter%:\switch\SXDUMPER"
exit /b

:endscript
pause
rmdir /s /q templogs
endlocal