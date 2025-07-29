-- PostgreSQL初始化脚本
-- 创建sniper_bot数据库（如果不存在）

SELECT 'CREATE DATABASE sniper_bot'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'sniper_bot')\gexec