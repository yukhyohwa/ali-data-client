import pandas as pd
import numpy as np
from scipy.optimize import curve_fit
from datetime import datetime
from src.utils.logger import logger

def power_function(num_day, a, b):
    """Model for LTV/Retention fitting: y = a * x^b"""
    return a * num_day**b

class LTVService:
    """
    Professional LTV Prediction Service
    Encapsulates retention fitting, ARPU prediction, and ROI analysis.
    """
    def __init__(self, data: pd.DataFrame):
        self.raw_data = data.copy()
        self.results_df = None
        self.params_retention = None

    def _fit_retention(self, df):
        try:
            fit_data = df.dropna(subset=['actual_rr'])
            fit_data = fit_data[fit_data['num_day'] > 1]
            if len(fit_data) < 2:
                return None, None
            x_data = fit_data['num_day'].values - 1
            y_data = fit_data['actual_rr'].values
            params, _ = curve_fit(power_function, x_data, y_data, maxfev=2000)
            return params
        except Exception as e:
            logger.error(f"Retention fitting error: {e}")
            return None

    def predict(self, ecpnu: float = 50.0, net_rate: float = 0.35) -> pd.DataFrame:
        df = self.raw_data.copy()
        retention_params = self._fit_retention(df)
        if retention_params is not None:
            a_fit, b_fit = retention_params
            self.params_retention = (a_fit, b_fit)
            df['predicted_rr'] = np.where(df['num_day'] == 1, 1.0, power_function(df['num_day'] - 1, a_fit, b_fit))
        else:
            df['predicted_rr'] = df['actual_rr'].fillna(0)

        actual_arpu = df['actual_arpu'].values
        num_rows = len(df)
        pred_arpu = np.zeros(num_rows)
        cumulative_error = np.zeros(num_rows)
        cumulative_actual_arpu = np.zeros(num_rows)
        cumulative_pred_arpu = np.zeros(num_rows)

        has_actual_arpu = not np.isnan(actual_arpu[0])
        pred_arpu[0] = actual_arpu[0] if has_actual_arpu else 0
        cumulative_actual_arpu[0] = pred_arpu[0]
        cumulative_pred_arpu[0] = pred_arpu[0]

        for i in range(1, num_rows):
            history_start = max(0, i - 7)
            history_window = actual_arpu[history_start:i]
            valid_history = history_window[~np.isnan(history_window)]
            avg_val = np.mean(valid_history) if len(valid_history) > 0 else 0
            pred_arpu[i] = avg_val * (1 - cumulative_error[i-1]) if not np.isnan(actual_arpu[i]) else avg_val
            current_actual = actual_arpu[i] if not np.isnan(actual_arpu[i]) else 0
            cumulative_actual_arpu[i] = cumulative_actual_arpu[i-1] + current_actual
            cumulative_pred_arpu[i] = cumulative_pred_arpu[i-1] + pred_arpu[i]
            if cumulative_actual_arpu[i] > 0:
                cumulative_error[i] = (cumulative_pred_arpu[i] / cumulative_actual_arpu[i]) - 1
            else:
                cumulative_error[i] = 0

        df['predicted_arpu'] = pred_arpu
        df['predicted_ltv'] = np.cumsum(df['predicted_arpu'] * df['predicted_rr'])
        last_ltv = df['predicted_ltv'].iloc[-1]
        if last_ltv > 0:
            growth_rate = last_ltv / df['predicted_ltv']
            df['required_ltv'] = (ecpnu / net_rate) / growth_rate
        else:
            df['required_ltv'] = np.nan

        self.results_df = df
        return df

    def get_summary_benchmarks(self) -> pd.DataFrame:
        if self.results_df is None: return pd.DataFrame()
        benchmarks = [1, 3, 7, 14, 30, 60, 90]
        selected_indices = []
        for d in benchmarks:
            closest_idx = (self.results_df['num_day'] - d).abs().idxmin()
            selected_indices.append(closest_idx)
        return self.results_df.loc[selected_indices].copy()
