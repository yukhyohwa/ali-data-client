import argparse
import os
import sys  # 必须导入这个，否则 sys.exit(1) 会报错
from db_client import DataEngine
from config import DEFAULT_SQL

def save_data(df, prefix):
    """保存数据到脚本同级的 output 文件夹"""
    # 1. 获取当前脚本所在的绝对路径 (确保在任何地方运行都能找到正确位置)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 2. 强制指定保存到脚本同级的 output 文件夹
    output_dir = os.path.join(script_dir, "output")
    
    # 如果目录不存在，自动创建
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # 3. 拼接完整路径 (不含后缀)
    full_path_prefix = os.path.join(output_dir, prefix)

    # 定义保存格式
    formats = {
        '1': ('CSV', lambda: df.to_csv(f"{full_path_prefix}.csv", index=False, encoding='utf-8-sig')),
        '2': ('Excel', lambda: df.to_excel(f"{full_path_prefix}.xlsx", index=False)),
        '3': ('TXT', lambda: df.to_csv(f"{full_path_prefix}.txt", sep='\t', index=False))
    }
    
    print("\n" + "-"*30)
    print(f"[?] 请选择保存格式 (文件将存入: {output_dir})")
    for k, v in formats.items(): 
        print(f"   {k}. {v[0]}")
    print("   4. 全部保存")
    
    choice = input(">> ").strip()
    
    selected = []
    if choice == '4':
        selected = formats.keys()
    elif choice in formats:
        selected = [choice]
    else:
        print(f"[!] 输入了 '{choice}'，无效选项，未保存文件！")
        return

    for key in selected:
        name, func = formats[key]
        try:
            func()
            # 简单的后缀判断用于显示
            ext = "csv" if key == '1' else "xlsx" if key == '2' else "txt"
            final_file = f"{full_path_prefix}.{ext}"
            
            print(f"[+] 成功保存! 路径 -> {final_file}") 
        except Exception as e:
            print(f"[!] {name} 保存失败: {e}")

def load_sql_from_file(file_path):
    """读取 SQL 文件内容"""
    if not os.path.exists(file_path):
        print(f"[!] 错误: 找不到文件 {file_path}")
        sys.exit(1)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"[!] 读取 SQL 文件失败: {e}")
        sys.exit(1)

def main():
    # 1. 解析参数
    parser = argparse.ArgumentParser(description="ODPS/HOLO 数据查询助手")
    parser.add_argument('--env', choices=['cn', 'overseas'], default='cn', help='环境: cn 或 overseas')
    parser.add_argument('--engine', choices=['odps', 'holo'], default='odps', help='引擎: odps 或 holo')
    
    # SQL文件路径参数
    parser.add_argument('--sql_file', type=str, default=None, 
                        help='SQL 脚本文件的路径 (例如: query.sql)。如果不填，将使用 config.py 中的默认 SQL。')
    
    args = parser.parse_args()

    # 2. 确定使用哪段 SQL
    if args.sql_file:
        print(f"[*] 正在读取 SQL 文件: {args.sql_file}")
        target_sql = load_sql_from_file(args.sql_file)
    else:
        print("[*] 未指定 SQL 文件，使用 config.py 中的默认 SQL")
        target_sql = DEFAULT_SQL

    # 3. 初始化引擎并查询
    try:
        engine = DataEngine(args.env, args.engine)
        
        # 获取数据
        df = engine.fetch_data(target_sql)
        
        # 结果判断
        if df.empty:
            print("[!] 查询成功，但结果集为空。")
            return

        # 4. 预览数据
        print("\n" + "="*20 + " 数据预览 (Sample) " + "="*20)
        print(df.head(10)) 
        print("="*50)
        print(f"[*] 数据概览: 共 {len(df)} 行, {len(df.columns)} 列")

        # 5. 确认下载
        confirm = input("\n[?] 确认下载这些数据吗? (y/n): ").lower()
        if confirm == 'y':
            default_name = "data_result"
            out_name = input(f"[?] 请输入文件名前缀 (回车使用默认 '{default_name}'): ").strip()
            if not out_name: 
                out_name = default_name
            
            save_data(df, out_name)
            print("\n[*] 任务完成。")
        else:
            print("[*] 已取消下载。")

    except Exception as e:
        print(f"\n[!] 运行过程中发生错误: {e}")

if __name__ == "__main__":
    main()