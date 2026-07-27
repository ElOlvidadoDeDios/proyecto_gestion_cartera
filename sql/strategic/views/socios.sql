GO
CREATE OR ALTER VIEW gc_socios WITH ENCRYPTION AS
WITH
CTE_AUX_SOCIOS AS (
SELECT
	T_PRE.PERIODO,
--- Variables de agrupacion
	--- Identificador subrogado del asesor
	T_USU.ID_USER,
--- Variables de agregacion
	--- Numero de socios del periodo vigente
	COUNT(DISTINCT T_PRE.CUENTA) AS NroSocios
FROM
    PREEC T_PRE
    INNER JOIN SEGURIDAD.DBO.ANAREC T_ANA
		ON  T_ANA.ID_ANAREC = T_PRE.ID_ANA
		AND T_ANA.FLAG_ANAREC = 'A'
    INNER JOIN SEGURIDAD.dbo.USUARIOS T_USU
		ON  T_USU.ID_USER = T_ANA.ID_USER
    INNER JOIN SEGURIDAD.dbo.GRUPOUSER T_GRU
		ON  T_GRU.ID_GRUPO = T_USU.ID_GRUPO
		AND T_GRU.NOM_GRUPO =  'CREDITOS'
WHERE
	T_PRE.PERIODO IN ('202606','202607')
	AND T_PRE.SALDO_PRES > 0 -- Excluir socios que al cierre no tengan saldo
GROUP BY
	T_PRE.PERIODO,
	T_USU.ID_USER
),
CTE_AUX_SOCIOS_ANTERIORES AS (
SELECT
--- Variables de agrupacion
	T.PERIODO,
	T.ID_USER,
--- Variables de agregacion
	--- Numero de socios del periodo vigente
	T.NroSocios,
	--- Numero de socios del periodo anterior
	ISNULL(LAG(T.NroSocios) OVER(PARTITION BY T.ID_USER ORDER BY T.PERIODO), 0) AS NroSociosAnterior
FROM
	CTE_AUX_SOCIOS T
)
SELECT
--- Variables de agrupacion
	T.PERIODO AS Periodo,
	T.ID_USER AS IdSAsesor,
	T.NroSocios,
	T.NroSociosAnterior
FROM
	CTE_AUX_SOCIOS_ANTERIORES T
WHERE
	T.PERIODO = '202607'
GO
