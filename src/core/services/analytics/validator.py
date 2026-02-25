import pandas as pd
import numpy as np
from src.utils.logger import logger

class DataValidator:
    """
    Data cleaning and validation layer to ensure data quality
    before passing it to analytical models.
    """
    @staticmethod
    def clean_ltv_data(df: pd.DataFrame) -> pd.DataFrame:
        """
        Cleans data for LTV prediction.
        Expected columns: num_day, actual_rr, actual_arpu
        """
        required_cols = ['num_day', 'actual_rr', 'actual_arpu']
        missing = [c for c in required_cols if c not in df.columns]
        if missing:
            raise ValueError(f"Missing required columns for LTV: {missing}")

        # Drop rows with invalid num_day
        df = df[df['num_day'] > 0].copy()
        
        # Fill missing numeric values with 0 or interpolate
        df['actual_rr'] = pd.to_numeric(df['actual_rr'], errors='coerce').fillna(0)
        df['actual_arpu'] = pd.to_numeric(df['actual_arpu'], errors='coerce').fillna(0)
        
        # Ensure num_day is integer
        df['num_day'] = df['num_day'].astype(int)
        
        # Sort by num_day
        df = df.sort_values('num_day')
        
        logger.info(f"Data validated: {len(df)} rows ready for LTV prediction.")
        return df

    @staticmethod
    def clean_mau_data(df: pd.DataFrame) -> pd.DataFrame:
        """
        Cleans data for MAU prediction.
        Expected columns: data_date, nuu, ouu, ruu, nuu_retention_rate, ouu_retention_rate, ruu_retention_rate
        """
        required_cols = ['data_date', 'nuu', 'ouu', 'ruu']
        missing = [c for c in required_cols if c not in df.columns]
        if missing:
            raise ValueError(f"Missing required columns for MAU: {missing}")

        # Ensure numeric columns
        numeric_cols = ['nuu', 'ouu', 'ruu', 'nuu_retention_rate', 'ouu_retention_rate', 'ruu_retention_rate']
        for col in [c for c in numeric_cols if c in df.columns]:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
            
        # Date conversion
        df['data_date'] = pd.to_datetime(df['data_date'], errors='coerce')
        df = df.dropna(subset=['data_date']).copy()
        
        df = df.sort_values('data_date')
        logger.info(f"Data validated: {len(df)} months ready for MAU prediction.")
        return df
