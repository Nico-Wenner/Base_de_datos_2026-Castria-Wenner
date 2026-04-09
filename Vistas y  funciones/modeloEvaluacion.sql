-- Crear base de datos
CREATE DATABASE concesionaria;
USE concesionaria;

-- Tabla modelo
CREATE TABLE modelo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    marca VARCHAR(45),
    potencia VARCHAR(45)
);

-- Tabla auto
CREATE TABLE auto (
    patente VARCHAR(45) PRIMARY KEY,
    anoFabricacion VARCHAR(45),
    observaciones VARCHAR(45),
    color VARCHAR(45),
    modelo_id INT,
    precio FLOAT,
    FOREIGN KEY (modelo_id) REFERENCES modelo(id)
);

-- Tabla cliente
CREATE TABLE cliente (
    dni INT PRIMARY KEY,
    nombre VARCHAR(45),
    apellido VARCHAR(45),
    mail VARCHAR(45),
    fechaNacimiento DATE
);

-- Tabla empleado
CREATE TABLE empleado (
    dni INT PRIMARY KEY,
    nombre VARCHAR(45),
    apellido VARCHAR(45),
    numeroTel INT,
    direccion VARCHAR(45),
    mail VARCHAR(45),
    fechaIngreso DATE
);

-- Tabla compra
CREATE TABLE compra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE,
    auto_patente VARCHAR(45),
    cliente_dni INT,
    empleado_dni INT,
    precio FLOAT,
    FOREIGN KEY (auto_patente) REFERENCES auto(patente),
    FOREIGN KEY (cliente_dni) REFERENCES cliente(dni),
    FOREIGN KEY (empleado_dni) REFERENCES empleado(dni)
);

-- Tabla metodoPago
CREATE TABLE metodoPago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45)
);

-- Tabla pago
CREATE TABLE pago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    monto FLOAT,
    compra_id INT,
    metodoPago_id INT,
    FOREIGN KEY (compra_id) REFERENCES compra(id),
    FOREIGN KEY (metodoPago_id) REFERENCES metodoPago(id)
);

-- Insertar modelos
INSERT INTO modelo (marca, potencia) VALUES
('Toyota', '150 HP'),
('Honda', '130 HP'),
('Ford', '180 HP'),
('Chevrolet', '200 HP');

-- Insertar autos
INSERT INTO auto (patente, anoFabricacion, observaciones, color, modelo_id, precio) VALUES
('ABC123', '2020', 'Excelente estado', 'Rojo', 1, 25000),
('DEF456', '2019', 'Único dueño', 'Azul', 2, 22000),
('GHI789', '2021', 'Nuevo', 'Negro', 3, 30000),
('JKL012', '2018', 'Revisado', 'Blanco', 4, 27000);

-- Insertar clientes
INSERT INTO cliente (dni, nombre, apellido, mail, fechaNacimiento) VALUES
(12345678, 'Juan', 'Pérez', 'juan.perez@mail.com', '1985-05-12'),
(87654321, 'María', 'Gómez', 'maria.gomez@mail.com', '1990-11-23'),
(11223344, 'Carlos', 'López', 'carlos.lopez@mail.com', '1978-02-14');

-- Insertar empleados
INSERT INTO empleado (dni, nombre, apellido, numeroTel, direccion, mail, fechaIngreso) VALUES
(99887766, 'Ana', 'Martínez', 123456789, 'Calle Falsa 123', 'ana.martinez@mail.com', '2015-03-01'),
(66778899, 'Luis', 'Fernández', 987654321, 'Av. Siempre Viva 456', 'luis.fernandez@mail.com', '2018-07-15');

-- Insertar compras
INSERT INTO compra (fecha, auto_patente, cliente_dni, empleado_dni, precio) VALUES
('2022-08-10', 'ABC123', 12345678, 99887766, 25000),
('2023-01-20', 'DEF456', 87654321, 66778899, 22000),
('2023-03-15', 'GHI789', 11223344, 99887766, 30000);

-- Insertar métodos de pago
INSERT INTO metodoPago (nombre) VALUES
('Efectivo'),
('Tarjeta de crédito'),
('Transferencia bancaria');

-- Insertar pagos
INSERT INTO pago (monto, compra_id, metodoPago_id) VALUES
(25000, 1, 2),
(22000, 2, 1),
(30000, 3, 3);

-- funciones
-- 1
delimiter $$
create function deuda (idCompra int)
returns int deterministic
begin
	declare totalAPagar float;
    declare totalPagado float;
    
    select precio into totalAPagar from compra where id=idCompra;
    
    select ifnull(sum(monto),0) into totalPagado from pago where compra_id=idCompra group by compra_id;
    
    if totalAPagar <= totalPagado then
		return 1;
	else
		return 0;
	end if;
end$$
delimiter ;

-- 2
delimiter $$
create function comision (dniEmpleado int, mes int, anio int)
returns float deterministic
begin
	declare vendidoMes float;
    declare antiguedad int;
    
    select sum(precio) into vendidoMes from compra where empleado_dni=dniEmpleado 
    and month(fecha)=mes and year(fecha)=anio;
    
    select timestampdiff(year, fechaIngreso,curdate()) as anios
    into antiguedad from empleado where dni=dniEmpleado;
    
    if antiguedad < 5 then
		return vendidoMes*5/100;
	else if antiguedad >= 5 and antiguedad <= 10 then
		return vendidoMes*7/100;
	else
		return vendidoMes*10/100;
	end if;
    end if;
end$$
delimiter ;

-- 3
delimiter $$
create function modeloMes (idModelo int, mes int)
returns int deterministic
begin
	declare cantidad int;
    
    select count(patente) into cantidad from auto a
    join compra c on a.patente=c.auto_patente
    where a.modelo_id=idModelo and month(c.fecha)=mes;
    
    return cantidad;
end$$
delimiter ;

-- ejercicio vistas
-- 1
create view resumen as
select cl.dni, cl.mail, co.fecha, a.patente, a.color, m.marca, deuda(co.id) from
cliente cl join compra co on cl.dni=co.cliente_dni
join auto a on co.auto_patente=a.patente
join modelo m on a.modelo_id=m.id;

-- 3
create view ventasModelo as
select m.id, modeloMes(m.id,month(c.fecha)) as ventas, sum(c.precio) as ganancia, 
	(select c.fecha from compra c join auto a on c.auto_patente = a.patente 
    where a.modelo_id = m.id group by c.fecha order by count(*) desc limit 1)
as fecha_mas_vendida from modelo m 
join auto a on m.id=a.modelo_id join compra c on a.patente=c.auto_patente
group by m.id, month(c.fecha), ventas;