# ML Upgrade Plan - Classification Engine

## Overview

The current rule-based classification engine is designed with a **pluggable architecture** that allows seamless migration to ML-based classification. This document outlines the complete upgrade path.

---

## Current Architecture (Rule-Based)

```python
class BaseClassifier(ABC):
    @abstractmethod
    async def classify(self, user_id: int, db: AsyncSession) -> ClassificationResult:
        pass

class RuleBasedClassifier(BaseClassifier):
    # Weighted scoring across 6 dimensions
    async def classify(self, user_id, db) -> ClassificationResult:
        metrics = await self._compute_behavior_metrics(user_id, db)
        scores = self._compute_scores(metrics)
        return ClassificationResult(user_type=top_type, confidence=confidence, scores=scores)

class MLClassifier(BaseClassifier):
    # Placeholder - ready for implementation
    pass

def get_classifier() -> BaseClassifier:
    if settings.USE_ML_CLASSIFIER:
        return MLClassifier()
    return RuleBasedClassifier()
```

**Key:** Change `USE_ML_CLASSIFIER=true` in config to switch. No other code changes needed.

---

## Phase 1: Data Collection Pipeline (Month 1-2)

### 1.1 Feature Engineering
Extract features from existing database tables:

```python
# Features per user (computed from raw behavioral data)
features = {
    # Browsing Features
    'total_product_views': int,
    'unique_products_viewed': int,
    'avg_time_per_product': float,
    'category_diversity': float,       # unique categories / total views
    'brand_concentration': float,      # top_brand_views / total_views
    
    # Search Features
    'total_searches': int,
    'search_to_click_rate': float,
    'avg_results_clicked': float,
    
    # Cart/Wishlist Features
    'cart_add_rate': float,
    'wishlist_add_rate': float,
    'cart_abandonment_rate': float,
    
    # Purchase Features
    'total_orders': int,
    'avg_order_value': float,
    'purchase_frequency': float,       # orders / days_active
    'discount_purchase_ratio': float,  # discounted_purchases / total
    'premium_purchase_ratio': float,
    
    # Engagement Features
    'session_frequency': float,
    'actions_per_session': float,
    'feature_usage_depth': float,
    'review_count': int,
    'share_count': int,
    
    # Price Sensitivity
    'avg_viewed_price': float,
    'price_filter_usage': int,
    'coupon_apply_count': int,
}
```

### 1.2 Data Export Script
```python
# ml_pipeline/export_training_data.py
async def export_training_data():
    """Export labeled data from user_analytics + user_type_history."""
    # Query user_analytics for feature vectors
    # Use current user_type as label (from rule-based classification)
    # Export as CSV for model training
```

### 1.3 Label Strategy
- **Initial labels:** Use rule-based classification results as ground truth
- **Refinement:** Manual review of edge cases (confidence < 0.4)
- **Feedback loop:** Track classification-to-action correlation

---

## Phase 2: Model Training (Month 2-3)

### 2.1 Model Selection

| Model | Pros | Cons | Recommended For |
|-------|------|------|-----------------|
| Random Forest | Explainable, fast | Limited patterns | Initial deployment |
| XGBoost | High accuracy, handles imbalance | Needs tuning | Production upgrade |
| Neural Network | Complex patterns | Black box, needs data | Future iteration |
| K-Means Clustering | Unsupervised, discovers types | Fixed clusters | Discovery phase |

### 2.2 Training Pipeline

```python
# ml_pipeline/train_model.py
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import joblib

def train_classifier():
    # Load exported data
    df = pd.read_csv('data/user_features.csv')
    
    # Feature matrix and labels
    feature_cols = [col for col in df.columns if col not in ['user_id', 'user_type']]
    X = df[feature_cols]
    y = df['user_type']
    
    # Split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y)
    
    # Train
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate
    y_pred = model.predict(X_test)
    print(classification_report(y_test, y_pred))
    
    # Save
    joblib.dump(model, 'models/user_classifier_v1.pkl')
    
    # Feature importance
    importances = pd.Series(model.feature_importances_, index=feature_cols)
    print("\nTop 10 Features:")
    print(importances.nlargest(10))
```

