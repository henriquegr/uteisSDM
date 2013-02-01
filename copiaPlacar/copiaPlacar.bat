@echo off
@cls

@echo:
@echo:
@echo ==============================================================================
@echo Pegando os IDs que interessam 
@bop_odump domsrvr role "name like '%~1'" persistent_id | grep role | sed "s/ .*//g" > origem.tmp
@set /p origem=<ORIGEM.tmp
@echo ID de Origem:  '%ORIGEM%' - %~1

bop_odump domsrvr role "name like '%~2'" persistent_id | grep role | sed "s/ .*//g" > destino.tmp
@set /p DESTINO=<destino.tmp
@echo ID de destino: '%DESTINO%' - %~2

IF [%DESTINO%] == []  goto :ERRO
IF [%ORIGEM%] == [] goto :ERRO


@echo:
@echo:
@echo ==============================================================================
@echo Fazendo Backup da User Query
SET NOMEBKP=User_Query_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

@pdm_extract User_Query > "%NOMEBKP%.bkp"

@echo:
@echo:
@echo ==============================================================================
@echo Criando os arquivos base para o samba-lele
@pdm_extract -f"Select * from User_Query where obj_persid='%ORIGEM%'" > origem.bkp
@pdm_extract -f"Select * from User_Query where obj_persid='%DESTINO%'" > destino.bkp

@pdm_extract -f"Select sequence, parent from User_Query where obj_persid = '%ORIGEM%' and parent>0" > pais_origem.tmp
@pdm_extract -f"Select sequence, parent from User_Query where obj_persid = '%DESTINO%' and parent>0" > pais_destino.tmp

@echo:
@echo:
@echo ==============================================================================
@echo Executando a copia
@type modelo.deref | sed "s/rule.*/rule = \"SELECT sequence FROM User_Query WHERE id=? and obj_persid='%ORIGEM%'\"/g" > destino_deref.tmp
@pdm_deref -s destino_deref.tmp  pais_origem.tmp > pais_para_deref.tmp

@pdm_extract -f"Select id from User_Query where role_persid='%DESTINO%'" > remover.tmp
@pdm_userload -r -f remover.tmp

@pdm_userload -r -f destino.bkp
@type origem.bkp | sed "s/%ORIGEM%/%DESTINO%/g" > destino_userload.tmp

@pdm_load -i -f destino_userload.tmp

@type modelo2.deref | sed "s/rule.*/rule = \"SELECT id FROM User_Query WHERE sequence=? and obj_persid='%DESTINO%'\"/g" > destino2_deref.tmp
@pdm_deref -s destino2_deref.tmp pais_para_deref.tmp > pais_userload.tmp
@pdm_userload -f pais_userload.tmp

@echo:
@echo:
@echo ==============================================================================
@echo Limpando a zona
@echo:
@echo:
@echo FEITO!!!!!


del *.tmp
goto :END

:ERRO
@echo:
@echo:
@echo ==============================================================================
@Echo ERRO!!!! - Nao encontrei um dos IDs. Olha direito o nome!!!
@echo ==============================================================================
@echo:
@echo:


:END


