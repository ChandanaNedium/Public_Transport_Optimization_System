# RouteSync: Public Transport Optimisation System

RouteSync is a complete, full-stack database management system application designed to model and optimize public urban transportation. It handles passenger profiles, driver rosters, vehicle fleets, route pathways, transit schedules, stopping checkpoints, and ticket reservations. The project strongly emphasizes relational database integrity, normalized database schemas, constraints, multi-table joins, precompiled views, automated triggers, and transaction-safe stored procedures.

---

## 🚀 Key DBMS Features 

1. **Relational Database Design**: A fully normalized relational schema structured up to **3rd Normal Form (3NF)**, ensuring zero data redundancy.
2. **Referential Integrity constraints**: Robust foreign key constraints with `ON DELETE CASCADE` and `ON DELETE SET NULL` policies to safeguard against orphaned records.
3. **Database Views**:
   - `passenger_booking_history_v`: Precompiled view joining `passenger`, `ticket`, `schedule`, `route`, and `vehicle` tables for seamless audit lookups.
   - `route_schedule_details_v`: Precompiled view merging routes, schedules, and driver scopes for timetables.
   - `vehicle_occupancy_v`: Pre-aggregated view calculating seat occupancy percentages on-the-fly.
4. **Database Trigger (`check_seat_availability`)**:
   - Fires `BEFORE INSERT` on the `ticket` table.
   - Queries vehicle capacity against existing tickets booked for a specific schedule and travel date.
   - If capacity is exceeded, it halts the operation using SQL standard `SIGNAL SQLSTATE '45000'` with a custom exception message.
   - If a seat is available, it **automatically calculates and assigns the next incremental seat number** (`seat_no`).
5. **Stored Procedure (`book_ticket_sp`)**:
   - Encapsulates ticket booking inside an atomic `START TRANSACTION` / `COMMIT` / `ROLLBACK` boundary to guarantee transactional safety.
   - Looks up the assigned vehicle and executes the insertion securely, returning the generated `ticket_id`.

---

## 📂 Project Directory Structure
```
RouteSync/
│
├── database/
│   └── schema.sql             # SQL Script (Tables, Views, Procedures, Triggers, Mock Data)
│
├── backend/
│   ├── config/
│   │   └── db.js              # MySQL Pool Client & Simulated Mock Database Fallback
│   ├── controllers/           # Express Controllers (Auth, CRUD, SQL queries)
│   ├── middleware/            # Error Handling & Request Body Validators
│   ├── routes/                # Express API Route Mappings
│   ├── server.js              # Node.js Server Entry
│   ├── .env                   # Environment Variables Configuration
│   └── package.json           # Node Dependencies & Run Scripts
│
├── frontend/
│   ├── src/
│   │   ├── components/        # Shared Reusable UI Components
│   │   ├── layouts/
│   │   │   └── Layout.jsx     # Responsive glassmorphic sidebar layout & online monitor
│   │   ├── pages/             # Route pages (Dashboards, CRUD modules, Reports)
│   │   ├── services/
│   │   │   └── api.js         # Centralized Axios Interceptor Client
│   │   ├── App.jsx            # React Router DOM mappings
│   │   └── index.css          # Styling declarations & glassmorphism configurations
│   ├── tailwind.config.js     # Tailwind setup
│   ├── vite.config.js         # Vite dev configs
│   ├── index.html             # Google fonts & assets link Scaffolder
│   └── package.json           # React dependencies
│
├── postman_collection.json    # Complete API test suite for Postman
└── README.md                  # Installation & documentation handbook
```

---

## ⚡ Setup & Execution Instructions

### Prerequisites
- **Node.js** (v18.0.0 or higher)
- **MySQL Server** (v5.8 or higher)
- **MySQL Workbench** or any equivalent SQL client
- **Postman** (for testing APIs)

---

### Step 1: Database Setup (MySQL)
1. Open your MySQL client (e.g., MySQL Workbench).
2. Connect to your local MySQL instance.
3. Open and run the `database/schema.sql` script to create the database, tables, triggers, stored procedures, views, and load sample records:
   ```sql
   SOURCE database/schema.sql;
   ```

---

### Step 2: Backend Configuration
1. Open your terminal inside the `backend` folder:
   ```bash
   cd backend
   ```
2. Install the necessary Node packages:
   ```bash
   npm install
   ```
3. Open `backend/.env` and update the database credentials to match your local MySQL configuration:
   ```env
   PORT=5000
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=public_transport_db
   ```
4. Start the Express server in Developer Live-Reload Mode:
   ```bash
   npm run dev
   ``` 

---

### Step 3: Frontend Installation
1. Open a new terminal inside the `frontend` folder:
   ```bash
   cd frontend
   ```
2. Install the frontend dependencies:
   ```bash
   npm install
   ```
3. Start the Vite React development server:
   ```bash
   npm run dev
   ```
4. Open your browser and navigate to **`http://localhost:3000`** to view the application!

---

## 👥 Demo Logins

### 🛠️ Administrative Console
*   **Username**: `admin@routesync.com`
*   **Password**: `admin123`
*   *Accesses: Fleet management, Route modifications, timetables, driver rosters, passenger audits, and precompiled views reports.*

### 🚌 Passenger Portal
*   **Username**: `ramesh@gmail.com`
*   **Password**: `password123` (or register a fresh passenger account directly on the UI!)
*   *Accesses: Route searching, bus schedule timetables, live ticket booking, and seat assignments.*

---

## 🧪 Postman API Collection
> complete **`postman_collection.json`** file in the root directory.
Import it into Postman to run automated API verification:
1. Open Postman.
2. Click **Import** in the top left corner.
3. Select and upload the `postman_collection.json` file.
4. You will see a collection named **`RouteSync Public Transport Optimisation`** containing pre-configured requests for all Passengers, Drivers, Vehicles, Routes, Schedules, Stops, and Tickets.

---

## 🎓 Viva Questions Checklist

1. **How is the seat capacity constraint enforced?**
   - *Answer*: It is handled at the database level by the `check_seat_availability` trigger. Before a ticket is inserted, the trigger counts the existing rows in `ticket` for that schedule on that date, compares it with the `capacity` in the `vehicle` table, and raises an exception using `SIGNAL SQLSTATE '45000'` if the vehicle is fully booked.
2. **What happens when a Route is deleted?**
   - *Answer*: Because of the `ON DELETE CASCADE` constraint on `schedule` and `stop` tables, deleting a route will automatically clear all stops and timetables scheduled for that route, maintaining referential integrity.
3. **What is the difference between a Stored Procedure and a Trigger in your project?**
   - *Answer*: The stored procedure `book_ticket_sp` is called explicitly by our Node.js server to coordinate the transaction. The trigger `check_seat_availability` is fired automatically by MySQL *before* the ticket row is written to verify seat counts and auto-assign seat numbers.
