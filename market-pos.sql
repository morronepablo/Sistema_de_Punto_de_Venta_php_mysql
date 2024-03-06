-- phpMyAdmin SQL Dump
-- version 4.7.4
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 06-03-2024 a las 16:39:26
-- Versión del servidor: 10.1.26-MariaDB
-- Versión de PHP: 7.1.9

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `market-pos`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductos` ()  NO SQL
BEGIN

SELECT '' AS detalles,
		p.id,
        p.codigo_producto,
        c.id_categoria,
        c.nombre_categoria,
        p.descripcion_producto,
        ROUND(p.precio_compra_producto,2) AS precio_compra,
        ROUND(p.precio_venta_producto,2) AS precio_venta,
        ROUND(p.utilidad,2) AS utilidad,
        case when c.aplica_peso = 1 then concat(p.stock_producto,' Kg(s)') else concat(p.stock_producto,' Und(s)') end AS stock,
        case when c.aplica_peso = 1 then concat(p.minimo_stock_producto,' Kg(s)') else concat(p.minimo_stock_producto,' Und(s)') end AS minimo_stock,
        case when c.aplica_peso = 1 then concat(p.ventas_producto,' Kg(s)') else concat(p.ventas_producto,' Und(s)') end AS ventas,
        p.fecha_creacion_producto,
        p.fecha_actualizacion_producto,
        '' as acciones
FROM productos p INNER JOIN categorias c ON p.id_categoria_producto = c.id_categoria;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL
BEGIN

SELECT p.codigo_producto, 
	   p.descripcion_producto,
       sum(vd.cantidad) AS cantidad,
       sum(round(vd.total_venta,2)) AS total_venta 
FROM venta_detalle vd INNER JOIN productos p ON vd.codigo_producto = p.codigo_producto 
group by p.codigo_producto, 
	   p.descripcion_producto 
order by sum(round(vd.total_venta,2)) desc 
limit 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL
BEGIN

SELECT p.codigo_producto,
		p.descripcion_producto,
        p.stock_producto,
        p.minimo_stock_producto
FROM productos p 
WHERE p.stock_producto <= p.minimo_stock_producto 
order by p.stock_producto asc;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL
BEGIN
declare totalProductos int;
declare totalCompras float;
declare totalVentas float;
declare ganancias float;
declare productosPocoStock int;
declare ventasHoy float;

SET totalProductos = (SELECT count(*) FROM productos p);
SET totalCompras = (SELECT sum(p.precio_compra_producto*p.stock_producto) FROM productos p);
SET totalVentas = (SELECT sum(vc.total_venta) FROM venta_cabecera vc);
SET ganancias = (SELECT sum(vd.total_venta) - sum(p.precio_compra_producto * vd.cantidad) FROM venta_detalle vd INNER JOIN productos p ON vd.codigo_producto = p.codigo_producto);
SET productosPocoStock = (SELECT count(1) FROM productos p WHERE p.stock_producto <= p.minimo_stock_producto);
SET ventasHoy = (SELECT sum(vc.total_venta) FROM venta_cabecera vc WHERE vc.fecha_venta = curdate());

SELECT IFNULL(totalProductos,0) AS totalProductos,
	   IFNULL(ROUND(totalCompras,2),0) AS totalCompras,
       IFNULL(ROUND(totalVentas,2),0) AS totalVentas,
       IFNULL(ROUND(ganancias,2),0) AS ganancias,
       IFNULL(productosPocoStock,0) AS productosPocoStock,
       IFNULL(ROUND(ventasHoy,2),0) AS ventasHoy;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL
BEGIN

SELECT  date(vc.fecha_venta) AS fecha_venta,
		sum(round(vc.total_venta,2)) AS total_venta 
FROM venta_cabecera vc 
WHERE date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 1 month) + INTERVAL 1 day) 
AND date(vc.fecha_venta) <= last_day(date(CURRENT_DATE)) 
group by date(vc.fecha_venta);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL,
  `nombre_categoria` text COLLATE utf8_spanish_ci,
  `aplica_peso` int(11) NOT NULL,
  `fecha_creacion_categoria` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `fecha_actualizacion_categoria` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresa`
