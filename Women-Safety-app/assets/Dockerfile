FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY api.py ./api.py
# Model .pkl files should also be in /app (copy or mount them)

EXPOSE 5000

CMD ["python", "api.py"]