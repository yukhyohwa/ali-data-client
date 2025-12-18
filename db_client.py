# db_client.py
import pandas as pd
import psycopg2
from odps import ODPS
from config import CREDENTIALS

class DataEngine:
    def __init__(self, env, engine_type):
        """初始化引擎配置"""
        self.env = env
        self.engine_type = engine_type
        # 从 config.py 中读取对应的配置
        try:
            self.conf = CREDENTIALS[env][engine_type]
        except KeyError:
            raise ValueError(f"未找到环境 {env} 或引擎 {engine_type} 的配置信息")

    def fetch_data(self, sql):
        """执行 SQL 并统一返回 Pandas DataFrame"""
        if self.engine_type == 'odps':
            return self._query_odps(sql)
        else:
            return self._query_holo(sql)

    def _query_odps(self, sql):
        print(f"[*] 连接到 ODPS ({self.env})...")
        o = ODPS(self.conf['access_id'], self.conf['access_key'], 
                 self.conf['project'], endpoint=self.conf['endpoint'])
        
        print("[*] 正在执行 ODPS 查询 (Reader模式)...")
        with o.execute_sql(sql).open_reader() as reader:
            return reader.to_pandas()

    def _query_holo(self, sql):
        print(f"[*] 连接到 Hologres ({self.env})...")
        conn = psycopg2.connect(
            host=self.conf['host'], port=self.conf['port'],
            dbname=self.conf['dbname'], user=self.conf['user'],
            password=self.conf['password']
        )
        
        print("[*] 正在执行 Hologres 查询...")
        # 使用 pandas 的 read_sql 直接读取，代码更简洁
        try:
            df = pd.read_sql(sql, conn)
        finally:
            conn.close()
        return df