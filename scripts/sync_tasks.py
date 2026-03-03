
import os
import json
import re

# =================关键词配置=================
# SQL 库中存放任务 SQL 的目录
SQL_LIB_JOBS = r"C:\Users\5xgames\Desktop\github\fivecross-sql-lib\tasks\jobs"
# Client 库中存放定时任务配置的 JSON 文件
CLIENT_CONFIG = r"C:\Users\5xgames\Desktop\github\fivecross-data-client\tasks\configs\scheduled_multi_tasks.json"
# ===========================================

def parse_sql_meta(file_path):
    """
    从 SQL 注释中提取元数据。
    支持格式: 
    -- ENGINE: odps
    -- REGION: global
    -- MAILTO: example@5xgames.com
    """
    meta = {
        "engine": "odps", 
        "region": "global", 
        "formats": ["xlsx"]
    }
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # 只读取前 20 行以提高性能
            head = "".join([f.readline() for _ in range(20)])
            
            # 引擎匹配
            engine_match = re.search(r'--\s*ENGINE:\s*(\w+)', head, re.I)
            if engine_match: meta["engine"] = engine_match.group(1).lower()
            
            # 区域匹配
            region_match = re.search(r'--\s*REGION:\s*(\w+)', head, re.I)
            if region_match: meta["region"] = region_match.group(1).lower()
            
            # 收件人匹配
            mailto_match = re.search(r'--\s*MAILTO:\s*([^\n\r]+)', head, re.I)
            if mailto_match:
                emails = [e.strip() for e in mailto_match.group(1).split(',') if '@' in e]
                if emails: meta["mailto"] = ",".join(emails)
    except Exception as e:
        print(f"Warning: Could not parse meta for {file_path}: {e}")
    return meta

def main():
    print(f"开始同步任务自: {SQL_LIB_JOBS}")
    
    if not os.path.exists(SQL_LIB_JOBS):
        print(f"❌ 错误: 找不到 SQL 任务目录 {SQL_LIB_JOBS}")
        return

    tasks = []
    # 递归遍历目录寻找 SQL 文件
    for root, dirs, files in os.walk(SQL_LIB_JOBS):
        for f in files:
            if f.endswith('.sql'):
                full_path = os.path.join(root, f)
                meta = parse_sql_meta(full_path)
                
                # 构造任务配置
                task = {
                    "name": f.replace('.sql', ''),
                    "engine": meta["engine"],
                    "region": meta["region"],
                    "file": full_path, # 使用绝对路径，main.py 兼容
                    "formats": meta["formats"],
                    "enabled": True
                }
                
                if "mailto" in meta:
                    task["mailto"] = meta["mailto"]
                
                tasks.append(task)
                print(f"  + 发现任务: {task['name']} ({task['engine']})")

    # 写入 JSON
    try:
        # 如果文件已存在，可以选择保留一些原有配置或直接覆盖
        # 此处选择直接基于文件夹内容生成，因为用户希望全自动化
        with open(CLIENT_CONFIG, 'w', encoding='utf-8') as jf:
            json.dump(tasks, jf, indent=4, ensure_ascii=False)
        print(f"\n✅ 成功将 {len(tasks)} 个任务写入 {CLIENT_CONFIG}")
    except Exception as e:
        print(f"❌ 写入配置失败: {e}")

if __name__ == "__main__":
    main()
