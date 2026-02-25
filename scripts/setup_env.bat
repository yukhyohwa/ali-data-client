@echo off
:: setup_env.bat
:: 快速配置 Python 环境和必要的依赖

cd /d "%~dp0.."

echo Creating Virtual Environment...
python -m venv venv

echo Activating Environment...
call venv\Scripts\activate

echo Installing Dependencies...
pip install --upgrade pip
pip install -r requirements.txt

echo Installing Playwright Browsers (for TA Engine)...
python -m playwright install chromium

echo.
echo Environment setup complete! 
echo Run 'venv\Scripts\activate' to start working.
pause
