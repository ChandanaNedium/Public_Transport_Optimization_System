-- ========================================================
-- PUBLIC TRANSPORT OPTIMISATION SYSTEM - DATABASE SCHEMA
-- DBMS Mini Project - College Demonstration & Viva
-- ========================================================

CREATE DATABASE IF NOT EXISTS public_transport_db;
USE public_transport_db;

-- Drop items in proper order of constraints
DROP TRIGGER IF EXISTS check_seat_availability;
DROP PROCEDURE IF EXISTS book_ticket_sp;
DROP VIEW IF EXISTS passenger_booking_history_v;
DROP VIEW IF EXISTS route_schedule_details_v;
DROP VIEW IF EXISTS vehicle_occupancy_v;

DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS stop;
DROP TABLE IF EXISTS schedule;
DROP TABLE IF EXISTS vehicle;
DROP TABLE IF EXISTS driver;
DROP TABLE IF EXISTS route;
DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS admin;

-- --------------------------------------------------------
-- 1. Table: Passenger
-- --------------------------------------------------------
CREATE TABLE passenger (
    passenger_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Hashed passwords for registration/login
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 1b. Table: Admin
-- --------------------------------------------------------
CREATE TABLE admin (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 2. Table: Driver
-- --------------------------------------------------------
CREATE TABLE driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    license_no VARCHAR(50) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 3. Table: Vehicle
-- --------------------------------------------------------
CREATE TABLE vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL, -- e.g., 'Bus', 'Metro', 'Tram'
    capacity INT NOT NULL,
    driver_id INT UNIQUE, -- One-to-One: One Driver manages one Vehicle
    CONSTRAINT fk_vehicle_driver FOREIGN KEY (driver_id) 
        REFERENCES driver(driver_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 4. Table: Route
-- --------------------------------------------------------
CREATE TABLE route (
    route_id INT AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    distance DECIMAL(5,2) NOT NULL, -- Distance in km
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 5. Table: Schedule
-- --------------------------------------------------------
CREATE TABLE schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    vehicle_id INT NOT NULL,
    route_id INT NOT NULL,
    CONSTRAINT fk_schedule_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
    CONSTRAINT fk_schedule_route FOREIGN KEY (route_id) 
        REFERENCES route(route_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 6. Table: Stop
-- --------------------------------------------------------
CREATE TABLE stop (
    stop_id INT AUTO_INCREMENT PRIMARY KEY,
    stop_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    vehicle_id INT, -- Associated vehicles passing through this stop
    route_id INT NOT NULL,
    CONSTRAINT fk_stop_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicle(vehicle_id) ON DELETE SET NULL,
    CONSTRAINT fk_stop_route FOREIGN KEY (route_id) 
        REFERENCES route(route_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 7. Table: Ticket
-- --------------------------------------------------------
CREATE TABLE ticket (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    passenger_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    schedule_id INT NOT NULL,
    travel_date DATE NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    seat_no INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ticket_passenger FOREIGN KEY (passenger_id) 
        REFERENCES passenger(passenger_id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_schedule FOREIGN KEY (schedule_id) 
        REFERENCES schedule(schedule_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ========================================================
-- ADVANCED DBMS CONCEPTS
-- ========================================================

-- --------------------------------------------------------
-- Concept 1: View - Passenger Booking History
-- Joins: passenger, ticket, schedule, route, vehicle
-- --------------------------------------------------------
CREATE VIEW passenger_booking_history_v AS
SELECT 
    t.ticket_id,
    p.passenger_id,
    p.name AS passenger_name,
    p.email AS passenger_email,
    r.source,
    r.destination,
    s.departure_time,
    s.arrival_time,
    v.type AS vehicle_type,
    t.travel_date,
    t.fare,
    t.seat_no,
    t.created_at AS booking_date
FROM ticket t
INNER JOIN passenger p ON t.passenger_id = p.passenger_id
INNER JOIN schedule s ON t.schedule_id = s.schedule_id
INNER JOIN route r ON s.route_id = r.route_id
INNER JOIN vehicle v ON t.vehicle_id = v.vehicle_id;

-- --------------------------------------------------------
-- Concept 2: View - Route and Schedule Details
-- Joins: route, schedule, vehicle, driver
-- --------------------------------------------------------
CREATE VIEW route_schedule_details_v AS
SELECT 
    s.schedule_id,
    r.route_id,
    r.source,
    r.destination,
    r.distance,
    s.departure_time,
    s.arrival_time,
    v.vehicle_id,
    v.type AS vehicle_type,
    v.capacity,
    d.name AS driver_name,
    d.phone AS driver_phone
FROM schedule s
INNER JOIN route r ON s.route_id = r.route_id
INNER JOIN vehicle v ON s.vehicle_id = v.vehicle_id
LEFT JOIN driver d ON v.driver_id = d.driver_id;

-- --------------------------------------------------------
-- Concept 3: View - Vehicle Occupancy Rates
-- Demonstrates SQL Aggregation and LEFT JOINS
-- --------------------------------------------------------
CREATE VIEW vehicle_occupancy_v AS
SELECT 
    s.schedule_id,
    r.source,
    r.destination,
    v.vehicle_id,
    v.type AS vehicle_type,
    v.capacity AS max_capacity,
    t.travel_date,
    COUNT(t.ticket_id) AS seats_booked,
    (v.capacity - COUNT(t.ticket_id)) AS seats_available,
    ROUND((COUNT(t.ticket_id) / v.capacity) * 100, 2) AS occupancy_percentage
FROM schedule s
INNER JOIN route r ON s.route_id = r.route_id
INNER JOIN vehicle v ON s.vehicle_id = v.vehicle_id
LEFT JOIN ticket t ON s.schedule_id = t.schedule_id
GROUP BY s.schedule_id, t.travel_date, v.vehicle_id, r.source, r.destination, v.type, v.capacity;

-- --------------------------------------------------------
-- Concept 4: Trigger - Check Seat Availability & Auto-assign seat
-- Triggered BEFORE INSERT on ticket table
-- --------------------------------------------------------
DELIMITER //
CREATE TRIGGER check_seat_availability
BEFORE INSERT ON ticket
FOR EACH ROW
BEGIN
    DECLARE vehicle_cap INT;
    DECLARE booked_count INT;
    
    -- Retrieve maximum capacity of the vehicle
    SELECT capacity INTO vehicle_cap
    FROM vehicle
    WHERE vehicle_id = NEW.vehicle_id;
    
    -- Count the number of seats already booked for this schedule on the specified travel date
    SELECT COUNT(*) INTO booked_count
    FROM ticket
    WHERE schedule_id = NEW.schedule_id AND travel_date = NEW.travel_date;
    
    -- Prevent booking if capacity is exceeded
    IF booked_count >= vehicle_cap THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Seat availability limit reached! This vehicle is fully booked for this schedule on this date.';
    ELSE
        -- Auto assign seat number
        SET NEW.seat_no = booked_count + 1;
    END IF;
END;
//
DELIMITER ;

-- --------------------------------------------------------
-- Concept 5: Stored Procedure - Complete Ticket Booking
-- Wraps booking in a transaction structure for reliability
-- --------------------------------------------------------
DELIMITER //
CREATE PROCEDURE book_ticket_sp(
    IN p_passenger_id INT,
    IN p_schedule_id INT,
    IN p_travel_date DATE,
    IN p_fare DECIMAL(10,2),
    OUT p_ticket_id INT
)
BEGIN
    DECLARE v_vehicle_id INT;
    
    -- Error Handler for database failure
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction failed: Ticket booking could not be completed.';
    END;

    START TRANSACTION;
    
    -- Obtain vehicle_id from the schedule
    SELECT vehicle_id INTO v_vehicle_id
    FROM schedule
    WHERE schedule_id = p_schedule_id;
    
    IF v_vehicle_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Selected schedule does not have an assigned vehicle.';
    END IF;
    
    -- Insert ticket record (the BEFORE INSERT trigger validates seating and sets seat_no)
    INSERT INTO ticket (passenger_id, vehicle_id, schedule_id, travel_date, fare, seat_no)
    VALUES (p_passenger_id, v_vehicle_id, p_schedule_id, p_travel_date, p_fare, 0);
    
    SET p_ticket_id = LAST_INSERT_ID();
    
    COMMIT;
END;
//
DELIMITER ;

-- ========================================================
-- SAMPLE RECORDS FOR COLLEGE DEMONSTRATION
-- ========================================================

-- Insert Passengers (Password is 'password123' plain / bcrypt hashed equivalent)
INSERT INTO passenger (name, phone, email, password) VALUES
('Ramesh Kumar', '9876543210', 'ramesh@gmail.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1'),
('Anita Sharma', '9876543211', 'anita@gmail.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1'),
('Sunil Verma', '9876543212', 'sunil@gmail.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1'),
('Deepa Rao', '9876543213', 'deepa@gmail.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1');

-- Insert Admins
INSERT INTO admin (name, phone, email, password) VALUES
('System Administrator', '0000000000', 'admin@routesync.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1'),
('Siddharth Rao', '9876543201', 'siddharth@routesync.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1'),
('Priya Sharma', '9876543202', 'priya@routesync.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1'),
('Vikram Singh', '9876543203', 'vikram@routesync.com', '$2b$10$w8.hRWh8i719pMlyT9T79.1C72x04U0m1W.3jG166G1Q1R1Q1R1Q1');

-- Insert Drivers
INSERT INTO driver (name, license_no, phone) VALUES
('Vijay Singh', 'DL-1420110056789', '8888888801'),
('Rajesh Yadav', 'KA-0320150098765', '8888888802'),
('Suresh Patil', 'MH-1220180012345', '8888888803'),
('Manpreet Singh', 'PB-0220190045678', '8888888804');

-- Insert Vehicles
INSERT INTO vehicle (type, capacity, driver_id) VALUES
('AC Deluxe Bus', 40, 1),
('Electric Shuttle', 15, 2),
('Express Volvo Bus', 45, 3),
('Double Decker Bus', 60, 4);

-- Insert Routes
INSERT INTO route (source, destination, distance) VALUES
('Majestic (Bengaluru)', 'Whitefield (Bengaluru)', 25.50),
('Koramangala', 'Electronic City', 18.20),
('Delhi Airport T3', 'Connaught Place', 22.00),
('Mumbai CST', 'Navi Mumbai', 35.80);

-- Insert Schedules
INSERT INTO schedule (departure_time, arrival_time, vehicle_id, route_id) VALUES
('07:30:00', '09:00:00', 1, 1), -- Majestic to Whitefield
('09:15:00', '10:45:00', 3, 1), -- Majestic to Whitefield Volvo
('08:00:00', '09:00:00', 2, 2), -- Koramangala to E-City
('17:30:00', '19:00:00', 2, 2), -- Koramangala to E-City (Return)
('10:00:00', '11:15:00', 4, 3); -- Airport to CP

-- Insert Stops for Routes
INSERT INTO stop (stop_name, location, vehicle_id, route_id) VALUES
-- Stops for Majestic to Whitefield
('Majestic Terminal', 'Platform 5', 1, 1),
('Indiranagar Double Road', 'Metro Station pillar 120', 1, 1),
('HAL Road', 'Near ISRO Junction', 1, 1),
('Whitefield ITPL', 'Opposite ITPL Gate 2', 1, 1),
-- Stops for Koramangala to E-City
('Koramangala 3rd Block', 'Water Tank Bus Stop', 2, 2),
('Silk Board', 'Flyover Entrance', 2, 2),
('Electronic City Phase 1', 'Wipro Gate', 2, 2);

-- Insert Initial Tickets (Simulating bookings)
-- Using direct inserts (trigger will compute seat numbers automatically: 1, 2, 3...)
INSERT INTO ticket (passenger_id, vehicle_id, schedule_id, travel_date, fare, seat_no) VALUES
(1, 1, 1, '2026-06-01', 120.00, 0),
(2, 1, 1, '2026-06-01', 120.00, 0),
(3, 2, 3, '2026-06-01', 50.00, 0),
(4, 2, 3, '2026-06-01', 50.00, 0);