### 2.3 Evaluation Metrics
- **Accuracy:** Overall classification correctness
- **F1-Score per class:** Balance precision/recall per user type
- **Confusion Matrix:** Identify misclassification patterns
- **Confidence Calibration:** Predicted probabilities match actual frequencies

---

## Phase 3: MLClassifier Implementation (Month 3-4)

```python
# backend/app/classification/ml_classifier.py
import joblib
import numpy as np
from .engine import BaseClassifier, ClassificationResult

class MLClassifier(BaseClassifier):
    def __init__(self):
        self.model = joblib.load('models/user_classifier_v1.pkl')
        self.feature_names = self.model.feature_names_in_
        self.user_types = ['exploration', 'brand', 'price', 
                          'interaction', 'offer', 'premium']
    
    async def classify(self, user_id: int, db: AsyncSession) -> ClassificationResult:
        # Compute feature vector (reuse same metric computation)
        features = await self._extract_features(user_id, db)
        
        # Prepare input
        X = np.array([[features.get(f, 0) for f in self.feature_names]])
        
        # Predict with probabilities
        prediction = self.model.predict(X)[0]
        probabilities = self.model.predict_proba(X)[0]
        
        # Build scores dict
        scores = {
            self.user_types[i]: float(probabilities[i])
            for i in range(len(self.user_types))
        }
        
        confidence = float(max(probabilities))
        
        return ClassificationResult(
            user_type=prediction,
            confidence=confidence,
            scores=scores
        )
    
    async def _extract_features(self, user_id, db):
        """Extract the same features used during training."""
        # Reuse metric computation from RuleBasedClassifier
        rule_classifier = RuleBasedClassifier()
        metrics = await rule_classifier._compute_behavior_metrics(user_id, db)
        return metrics
```

---

## Phase 4: A/B Testing (Month 4-5)

### Experiment Design
```python
# Randomly assign users to rule-based vs ML classifier
async def classify_user(user_id, db):
    if user_id % 2 == 0:  # Simple split
        classifier = RuleBasedClassifier()
        source = 'rule_based'
    else:
        classifier = MLClassifier()
        source = 'ml'
    
    result = await classifier.classify(user_id, db)
    
    # Log for comparison
    await log_classification(user_id, result, source)
    return result
```

### Metrics to Compare
- Conversion rate (purchases / sessions)
- Average session duration
- Cart abandonment rate
- User type stability (fewer unnecessary switches = better)
- User satisfaction (if surveys available)

---

## Phase 5: Continuous Learning (Month 5+)

### Online Learning Pipeline
1. **Collect:** New user behaviors continuously
2. **Retrain:** Monthly model retraining with latest data
3. **Evaluate:** Compare new model vs. production model
4. **Deploy:** Auto-deploy if metrics improve
5. **Monitor:** Track model drift and classification distribution

### Model Versioning
```
models/
├── user_classifier_v1.pkl      # Initial RF model
├── user_classifier_v2.pkl      # XGBoost upgrade
├── model_metrics.json          # Performance history
└── feature_importance.json     # Feature tracking
```

---

## Files to Create for ML Pipeline

```
ml_pipeline/
├── requirements.txt            # scikit-learn, xgboost, pandas, joblib
├── export_training_data.py     # Extract features from DB
├── feature_engineering.py      # Feature computation
├── train_model.py             # Model training script
├── evaluate_model.py          # Evaluation and metrics
├── predict.py                 # Inference utilities
└── models/
    └── .gitkeep
```

---

## Configuration Switch

In `backend/app/core/config.py`:
```python
USE_ML_CLASSIFIER: bool = False  # Set True when ML model is ready
ML_MODEL_PATH: str = "models/user_classifier_v1.pkl"
```

**Zero-downtime switch:** Change env variable → restart server → ML classifier active.
