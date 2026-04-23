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

-- 13
ALTER TABLE employees ADD COLUMN comision DECIMAL(10,2) DEFAULT 0;
SET SQL_SAFE_UPDATES = 0;
delimiter $$
create procedure actualizarcomision()
begin
    declare done int default 0;
    declare v_employeenumber int;
    declare v_totalventas decimal(15,2);
    declare cur_empleados cursor for
        select employeenumber from employees;
    declare continue handler for not found set done = 1;
    open cur_empleados;
    read_loop: loop
        fetch cur_empleados into v_employeenumber;
        if done then
            leave read_loop;
        end if;
        select ifnull(sum(od.quantityordered * od.priceeach), 0)
        into v_totalventas
        from customers c
        join orders o on c.customernumber = o.customernumber
        join orderdetails od on o.ordernumber = od.ordernumber
        where c.salesrepemployeenumber = v_employeenumber;
        update employees
        set comision =
            case
                when v_totalventas > 100000 then v_totalventas * 0.05
                when v_totalventas between 50000 and 100000 then v_totalventas * 0.03
                else 0
            end
        where employeenumber = v_employeenumber;
    end loop;
    close cur_empleados;
end $$
delimiter ;

-- 14
delimiter $$
create procedure asignarempleados()
begin
    declare done int default 0;
    declare v_customernumber int;
    declare v_empleado int;
    declare cur_clientes cursor for
        select customernumber
        from customers
        where salesrepemployeenumber is null;
    declare continue handler for not found set done = 1;
    open cur_clientes;
    read_loop: loop
        fetch cur_clientes into v_customernumber;
        if done then
            leave read_loop;
        end if;
        select employeenumber
        into v_empleado
        from (
            select e.employeenumber, count(c.customernumber) as total
            from employees e
            left join customers c 
                on e.employeenumber = c.salesrepemployeenumber
            group by e.employeenumber
            order by total asc
            limit 1
        ) as sub;
        update customers
        set salesrepemployeenumber = v_empleado
        where customernumber = v_customernumber;
    end loop;
    close cur_clientes;
end $$
delimiter ;

create table reporte_ventas (
	numeroOrden int,
    nombreCliente varchar(45),
    pais varchar(45),
    totalGastado float,
    cantItems int,
    estado varchar(45),
    diasParaEntrega int
);

delimiter $$
create procedure generar_reporte()
begin
	declare sinFilas int default 0;
    declare v_numeroorden int;
    declare v_nombrecliente varchar(45);
    declare v_pais varchar(45);
    declare v_totalgastado float;
    declare v_cantitems int;
    declare v_estado varchar(45);
    declare v_diasparaentrega int;
    declare cur_ordenes cursor for
        select o.ordernumber, c.customername, c.country, o.status, 
        datediff(o.shippeddate, o.orderdate) as diasentrega from orders o
        join customers c on o.customernumber = c.customernumber;
    declare continue handler for not found set sinFilas = 1;

    open cur_ordenes;
    bucle : loop
        fetch cur_ordenes into 
            v_numeroorden, 
            v_nombrecliente, 
            v_pais, 
            v_estado, 
            v_diasparaentrega;

        if sinFilas then
            leave bucle;
        end if;

        select sum(od.quantityordered * od.priceeach)
        into v_totalgastado
        from orderdetails od
        where od.ordernumber = v_numeroorden;

        select sum(od.quantityordered)
        into v_cantitems
        from orderdetails od
        where od.ordernumber = v_numeroorden;

        insert into reporte_ventas (numeroorden, nombrecliente, pais, totalgastado, cantitems, estado,
        diasparaentrega)
        values (v_numeroorden, v_nombrecliente, v_pais, v_totalgastado, v_cantitems, v_estado, 
        v_diasparaentrega);
    end loop;
    close cur_ordenes;
end $$
delimiter ;

delimiter $$

create procedure insertar_ordenes_masivas()
begin
    declare i int default 0;
    declare v_ordernumber int;
    declare v_customernumber int;

    -- base inicial
    select ifnull(max(ordernumber), 0) + 1 into v_ordernumber from orders;

    while i < 3000 do

        -- cliente random
        select customernumber into v_customernumber
        from customers
        order by rand()
        limit 1;

        -- insertar orden
        insert into orders (
            ordernumber,
            orderdate,
            requireddate,
            shippeddate,
            status,
            comments,
            customernumber
        ) values (
            v_ordernumber,
            curdate(),
            date_add(curdate(), interval 7 day),
            date_add(curdate(), interval 2 day),
            'shipped',
            'orden generada automaticamente',
            v_customernumber
        );

        -- insertar 3 productos distintos (sin variables @)
        insert into orderdetails (
            ordernumber,
            productcode,
            quantityordered,
            priceeach,
            orderlinenumber
        )
        select 
            v_ordernumber,
            p.productcode,
            floor(1 + rand() * 10),
            p.buyprice,
            row_number() over () as orderlinenumber
        from (
            select productcode, buyprice
            from products
            order by rand()
            limit 3
        ) p;

        -- incrementar id
        set v_ordernumber = v_ordernumber + 1;
        set i = i + 1;

    end while;

end$$

delimiter ;

delete from reporte_ventas;