"""
Unit tests for data transformation functions
"""

import pytest
import pandas as pd
import sys

sys.path.append("src/processing")

from transform_bronze_to_silver import (
    transform_customers,
    transform_products,
    transform_orders,
)


def test_transform_customers_removes_duplicates():
    """Test that duplicate customers are removed"""
    df = pd.DataFrame(
        {
            "customer_id": ["C1", "C1", "C2"],
            "email": ["test@example.com", "test@example.com", "user@example.com"],
            "phone": ["1234567890", "1234567890", "0987654321"],
        }
    )

    result = transform_customers(df)

    assert len(result) == 2, "Should have 2 unique customers"
    assert result["customer_id"].nunique() == 2


def test_transform_customers_standardizes_email():
    """Test email standardization"""
    df = pd.DataFrame(
        {
            "customer_id": ["C1"],
            "email": ["  TEST@EXAMPLE.COM  "],
            "phone": ["1234567890"],
        }
    )

    result = transform_customers(df)

    assert result["email"].iloc[0] == "test@example.com"


def test_transform_products_filters_negative_prices():
    """Test that products with negative prices are filtered"""
    df = pd.DataFrame(
        {
            "product_id": ["P1", "P2", "P3"],
            "product_name": ["Item1", "Item2", "Item3"],
            "base_price": [100, -50, 200],
            "current_price": [90, 40, 180],
            "cost": [60, 30, 120],
        }
    )

    result = transform_products(df)

    assert len(result) == 2, "Should filter out negative prices"
    assert all(result["base_price"] > 0)


def test_transform_orders_removes_invalid():
    """Test that invalid orders are filtered"""
    df = pd.DataFrame(
        {
            "order_id": ["O1", "O2", "O3", "O4"],
            "customer_id": ["C1", "C2", "C3", "C4"],
            "product_id": ["P1", "P2", "P3", "P4"],
            "total_amount": [100, -50, 200, 10],
            "quantity": [1, 2, 0, 1],
            "order_date": ["2025-01-01", "2025-01-02", "2025-01-03", "2025-01-04"],
            "status": ["delivered", "pending", "shipped", "delivered"],
        }
    )

    result = transform_orders(df)

    # Should remove orders with negative amount or zero quantity
    assert len(result) == 2
    assert all(result["total_amount"] > 0)
    assert all(result["quantity"] > 0)


def test_transform_orders_extracts_date_components():
    """Test date component extraction"""
    df = pd.DataFrame(
        {
            "order_id": ["O1"],
            "customer_id": ["C1"],
            "product_id": ["P1"],
            "total_amount": [100],
            "quantity": [1],
            "order_date": ["2025-01-15 14:30:00"],
            "status": ["delivered"],
        }
    )

    result = transform_orders(df)

    assert "order_year" in result.columns
    assert "order_month" in result.columns
    assert "order_day" in result.columns
    assert result["order_year"].iloc[0] == 2025
    assert result["order_month"].iloc[0] == 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
