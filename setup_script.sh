#!/bin/bash

# Thirty Bees Docker Setup Script
echo "==================================="
echo "Thirty Bees 1.6 Docker Setup"
echo "==================================="

# Create necessary directories
echo "Creating directories..."
mkdir -p html
mkdir -p uploads
mkdir -p logs
mkdir -p mysql-init

# Set permissions
echo "Setting permissions..."
chmod 777 html uploads logs

# Create MySQL initialization script
cat > mysql-init/01-init.sql << 'EOF'
-- Initialize Thirty Bees database
CREATE DATABASE IF NOT EXISTS thirtybees CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON thirtybees.* TO 'thirtybees'@'%';
FLUSH PRIVILEGES;

-- Set MySQL settings for Thirty Bees
SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
EOF

# Create .env file for environment variables
cat > .env << 'EOF'
# MySQL Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=thirtybees
MYSQL_USER=thirtybees
MYSQL_PASSWORD=thirtybees_password

# Thirty Bees Configuration
TB_DB_HOST=mysql
TB_DB_PORT=3306
TB_DB_NAME=thirtybees
TB_DB_USER=thirtybees
TB_DB_PASSWORD=thirtybees_password
EOF

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Build and start the containers:"
echo "   docker-compose up --build -d"
echo ""
echo "2. Wait for the containers to start (about 2-3 minutes)"
echo ""
echo "3. Access Thirty Bees installation:"
echo "   - Web installer: http://localhost:9080"
echo "   - PHPMyAdmin: http://localhost:7080"
echo ""
echo "4. During installation, use these database settings:"
echo "   - Database Host: mysql"
echo "   - Database Name: thirtybees"
echo "   - Database User: thirtybees"
echo "   - Database Password: thirtybees_password"
echo ""
echo "5. Monitor the installation:"
echo "   docker-compose logs -f thirtybees"
echo ""
echo "6. To stop the containers:"
echo "   docker-compose down"
echo ""
echo "7. To remove everything including data:"
echo "   docker-compose down -v"
echo ""
echo "==================================="