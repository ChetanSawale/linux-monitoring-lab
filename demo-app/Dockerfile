FROM python:3.12-slim
WORKDIR /srv
COPY app.py .
RUN pip install --no-cache-dir prometheus_client
EXPOSE 8080
CMD ["python", "app.py"]
