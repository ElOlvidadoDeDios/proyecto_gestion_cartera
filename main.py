from dotenv import load_dotenv
from gestion_cartera.core.constants import PATH_ENV

load_dotenv(PATH_ENV)
import argparse
import os
import atexit
import logging
import warnings
import pyodbc  # 🔥 AÑADIDO: Para conectar a la BD

# Silenciar las advertencias estéticas de Pandas en el log
warnings.filterwarnings("ignore", category=UserWarning, module="pandas")

# 🔥 SOLUCIÓN CRÍTICA: Calcular la ruta absoluta automática del proyecto
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(BASE_DIR, "ejecucion.log")

MAX_REGISTROS = 100

# Configurar el sistema de rastro (consola + archivo ejecucion.log absoluto)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler()],
)


# Algoritmo de limpieza de registros históricos (usa la ruta absoluta)
def purgar_logs_antiguos():
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            lineas = f.readlines()

        if len(lineas) > MAX_REGISTROS:
            with open(LOG_FILE, "w", encoding="utf-8") as f:
                f.writelines(lineas[-MAX_REGISTROS:])


atexit.register(purgar_logs_antiguos)

from gestion_cartera.pipelines import (
    pipeline_initial,
    pipeline_variational,
    pipeline_operational,
    pipeline_operational_ranking_asesor,
)

PIPELINES = {
    "initial": pipeline_initial,
    "variational": pipeline_variational,
    "operational": pipeline_operational,
    "opr_ranking_asesor": pipeline_operational_ranking_asesor,
}


# 🔥 NUEVA FUNCIÓN: Actualiza la tabla de Log en SQL Server
def actualizar_fecha_bd():
    try:
        # Extraemos las variables exactas de tu .env
        server = os.getenv("DB_DOWNSTREAM_SERVER")
        db = os.getenv("DB_DOWNSTREAM_DATABASE")

        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={server};"
            f"DATABASE={db};"
            f"Trusted_Connection=yes;"
        )

        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()

        # Ejecuta el UPDATE con la fecha y hora actual del servidor local
        cursor.execute(
            "UPDATE [dbo].[Log_Actualizacion] SET UltimaActualizacion = GETDATE() WHERE Id = 1;"
        )
        conn.commit()
        conn.close()

        logging.info("✅ Fecha de Última Actualización renovada exitosamente en BD.")
    except Exception as e:
        logging.error(f"❌ Error al actualizar la fecha en BD: {e}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ejecutar pipelines de gestión de cartera."
    )
    parser.add_argument(
        "pipeline",
        choices=PIPELINES.keys(),
        help="Pipeline a ejecutar: 'initial', 'variational', 'operational' o 'opr_ranking_asesor'.",
    )
    args = parser.parse_args()

    logging.info(f"🚀 Iniciando ejecución de pipeline: {args.pipeline}")

    # 1. Ejecuta el pipeline solicitado por la tarea programada
    PIPELINES[args.pipeline]()

    # 2. Si el pipeline termina sin errores, actualiza la fecha en SQL
    actualizar_fecha_bd()

    logging.info(f"🏁 Ejecución de {args.pipeline} finalizada.")


if __name__ == "__main__":
    main()
