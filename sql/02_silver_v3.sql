/*
  CAPA SILVER - version 3 (dw_transporte)
  Parte del 02_silver_v2.sql del docente con los cambios explicados en los videos 5.1 y 5.3.4:
    - Nombres sin el sufijo "Azure".
    - Sin la columna AnioFuente: las claves primarias y foraneas usan solo el id historico.
  Agrega dos tablas de control:
    - silver.Cuarentena: registros observados (datos invalidos o duplicados) con su motivo.
    - silver.AuditoriaCarga: conteo bronze vs silver vs cuarentena de cada ejecucion.
  ATENCION: borra y vuelve a crear las tablas silver.
*/
SET NOCOUNT ON;
IF DB_NAME() <> N'dw_transporte'
    THROW 51100, 'Conectese a la base de datos dw_transporte antes de ejecutar este script.', 1;
IF SCHEMA_ID(N'silver') IS NULL EXEC(N'CREATE SCHEMA silver');
GO

-- Borrado en orden: primero las tablas que tienen llaves foraneas
DROP TABLE IF EXISTS silver.IncidenteRuta, silver.IncidenteRutaAzure;
DROP TABLE IF EXISTS silver.Incidentes, silver.IncidentesAzure;
DROP TABLE IF EXISTS silver.DemandaParadas, silver.DemandaParadasAzure;
DROP TABLE IF EXISTS silver.Viajes, silver.ViajesAzure;
DROP TABLE IF EXISTS silver.Vehiculos, silver.VehiculosAzure;
DROP TABLE IF EXISTS silver.Paradas, silver.ParadasAzure;
DROP TABLE IF EXISTS silver.Rutas, silver.RutasAzure;
DROP TABLE IF EXISTS silver.Cuarentena, silver.AuditoriaCarga;
GO

CREATE TABLE silver.Rutas (
    RutaHistoricaId    NVARCHAR(30)  NOT NULL,
    CodigoRuta         NVARCHAR(20)  NOT NULL,
    NombreRuta         NVARCHAR(120) NOT NULL,
    Origen             NVARCHAR(80)  NOT NULL,
    Destino            NVARCHAR(80)  NOT NULL,
    VigenciaDesde      DATE          NOT NULL,
    VigenciaHasta      DATE          NOT NULL,
    Estado             NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_silver_Rutas PRIMARY KEY (RutaHistoricaId)
);

CREATE TABLE silver.Paradas (
    ParadaHistoricaId  NVARCHAR(30)  NOT NULL,
    CodigoPublicado    NVARCHAR(20)  NOT NULL,
    NombreParada       NVARCHAR(120) NOT NULL,
    Zona               NVARCHAR(40)  NOT NULL,
    Latitud            DECIMAL(9,6)  NOT NULL,
    Longitud           DECIMAL(9,6)  NOT NULL,
    VigenciaDesde      DATE          NOT NULL,
    VigenciaHasta      DATE          NOT NULL,
    Estado             NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_silver_Paradas PRIMARY KEY (ParadaHistoricaId)
);

CREATE TABLE silver.Vehiculos (
    VehiculoId          NVARCHAR(20) NOT NULL,
    Placa               NVARCHAR(20) NOT NULL,
    TipoVehiculo        NVARCHAR(30) NOT NULL,
    CapacidadEfectiva   INT          NOT NULL,
    VigenciaDesde       DATE         NOT NULL,
    VigenciaHasta       DATE         NOT NULL,
    Estado              NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_silver_Vehiculos PRIMARY KEY (VehiculoId)
);

CREATE TABLE silver.Viajes (
    ViajeId               NVARCHAR(30)  NOT NULL,
    RutaHistoricaId       NVARCHAR(30)  NOT NULL,
    VehiculoId            NVARCHAR(20)  NOT NULL,
    FechaServicio         DATE          NOT NULL,
    HoraProgramada        TIME(0)       NOT NULL,
    HoraSalida            TIME(0)       NOT NULL,
    HoraLlegada           TIME(0)       NOT NULL,
    ValidacionesTarjeta   INT           NOT NULL,
    KmRecorridos          DECIMAL(8,1)  NOT NULL,
    EstadoViaje           NVARCHAR(20)  NOT NULL,
    CONSTRAINT PK_silver_Viajes PRIMARY KEY (ViajeId),
    CONSTRAINT FK_silver_Viajes_Rutas FOREIGN KEY (RutaHistoricaId) REFERENCES silver.Rutas (RutaHistoricaId),
    CONSTRAINT FK_silver_Viajes_Vehiculos FOREIGN KEY (VehiculoId) REFERENCES silver.Vehiculos (VehiculoId)
);

