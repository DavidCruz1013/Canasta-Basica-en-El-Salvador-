CREATE DATABASE CanastaBasicaSV;
GO

USE CanastaBasicaSV;
GO

CREATE TABLE canasta_zonas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    zona VARCHAR(20),
    anio INT,
    articulo VARCHAR(150),
    gramos_persona INT,

    enero FLOAT,
    febrero FLOAT,
    marzo FLOAT,
    abril FLOAT,
    mayo FLOAT,
    junio FLOAT,
    julio FLOAT,
    agosto FLOAT,
    septiembre FLOAT,
    octubre FLOAT,
    noviembre FLOAT,
    diciembre FLOAT
);
go

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


--KPI 1: Costo promedio mensual de la canasta básica
SELECT 
    [AÑO],
    AVG(
        (ENERO + FEBRERO + MARZO + ABRIL + MAYO + JUNIO +
         JULIO + AGOSTO + SEPTIEMBRE + OCTUBRE +
         NOVIEMBRE + DICIEMBRE) / 12.0
    ) AS promedio_mensual
FROM canasta_limpia
GROUP BY [AÑO]
ORDER BY [AÑO];
GO

--KPI 2: Variación porcentual mensual
SELECT
    [AÑO],
    Zona,

    ROUND(AVG(ENERO), 2) AS promedio_enero,
    ROUND(AVG(FEBRERO), 2) AS promedio_febrero,

    ROUND(
        ((AVG(FEBRERO) - AVG(ENERO)) / NULLIF(AVG(ENERO), 0)) * 100,
        2
    ) AS variacion_enero_febrero

FROM canasta_limpia
WHERE ENERO > 0
  AND FEBRERO > 0
GROUP BY [AÑO], Zona
ORDER BY [AÑO], Zona;
GO

--KPI 3: Diferencia entre la zona urbana y rural
SELECT
    u.[AÑO],

    ROUND(u.Promedio,0) AS Promedio_Urbano,

    ROUND(r.Promedio,0) AS Promedio_Rural,

    ROUND((u.Promedio - r.Promedio),0) AS Diferencia,

    ROUND(
        ((u.Promedio - r.Promedio) / r.Promedio) * 100,
        2
    ) AS Diferencia_Porcentual

FROM
(
    SELECT
        [AÑO],
        AVG(
            (ENERO + FEBRERO + MARZO + ABRIL +
             MAYO + JUNIO + JULIO + AGOSTO +
             SEPTIEMBRE + OCTUBRE + NOVIEMBRE + DICIEMBRE) / 12.0
        ) AS Promedio
    FROM canasta_limpia
    WHERE ARTICULO LIKE '%Costo mensual por familia%'
      AND ZONA = 'Urbana'
    GROUP BY [AÑO]
) u

INNER JOIN

(
    SELECT
        [AÑO],
        AVG(
            (ENERO + FEBRERO + MARZO + ABRIL +
             MAYO + JUNIO + JULIO + AGOSTO +
             SEPTIEMBRE + OCTUBRE + NOVIEMBRE + DICIEMBRE) / 12.0
        ) AS Promedio
    FROM canasta_limpia
    WHERE ARTICULO LIKE '%Costo mensual por familia%'
      AND ZONA = 'Rural'
    GROUP BY [AÑO]
) r

ON u.[AÑO] = r.[AÑO]

ORDER BY u.[AÑO];
GO

-- KPI 4: Producto con mayor incremento de precio evaluando todos los meses

WITH Meses AS (
    SELECT
        [AÑO],
        Zona,
        ARTICULO,
        MesOrden,
        Mes,
        Precio
    FROM canasta_limpia
    CROSS APPLY (
        VALUES
            (1, 'ENERO', ENERO),
            (2, 'FEBRERO', FEBRERO),
            (3, 'MARZO', MARZO),
            (4, 'ABRIL', ABRIL),
            (5, 'MAYO', MAYO),
            (6, 'JUNIO', JUNIO),
            (7, 'JULIO', JULIO),
            (8, 'AGOSTO', AGOSTO),
            (9, 'SEPTIEMBRE', SEPTIEMBRE),
            (10, 'OCTUBRE', OCTUBRE),
            (11, 'NOVIEMBRE', NOVIEMBRE),
            (12, 'DICIEMBRE', DICIEMBRE)
    ) AS M(MesOrden, Mes, Precio)
    WHERE Precio > 0

      -- Excluir indicadores generales
      AND ARTICULO NOT LIKE '%Costo%'
      AND ARTICULO NOT LIKE '%familia%'
      AND ARTICULO NOT LIKE '%persona%'
      AND ARTICULO NOT LIKE '%Total%'

      -- Excluir ajustes que no son productos
      AND ARTICULO NOT LIKE '%cocción%'
      AND ARTICULO NOT LIKE '%coccion%'
      AND ARTICULO NOT LIKE '%10%%'
      AND ARTICULO NOT LIKE '%más%'
      AND ARTICULO NOT LIKE '%mas%'
),

Variaciones AS (
    SELECT
        actual.[AÑO],
        actual.Zona,
        actual.ARTICULO,
        anterior.Mes AS Mes_Inicial,
        actual.Mes AS Mes_Final,
        anterior.Precio AS Precio_Inicial,
        actual.Precio AS Precio_Final,
        ROUND(actual.Precio - anterior.Precio, 2) AS Incremento,
        ROUND(
            ((actual.Precio - anterior.Precio) / NULLIF(anterior.Precio, 0)) * 100,
            2
        ) AS Variacion_Porcentual
    FROM Meses actual
    INNER JOIN Meses anterior
        ON actual.[AÑO] = anterior.[AÑO]
        AND actual.Zona = anterior.Zona
        AND actual.ARTICULO = anterior.ARTICULO
        AND actual.MesOrden = anterior.MesOrden + 1
)

