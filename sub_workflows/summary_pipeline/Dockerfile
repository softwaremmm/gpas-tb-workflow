# Python 3.11 base image
FROM python:3.11

# Add Python files from repo to Docker image
COPY ./src /app/src
COPY ./pyproject.toml /app/pyproject.toml

# Set the working directory within the container
WORKDIR /app

# Install Python package which makes summaries
RUN pip install .

# Run summary_json (In practice this command will be overriden by NextFlow)
CMD ["summary_json"]