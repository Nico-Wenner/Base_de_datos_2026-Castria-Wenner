Create schema videojuegos;
USE videojuegos;

-- CREATEs
-- Tabla Jugadores
CREATE TABLE Jugadores (
    idJugador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45),
    apellido VARCHAR(45),
    email VARCHAR(45),
    fechaDeNacimiento DATE,
    pais VARCHAR(45)
);

-- Tabla Videojuegos
CREATE TABLE Videojuegos (
    idVideojuegos INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45) UNIQUE NOT NULL,
    genero VARCHAR(45),
    edadMinima INT
);

-- Tabla Equipos
CREATE TABLE Equipos (
    idEquipos INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45) UNIQUE,
    id_capitan int,
    constraint FK_capitan foreign key (id_capitan) references Jugadores(idJugador)
    on delete restrict on update restrict
);

-- Tabla Torneo
CREATE TABLE Torneo (
    idTorneo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45),
    fechaInicio DATE,
    fechaFin DATE,
    constraint fechasLimites check (fechaFin >= fechaInicio),
    premio INT NOT NULL,
    constraint dineroPremio check (premio >= 0),
    id_videojuego INT NOT NULL,
    constraint FK_videojuego foreign key (id_videojuego) references Videojuegos(idVideojuegos) 
    on delete restrict on update restrict
);

-- Tabla Inscripcion
CREATE TABLE Inscripcion (
    Equipo_id INT,
    Torneo_id INT,
    Posicion INT,
    fechaInscripcion DATE,
    PRIMARY KEY (Equipo_id, Torneo_id),
    UNIQUE (Torneo_id, Posicion),
    
    constraint FK_equipo foreign key (Equipo_id) references Equipos(idEquipos) 
    on delete restrict on update restrict,
    constraint FK_torneo foreign key (Torneo_id) references Torneo(idTorneo) 
    on delete restrict on update restrict
);

-- Tabla Participacion
CREATE TABLE Participacion (
    Equipo_id INT,
    Jugador_id INT,
    PRIMARY KEY (Equipo_id, Jugador_id),
    
    foreign key (Equipo_id) references Equipos(idEquipos) 
    on delete restrict on update restrict,
    foreign key (Jugador_id) references Jugadores(idJugador) 
    on delete restrict on update restrict
);

-- INSERTs
INSERT INTO Jugadores (nombre, apellido, email, fechaDeNacimiento, pais) VALUES
('Juan', 'Perez', 'juanp@gmail.com', '2000-05-14', 'Argentina'),
('Lucas', 'Martinez', 'lucasm@gmail.com', '1999-11-22', 'Argentina'),
('Sofia', 'Lopez', 'sofial@gmail.com', '2001-02-10', 'Chile'),
('Martin', 'Gomez', 'marting@gmail.com', '1998-07-03', 'Uruguay'),
('Carlos', 'Diaz', 'carlosd@gmail.com', '2002-09-18', 'Argentina'),
('Ana', 'Torres', 'anatorres@gmail.com', '2000-12-01', 'Peru');

INSERT INTO Videojuegos (nombre, genero, edadMinima) VALUES
('League of Legends', 'MOBA', 12),
('Counter Strike 2', 'FPS', 16),
('FIFA 24', 'Deportes', 3),
('Valorant', 'FPS', 16);

INSERT INTO Equipos (nombre, id_capitan) VALUES
('Dragones', 1),
('Titanes', 2),
('Samurais', 3);

INSERT INTO Torneo (nombre, fechaInicio, fechaFin, premio, id_videojuego) VALUES
('Copa Latinoamerica', '2024-06-01', '2024-06-10', 5000, 1),
('FPS Masters', '2024-07-15', '2024-07-20', 3000, 2),
('Ultimate Valorant Cup', '2024-08-05', '2024-08-12', 4000, 4);

INSERT INTO Participacion (Equipo_id, Jugador_id) VALUES
(1,1),
(1,4),
(2,2),
(2,5),
(3,3),
(3,6);

INSERT INTO Inscripcion (Equipo_id, Torneo_id, Posicion, fechaInscripcion) VALUES
(1,1,1,'2024-05-20'),
(2,1,2,'2024-05-21'),
(3,1,3,'2024-05-22'),

(1,2,2,'2024-07-01'),
(2,2,1,'2024-07-01'),

(3,3,1,'2024-07-15'),
(1,3,2,'2024-07-16');

-- EJERCICIOS
-- 1)
select idJugador, nombre, apellido from Jugadores where pais="Argentina" order by apellido asc;

-- 2)
select nombre from Videojuegos where edadMinima >= 16;

-- 3)
select e.id_capitan, j.nombre, j.apellido from Equipos e
join Jugadores j on e.id_capitan = j.idJugador;

-- 5)
select count(idJugador) from Jugadores group by pais;

-- 8)
select e.nombre, count(i.Equipo_id) as cant from Equipos e join Inscripcion i on e.idEquipos = i.Equipo_id
group by i.Equipo_id having cant > 5;

-- 11)
select max(cant) from
    (select count(id_videojuego) as cant from Torneo group by id_videojuego);
    
-- 13)
SET SQL_SAFE_UPDATES = 0;
update Torneo t set t.premio=t.premio*2 where 
	(select count(i.Equipo_id) from Inscripcion i where i.Torneo_id=t.idTorneo) <3;
    
-- 14)
update Videojuegos v set v.nombre=concat('[Popular]', v.nombre) where
	(select count(t.idTorneo) from Torneo t where t.id_videojuego=v.idVideojuegos) >2;
 
-- 16)
delete from Jugadores where idJugador not in 
    (select Jugador_id from Participación);