--

CREATE TABLE `empresa` (
  `id_empresa` int(11) NOT NULL,
  `razon_social` text NOT NULL,
  `ruc` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `marca` text NOT NULL,
  `serie_boleta` varchar(4) NOT NULL,
  `nro_correlativo_venta` varchar(8) NOT NULL,
  `email` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `empresa`
--

INSERT INTO `empresa` (`id_empresa`, `razon_social`, `ruc`, `direccion`, `marca`, `serie_boleta`, `nro_correlativo_venta`, `email`) VALUES
(1, 'Maga & Tito Market', 10467291241, 'Avenida Brasil 1347 - Jesus María', 'Maga & Tito Market', '0002', '00000024', 'magaytito@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `codigo_producto` bigint(13) NOT NULL,
  `id_categoria_producto` int(11) DEFAULT NULL,
  `descripcion_producto` text COLLATE utf8_spanish_ci,
  `precio_compra_producto` float NOT NULL,
  `precio_venta_producto` float NOT NULL,
  `utilidad` float NOT NULL,
  `stock_producto` float DEFAULT NULL,
  `minimo_stock_producto` float DEFAULT NULL,
  `ventas_producto` float DEFAULT NULL,
  `fecha_creacion_producto` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `fecha_actualizacion_producto` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_cabecera`
--

CREATE TABLE `venta_cabecera` (
  `id_boleta` int(11) NOT NULL,
  `nro_boleta` varchar(8) NOT NULL,
  `descripcion` text,
  `subtotal` float NOT NULL,
  `igv` float NOT NULL,
  `total_venta` float DEFAULT NULL,
  `fecha_venta` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla `venta_cabecera`
--

INSERT INTO `venta_cabecera` (`id_boleta`, `nro_boleta`, `descripcion`, `subtotal`, `igv`, `total_venta`, `fecha_venta`) VALUES
(46, '00000014', 'Venta realizada con Nro Boleta: 00000014', 0, 0, 69, '2021-10-18 21:54:10'),
(47, '00000015', 'Venta realizada con Nro Boleta: 00000015', 0, 0, 17.5, '2021-10-18 22:34:17'),
(48, '00000016', 'Venta realizada con Nro Boleta: 00000016', 0, 0, 16.2, '2021-10-18 22:34:51'),
(49, '00000017', 'Venta realizada con Nro Boleta: 00000017', 0, 0, 5, '2021-10-18 23:01:17'),
(50, '00000018', 'Venta realizada con Nro Boleta: 00000018', 0, 0, 1.8, '2021-10-18 23:56:24'),
(51, '00000019', 'Venta realizada con Nro Boleta: 00000019', 0, 0, 21.2, '2021-10-19 02:27:17'),
(52, '00000020', 'Venta realizada con Nro Boleta: 00000020', 0, 0, 29.5, '2021-10-19 02:29:41'),
(53, '00000021', 'Venta realizada con Nro Boleta: 00000021', 0, 0, 9.2, '2021-10-19 02:31:19'),
(54, '00000022', 'Venta realizada con Nro Boleta: 00000022', 0, 0, 1.25, '2021-10-19 02:32:55'),
(55, '00000023', 'Venta realizada con Nro Boleta: 00000023', 0, 0, 1.8, '2021-10-24 22:27:16'),
(56, '00000024', 'Venta realizada con Nro Boleta: 00000024', 0, 0, 65.8, '2021-10-24 22:27:45');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_detalle`
--

CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL,
  `nro_boleta` varchar(8) COLLATE utf8_spanish_ci NOT NULL,
  `codigo_producto` bigint(20) NOT NULL,
  `cantidad` float NOT NULL,
  `total_venta` float NOT NULL,
  `fecha_venta` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `venta_detalle`
--

INSERT INTO `venta_detalle` (`id`, `nro_boleta`, `codigo_producto`, `cantidad`, `total_venta`, `fecha_venta`) VALUES
(521, '00000014', 7755139002809, 3, 69, '2021-10-18 21:54:10'),
(522, '00000015', 7754725000281, 5, 17.5, '2021-10-18 22:34:17'),
(523, '00000016', 7751271021975, 1, 3.3, '2021-10-18 22:34:51'),
(524, '00000016', 7750182006088, 1, 2.5, '2021-10-18 22:34:51'),
(525, '00000016', 7750151003902, 1, 8.8, '2021-10-18 22:34:51'),
(526, '00000016', 7750885012928, 1, 0.8, '2021-10-18 22:34:51'),
(527, '00000016', 7750106002608, 1, 0.8, '2021-10-18 22:34:51'),
(528, '00000017', 7751271027656, 1, 5, '2021-10-18 23:01:17'),
(529, '00000018', 7750182002363, 1, 1.8, '2021-10-18 23:56:24'),
(530, '00000019', 7754725000281, 4, 14, '2021-10-19 02:27:17'),
(531, '00000019', 7750182002363, 4, 7.2, '2021-10-19 02:27:17'),
(532, '00000020', 7759222002097, 1, 9.5, '2021-10-19 02:29:41'),
(533, '00000020', 7755139002809, 1, 20, '2021-10-19 02:29:41'),
(534, '00000021', 10001, 4, 9.2, '2021-10-19 02:31:19'),
(535, '00000022', 10002, 0.25, 1.25, '2021-10-19 02:32:55'),
(536, '00000014', 7755139002809, 3, 69, '2021-10-02 02:54:10'),
(537, '00000015', 7754725000281, 5, 17.5, '2021-10-02 03:34:17'),
(538, '00000016', 7751271021975, 1, 3.3, '2021-10-02 03:34:51'),
(539, '00000016', 7750182006088, 1, 2.5, '2021-10-02 03:34:51'),
(540, '00000016', 7750151003902, 1, 8.8, '2021-10-02 03:34:51'),
(541, '00000016', 7750885012928, 1, 0.8, '2021-10-02 03:34:51'),
(542, '00000016', 7750106002608, 1, 0.8, '2021-10-02 03:34:51'),
(543, '00000017', 7751271027656, 1, 5, '2021-10-02 04:01:17'),
(544, '00000018', 7750182002363, 1, 1.8, '2021-10-02 04:56:24'),
(545, '00000019', 7754725000281, 4, 14, '2021-10-01 07:27:17'),
(546, '00000019', 7750182002363, 4, 7.2, '2021-10-01 07:27:17'),
(547, '00000020', 7759222002097, 1, 9.5, '2021-10-01 07:29:41'),
(548, '00000020', 7755139002809, 1, 20, '2021-10-01 07:29:41'),
(549, '00000021', 10001, 4, 9.2, '2021-10-01 07:31:19'),
(550, '00000022', 10002, 0.25, 1.25, '2021-10-01 07:32:55'),
(551, '00000014', 7755139002809, 3, 69, '2021-10-03 02:54:10'),
(552, '00000015', 7754725000281, 5, 17.5, '2021-10-03 03:34:17'),
(553, '00000016', 7751271021975, 1, 3.3, '2021-10-03 03:34:51'),
(554, '00000016', 7750182006088, 1, 2.5, '2021-10-03 03:34:51'),
(555, '00000016', 7750151003902, 1, 8.8, '2021-10-03 03:34:51'),
(556, '00000016', 7750885012928, 1, 0.8, '2021-10-03 03:34:51'),
(557, '00000016', 7750106002608, 1, 0.8, '2021-10-03 03:34:51'),
(558, '00000017', 7751271027656, 1, 5, '2021-10-03 04:01:17'),
(559, '00000018', 7750182002363, 1, 1.8, '2021-10-03 04:56:24'),
(560, '00000019', 7754725000281, 4, 14, '2021-10-02 07:27:17'),
(561, '00000019', 7750182002363, 4, 7.2, '2021-10-02 07:27:17'),
(562, '00000020', 7759222002097, 1, 9.5, '2021-10-02 07:29:41'),
(563, '00000020', 7755139002809, 1, 20, '2021-10-02 07:29:41'),
(564, '00000021', 10001, 4, 9.2, '2021-10-02 07:31:19'),
(565, '00000022', 10002, 0.25, 1.25, '2021-10-02 07:32:55'),
(566, '00000014', 7755139002809, 3, 69, '2021-10-04 02:54:10'),
(567, '00000015', 7754725000281, 5, 17.5, '2021-10-04 03:34:17'),
(568, '00000016', 7751271021975, 1, 3.3, '2021-10-04 03:34:51'),
(569, '00000016', 7750182006088, 1, 2.5, '2021-10-04 03:34:51'),
(570, '00000016', 7750151003902, 1, 8.8, '2021-10-04 03:34:51'),
(571, '00000016', 7750885012928, 1, 0.8, '2021-10-04 03:34:51'),
(572, '00000016', 7750106002608, 1, 0.8, '2021-10-04 03:34:51'),
(573, '00000017', 7751271027656, 1, 5, '2021-10-04 04:01:17'),
(574, '00000018', 7750182002363, 1, 1.8, '2021-10-04 04:56:24'),
(575, '00000019', 7754725000281, 4, 14, '2021-10-03 07:27:17'),
(576, '00000019', 7750182002363, 4, 7.2, '2021-10-03 07:27:17'),
(577, '00000020', 7759222002097, 1, 9.5, '2021-10-03 07:29:41'),
(578, '00000020', 7755139002809, 1, 20, '2021-10-03 07:29:41'),
(579, '00000021', 10001, 4, 9.2, '2021-10-03 07:31:19'),
(580, '00000022', 10002, 0.25, 1.25, '2021-10-03 07:32:55'),
(581, '00000014', 7755139002809, 3, 69, '2021-10-05 02:54:10'),
(582, '00000015', 7754725000281, 5, 17.5, '2021-10-05 03:34:17'),
(583, '00000016', 7751271021975, 1, 3.3, '2021-10-05 03:34:51'),
(584, '00000016', 7750182006088, 1, 2.5, '2021-10-05 03:34:51'),
(585, '00000016', 7750151003902, 1, 8.8, '2021-10-05 03:34:51'),
(586, '00000016', 7750885012928, 1, 0.8, '2021-10-05 03:34:51'),
(587, '00000016', 7750106002608, 1, 0.8, '2021-10-05 03:34:51'),
(588, '00000017', 7751271027656, 1, 5, '2021-10-05 04:01:17'),
(589, '00000018', 7750182002363, 1, 1.8, '2021-10-05 04:56:24'),
(590, '00000019', 7754725000281, 4, 14, '2021-10-04 07:27:17'),
(591, '00000019', 7750182002363, 4, 7.2, '2021-10-04 07:27:17'),
(592, '00000020', 7759222002097, 1, 9.5, '2021-10-04 07:29:41'),
(593, '00000020', 7755139002809, 1, 20, '2021-10-04 07:29:41'),
(594, '00000021', 10001, 4, 9.2, '2021-10-04 07:31:19'),
(595, '00000022', 10002, 0.25, 1.25, '2021-10-04 07:32:55'),
(596, '00000014', 7755139002809, 3, 69, '2021-10-06 02:54:10'),
(597, '00000015', 7754725000281, 5, 17.5, '2021-10-06 03:34:17'),
(598, '00000016', 7751271021975, 1, 3.3, '2021-10-06 03:34:51'),
(599, '00000016', 7750182006088, 1, 2.5, '2021-10-06 03:34:51'),
(600, '00000016', 7750151003902, 1, 8.8, '2021-10-06 03:34:51'),
(601, '00000016', 7750885012928, 1, 0.8, '2021-10-06 03:34:51'),
(602, '00000016', 7750106002608, 1, 0.8, '2021-10-06 03:34:51'),
(603, '00000017', 7751271027656, 1, 5, '2021-10-06 04:01:17'),
(604, '00000018', 7750182002363, 1, 1.8, '2021-10-06 04:56:24'),
(605, '00000019', 7754725000281, 4, 14, '2021-10-05 07:27:17'),
(606, '00000019', 7750182002363, 4, 7.2, '2021-10-05 07:27:17'),
(607, '00000020', 7759222002097, 1, 9.5, '2021-10-05 07:29:41'),
(608, '00000020', 7755139002809, 1, 20, '2021-10-05 07:29:41'),
(609, '00000021', 10001, 4, 9.2, '2021-10-05 07:31:19'),
(610, '00000022', 10002, 0.25, 1.25, '2021-10-05 07:32:55'),
(611, '00000014', 7755139002809, 3, 69, '2021-10-07 02:54:10'),
(612, '00000015', 7754725000281, 5, 17.5, '2021-10-07 03:34:17'),
(613, '00000016', 7751271021975, 1, 3.3, '2021-10-07 03:34:51'),
(614, '00000016', 7750182006088, 1, 2.5, '2021-10-07 03:34:51'),
(615, '00000016', 7750151003902, 1, 8.8, '2021-10-07 03:34:51'),
(616, '00000016', 7750885012928, 1, 0.8, '2021-10-07 03:34:51'),
(617, '00000016', 7750106002608, 1, 0.8, '2021-10-07 03:34:51'),
(618, '00000017', 7751271027656, 1, 5, '2021-10-07 04:01:17'),
(619, '00000018', 7750182002363, 1, 1.8, '2021-10-07 04:56:24'),
(620, '00000019', 7754725000281, 4, 14, '2021-10-06 07:27:17'),
(621, '00000019', 7750182002363, 4, 7.2, '2021-10-06 07:27:17'),
(622, '00000020', 7759222002097, 1, 9.5, '2021-10-06 07:29:41'),
(623, '00000020', 7755139002809, 1, 20, '2021-10-06 07:29:41'),
(624, '00000021', 10001, 4, 9.2, '2021-10-06 07:31:19'),
(625, '00000022', 10002, 0.25, 1.25, '2021-10-06 07:32:55'),
(626, '00000014', 7755139002809, 3, 69, '2021-10-08 02:54:10'),
(627, '00000015', 7754725000281, 5, 17.5, '2021-10-08 03:34:17'),
(628, '00000016', 7751271021975, 1, 3.3, '2021-10-08 03:34:51'),
(629, '00000016', 7750182006088, 1, 2.5, '2021-10-08 03:34:51'),
(630, '00000016', 7750151003902, 1, 8.8, '2021-10-08 03:34:51'),
(631, '00000016', 7750885012928, 1, 0.8, '2021-10-08 03:34:51'),
(632, '00000016', 7750106002608, 1, 0.8, '2021-10-08 03:34:51'),
(633, '00000017', 7751271027656, 1, 5, '2021-10-08 04:01:17'),
(634, '00000018', 7750182002363, 1, 1.8, '2021-10-08 04:56:24'),
(635, '00000019', 7754725000281, 4, 14, '2021-10-07 07:27:17'),
(636, '00000019', 7750182002363, 4, 7.2, '2021-10-07 07:27:17'),
(637, '00000020', 7759222002097, 1, 9.5, '2021-10-07 07:29:41'),
(638, '00000020', 7755139002809, 1, 20, '2021-10-07 07:29:41'),
(639, '00000021', 10001, 4, 9.2, '2021-10-07 07:31:19'),
(640, '00000022', 10002, 0.25, 1.25, '2021-10-07 07:32:55'),
(641, '00000023', 7750182002363, 1, 1.8, '2021-10-24 22:27:16'),
(642, '00000024', 10001, 1, 2.3, '2021-10-24 22:27:45'),
(643, '00000024', 7501006559019, 1, 3.5, '2021-10-24 22:27:45'),
(644, '00000024', 7755139002809, 3, 60, '2021-10-24 22:27:45');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `empresa`
--
ALTER TABLE `empresa`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`,`codigo_producto`);

--
-- Indices de la tabla `venta_cabecera`
--
ALTER TABLE `venta_cabecera`
  ADD PRIMARY KEY (`id_boleta`);

--
-- Indices de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `empresa`
--
ALTER TABLE `empresa`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `venta_cabecera`
--
ALTER TABLE `venta_cabecera`
  MODIFY `id_boleta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=645;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
