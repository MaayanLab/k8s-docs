FROM python
ADD requirements.txt requirements.txt
RUN pip install -r requirements.txt
ADD app.py app.py
CMD ["python", "app.py"]