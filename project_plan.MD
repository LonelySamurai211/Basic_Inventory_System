1. Project Overview
The Materials Inventory Management System (MIMS) is designed to digitize and automate the hotel's material tracking process. It replaces manual spreadsheets and inconsistent record-keeping with a centralized database-driven system, ensuring real-time visibility, data accuracy, and operational efficiency for hotel staff.
This system will be developed using C# and MySQL, integrated through MySQL Workbench for database management. It will provide a user-friendly desktop interface that can later be expanded into a web or mobile version if required.
________________________________________
2. System Goals
From a development standpoint, MIMS will:
•	Implement CRUD functionality (Create, Read, Update, Delete) for all inventory records.
•	Use MySQL relational database design for scalable data organization.
•	Include authentication and authorization modules (Admin, Department Head, Staff).
•	Generate dynamic reports and analytics using SQL queries and data visualization.
•	Support modular architecture for easier feature upgrades.
•	Ensure data integrity and security through validations and role-based access control.
________________________________________
3. System Architecture
Architecture Type:
•	3-Layer Architecture (Presentation – Business Logic – Data Access)
Layers Overview:
•	Presentation Layer: C# Windows Forms (or WPF) for GUI; responsive design and clear UX flow.
•	Business Logic Layer: Handles input validation, calculations (e.g., reorder levels), and process automation.
•	Data Access Layer: Uses MySQL queries and stored procedures for efficient and secure data handling.
Data Flow:
User Input → Business Logic Validation → SQL Query Execution → Database Update → UI Feedback
________________________________________
4. Database Design (MySQL)
Main Tables:
•	users – user credentials, roles, and login logs
•	items – item details (name, category, unit, supplier ID, stock quantity, reorder level)
•	suppliers – supplier contact and delivery info
•	transactions – item movement logs (in/out, quantity, date, user ID)
•	purchase_orders – purchase requests, approvals, and fulfillment status
•	notifications – low-stock and expiry alerts
•	audit_logs – record of system actions for accountability
Database Features:
•	Foreign keys to maintain referential integrity
•	Indexing for faster searches
•	Stored procedures for complex transactions
•	Backup and recovery plan
________________________________________
5. Core System Features
1. Dashboard:
•	Real-time summary of total stock, low-stock alerts, and pending orders.
2. Inventory Management:
•	Add, update, or remove items.
•	Track current quantity and item lifecycle.
3. Transaction Logging:
•	Logs all withdrawals, issuances, and deliveries.
•	Supports user tagging for accountability.
4. Purchase Order Module:
•	Department heads can request new materials.
•	Admins can approve, reject, or modify orders.
5. User Authentication & Role Management:
•	Password encryption (e.g., SHA256 or bcrypt).
•	Role-based access: Admin, Staff, Department Head.
6. Reports & Analytics:
•	SQL-based reporting on usage trends, supplier performance, and cost analysis.
•	Export to PDF or Excel.
7. Notifications & Alerts:
•	Automated low-stock and expiry warnings using triggers or scheduled tasks.
________________________________________
6. Technology Stack
Layer	Technology	Description
Frontend	C# (Windows Forms / WPF)	Desktop GUI
Backend	C# (Business Logic)	Input validation, transaction handling
Database	MySQL	Structured data storage
Server	XAMPP / Localhost	Local testing environment
Tools	MySQL Workbench, Visual Studio	Development and database management
Optional	Barcode scanner, Cloud backup	For scalability and efficiency
________________________________________
7. Security Considerations
•	Input Validation: Prevent SQL injection and data corruption.
•	Password Hashing: Store encrypted passwords only.
•	Access Control: Role-based restrictions on CRUD operations.
•	Audit Logging: All user actions are timestamped for traceability.
•	Regular Backups: Automated backups to prevent data loss.
________________________________________
8. Development Timeline (Estimated)
Phase	Task	Duration
Phase 1	System Design & ERD creation	1 week
Phase 2	Database Setup (MySQL)	1 week
Phase 3	UI Design (C#)	1–2 weeks
Phase 4	Business Logic & CRUD Implementation	2 weeks
Phase 5	Reports & Notifications	1 week
Phase 6	Testing & Debugging	1 week
Phase 7	Documentation & Deployment	1 week
________________________________________
9. Expected Outcome
Upon completion, MIMS will provide a reliable, secure, and efficient inventory management platform for the hotel. It will enhance resource tracking, streamline procurement, and deliver actionable insights for decision-making.
Future updates can include:
•	Cloud integration for remote access
•	Mobile app for real-time stock monitoring
•	Integration with accounting or POS systems

