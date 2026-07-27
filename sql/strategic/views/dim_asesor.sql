GO
CREATE OR ALTER VIEW gc_dim_asesor WITH ENCRYPTION AS
/*
Recuperados de tramo de mora superior al de un recuperador de agencia
se crean dentro de la agencia molino. Asi que hay que excluir a estos.
*/
--- ***************
WITH
--- ***************
CTE_AUX_ASESOR AS (
SELECT
	T_PRE.PERIODO AS Periodo,

--- ID Agencia Estratégica con soporte para 13 agencias
CASE
    --- Segmentar agencias digitales (Base SICOOP 98) de 1 y 2 dígitos
    WHEN T_ANA.ID_AGE = '98' THEN
        CASE
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%10' THEN '10' -- Lima San Juan de Lurigancho
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%11' THEN '11' -- Chiclayo
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%12' THEN '12' -- Arequipa
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%13' THEN '13' -- Pucallpa
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%6'  THEN '06' -- Juliaca
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%7'  THEN '07' -- Lima Los Olivos
            ELSE '98'
        END

    --- Segmentar sucursales de Wanchaq (01) y Magisterio (09)
    WHEN T_ANA.ID_AGE = '01' THEN
        CASE
            WHEN RTRIM(T_ANA.ID_USER) LIKE '%9' THEN '09'
            ELSE '01'
        END
    --- Preservar ID nativo para el resto de agencias comerciales fijas
    ELSE T_ANA.ID_AGE
END AS IdSAgencia,
	T_ANA.ID_USER AS IdSAsesor,
	T_PER.RAZON AS AsesorNombresApellidos,
	T_CAR.DESCRIP AS Cargo
FROM
	PREEC T_PRE
	INNER JOIN SEGURIDAD.DBO.ANAREC T_ANA
		ON	T_ANA.ID_ANAREC = T_PRE.ID_ANA AND
			T_ANA.FLAG_ANAREC = 'A'
	INNER JOIN SEGURIDAD.dbo.USUARIOS T_USU
		ON	T_USU.ID_USER = T_ANA.ID_USER
	INNER JOIN SEGURIDAD.dbo.GRUPOUSER T_GRU
		ON  T_GRU.ID_GRUPO = T_USU.ID_GRUPO
		AND T_GRU.NOM_GRUPO = 'CREDITOS'
    INNER JOIN SEGURIDAD.dbo.PERSONAL T_PER
		ON	T_PER.DNI = T_USU.DNI
    INNER JOIN SEGURIDAD.dbo.TCARGO_USER T_CAR
		ON	T_CAR.ID_CARGO  = T_PER.ID_CARGO
WHERE
	T_PRE.PERIODO  = '202607'
--- Considerar solo asesores vigentes
	AND T_PRE.SALDO_PRES > 0
--- Excluir casos excepcionales
	AND T_USU.ID_USER NOT IN (
	'PRECASTIGO' -- Cartera de castigos
	, 'RJULI6', 'RJULIACA', 'RLIMA7', 'RQUILLA3', 'RSICUA4' -- Carteras de recuperacion fuera de agencia
	, 'LHR5', 'HTEJ5', 'TKPN5', 'GHVJ5', 'OTA5', 'SDHF5', 'CMN5', 'HQND5' -- Recuperados de tramo de mora superior al de un recuperador de agencia
	)
)
SELECT DISTINCT
	T.Periodo,
	T.IdSAgencia,
	T.IdSAsesor,
	T.AsesorNombresApellidos,
    T.Cargo,
	ColocacionNumMeta = 30
FROM
	CTE_AUX_ASESOR T
--ORDER BY
--	IdSAgencia ASC,
--	IdSAsesor  ASC
GO
