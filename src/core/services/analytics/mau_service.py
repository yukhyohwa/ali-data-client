import pandas as pd
import numpy as np
from src.utils.logger import logger

class MAUService:
    """
    MAU (Monthly Active Users) Prediction Service.
    Uses historical NUU/OUU/RUU and retention rates to predict future growth.
    """
    def __init__(self, data: pd.DataFrame):
        self.raw_data = data.copy()
        self.results_df = None

    def predict(self, months_to_predict: int = 12, growth_factor: float = 1.0) -> pd.DataFrame:
        """
        Predicts MAU for future months.
        growth_factor: Multiplier for NUU (New User Units)
        """
        df = self.raw_data.copy()
        df['data_date'] = pd.to_datetime(df['data_date'])
        df = df.sort_values('data_date').tail(6) # Use last 6 months as baseline

        if df.empty:
            logger.error("No historical data for MAU prediction.")
            return pd.DataFrame()

        # Calculate baseline averages
        avg_nuu = df['nuu'].mean() * growth_factor
        avg_nuu_rr = df['nuu_retention_rate'].mean()
        avg_ouu_rr = df['ouu_retention_rate'].mean()
        avg_ruu_rr = df['ruu_retention_rate'].mean()

        last_date = df['data_date'].iloc[-1]
        last_mau = df['nuu'].iloc[-1] + df['ouu'].iloc[-1] + df['ruu'].iloc[-1]
        
        predictions = []
        current_date = last_date

        for i in range(months_to_predict):
            current_date = current_date + pd.DateOffset(months=1)
            
            # Simplified MAU projection logic
            # Predicted MAU = New + (Existing * Decay) + (Returning)
            # In professional models, this is a Markov chain or Cohort analysis
            pred_nuu = avg_nuu
            pred_ouu = last_mau * avg_ouu_rr # Rough decay of previous MAU
            pred_ruu = avg_nuu * 0.1 # Dynamic returning users (placeholder)
            
            pred_mau = pred_nuu + pred_ouu + pred_ruu
            
            predictions.append({
                'data_date': current_date,
                'nuu': pred_nuu,
                'ouu': pred_ouu,
                'ruu': pred_ruu,
                'mau': pred_mau,
                'is_predicted': True
            })
            last_mau = pred_mau

        pred_df = pd.DataFrame(predictions)
        
        # Merge with history
        history_df = self.raw_data.copy()
        history_df['data_date'] = pd.to_datetime(history_df['data_date'])
        history_df['mau'] = history_df['nuu'] + history_df['ouu'] + history_df['ruu']
        history_df['is_predicted'] = False
        
        self.results_df = pd.concat([history_df, pred_df], ignore_index=True)
        return self.results_df