SELECT TOP 1
    [AÑO],
    Zona,
    ARTICULO,
    Mes_Inicial,
    Mes_Final,
    Precio_Inicial,
    Precio_Final,
    Incremento,
    Variacion_Porcentual
FROM Variaciones
ORDER BY Incremento DESC;
GO

--KPI 5: Tendencia anual de la canasta básica
SELECT
    [AÑO],
    AVG(
        ENERO + FEBRERO + MARZO + ABRIL +
        MAYO + JUNIO + JULIO + AGOSTO +
        SEPTIEMBRE + OCTUBRE + NOVIEMBRE + DICIEMBRE
    ) AS tendencia_anual
FROM canasta_limpia
GROUP BY [AÑO]
ORDER BY [AÑO];
GO 


-----------------------------------------------------------------------------------------------
------------------------------CONSULTAS APARTES DE LOS KPIS------------------------------------
-----------------------------------------------------------------------------------------------


--Los 20 productos 
SELECT TOP 180 *
FROM canasta_limpia;
go

--Consultar la tabla  canasta_limpia
Select * FROM canasta_limpia
go


--Consulta por anio
SELECT *
FROM canasta_limpia
ORDER BY AÑO ASC;
go

--por nombre alfabetico  de los productos 
SELECT *
FROM canasta_limpia
ORDER BY AÑO ASC, ARTICULO ASC;
go

--Año con mayor “tasa de ventas
SELECT TOP 1 
    [AÑO],
    AVG(
        ENERO + FEBRERO + MARZO + ABRIL + MAYO + JUNIO +
        JULIO + AGOSTO + SEPTIEMBRE + OCTUBRE + NOVIEMBRE + DICIEMBRE
    ) AS promedio_anual
FROM canasta_limpia
GROUP BY [AÑO]
ORDER BY promedio_anual DESC;
go

--Mes con mayor valor registrado
SELECT 
    MAX(ENERO) AS Enero_Max,
    MAX(FEBRERO) AS Febrero_Max,
    MAX(MARZO) AS Marzo_Max,
    MAX(ABRIL) AS Abril_Max,
    MAX(MAYO) AS Mayo_Max,
    MAX(JUNIO) AS Junio_Max,
    MAX(JULIO) AS Julio_Max,
    MAX(AGOSTO) AS Agosto_Max,
    MAX(SEPTIEMBRE) AS Septiembre_Max,
    MAX(OCTUBRE) AS Octubre_Max,
    MAX(NOVIEMBRE) AS Noviembre_Max,
    MAX(DICIEMBRE) AS Diciembre_Max
FROM canasta_limpia;
go

--Producto más caro en promedio
SELECT TOP 1
    ARTICULO,
    AVG(
        ENERO + FEBRERO + MARZO + ABRIL + MAYO + JUNIO +
        JULIO + AGOSTO + SEPTIEMBRE + OCTUBRE + NOVIEMBRE + DICIEMBRE
    ) AS promedio_producto
FROM canasta_limpia
GROUP BY ARTICULO
ORDER BY promedio_producto DESC;
go

--Productos del año 2026
SELECT *
FROM canasta_limpia
WHERE [AÑO] = 2020
ORDER BY ARTICULO;
go


--Mostrar solo artículos específicos
SELECT *
FROM canasta_limpia
WHERE ARTICULO LIKE '%Tortilla%';


--Promedio de enero por año
SELECT 
    [AÑO],
    AVG(ENERO) AS promedio_enero
FROM canasta_limpia
GROUP BY [AÑO]
ORDER BY [AÑO];
go

--Año con mayor costo mensual familiar
SELECT TOP 1
    [AÑO],
    MAX(ENERO) AS mayor_costo
FROM canasta_limpia
WHERE ARTICULO LIKE '%Costo mensual%'
GROUP BY [AÑO]
ORDER BY mayor_costo DESC;
go


--Buscar registros con datos incompletos
SELECT *
FROM canasta_limpia
WHERE [AÑO] = 2026
AND (
    MAYO = 0
    OR JUNIO = 0
    OR JULIO = 0
    OR AGOSTO = 0
    OR SEPTIEMBRE = 0
    OR OCTUBRE = 0
    OR NOVIEMBRE = 0
    OR DICIEMBRE = 0
);
GO

--Total promedio por producto
SELECT 
    ARTICULO,
    AVG(
        (ENERO + FEBRERO + MARZO + ABRIL + MAYO + JUNIO +
         JULIO + AGOSTO + SEPTIEMBRE + OCTUBRE + NOVIEMBRE + DICIEMBRE) / 12
    ) AS promedio_total
FROM canasta_limpia
GROUP BY ARTICULO
ORDER BY promedio_total DESC;
go

--Cantidad de productos registrados por año
SELECT 
    [AÑO],
    COUNT(*) AS total_registros
FROM canasta_limpia
GROUP BY [AÑO]
ORDER BY [AÑO];
go

--Año con mayor costo
SELECT TOP 1
    [AÑO],
    MAX(DICIEMBRE) AS mayor_costo
FROM canasta_limpia
GROUP BY [AÑO]
ORDER BY mayor_costo DESC;
GO

--Producto más caro
SELECT TOP 1
    ARTICULO,
    MAX(DICIEMBRE) AS precio_maximo
FROM canasta_limpia
GROUP BY ARTICULO
ORDER BY precio_maximo DESC;
GO

--Mes con más ventas/promedio
SELECT
    AVG(ENERO) AS Enero,
    AVG(FEBRERO) AS Febrero,
    AVG(MARZO) AS Marzo,
    AVG(ABRIL) AS Abril
FROM canasta_limpia;
GO