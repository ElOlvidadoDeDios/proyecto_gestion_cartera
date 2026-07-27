CREATE OR ALTER PROCEDURE gc.sp_fct_stock_flow
    @Periodo CHAR(6)
AS
BEGIN
WITH
CTE_DIM_ASESOR AS (
SELECT * FROM gc.tvf_dim_asesor(@Periodo)
),
CTE_FCT_STOCK AS (
SELECT * FROM gc.tvf_fct_stock(@Periodo)
),
CTE_FCT_FLOW AS (

SELECT
	T.Periodo,
	T.IdSAgencia,
	T.IdSAsesor,
	SUM(T.ColocacionNumReal) AS ColocacionNumReal,
	SUM(T.ColocacionMontoReal) AS ColocacionMontoReal,
	SUM(T.RepagoReal) AS RepagoReal
FROM
	gc.tvf_fct_flow(@Periodo) T
GROUP BY
	T.Periodo,
	T.IdSAgencia,
	T.IdSAsesor
)
SELECT
    T_STO.Periodo,
	T_ASE.IdSAgencia,
    TRIM(T_ASE.IdSAsesor) AS IdSAsesor,
	T_ASE.AsesorNombresApellidos,
	T_ASE.Cargo,
    T_STO.Cartera,
    T_STO.Mora9,
    T_STO.Mora31,
    T_STO.Mora150,
    T_STO.Varios,
    T_STO.TEA,
	T_STO.NroSocios,
	T_STO.NroSociosAnterior,
	T_FLO.ColocacionNumReal,
	T_FLO.ColocacionMontoReal,
	T_FLO.RepagoReal
FROM
	CTE_DIM_ASESOR T_ASE
	INNER JOIN CTE_FCT_STOCK T_STO
		ON  T_STO.Periodo = T_ASE.Periodo
		AND T_STO.IdSAsesor = T_ASE.IdSAsesor
	INNER JOIN CTE_FCT_FLOW T_FLO
		ON  T_FLO.Periodo = T_STO.Periodo
		AND T_FLO.IdSAsesor = T_STO.IdSAsesor
END;