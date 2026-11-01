# Tarea 2 – Data Warehouse de transporte urbano (Azure Data Factory)

Fabian Torrico Lazarte – Universidad Católica Boliviana

Arquitectura de medallones: `raw` (Storage) → **bronze** → **silver** → gold (siguiente entrega).
La infraestructura se despliega con Terraform; Data Factory orquesta el flujo de datos.

## Fuentes

| Fuente | Años | Contenedor / origen |
|---|---|---|
| CSV | 2020–2021 | `raw/datos_csv` |
| Excel (`operacion_2022.xlsx`, `operacion_2023.xlsx`) | 2022–2023 | `raw/datos_xls` |
| Azure SQL (`erp_transporte_db`) | 2024–2025 | tablas `dbo.*Azure` |

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `linkedService/` | Storage, ERP y DW |
| `dataset/` | `bronze_*` = fuentes; `sw_bronze_*` y `sw_silver_*` = tablas del DW |
| `dataflow/` | `df_bronze_*` (6) y `df_silver_*` (7) |
| `pipeline/` | `pl_bronze`, `pl_silver`, `pl_medallon_completo` |
| `sql/` | scripts del DW y consultas de verificación |

## Capa bronze – juntar sin limpiar

Un data flow por entidad (`df_bronze_rutas`, `paradas`, `vehiculos`, `viajes`, `demanda_paradas`, `incidentes`):

1. Lee CSV, Excel 2022, Excel 2023 y SQL, todo como `string`.
2. `select` renombra las columnas de CSV/Excel al nombre del ERP (`nro_bus` → `VehiculoId`, etc.).
3. `derive` agrega `AnioFuente` para rastrear el origen (`2020-2021`, `2022`, `2023`; SQL ya lo trae).
4. `union` por nombre y `sink` a `bronze.<Entidad>`.

Los campos que no existen en la tabla destino (`pasajeros_reportados`, `pasajeros_estimados`, `tipo_metrica`) no se cargan.
`df_bronze_incidentes` además separa `rutas_afectadas` (`RH-05|RH-04`) en filas de `bronze.IncidenteRuta`; la primera ruta es la principal.

`pl_bronze` vacía las tablas bronze y ejecuta los 6 data flows.

## Capa silver – limpiar, tipar y validar

Cada `df_silver_*` sigue los mismos pasos:

| Paso | Qué hace |
|---|---|
| `normalizar` | `trim`, nulos → `''`, mayúsculas en códigos y estados |
| `tipar` | fechas, horas, decimales y enteros al tipo nativo |
| `equivalencias` | unifica identificadores entre fuentes (ver tabla) |
| `buscar*Silver` | `lookup` contra silver para validar llaves foráneas |
| `validar` | calcula `Motivo`: vacío = registro válido |
| `clasificar` | `split` válidos / observados |
| `ordenarVersiones` + `quitarDuplicados` | `window` por id: queda la versión de la fuente más reciente |
| `sinkSilver` / `sinkCuarentena` | válidos a `silver.<Entidad>`, observados a `silver.Cuarentena` |

### Suciedad encontrada y cómo se trata

| Problema | Ejemplo | Regla |
|---|---|---|
| Fechas en varios formatos | `09/07/2020`, `2021-08-05`, número de serie Excel `43831` | se detecta el formato con `regexMatch` y se convierte con `toDate` |
| Horas como texto o celda de hora | `10:47`, `07:42:00`, `7:42 AM` | se extrae `HH:mm` y se lleva a `HH:mm:00` |
| Coma decimal | `14,7` km | `replace(',', '.')` y `toDecimal` |
| Códigos de ruta distintos | `05`, `R-05`, `Ruta 5` | `RH-05` |
| Códigos de vehículo distintos | `001`, `V-001` | `V-001` |
| Ids de viaje que se repiten por año (CSV) | `00001` en 2020 y en 2021 | `VJ-2020-00001`, `VJ-2021-00001` |
| Demanda sin id (CSV/Excel) | — | `DM-<año>-<correlativo>` |
| Filas de totales en Excel | `TOTAL_OPERACION`, `TOTAL_CANCELADOS` | cuarentena |
| Id alterado | `00322-A` | cuarentena |
| Catálogos repetidos cada año | P001 aparece en 2020, 2021, 2022… | se conserva la versión más reciente |
| Medición no realizada | `NO_MEDIDO` | se conserva en `Metodo` (cobertura de medición) |

### Equivalencias históricas

| Código publicado | Periodo | Id histórico |
|---|---|---|
| R-07 (Terminal Norte – Mercado Central, retirada) | hasta 2021 | `RH-07-OLD` |
| R-07 (Parque Industrial – Universidad) | desde 2024 | `RH-07-NEW` |
| R-12 (dividida) | hasta 2022 | `RH-12-OLD` |
| R12-N / R12-S | desde 2023 | `RH-12-N` / `RH-12-S` |
| MC-01 Mercado Central (reubicada) | hasta 30/06/2023 | `P219-MC-OLD` |
| MC-01 Mercado Central | desde 01/07/2023 | `P220-MC-NEW` |

`RH-07-OLD` y `RH-12-OLD` son los ids que usan los propios incidentes de 2020–2023.
`P219-MC-OLD` es un id definido en este proyecto porque ninguna fuente trae el id histórico de la parada antigua.

### Decisiones

- **Sin `AnioFuente` en silver**, como en el video 5.3.4: las llaves usan solo el id histórico. El origen de cada fila queda en bronze y en la cuarentena.
- **`ValidacionesTarjeta` de viajes = 0 para 2020–2023**: CSV y Excel no tienen validaciones con tarjeta (solo conteos manuales o estimados, que no se cargan en bronze).
- **Nada se descarta en silencio**: cada fila de bronze termina en silver o en `silver.Cuarentena` con su motivo. `silver.AuditoriaCarga` lo comprueba en cada ejecución (`Diferencia = 0`).

`pl_silver` vacía silver (primero las tablas hijas), ejecuta los 7 data flows en orden de dependencia (rutas, paradas, vehículos → viajes, demanda, incidentes → incidente_ruta) y registra la auditoría.

## Cómo ejecutar

1. En el Query editor de `dw_transporte`: `sql/01_bronze_tablas.sql` y `sql/02_silver_v3.sql`.
2. En Data Factory: **Depurar** `pl_medallon_completo` (o `pl_bronze` y luego `pl_silver`).
3. Verificar con `sql/03_consultas_verificacion.sql`.
