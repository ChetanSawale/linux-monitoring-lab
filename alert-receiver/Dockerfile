FROM python:3.12-slim
WORKDIR /srv
COPY receiver.py .
RUN mkdir -p /data
EXPOSE 5001
CMD ["python", "receiver.py"]
