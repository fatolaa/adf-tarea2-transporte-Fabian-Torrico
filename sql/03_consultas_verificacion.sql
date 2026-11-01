/* Consultas para verificar la carga y tomar capturas para el informe */

-- 1. Resumen de la ultima carga: Diferencia debe ser 0 (bronze = silver + cuarentena)
SELECT * FROM silver.AuditoriaCarga
WHERE FechaCarga = (SELECT MAX(FechaCarga) FROM silver.AuditoriaCarga)
ORDER BY Entidad;

-- 2. Registros observados por motivo
SELECT Entidad, Motivo, COUNT(*) AS Filas
FROM silver.Cuarentena GROUP BY Entidad, Motivo ORDER BY Entidad, Filas DESC;

-- 3. Detalle de los registros invalidos (sin contar los duplicados)
SELECT * FROM silver.Cuarentena WHERE Motivo NOT LIKE 'DUPLICADO%';

-- 4. Equivalencias historicas aplicadas
SELECT * FROM silver.Rutas WHERE RutaHistoricaId LIKE 'RH-07%' OR RutaHistoricaId LIKE 'RH-12%';
SELECT * FROM silver.Paradas WHERE CodigoPublicado = 'MC-01';

-- 5. Filas por anio en los hechos
SELECT YEAR(FechaServicio) AS Anio, COUNT(*) AS Viajes FROM silver.Viajes GROUP BY YEAR(FechaServicio) ORDER BY Anio;
SELECT YEAR(FechaServicio) AS Anio, Metodo, COUNT(*) AS Filas FROM silver.DemandaParadas GROUP BY YEAR(FechaServicio), Metodo ORDER BY Anio;
SELECT YEAR(FechaHoraInicio) AS Anio, COUNT(*) AS Incidentes FROM silver.Incidentes GROUP BY YEAR(FechaHoraInicio) ORDER BY Anio;

-- 6. Conteos bronze
SELECT 'Rutas' AS Tabla, COUNT(*) AS Filas FROM bronze.Rutas UNION ALL
SELECT 'Paradas', COUNT(*) FROM bronze.Paradas UNION ALL
SELECT 'Vehiculos', COUNT(*) FROM bronze.Vehiculos UNION ALL
SELECT 'Viajes', COUNT(*) FROM bronze.Viajes UNION ALL
SELECT 'DemandaParadas', COUNT(*) FROM bronze.DemandaParadas UNION ALL
SELECT 'Incidentes', COUNT(*) FROM bronze.Incidentes UNION ALL
SELECT 'IncidenteRuta', COUNT(*) FROM bronze.IncidenteRuta;
