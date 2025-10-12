#!/usr/bin/env python3
"""
Script to check Railway PostgreSQL database for EventJoinRequest table
"""

import os
import psycopg2
from urllib.parse import urlparse

def check_database():
    """Check if EventJoinRequest table exists in Railway database"""
    
    # Get database URL from environment (Railway provides this)
    database_url = os.getenv('DATABASE_URL')
    
    if not database_url:
        print("❌ DATABASE_URL not found in environment")
        print("💡 To check Railway database, you need to:")
        print("   1. Go to your Railway project dashboard")
        print("   2. Click on your PostgreSQL service")
        print("   3. Go to 'Connect' tab")
        print("   4. Copy the connection string")
        print("   5. Set it as DATABASE_URL environment variable")
        return
    
    try:
        # Parse the database URL
        parsed = urlparse(database_url)
        
        # Connect to database
        conn = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port,
            database=parsed.path[1:],  # Remove leading slash
            user=parsed.username,
            password=parsed.password,
            sslmode='require'
        )
        
        cursor = conn.cursor()
        
        # Check if EventJoinRequest table exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'myapp_eventjoinrequest'
            );
        """)
        
        table_exists = cursor.fetchone()[0]
        
        if table_exists:
            print("✅ EventJoinRequest table EXISTS in database")
            
            # Check table structure
            cursor.execute("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = 'myapp_eventjoinrequest'
                ORDER BY ordinal_position;
            """)
            
            columns = cursor.fetchall()
            print("\n📋 Table structure:")
            for col in columns:
                print(f"   - {col[0]}: {col[1]} (nullable: {col[2]}, default: {col[3]})")
            
            # Check if there are any records
            cursor.execute("SELECT COUNT(*) FROM myapp_eventjoinrequest;")
            count = cursor.fetchone()[0]
            print(f"\n📊 Records in table: {count}")
            
        else:
            print("❌ EventJoinRequest table does NOT exist in database")
            print("💡 This means the migration wasn't applied")
            
            # List all tables
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name LIKE 'myapp_%'
                ORDER BY table_name;
            """)
            
            tables = cursor.fetchall()
            print("\n📋 Existing myapp tables:")
            for table in tables:
                print(f"   - {table[0]}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print("\n💡 Alternative ways to check:")
        print("   1. Railway CLI: railway connect")
        print("   2. Railway Dashboard → PostgreSQL → Query tab")
        print("   3. Use a PostgreSQL client like pgAdmin")

if __name__ == "__main__":
    check_database()