CREATE TABLE silver.DemandaParadas (
    DemandaId              NVARCHAR(30)  NOT NULL,
    FechaServicio          DATE          NOT NULL,
    RutaHistoricaId        NVARCHAR(30)  NOT NULL,
    ParadaHistoricaId      NVARCHAR(30)  NOT NULL,
    Franja                 NVARCHAR(20)  NOT NULL,
    ValidacionesTarjeta    INT           NOT NULL,
    Descensos              INT           NOT NULL,
    DemandaNoAtendida      INT           NOT NULL,
    Metodo                 NVARCHAR(30)  NOT NULL,
    CONSTRAINT PK_silver_DemandaParadas PRIMARY KEY (DemandaId),
    CONSTRAINT FK_silver_Demanda_Rutas FOREIGN KEY (RutaHistoricaId) REFERENCES silver.Rutas (RutaHistoricaId),
    CONSTRAINT FK_silver_Demanda_Paradas FOREIGN KEY (ParadaHistoricaId) REFERENCES silver.Paradas (ParadaHistoricaId)
);

CREATE TABLE silver.Incidentes (
    IncidenteId         NVARCHAR(30)   NOT NULL,
    TipoIncidente       NVARCHAR(30)   NOT NULL,
    Severidad           NVARCHAR(15)   NOT NULL,
    FechaHoraInicio     DATETIME2(0)   NOT NULL,
    FechaHoraFin        DATETIME2(0)   NOT NULL,
    FechaHoraRegistro   DATETIME2(0)   NOT NULL,
    VehiculoId          NVARCHAR(20)   NULL,
    Descripcion         NVARCHAR(200)  NOT NULL,
    CONSTRAINT PK_silver_Incidentes PRIMARY KEY (IncidenteId),
    CONSTRAINT FK_silver_Incidentes_Vehiculos FOREIGN KEY (VehiculoId) REFERENCES silver.Vehiculos (VehiculoId)
);

CREATE TABLE silver.IncidenteRuta (
    IncidenteId       NVARCHAR(30)  NOT NULL,
    RutaHistoricaId   NVARCHAR(30)  NOT NULL,
    EsPrincipal       BIT           NOT NULL,
    CONSTRAINT PK_silver_IncidenteRuta PRIMARY KEY (IncidenteId, RutaHistoricaId),
    CONSTRAINT FK_silver_IncidenteRuta_Incidente FOREIGN KEY (IncidenteId) REFERENCES silver.Incidentes (IncidenteId),
    CONSTRAINT FK_silver_IncidenteRuta_Ruta FOREIGN KEY (RutaHistoricaId) REFERENCES silver.Rutas (RutaHistoricaId)
);

CREATE TABLE silver.Cuarentena (
    CuarentenaId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_silver_Cuarentena PRIMARY KEY,
    Entidad       NVARCHAR(30)   NOT NULL,
    RegistroId    NVARCHAR(100)  NULL,
    Fuente        NVARCHAR(20)   NULL,
    Motivo        NVARCHAR(200)  NOT NULL,
    DatosOrigen   NVARCHAR(1000) NULL,
    FechaCarga    DATETIME2(0)   NOT NULL CONSTRAINT DF_silver_Cuarentena_Fecha DEFAULT SYSDATETIME()
);

CREATE TABLE silver.AuditoriaCarga (
    AuditoriaId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_silver_AuditoriaCarga PRIMARY KEY,
    FechaCarga       DATETIME2(0) NOT NULL CONSTRAINT DF_silver_Auditoria_Fecha DEFAULT SYSDATETIME(),
    Entidad          NVARCHAR(30) NOT NULL,
    FilasBronze      INT NOT NULL,
    FilasSilver      INT NOT NULL,
    FilasCuarentena  INT NOT NULL,
    Diferencia       AS (FilasBronze - FilasSilver - FilasCuarentena)
);
GO

CREATE INDEX IX_silver_Viajes_FechaRuta ON silver.Viajes (FechaServicio, RutaHistoricaId);
CREATE INDEX IX_silver_Demanda_FechaFranja ON silver.DemandaParadas (FechaServicio, Franja);
CREATE INDEX IX_silver_Cuarentena_Entidad ON silver.Cuarentena (Entidad, Motivo);
GO
