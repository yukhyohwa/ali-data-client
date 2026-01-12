# Ali Data Client

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![Database](https://img.shields.io/badge/Database-ODPS%20%7C%20Hologres-orange)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

**Ali Data Client** is a command-line tool designed to simplify data querying and retrieval from Alibaba Cloud's **ODPS (MaxCompute)** and **Hologres** engines. It supports switching between environments (Domestic/Overseas) and engines seamlessly, allowing users to export results directly to CSV, Excel, or TXT formats.

## Features / 功能

1.  **Multi-Engine Support**: Query data from **ODPS** and **Hologres**.
2.  **Environment Switching**: Easily toggle between China (cn) and Overseas environments.
3.  **SQl File Support**: Execute queries from external `.sql` files.
4.  **Data Persistence**: Export query results to local files (CSV, Excel, TXT).
5.  **Interactive CLI**: Simple command-line interface for ease of use.

## Requirements / 依赖

*   Python 3.x
*   `odps` (PyODPS)
*   `psycopg2` (For Hologres connection)
*   `access` credentials (AK/SK)

## Installation / 安装

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yukhyohwa/ali-data-client.git
    cd ali-data-client
    ```

2.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
    *(Note: If `requirements.txt` is missing, manual install via `pip install pyodps psycopg2 pandas argparse openpyxl`)*

3.  **Configuration**:
    *   Set your Alibaba Cloud Access Key (AK) and Secret Key (SK) in environment variables or `config.py`.
    *   Example using environment variables (Recommended):
        ```bash
        export ALIYUN_AK_CN="your_ak_cn"
        export ALIYUN_SK_CN="your_sk_cn"
        ```

## Usage / 使用方法

### Core Command (Recommended) / 核心命令 (推荐)
**This is the most common use case for querying overseas data using a SQL file:**
```bash
python main.py --env overseas --engine odps --sql_file my_query.sql
```

### 1. Default Query (ODPS - CN)
Execute the default SQL defined in `config.py`.
```bash
python main.py
```

### 2. Specify Environment & Engine
Query Hologres in the Overseas environment.
```bash
python main.py --env overseas --engine holo
```

### 3. Execute SQL from File
Run a specific SQL script.
```bash
python main.py --sql_file ./my_query.sql
```

## Project Structure / 项目结构

```text
ali-data-client/
├── main.py             # Entry point (CLI & Logic)
├── db_client.py        # Database connection engine
├── config.py           # Configuration & Credentials
├── my_query.sql        # Example SQL file
├── output/             # Exported data directory
└── .gitignore
```

## License

[MIT](LICENSE)
