/*
  CAPA BRONZE - tablas de aterrizaje (dw_transporte)
  Basado en 01_bronze_v2.sql del docente, sin el sufijo "Azure" en los nombres.
  Solo crea las tablas que falten; NO borra las que ya existen.
  Todos los campos son VARCHAR porque bronze recibe los datos sucios tal como vienen.
*/
SET NOCOUNT ON;
IF DB_NAME() <> N'dw_transporte'
    THROW 51000, 'Conectese a la base de datos dw_transporte antes de ejecutar este script.', 1;
IF SCHEMA_ID(N'bronze') IS NULL EXEC(N'CREATE SCHEMA bronze');
GO

IF OBJECT_ID(N'bronze.Rutas', N'U') IS NULL
CREATE TABLE bronze.Rutas (
    AnioFuente VARCHAR(10) NULL, RutaHistoricaId VARCHAR(30) NULL, CodigoRuta VARCHAR(20) NULL,
    NombreRuta VARCHAR(120) NULL, Origen VARCHAR(80) NULL, Destino VARCHAR(80) NULL,
    VigenciaDesde VARCHAR(30) NULL, VigenciaHasta VARCHAR(30) NULL, Estado VARCHAR(20) NULL);

IF OBJECT_ID(N'bronze.Paradas', N'U') IS NULL
CREATE TABLE bronze.Paradas (
    AnioFuente VARCHAR(10) NULL, ParadaHistoricaId VARCHAR(30) NULL, CodigoPublicado VARCHAR(20) NULL,
    NombreParada VARCHAR(120) NULL, Zona VARCHAR(40) NULL, Latitud VARCHAR(30) NULL, Longitud VARCHAR(30) NULL,
    VigenciaDesde VARCHAR(30) NULL, VigenciaHasta VARCHAR(30) NULL, Estado VARCHAR(20) NULL);

IF OBJECT_ID(N'bronze.Vehiculos', N'U') IS NULL
CREATE TABLE bronze.Vehiculos (
    AnioFuente VARCHAR(10) NULL, VehiculoId VARCHAR(20) NULL, Placa VARCHAR(20) NULL, TipoVehiculo VARCHAR(30) NULL,
    CapacidadEfectiva VARCHAR(20) NULL, VigenciaDesde VARCHAR(30) NULL, VigenciaHasta VARCHAR(30) NULL, Estado VARCHAR(20) NULL);

IF OBJECT_ID(N'bronze.Viajes', N'U') IS NULL
CREATE TABLE bronze.Viajes (
    AnioFuente VARCHAR(10) NULL, ViajeId VARCHAR(30) NULL, RutaHistoricaId VARCHAR(30) NULL, VehiculoId VARCHAR(20) NULL,
    FechaServicio VARCHAR(30) NULL, HoraProgramada VARCHAR(30) NULL, HoraSalida VARCHAR(30) NULL, HoraLlegada VARCHAR(30) NULL,
    ValidacionesTarjeta VARCHAR(20) NULL, KmRecorridos VARCHAR(30) NULL, EstadoViaje VARCHAR(20) NULL);

IF OBJECT_ID(N'bronze.DemandaParadas', N'U') IS NULL
CREATE TABLE bronze.DemandaParadas (
    AnioFuente VARCHAR(10) NULL, DemandaId VARCHAR(30) NULL, FechaServicio VARCHAR(30) NULL, RutaHistoricaId VARCHAR(30) NULL,
    ParadaHistoricaId VARCHAR(30) NULL, Franja VARCHAR(20) NULL, ValidacionesTarjeta VARCHAR(20) NULL,
    Descensos VARCHAR(20) NULL, DemandaNoAtendida VARCHAR(20) NULL, Metodo VARCHAR(30) NULL);

-- FechaHora* mas ancho que en v2: en CSV/Excel la fecha y la hora llegan separadas y se guardan juntas como texto
IF OBJECT_ID(N'bronze.Incidentes', N'U') IS NULL
CREATE TABLE bronze.Incidentes (
    AnioFuente VARCHAR(10) NULL, IncidenteId VARCHAR(30) NULL, TipoIncidente VARCHAR(30) NULL, Severidad VARCHAR(15) NULL,
    FechaHoraInicio VARCHAR(60) NULL, FechaHoraFin VARCHAR(60) NULL, FechaHoraRegistro VARCHAR(60) NULL,
    VehiculoId VARCHAR(20) NULL, Descripcion VARCHAR(200) NULL);

IF OBJECT_ID(N'bronze.IncidenteRuta', N'U') IS NULL
CREATE TABLE bronze.IncidenteRuta (
    AnioFuente VARCHAR(10) NULL, IncidenteId VARCHAR(30) NULL, RutaHistoricaId VARCHAR(30) NULL, EsPrincipal VARCHAR(10) NULL);
GO

-- Si bronze.Incidentes ya existia con VARCHAR(35), se amplia (no borra datos)
ALTER TABLE bronze.Incidentes ALTER COLUMN FechaHoraInicio VARCHAR(60) NULL;
ALTER TABLE bronze.Incidentes ALTER COLUMN FechaHoraFin VARCHAR(60) NULL;
ALTER TABLE bronze.Incidentes ALTER COLUMN FechaHoraRegistro VARCHAR(60) NULL;
GO
