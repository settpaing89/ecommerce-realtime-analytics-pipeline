# Contributing to E-Commerce Analytics Pipeline

Thank you for your interest in contributing to this project! We welcome contributions to improve the documentation, code quality, and features.

## Getting Started

1.  **Fork the repository** to your GitHub account.
2.  **Clone your fork** locally:
    ```bash
    git clone https://github.com/YOUR_USERNAME/ecommerce-realtime-analytics-pipeline.git
    cd ecommerce-realtime-analytics-pipeline
    ```
3.  **Create a virtual environment**:
    ```bash
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

## Development Workflow

1.  **Create a new branch** for your feature or fix:
    ```bash
    git checkout -b feature/your-feature-name
    ```
2.  **Make your changes**. Ensure your code is clean and documented.
3.  **Run tests** to ensure no regressions:
    ```bash
    pytest
    ```
4.  **Commit your changes** using conventional commits:
    ```bash
    git commit -m "feat: add new data validation rule"
    ```
    *   `feat`: A new feature
    *   `fix`: A bug fix
    *   `docs`: Documentation only changes
    *   `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
    *   `refactor`: A code change that neither fixes a bug nor adds a feature
    *   `perf`: A code change that improves performance
    *   `test`: Adding missing tests or correcting existing tests

## Pull Request Process

1.  **Push your branch** to GitHub:
    ```bash
    git push origin feature/your-feature-name
    ```
2.  **Open a Pull Request** against the `main` branch of the original repository.
3.  Provide a clear description of your changes and reference any related issues.

## Style Guide

*   **Python**: Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/).
*   **Terraform**: Use `terraform fmt` to format your code.
*   **SQL**: Keywords should be uppercase (e.g., `SELECT`, `FROM`).

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
