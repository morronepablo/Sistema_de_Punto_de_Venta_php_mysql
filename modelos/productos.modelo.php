<?php

require_once "conexion.php";

use PhpOffice\PhpSpreadsheet\IOFactory;

class ProductosModelo
{
    static public function mdlCargaMasivaProductos($fileProductos)
    {
        $nombreArchivo = $fileProductos['tmp_name'];
        $documento = IOFactory::load($nombreArchivo);

        $hojaCategorias = $documento->getSheet(1);
        $numeroFilasCategorias = $hojaCategorias->getHighestDataRow();

        $hojaProductos = $documento->getSheetByName("Productos");
        $numeroFilasProductos = $hojaProductos->getHighestDataRow();

        //var_dump($numerofilasCategorias);

        $categoriasRegistradas = 0;
        $productosRegistrados = 0;

        //CICLO FOR PARA REGISTRO DE CATEGORIAS
        for ($i = 2; $i <= $numeroFilasCategorias; $i++) {

            $categoria = $hojaCategorias->getCellByColumnAndRow(1, $i);
            $aplica_peso = $hojaCategorias->getCellByColumnAndRow(2, $i);
            $fecha_actualizacion = date("Y-m-d");

            if (!empty($categoria)) {
                $stmt = Conexion::conectar()->prepare("INSERT INTO categorias(nombre_categoria,
                                                                                aplica_peso,
                                                                                fecha_actualizacion_categoria) 
                                                                    values(:nombre_categoria,
                                                                            :aplica_peso,
                                                                            :fecha_actualizacion_categoria);");
                $stmt->bindParam(":nombre_categoria", $categoria, PDO::PARAM_STR);
                $stmt->bindParam(":aplica_peso", $aplica_peso, PDO::PARAM_STR);
                $stmt->bindParam(":fecha_actualizacion_categoria", $fecha_actualizacion, PDO::PARAM_STR);

                if ($stmt->execute()) {
                    $categoriasRegistradas = $categoriasRegistradas + 1;
                } else {
                    $categoriasRegistradas = 0;
                }
            }
        }

        if ($categoriasRegistradas > 0) {
            //CICLO FOR PARA REGISTRO DE PRODUCTOS
            for ($i = 2; $i <= $numeroFilasProductos; $i++) {

                $codigo_producto = $hojaProductos->getCell("A" . $i);
                $id_categoria_producto = ProductosModelo::mdlBuscarIdCategoria($hojaProductos->getCell("B" . $i));
                $descripcion_producto = $hojaProductos->getCell("C" . $i);
                $precio_compra_producto = $hojaProductos->getCell("D" . $i);
                $precio_venta_producto = $hojaProductos->getCell("E" . $i);
                $utilidad = $hojaProductos->getCell("F" . $i);
                $stock_producto = $hojaProductos->getCell("G" . $i);
                $minimo_stock_producto = $hojaProductos->getCell("H" . $i);
                $ventas_producto = $hojaProductos->getCell("I" . $i);
                $fecha_actualizacion_producto = date('Y-m-d');

                if (!empty($codigo_producto)) {
                    $stmt = Conexion::conectar()->prepare("INSERT INTO productos(   codigo_producto,
                                                                                    id_categoria_producto,
                                                                                    descripcion_producto,
                                                                                    precio_compra_producto,
                                                                                    precio_venta_producto,
                                                                                    utilidad,
                                                                                    stock_producto,
                                                                                    minimo_stock_producto,
                                                                                    ventas_producto,
                                                                                    fecha_actualizacion_producto) 
                                                                        values( :codigo_producto,
                                                                                :id_categoria_producto,
                                                                                :descripcion_producto,
                                                                                :precio_compra_producto,
                                                                                :precio_venta_producto,
                                                                                :utilidad,
                                                                                :stock_producto,
                                                                                :minimo_stock_producto,
                                                                                :ventas_producto,
                                                                                :fecha_actualizacion_producto);");
                    $stmt->bindParam(":codigo_producto", $codigo_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":id_categoria_producto", $id_categoria_producto[0], PDO::PARAM_STR);
                    $stmt->bindParam(":descripcion_producto", $descripcion_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":precio_compra_producto", $precio_compra_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":precio_venta_producto", $precio_venta_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":utilidad", $utilidad, PDO::PARAM_STR);
                    $stmt->bindParam(":stock_producto", $stock_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":minimo_stock_producto", $minimo_stock_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":ventas_producto", $ventas_producto, PDO::PARAM_STR);
                    $stmt->bindParam(":fecha_actualizacion_producto", $fecha_actualizacion_producto, PDO::PARAM_STR);

                    if ($stmt->execute()) {
                        $productosRegistrados = $productosRegistrados + 1;
                    } else {
                        $productosRegistrados = 0;
                    }
                }
            }
        }

        $respuesta["totalCategorias"] = $categoriasRegistradas;
        $respuesta["totalProductos"] = $productosRegistrados;

        return $respuesta;
    }

    static public function mdlBuscarIdCategoria($nombreCategoria)
    {
        $stmt = Conexion::conectar()->prepare("SELECT id_categoria FROM categorias WHERE nombre_categoria = :nombre_categoria");
        $stmt->bindParam(":nombre_categoria", $nombreCategoria, PDO::PARAM_STR);
        $stmt->execute();

        return $stmt->fetch();
    }

    static public function mdlListarProductos()
    {
        $stmt = Conexion::conectar()->prepare('call prc_ListarProductos()');

        $stmt->execute();

        return $stmt->fetchAll();
    }
}
