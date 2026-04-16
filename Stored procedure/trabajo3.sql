USE `classicmodels`;

-- 1
delimiter //
create procedure mayorPromedio()
begin
	select productCode from products where buyPrice > (select avg(buyPrice) from products);
    select count(*) as cantidad from products where buyPrice > (select avg(buyPrice) from products);
end //
delimiter ;

-- 2
delimiter //
create procedure borrarOrden(in numero int)
begin
	declare cuenta int default 0;
    declare lineasBorradas int default 0;
    
    select count(*) into cuenta from orders where orderNumber=numero;
    if cuenta = 0 then
		select 0;
	else
		delete from orderdetails where orderNumber=numero;
        set lineasBorradas = row_count();
        delete from orders where orderNumber=numero;
        select lineasBorradas;
	end if;
end //
delimiter ;

-- 3
delimiter //
create procedure borrarLinea (in linea varchar(50), out mensaje varchar(200))
begin
	declare cantProductos int default 0;
	select productos(linea) into cantProductos;
    if cantProductos=0 then
		set mensaje="La línea de productos fue borrada";
	else
		set mensaje="La línea de productos no pudo borrarse porque contiene productos asociados";
	end if;
end //
delimiter ;

-- 8
delimiter //
create procedure modificarComentario (in numero int, in mensaje varchar(200), out logro bool)
begin
	update orders set comments=mensaje where orderNumber=numero;
    if row_count()>0 then
		set logro=1;
	end if;
end //
delimiter ;

-- 9
delimiter //
create procedure getCiudadesOffices (out listadoCiudad varchar(5000))
begin
	declare hayFilas boolean default 1;
	declare ciudad varchar(50);
    declare nombreCursor cursor for select city from offices;
    declare continue handler for not found set hayFilas = 0;
    set listadoCiudad='';
    open nombreCursor;
    bucle:loop
		fetch nombreCursor into ciudad;
        if hayFilas=0 then
			leave bucle;
		end if;
        set listadoCiudad=concat(ciudad,", ",listadoCiudad);
	end loop bucle;
    close nombreCursor;
end //
delimiter ;

-- 11
delimiter //
create procedure comentarPrecio (in nroCliente int)
begin
	declare hayFilas boolean default 1;
    declare comentario varchar(75);
    declare precio float;
    declare nombreCursor cursor for select comments from orders;
    declare continue handler for not found set hayFilas = 0;
    open nombreCursor;
    bucle:loop
		fetch nombreCursor into comentario;
        if hayFilas=0 then
			leave bucle;
		end if;
        if comentario is null then
			select sum(od.quantityOrdered*od.priceEach) into precio from orderdetails od join orders o on
            od.orderNumber=o.orderNumber where o.customerNumber=nroCliente group by o.orderNumber;
			update orders set comments=("El total de la orden es "+precio) where customerNumber=nroCliente;
		end if;
	end loop bucle;
    close nombreCursor;
end //
delimiter ;