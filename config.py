# config.py
import os

# 凭据配置：根据环境和引擎分类
# 建议将敏感信息配置在系统环境变量中，避免硬编码在代码里泄露
CREDENTIALS = {
    'cn': {
        'odps': {
            'access_id': os.getenv('ALIYUN_AK_CN', 'YOUR_ACCESS_ID_CN'),
            'access_key': os.getenv('ALIYUN_SK_CN', 'YOUR_ACCESS_KEY_CN'),
            'endpoint': 'http://service.odps.aliyun.com/api',
            'project': 'g13001230'
        },
        'holo': {
            'host': 'hgprecn-cn-n6w1y5llh002-cn-hangzhou.hologres.aliyuncs.com',
            'port': 80,
            'dbname': 'online',
            'user': os.getenv('ALIYUN_AK_CN', 'YOUR_ACCESS_ID_CN'),
            'password': os.getenv('ALIYUN_SK_CN', 'YOUR_ACCESS_KEY_CN')
        }
    },
    'overseas': {
        'odps': {
            'access_id': os.getenv('ALIYUN_AK_OVERSEAS', 'YOUR_ACCESS_ID_OVERSEAS'),
            'access_key': os.getenv('ALIYUN_SK_OVERSEAS', 'YOUR_ACCESS_KEY_OVERSEAS'),
            'endpoint': 'http://service.ap-northeast-1.maxcompute.aliyun.com/api',
            'project': 'g65002007'
        },
        'holo': {
            'host': 'hgpre-sg-6wr2ald3b002-ap-northeast-1.hologres.aliyuncs.com',
            'port': 80,
            'dbname': 'online',
            'user': os.getenv('ALIYUN_AK_OVERSEAS', 'YOUR_ACCESS_ID_OVERSEAS'),
            'password': os.getenv('ALIYUN_SK_OVERSEAS', 'YOUR_ACCESS_KEY_OVERSEAS')
        }
    }
}

# 默认 SQL 语句 (保持原样)
DEFAULT_SQL = '''
SELECT 1=1 '''